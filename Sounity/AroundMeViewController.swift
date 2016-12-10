//
//  AroundMeViewController.swift
//  Sounity
//
//  Created by Alix FORNIELES on 10/12/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import GuillotineMenu
import Alamofire
import CoreLocation
import SwiftyJSON
import MapKit
import AddressBook
import LiquidFloatingActionButton

class AroundMeViewController: UIViewController {
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: API connection
    var api = SounityAPI()
    
    // MARK: Guillotine menu variable
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    // MARK: StoryBoard UIElements
    @IBOutlet weak var mapEvent: MKMapView!{
        didSet{
            mapEvent.delegate = self
        }
    }
    
    //MARK: Floating buttons variables
    var cells: [LiquidFloatingCell] = []
    var floatingActionButton: LiquidFloatingActionButton!
    
    //MARK: Location Manager variables
    var locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    var latitudeUpdate: Double?
    var longitudeUpdate: Double?
    
    //MARK: Other Variables used
    var resultAroundMe = [EventsAround]()
    let coordLabel = UILabel(frame: CGRect(origin: CGPoint(x: 10,y :100), size: CGSize(width: 400, height: 50)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        super.viewDidLoad()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            self.mapEvent.showsUserLocation = true
        }
        else {
            print("Location service disabled");
        }
        
        self.setFloatingButton()
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.resultAroundMe.removeAll()
        loadEventsAroundMe()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: Location manager delegate
extension AroundMeViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center: CLLocationCoordinate2D
        if (location != nil) {
            center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
            latitudeUpdate = location?.coordinate.latitude
            longitudeUpdate = location?.coordinate.longitude
        } else {
            // geolocalisation of france
            center = CLLocationCoordinate2D(latitude: 46.227638, longitude: 2.213749)
        }
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        
        self.mapEvent.setRegion(region, animated: true)
        
        locationManager.stopUpdatingLocation();
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors : " + error.localizedDescription)
    }
}

//MARK: FUNCTION ANNEX
extension AroundMeViewController {
    func loadEventsAroundMe() {
        
        let api = SounityAPI()
        let parameters = [
            "latitude":  self.currentLocation.coordinate.latitude,
            "longitude": self.currentLocation.coordinate.longitude
        ]
        let url = api.getRoute(SounityAPI.ROUTES.GET_ALL_EVENTS)
        
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        Alamofire.request(url,method: .get, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<499)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Around Me", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    } else {
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.resultAroundMe.append(EventsAround(name: subJson["name"].stringValue, locationName: subJson["location_name"].stringValue, coordinate: CLLocationCoordinate2D(latitude: subJson["latitude"].doubleValue, longitude: subJson["longitude"].doubleValue), eventID: subJson["id"].intValue))
                        }
                        
                        for data in self.resultAroundMe {
                            
                            self.initCenterMapView(location: CLLocationCoordinate2D(latitude: data.coordinate.latitude, longitude: data.coordinate.longitude), name: data.name!, locationName: data.locationName! , eventID: data.eventID!)
                        }
                    }
                } else { self.resultAroundMe.removeAll() }
        }
    }
    
    func initCenterMapView(location: CLLocationCoordinate2D, name: String, locationName: String, eventID: Int) {
        
        let dropPin = CustomPointAnnotation(pinColor: ColorSounity.orangeSounity)
        
        dropPin.coordinate = location
        dropPin.title = name
        dropPin.subtitle = locationName
        dropPin.eventID = eventID
        
        self.mapEvent.addAnnotation(dropPin)
    }
    
    func redirectionToGoogleMaps(mapView: MKMapView, view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        let regiondistance:CLLocationDistance = 10000
        let regionSpan  = MKCoordinateRegionMakeWithDistance((view.annotation?.coordinate)!, regiondistance, regiondistance)
        
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        
        let placemark = MKPlacemark(coordinate: (view.annotation?.coordinate)!, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        
        mapItem.name = (view.annotation?.title)!
        mapItem.openInMaps(launchOptions: options)
    }
}

