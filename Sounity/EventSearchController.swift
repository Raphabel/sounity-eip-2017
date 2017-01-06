//
//  EventSearchController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import CoreLocation
import LiquidFloatingActionButton
import PullToRefresh
import QRCodeReader
import AVFoundation
import StatefulViewController
import PureLayout
import DZNEmptyDataSet

class EventSearchController: UIViewController, UITableViewDelegate, UISearchBarDelegate, LiquidFloatingActionButtonDelegate, CLLocationManagerDelegate, StatefulViewController, DZNEmptyDataSetDelegate {

    
    //MARK: UIElements variables
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var musicSearchBox: UISearchBar!
    @IBOutlet weak var showCancelButtonSwitch: UISwitch!
    
    //MARK: Floating buttons variables
    var cells: [LiquidFloatingCell] = []
    var floatingActionButton: LiquidFloatingActionButton!
    
    //MARK: Infos user connected
    var user = UserConnect()
    
    //MARK: SearchBox variables
    var timer: Timer? = nil
    var textSearchBox : String = ""
    var searchActive : Bool = false
    
    //MARK: Locations variables
    var locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    
    //MARK: Result from Research
    var resultResearch = [Event]()
    
    // MARK: QRCode reader functions
    lazy var reader = QRCodeReaderViewController(builder: QRCodeReaderViewControllerBuilder {
        $0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
        $0.showTorchButton = true
    })
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.emptyDataSetSource = self
        tableview.emptyDataSetDelegate = self
        tableview.tableFooterView = UIView()
        
        self.musicSearchBox.delegate = self
        self.musicSearchBox.placeholder = "Search for an event here"
        
        self.setFloatingButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        resultResearch.removeAll()
        tableview.reloadData()
        
        loadingView = LoadingView(_view: self.tableview)
        
        setupInitialViewState()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        else {
            let alert = DisplayAlert(title: "GPS", message: "Location service diasabled")
            alert.openAlertError()
        }

        self.getAllEventsAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let refresher = PullToRefresh()
        tableview.addPullToRefresh(refresher) {
            self.getAllEventsAround()
        }
    }
    
    deinit {
        self.tableview.removePullToRefresh(tableview.topPullToRefresh!)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showDetailEventFromHome") {
            let eventIndex = tableview.indexPathForSelectedRow?.row
            
            let navController = segue.destination as! UINavigationController
            let detailController = navController.topViewController as! ConsultEventController
            detailController.idEventSent = self.resultResearch[eventIndex!].id
            navController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        }
    }
}

//MARK: Initialisation functions
extension EventSearchController {
    func setFloatingButton () {
        let createButton: (CGRect, LiquidFloatingActionButtonAnimateStyle) -> LiquidFloatingActionButton = { (frame, style) in
            let floatingActionButton = LiquidFloatingActionButton(frame: frame)
            floatingActionButton.animateStyle = style
            floatingActionButton.dataSource = self
            floatingActionButton.delegate = self
            floatingActionButton.color = ColorSounity.orangeSounity
            return floatingActionButton
        }
        
        let cellFactory: (String) -> LiquidFloatingCell = { (iconName) in
            return LiquidFloatingCell(icon: UIImage(named: iconName)!)
        }
        cells.append(cellFactory("ic_event"))
        cells.append(cellFactory("qr_code"))
        
        let floatingFrame = CGRect(x: self.view.frame.width - 56 - 16, y: self.view.frame.height - 56 - 125, width: 56, height: 56)
        let bottomRightButton = createButton(floatingFrame, .up)
        
        self.view.addSubview(bottomRightButton)
    }
    
