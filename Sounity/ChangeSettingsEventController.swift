//
//  ChangeSettingsEventController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 15/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Eureka
import Alamofire
import SwiftDate
import SwiftyJSON
import SwiftMoment
import CoreLocation

class ChangeSettingsEventController: FormViewController {
    
    //MARK: Infos on event varibale
    var eventInfo: Event!
    
    //MARK: Infos user connected
    var user = UserConnect();
    
    //MARK: Id event received
    var idEventSent: NSInteger = -1

    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadEventInfo()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Segue that show the setting's event page
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showManagerUsersEvent") {
            let vc = segue.destination as! ManageAdminEvent
            vc.idEventSent = self.idEventSent
        }
        
        else if (segue.identifier == "showUsersEvent") {
            let vc = segue.destination as! ManageUserEvent
            vc.idEventSent = self.idEventSent
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (!user.checkUserConnected() && self.isViewLoaded) {
            (DispatchQueue.main).async(execute: { () -> Void in
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
}

//MARK: Actions on event changes functions
extension ChangeSettingsEventController {
    func actionOnEvent (_ _title: String, _msg: String, mode: String) {
        let alert = DisplayAlert(title: _title, message: _msg)
        alert.openAlertConfirmationWithCallback(mode == "delete" ? self.deleteEvent : self.saveSettingsEvent)
    }
    
    func deleteEvent() {
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        let parameters: Parameters = [ "id": self.idEventSent as AnyObject ]
        
        Alamofire.request(
            api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT), method: .delete, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: ("Event delete"), message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Delete Event", message: "Your event has been deleted.")
                        alert.openAlertSuccess()
                    }
                }
        }
        
    }
    
    func saveSettingsEvent() {
        let api = SounityAPI()
        let headers = [ "Authorization": "Bearer \(self.user.token)", "Accept": "application/json"]
        
        if let rowDescription = self.form.rowBy(tag: "description")! as? TextAreaRow {
            self.eventInfo.description = rowDescription.value ?? self.eventInfo.description
        }
        if let rowUserMax = self.form.rowBy(tag: "max_users")! as? StepperRow {
            self.eventInfo.user_max = Int(rowUserMax.value!) 
        }
        if let rowPublic = self.form.rowBy(tag: "public_event")! as? SwitchRow {
            self.eventInfo.publicEvent = rowPublic.value ?? self.eventInfo.publicEvent
        }
        if let rowLocationName = self.form.rowBy(tag: "location_name")! as? TextRow {
            self.eventInfo.location_name = rowLocationName.value ?? self.eventInfo.location_name
        }
        if let rowExpiredDate = self.form.rowBy(tag: "expired_date")! as? DateTimeInlineRow {
            self.eventInfo.expired_date = (rowExpiredDate.value)?.iso8601 ?? self.eventInfo.expired_date
        }
        if let rowLocation = self.form.rowBy(tag: "location_event")! as? LocationRow {
            self.eventInfo.longitude = rowLocation.value?.coordinate.longitude ?? self.eventInfo.longitude
            self.eventInfo.latitude = rowLocation.value?.coordinate.latitude ?? self.eventInfo.latitude
        }
        
        let parameters: Parameters = [
            "id": self.idEventSent as AnyObject,
            "name": self.eventInfo.name,
            "description": self.eventInfo.description,
            "picture": self.eventInfo.picture,
            "user_max": self.eventInfo.user_max,
            "public": self.eventInfo.publicEvent,
            "create_date": self.eventInfo.create_date,
            "expired_date": self.eventInfo.expired_date,
            "location_name": self.eventInfo.location_name,
            "latitude": self.eventInfo.latitude,
            "longitude": self.eventInfo.longitude
        ]
        
        Alamofire.request(api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT), method: .put, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: ("Event save"), message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        let alert = DisplayAlert(title: "Save Event", message: "Information has been saved.")
                        alert.openAlertSuccess()
                    }
                }
        }
        
    }
}

