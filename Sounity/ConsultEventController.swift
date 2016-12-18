//
//  ConsultEventController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/08/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import SwiftDate
//import SocketIO
import MapKit
import ImageLoader
import StatefulViewController
import SwiftMoment

class ConsultEventController: UIViewController, StatefulViewController {
    
    //MARK: UIElements variables
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var titleEvent: UILabel!
    @IBOutlet var locationNameEvent: UILabel!
    @IBOutlet var pictureEvent: UIImageView!
    @IBOutlet var descriptionEvent: UILabel!
    @IBOutlet var startEvent: UILabel!
    @IBOutlet var startedEvent: UILabel!
    @IBOutlet var endEvent: UILabel!
    @IBOutlet var progressEvent: UIProgressView!
    @IBOutlet var mapEvent: MKMapView!
    @IBOutlet var JoinButtonEvent: UIButton!
    @IBOutlet var settingsEvent: UIButton!
    
    //MARK: Info user connected
    var user = UserConnect();
    
    //MARK: Variable received from segue
    var idEventSent: NSInteger = -1
    
    //MARK: State of the page
    var loaded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Override functions
    
    override func viewWillAppear(_ animated: Bool) {
        self.loaded = false
        
        loadingView = LoadingView(_view: self.view)
        setupInitialViewState()

        loadFromIdEvent(idEventSent)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (!user.checkUserConnected() && self.isViewLoaded) {
            DispatchQueue.main.async(execute: { () -> Void in
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Authentication", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "LoginSignUpViewID") as! LoginSignUpController
                self.present(vc, animated: true, completion: nil)
            })
        }
        
        if (Reachability.isConnectedToNetwork() == false) {
            let alert = DisplayAlert(title: "No internet", message: "Please find an internet connection")
            alert.openAlertError()
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Segue that show the setting's event page
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showSettingsEvent") {
            let vc = segue.destination as! ChangeSettingsEventController
            vc.idEventSent = self.idEventSent
        }
    }
}

//MARK: Navigation functions
extension ConsultEventController {
    func startEventByOwner () {
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        Alamofire.request((api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + String(self.idEventSent) + "/start"), method: .post, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Start Event", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Event", bundle: nil)
                        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "EventViewID") as! EventController
                        vc.nameEvent = self.navigationItem.title!
                        vc.idEventSent = self.idEventSent
                        vc.owner = !self.settingsEvent.isHidden
                        self.user.setHisEventJoined(self.idEventSent)
                        self.present(vc, animated: true, completion: nil)
                    }
                }
        }
    }
    
    @IBAction func AccessToEvent(_ sender: AnyObject) {
        if (self.settingsEvent.isHidden == false && self.startedEvent.text != "Started") {
            startEventByOwner()
        } else {
            let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Event", bundle: nil)
            let vc = eventStoryBoard.instantiateViewController(withIdentifier: "EventViewID") as! EventController
            vc.nameEvent = self.navigationItem.title!
            vc.idEventSent = self.idEventSent
            vc.owner = !self.settingsEvent.isHidden
            user.setHisEventJoined(self.idEventSent)
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func backButton(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func GoToSettings () {
        self.performSegue(withIdentifier: "showSettingsEvent", sender: self)
    }
}

//MARK: Initialisation functions
extension ConsultEventController {
    func loadFromIdEvent(_ idEvent: Int) {
        let api = SounityAPI()
        let parameters = [ "id": idEvent ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        startLoading()
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT), method: .get, parameters: parameters, headers: headers)
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
                        self.navigationItem.title = jsonResponse["name"].stringValue
                        
                        self.locationNameEvent.text = jsonResponse["location_name"].stringValue
                        self.descriptionEvent.text = jsonResponse["description"].stringValue
                        
                        self.settingsEvent.isHidden = true
                        if (jsonResponse["owner"]["id"].intValue == self.user.id) {
                            if (jsonResponse["started"].boolValue) {
                                self.JoinButtonEvent.setTitle("Access to your event", for: .normal)
                            } else {
                                self.JoinButtonEvent.setTitle("Start your event", for: .normal)
                            }
                            self.settingsEvent.isHidden = false
                            self.settingsEvent.isUserInteractionEnabled = true;
                            self.settingsEvent.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ConsultEventController.GoToSettings)))
                        }
                        
                        let create_date = moment(jsonResponse["create_date"].stringValue)
                        let expired_date = moment(jsonResponse["expired_date"].stringValue)
                        let diffNow = NSDate().timeIntervalSince((expired_date?.date)!)
                        let diffStarted = (create_date?.date)?.timeIntervalSince((expired_date?.date)!)
                        
                        self.startEvent.text = create_date?.format("yyyy-MM-dd HH:mm")
                        self.endEvent.text = expired_date?.format("yyyy-MM-dd HH:mm")
                        self.startedEvent.text = "Not Started"

                        self.progressEvent.progress = 0.0;
                        if (jsonResponse["started"].boolValue) {
                            self.startedEvent.text = "Started"
                            self.progressEvent.progress = (1 - (Float(diffNow) / Float(diffStarted!)))
                        } else if (!jsonResponse["started"].boolValue && jsonResponse["owner"]["id"].intValue != self.user.id) {
                            self.JoinButtonEvent.isEnabled = false
                        }
                        
                        self.initCenterMapView(CLLocationCoordinate2D(latitude: jsonResponse["latitude"].doubleValue, longitude: jsonResponse["longitude"].doubleValue), place: jsonResponse["location_name"].stringValue)
                        
                        if (jsonResponse["picture"].stringValue != "" && Reachability.isConnectedToNetwork() == true) {
                            self.pictureEvent.load.request(with: jsonResponse["picture"].stringValue, onCompletion: { image, error, operation in
                                if (self.pictureEvent.image?.size == nil) {
                                    self.pictureEvent.image = UIImage(named: "emptyPicture")
                                }
                                MakeElementRounded().makeElementRounded(self.pictureEvent, newSize: self.pictureEvent.frame.width)
                            })
                        }
                    }
                    self.loaded = true
                }
                self.endLoading()
        }
    }
    
    func initCenterMapView(_ location: CLLocationCoordinate2D, place: String) {
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        self.mapEvent.setRegion(region, animated: true)
        
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = location
        dropPin.title = place
        self.mapEvent.addAnnotation(dropPin)
    }
    
}

//MARK: StatefulViewController override functions
extension ConsultEventController {
    func hasContent() -> Bool {
        return self.loaded
    }
    
    func handleErrorWhenContentAvailable(_ error: Error) {
        let alert = DisplayAlert(title: "Ooops", message: "Something went wrong.")
        alert.openAlertError()
    }
}

//MARK: Hide status bar
extension ConsultEventController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
