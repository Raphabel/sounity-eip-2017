//
//  MedalTableViewController.swift
//  Sounity
//
//  Created by Alix FORNIELES on 06/01/2017.
//  Copyright © 2017 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ConsultTrophiesController: UITableViewController {
    
    @IBOutlet var trophiesTableView: UITableView!
    
    // MARK: Playlist variables
    var trophies = [Trophies]()
    
    // MARK: Infos user connected
    var user = UserConnect()
    var IDUserConsulted: Int?
    
    // MARK: API Connection
    var api = SounityAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        trophiesTableView.dataSource = self
        trophiesTableView.delegate = self
        trophiesTableView.tableFooterView = UIView()
        trophiesTableView.backgroundColor = UIColor(red: 120/255 ,green: 118/255 ,blue: 130/255 ,alpha: 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (!user.checkUserConnected() && self.isViewLoaded) {
            DispatchQueue.main.async(execute: { () -> Void in
                let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Authentication", bundle: nil)
                let vc = eventStoryBoard.instantiateViewController(withIdentifier: "LoginSignUpViewID") as! LoginSignUpController
                self.present(vc, animated: true, completion: nil)
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadTrophies()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trophies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Trophies", for: indexPath) as! TrophiesTableViewCell
        let trophy = self.trophies[indexPath.row]
        
        cell.trophy = trophy
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.alpha = 0
        let transform = CATransform3DTranslate(CATransform3DIdentity, -250, 20, 0)
        cell.layer.transform = transform
        
        UIView.animate(withDuration: 0.5, animations: {
            cell.alpha = 1.0
            cell.layer.transform = CATransform3DIdentity
        })
        
    }
}

// MARK: Get all playlists user
extension ConsultTrophiesController {
    func loadTrophies() {
        print("#1")
        print(IDUserConsulted!)
    let url = api.getRoute(SounityAPI.ROUTES.TROPHIES) + "/\(IDUserConsulted!)"
        
        
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        
        Alamofire.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Load trophies", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        self.trophies.removeAll()
                        
                        for (_, subjson):(String, JSON) in jsonResponse {
                            self.trophies.append(Trophies(id: subjson["id"].intValue, name: subjson["name"].stringValue, desc: subjson["description"].stringValue, score: subjson["score"].intValue, level: subjson["level"].intValue))
                        }
                        
                        self.trophiesTableView.reloadData()
                    }
                }
        }
    }
}

// MARK: Navigation functions
extension ConsultTrophiesController {
    @IBAction func cancelButton(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Hide Top Bar
extension ConsultTrophiesController {
    override var prefersStatusBarHidden: Bool {
        return false
    }
}