//MARK: Create form Eureka
extension ChangeSettingsEventController {
    func loadEventInfo() {
        let api = SounityAPI()
        let parameters: Parameters = [ "id": idEventSent ]
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
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
                        self.eventInfo = (Event(_id: jsonResponse["id"].intValue, _userMax: jsonResponse["user_max"].intValue, _lat: jsonResponse["latitude"].doubleValue, _long: jsonResponse["longitude"].doubleValue, _started: jsonResponse["started"].boolValue, _public: jsonResponse["public"].boolValue, _name: jsonResponse["name"].stringValue, _desc: jsonResponse["description"].stringValue, _picture: jsonResponse["picture"].stringValue, _created: jsonResponse["create_date"].stringValue, _expired: jsonResponse["expired_date"].stringValue, _locationName: jsonResponse["location_name"].stringValue, _isOwner: true, _isAdmin: false))
                        
                        self.form +++ Section("Event description")
                            <<< TextAreaRow("description") {
                                $0.placeholder = "Description"
                                $0.value = self.eventInfo.description
                                $0.textAreaHeight = .dynamic(initialTextViewHeight: 50)
                            }
                            
                            +++ Section("Event location")
                            <<< TextRow("location_name") { row in
                                row.title = "Location's name"
                                row.value = self.eventInfo.location_name
                                row.placeholder = "Add a name of your location"
                            }
                            <<< LocationRow("location_event"){
                                $0.title = "Location's event"
                                $0.value = CLLocation(latitude: self.eventInfo.latitude, longitude: self.eventInfo.longitude)
                            }
                            
                            
                            /*+++ Section("Event cover")
                            <<< ImageRow(){
                                $0.title = "Cover"
                                $0.value = UIImage(named: "UnknownEventCover")
                            }*/
                            
                            +++ Section("Event info users")
                            <<< SwitchRow("public_event") {
                                $0.title = "Public"
                                $0.value = self.eventInfo.publicEvent
                            }
                            <<< LabelRow(){
                                $0.hidden = Condition.function(["public_event"], { form in
                                    return ((form.rowBy(tag: "public_event") as? SwitchRow)?.value ?? false)
                                })
                                $0.title = "Your event will be hidden from users.."
                            }
                            <<< StepperRow("max_users") {
                                $0.title = "Max_users"
                                $0.value = Double(self.eventInfo.user_max)
                            }
                            
                            +++ Section("Managed Users")
                            <<< ButtonRow("Admins") {
                                $0.title = $0.tag
                                $0.presentationMode = .segueName(segueName: "showManagerUsersEvent", onDismiss: nil)
                            }
                            <<< ButtonRow("Users") {
                                $0.title = $0.tag
                                $0.presentationMode = .segueName(segueName: "showUsersEvent", onDismiss: nil)
                            }
                            
                            +++ Section("Event info time")
                            <<< DateTimeInlineRow("expired_date") {
                                $0.title = "Event ends at : "
                                $0.value = moment(self.eventInfo.expired_date)?.date
                                $0.minimumDate = moment(self.eventInfo.create_date)?.date
                            }
                            
                            +++ Section()
                            <<< ButtonRow() { (row: ButtonRow) -> Void in
                                row.title = "Save"
                                }  .onCellSelection({ (cell, row) in
                                    self.actionOnEvent("Save Settings", _msg: "Do you really want to save these new settings ?", mode: "save")
                                }).cellUpdate { cell, row in
                                    cell.textLabel?.textColor = UIColor.white
                                    cell.backgroundColor = ColorSounity.orangeSounity
                            }
                            +++ Section()
                            <<< ButtonRow() { (row: ButtonRow) -> Void in
                                row.title = "Delete"
                                }  .onCellSelection({ (cell, row) in
                                    self.actionOnEvent("Delete Event", _msg: "Do you really want to delete this event ?", mode: "delete")
                                }).cellUpdate { cell, row in
                                    cell.textLabel?.textColor = ColorSounity.orangeSounity
                                    cell.backgroundColor = UIColor.white
                        }
                    }
                }
        }
    }
}

extension ChangeSettingsEventController {
    override var prefersStatusBarHidden : Bool {
        return true
    }
}

