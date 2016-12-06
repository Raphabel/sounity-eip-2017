
//
//  CreateEventController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 09/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreLocation
import MapKit
import SwiftMoment
import KMPlaceholderTextView
import DatePickerDialog

class CreateEventController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    //MARK: UIElements variables
    @IBOutlet var nameEvent: UITextField!
    @IBOutlet var locationNameEvent: UITextField!
    @IBOutlet var descriptionEvent: KMPlaceholderTextView!
    @IBOutlet var publicEvent: UISwitch!
    @IBOutlet var maxUserEvent: UILabel!
    @IBOutlet var stepperEvent: UIStepper!
    @IBOutlet var mapEvent: MKMapView!
    @IBOutlet var createEvent: UIButton!
    @IBOutlet weak var fromDateButton: UIButton!
    @IBOutlet weak var toDateButton: UIButton!
    
    //MARK: Infos user connected
    var user = UserConnect();
    
    //MARK: Location Manager variable
    var locationManager = CLLocationManager()
    
    //MARK: Id event that will be created and send when showing up the page
    var idEventCreated: Int = -1
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInitEvent()
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
    
    // Show the event that has been created
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showEventFromCreation") {
            let navController = segue.destination as! UINavigationController
            let detailController = navController.topViewController as! ConsultEventController
            detailController.idEventSent = self.idEventCreated
            navController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

//MARK: Navigation functions
extension CreateEventController {
    @IBAction func backButton(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: Initialisation functions
extension CreateEventController {
    func loadInitEvent() {
        
        let dateNow = moment()
        self.fromDateButton.setTitle(dateNow.format("YYYY-MM-dd"), for: .normal)
        self.toDateButton.setTitle(dateNow.add(1, .Days).format("YYYY-MM-dd"), for: .normal)
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            self.mapEvent.showsUserLocation = true
        }
        else {
            let alertDisplay = DisplayAlert(title: "GPS", message: "Unable to reach your GPS on your device")
            alertDisplay.openAlertError()
        }
        
        self.publicEvent.isOn = true
        self.maxUserEvent.text = "20"
        self.stepperEvent.value = 20
        
        self.nameEvent.attributedPlaceholder = NSAttributedString(string: "Event's name", attributes: [NSForegroundColorAttributeName:UIColor.white])
        self.locationNameEvent.attributedPlaceholder = NSAttributedString(string: "Event's location name", attributes: [NSForegroundColorAttributeName:UIColor.white])
        
        //refreshTitle()
    }
    
    //Called when the user click on the view (outside the UITextField).
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

//MARK: Create event functions
extension CreateEventController {
    @IBAction func createEvent(_ sender: AnyObject) {
        if (Reachability.isConnectedToNetwork() == false) {
            let alert = DisplayAlert(title: "No internet", message: "Please find an internet connection")
            alert.openAlertError()
            return
        }
        
        let parameters: Parameters = [
            "longitude": self.mapEvent.centerCoordinate.longitude,
            "latitude": self.mapEvent.centerCoordinate.latitude,
            "name": self.nameEvent.text!,
            "location_name": self.locationNameEvent.text!,
            "picture": "http://weknowyourdreams.com/images/party/party-09.jpg",
            "public": self.publicEvent.isOn,
            "user_max": Int(self.stepperEvent.value),
            "description": self.descriptionEvent.text!,
            "create_date": moment((fromDateButton.titleLabel?.text)!)!.date.iso8601,
            "expired_date": moment((toDateButton.titleLabel?.text)!)!.date.iso8601
        ]
        
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.CREATE_EVENT), method: .post, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON {(response) -> Void in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 201) {
                        let alert = DisplayAlert(title: "Create Event", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else if (response.result.isSuccess) {
                        self.idEventCreated = jsonResponse["id"].intValue
                        self.performSegue(withIdentifier: "showEventFromCreation", sender: self)
                    }
                }
        }
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        self.maxUserEvent.text = Int(sender.value).description
    }

}

//MARK: Locations funtions
extension CreateEventController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center: CLLocationCoordinate2D
        if (location != nil) {
            center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        } else {
            center = CLLocationCoordinate2D(latitude: 8.884301, longitude: 20.269393)
        }
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        self.mapEvent.setRegion(region, animated: true)
        
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = center
        dropPin.title = "Current Location"
        self.mapEvent.addAnnotation(dropPin)
        
        locationManager.stopUpdatingLocation();
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors: " + error.localizedDescription)
    }
}

//MARK: DatePicker functions
extension CreateEventController {
    @IBAction func touchedButton(_ sender: AnyObject) {
        if (sender.tag == 10) {
            DatePickerDialog().show(title: "Event start date", doneButtonTitle: "Done", cancelButtonTitle: "Cancel", datePickerMode: .date) {
                (date) -> Void in
                if ((date) != nil) {
                    self.fromDateButton.setTitle(moment(date!).format("YYYY-MM-dd"), for: UIControlState.normal)
                }
            }
        } else if (sender.tag == 20) {
            DatePickerDialog().show(title: "Event end date", doneButtonTitle: "Done", cancelButtonTitle: "Cancel", datePickerMode: .date) {
                (date) -> Void in
                if ((date) != nil) {
                    self.toDateButton.setTitle(moment(date!).format("YYYY-MM-dd"), for: UIControlState.normal)
                }
            }
        }
    }
}

//MARK: Hide status bar
extension CreateEventController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