//MARK: Functions related to the MAPVIEW
extension AroundMeViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationViewID") as? MKPinAnnotationView
        
        if annotation is MKUserLocation { return nil }
        if view == nil{
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationViewIDk")
            view!.canShowCallout = true
            
            if let customPointAnnotation = annotation as? CustomPointAnnotation {
                view?.pinTintColor = customPointAnnotation.pinColor
            }
        } else {
            view!.annotation = annotation
        }
        let itineraryButton = UIButton()
        itineraryButton.frame.size.width = 50
        itineraryButton.frame.size.height = 52
        itineraryButton.backgroundColor = ColorSounity.navigationBarColor
        itineraryButton.setImage(UIImage(named: "itineraryIcon"), for: .normal)
        
        view!.leftCalloutAccessoryView = itineraryButton
        view?.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control == view.rightCalloutAccessoryView) {
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            if let annotation = view.annotation as? CustomPointAnnotation {
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ConsultEventView") as! ConsultEventController
                
                vc.idEventSent = annotation.eventID
                mapView.removeAnnotations(mapView.annotations)
                
                let navController = UINavigationController.init(rootViewController: vc)
                self.present(navController, animated: true, completion: nil)
            }
        }
        
        if (control == view.leftCalloutAccessoryView) {
            let alert = DisplayAlert(title: "Launch GPS", message: "You will now be redirected to Google Maps")
            alert.openAlertConfirmationWithCallbackAndParameterForMapKit(self.redirectionToGoogleMaps, view: mapView, annotation: view)
        }
    }
}

//MARK: Actions
extension AroundMeViewController {
    @IBAction func showMenuAction(sender: UIButton) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Menu", bundle: nil)
        let menuVC = eventStoryBoard.instantiateViewController(withIdentifier: "MenuViewID")
        menuVC.modalPresentationStyle = .custom
        menuVC.transitioningDelegate = self
        if menuVC is GuillotineAnimationDelegate {
            presentationAnimator.animationDelegate = menuVC as? GuillotineAnimationDelegate
        }
        presentationAnimator.supportView = self.navigationController?.navigationBar
        presentationAnimator.presentButton = sender
        presentationAnimator.animationDuration = 0.3
        self.present(menuVC, animated: true, completion: nil)
    }
    
    @IBAction func geolocaliosation(sender: AnyObject) {
        mapEvent.zoomToUserLocation()
    }
    
    @IBAction func createNewEvent(sender: AnyObject) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "CreateEventView") as! CreateEventController
        
        let navController = UINavigationController.init(rootViewController: vc)
        self.present(navController, animated: true, completion: nil)
        
    }
    
}

//MARK: FLOATING BUTOTN
extension AroundMeViewController : LiquidFloatingActionButtonDelegate, LiquidFloatingActionButtonDataSource {
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
        cells.append(cellFactory("qr_code"))
        
        let floatingFrame = CGRect(x: self.view.frame.width - 56 - 16, y: self.view.frame.height - 56 - 60, width: 56, height: 56)
        let bottomRightButton = createButton(floatingFrame, .up)
        
        self.view.addSubview(bottomRightButton)
    }
    
    func numberOfCells(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Int {
        return cells.count
    }
    
    func cellForIndex(_ index: Int) -> LiquidFloatingCell {
        return cells[index]
    }
    
    func liquidFloatingActionButton(_ liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int) {
        if (index == 0) {
        }
        liquidFloatingActionButton.close()
    }
}

//MARK: GuillotineTransitionAnimation
extension AroundMeViewController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .presentation
        return presentationAnimator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .dismissal
        return presentationAnimator
    }
    
}

//MARK: Exntension of MAPVIEW
extension MKMapView {
    func zoomToUserLocation() {
        guard (userLocation.location?.coordinate) != nil else { return }
        
        let center = CLLocationCoordinate2D(latitude: (userLocation.location?.coordinate.latitude)!, longitude: (userLocation.location?.coordinate.longitude)!)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        
        setRegion(region, animated: true)
    }
}