    func getAllEventsAround () {
        let api = SounityAPI()
        let parameters = [
            "latitude": self.currentLocation.coordinate.latitude.isNaN ? 48.85341 : self.currentLocation.coordinate.latitude,
            "longitude": self.currentLocation.coordinate.longitude.isNaN ? 2.3488 : self.currentLocation.coordinate.longitude
        ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        self.startLoading()
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.GET_ALL_EVENTS), method: .get, parameters: parameters, headers : headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Consult Event", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.resultResearch.removeAll();
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.resultResearch.append(Event(_id: subJson["id"].intValue, _userMax: subJson["user_max"].intValue, _lat: subJson["latitude"].doubleValue, _long: subJson["longitude"].doubleValue, _started: subJson["started"].boolValue, _public: subJson["public"].boolValue, _name: subJson["name"].stringValue, _desc: subJson["description"].stringValue, _picture: subJson["picture"].stringValue, _created: subJson["created_date"].stringValue, _expired: subJson["expired_date"].stringValue, _locationName: subJson["location_name"].stringValue, _isOwner: subJson["isOwner"].boolValue, _isAdmin: subJson["isAdmin"].boolValue))
                        }
                        self.tableview.endRefreshing(at: Position.top)
                        self.tableview.reloadData()
                    }
                }
                else {
                    self.resultResearch.removeAll();
                    self.tableview.endRefreshing(at: Position.top)
                    self.tableview.reloadData()
                }
                
                self.endLoading()
        }
    }
}

//MARK: SearchBox functions
extension EventSearchController {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { searchActive = true; }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { searchActive = false; }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchActive = false; searchBar.resignFirstResponder() }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(EventSearchController.searchResultFromString(_:)), userInfo: searchText, repeats: false)
    }
    func searchResultFromString(_ timer: Timer) {
        self.textSearchBox = timer.userInfo! as! String
        
        if (self.textSearchBox.isEmpty) {
            self.getAllEventsAround()
            return
        }
        
        let api = SounityAPI()
        let parameters = [ "q": timer.userInfo! ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        self.resultResearch.removeAll();
        
        if Reachability.isConnectedToNetwork() == true {
            self.startLoading()
            
            Alamofire.request(api.getRoute(SounityAPI.ROUTES.SEARCH_USER), method: .post, parameters: parameters, headers : headers)
                .validate(statusCode: 200..<305)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! != 200) {
                            let alert = DisplayAlert(title: "Add Music", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            for (_,subJson):(String, JSON) in jsonResponse["events"] {
                                self.resultResearch.append(Event(_id: subJson["id"].intValue, _userMax: subJson["user_max"].intValue, _lat: subJson["latitude"].doubleValue, _long: subJson["longitude"].doubleValue, _started: subJson["started"].boolValue, _public: subJson["public"].boolValue, _name: subJson["name"].stringValue, _desc: subJson["description"].stringValue, _picture: subJson["picture"].stringValue, _created: subJson["created_date"].stringValue, _expired: subJson["expired_date"].stringValue, _locationName: subJson["location_name"].stringValue, _isOwner: subJson["isOwner"].boolValue, _isAdmin: subJson["isAdmin"].boolValue))
                            }
                            self.tableview.reloadData()
                        }
                    }
                    else {
                        self.tableview.reloadData()
                    }
                    self.endLoading()
            }
        } else {
            self.tableview.reloadData()
            
            let alert = DisplayAlert(title: "No connection", message: "Please check your internet connection")
            alert.openAlertError()
        }
    }
}

//MARK: QRCode functions
extension EventSearchController: QRCodeReaderViewControllerDelegate {
    func scanQRCodeEvent() {
        if QRCodeReader.supportsMetadataObjectTypes() {
            reader.modalPresentationStyle = .formSheet
            reader.delegate = self
            reader.completionBlock = { (result: QRCodeReaderResult?) in
                if let result = result {
                    print("Completion with result: \(result.value) of type \(result.metadataType)")
                }
            }
            present(reader, animated: true, completion: nil)
        }
        else {
            let alert = DisplayAlert(title: "Error", message: "Reader not supported by the current device")
            alert.openAlertError()
        }
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
        if let cameraName = newCaptureDevice.device.localizedName {
            print("Switching capturing to: \(cameraName)")
        }
    }
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        self.dismiss(animated: true) { [weak self] in
            let idEventScanned = Int(result.value)
            self!.getEventInfoById(idEventScanned!)
        }
    }
    
    func getEventInfoById(_ idEventScanned: Int) {
        let api = SounityAPI()
        let parameters = [ "id": idEventScanned ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT), method: .get, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Consult Event", message: jsonResponse["message"].stringValue)
                        self.present(alert.getPopAlert() , animated : true, completion : nil)
                    }
                    else {
                        if (jsonResponse["owner"]["id"].intValue == self.user.id) {
                            if (!jsonResponse["started"].boolValue) {
                                self.startEventByOwner(idEventScanned, nameEvent: jsonResponse["name"].stringValue, owner: true)
                            } else {
                                self.goToEventById(idEventScanned, nameEvent: jsonResponse["name"].stringValue, owner: true)
                            }
                        } else {
                            self.goToEventById(idEventScanned, nameEvent: jsonResponse["name"].stringValue, owner: false)
                        }
                    }
                }
        }
    }
    
    func goToEventById(_ idEvent: Int, nameEvent: String, owner: Bool) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Event", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "EventViewID") as! EventController
        vc.nameEvent = nameEvent
        vc.idEventSent = idEvent
        vc.owner = owner
        self.user.setHisEventJoined(idEvent)
        self.present(vc, animated: true, completion: nil)
    }
    
    func startEventByOwner (_ idEvent: Int, nameEvent: String, owner: Bool) {
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        Alamofire.request((api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + String(idEvent) + "/start"), method: .post, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Start Event", message: jsonResponse["message"].stringValue)
                        self.present(alert.getPopAlert() , animated : true, completion : nil)
                    }
                    else {
                        self.goToEventById(idEvent, nameEvent: nameEvent, owner: owner)
                    }
                }
        }
    }
}

//MARK: Locations functions
extension EventSearchController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        if (location == nil) {
            self.currentLocation = location!
        }
        
        locationManager.stopUpdatingLocation();
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors: " + error.localizedDescription)
    }
}

//MARK: StatefulViewController implementation functions
extension EventSearchController {
    func hasContent() -> Bool {
        return resultResearch.count > 0
    }
    
    func handleErrorWhenContentAvailable(_ error: Error) {
        let alert = DisplayAlert(title: "Ooops", message: "Something went wrong.")
        alert.openAlertError()
    }
}

//MARK: When table is empty
extension EventSearchController: DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        let attributedString = NSMutableAttributedString(string: "No event found around you", attributes: attrsBold)
        
        return attributedString
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (self.textSearchBox == "") {
            let str = "No event found around you"
            let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
            return NSAttributedString(string: str, attributes: attrs)
        }
        else {
            let attributedString = NSMutableAttributedString(string:"Seemingly the event does not exist : ")
            let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.darkGray]
            let boldString = NSMutableAttributedString(string:self.textSearchBox, attributes:attrsBold)
            attributedString.append(boldString)
            return attributedString
        }
    }
}

//MARK: Functions related to the floating button
extension EventSearchController: LiquidFloatingActionButtonDataSource {
    func numberOfCells(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Int {
        return cells.count
    }
    
    func cellForIndex(_ index: Int) -> LiquidFloatingCell {
        return cells[index]
    }
    
    func liquidFloatingActionButton(_ liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int) {
        if (index == 0) {
            performSegue(withIdentifier: "showCreationEventFromHome", sender: self)
        }
        if (index == 1) {
            self.scanQRCodeEvent()
        }
        liquidFloatingActionButton.close()
    }
}

//MARK: Tableview functions
extension EventSearchController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell:EventSearchCustomTableCell = tableView.dequeueReusableCell(withIdentifier: "EventSearchCustomTableCell", for: indexPath) as! EventSearchCustomTableCell
        
        cell.eventName.text = "\(self.resultResearch[indexPath.row].name.uppercaseFirst)"
        cell.eventLocationName.text = "\(self.resultResearch[indexPath.row].location_name.uppercaseFirst)"
        if (self.resultResearch[indexPath.row].started == true) {
            cell.eventStarted.isOn = true;
        }
        
        if (self.resultResearch[indexPath.row].isOwner) {
            cell.rightsOnEvent.image = UIImage(named: "OwnerEvent")!
        } else if (self.resultResearch[indexPath.row].isOwner) {
            cell.rightsOnEvent.image = UIImage(named: "AdminEvent")!
        } else {
            cell.rightsOnEvent.isHidden = true
        }
        
        if (self.resultResearch[indexPath.row].picture == "") {
            cell.eventPicture.image = UIImage(named: "UnknownEventCover")!
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            cell.eventPicture.load.request(with: self.resultResearch[indexPath.row].picture, onCompletion: { image, error, operation in
                if (cell.eventPicture.image?.size == nil) {
                    cell.eventPicture.image = UIImage(named: "emptyPicture")
                }
                MakeElementRounded().makeElementRounded(cell.eventPicture, newSize: cell.eventPicture.frame.width)
            })
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.resultResearch.count
    }
}
