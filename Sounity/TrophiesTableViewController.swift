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

class TrophiesTableViewController: UITableViewController {
        
    @IBOutlet var trophiesTableView: UITableView!
    
    // MARK: Playlist variables
    var trophies = [Trophies]()
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: API Connection
    var api = SounityAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        trophiesTableView.dataSource = self
        trophiesTableView.delegate = self
        trophiesTableView.tableFooterView = UIView()
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
        let trophies = self.trophies[indexPath.row]
        
        cell.Name.text = trophies.name
        cell.descriptionTrophies.text = trophies.desc
        cell.levelNumber.text = (String)(trophies.level)
    
        if (trophies.id == 1 && trophies.level >= 1) { cell.levelImage.image = UIImage(named: "JukeBox") }
            else if (trophies.id == 1) { cell.levelImage.image = UIImage(named: "JukeBoxDark") }
        if (trophies.id == 2 && trophies.level >= 1) { cell.levelImage.image = UIImage(named: "BestDJ") }
            else if (trophies.id == 2) { cell.levelImage.image = UIImage(named: "BestDJDark") }
        if (trophies.id == 3 && trophies.level >= 1) { cell.levelImage.image = UIImage(named: "SounityStar") }
            else if (trophies.id == 3) { cell.levelImage.image = UIImage(named: "SounityStarDark") }
        if (trophies.id == 4 && trophies.level >= 1) { cell.levelImage.image = UIImage(named: "KingOfTheNight") }
            else if (trophies.id == 4) { cell.levelImage.image = UIImage(named: "KingOfTheNightDark") }
        if (trophies.id == 5 && trophies.level >= 1) { cell.levelImage.image = UIImage(named: "SocialNetworkAddict") }
            else if (trophies.id == 5) { cell.levelImage.image = UIImage(named: "SocialNetworkAddictDark") }
        if (trophies.id == 6 && trophies.level >= 1) { cell.levelImage.image = UIImage(named: "PartyAnimal") }
            else if (trophies.id == 6) { cell.levelImage.image = UIImage(named: "PartyAnimalDark") }
        if (trophies.id == 7 && trophies.level >= 1) { cell.levelImage.image = UIImage(named: "Rockstar") }
            else if (trophies.id == 7) { cell.levelImage.image = UIImage(named: "RockstarDark") }

        switch trophies.level {
        case 1:
           cell.level1.isHidden = false
            break
        case 2:
            cell.level1.isHidden = false
            cell.level2.isHidden = false
            break
        case 3:
            cell.level1.isHidden = false
            cell.level2.isHidden = false
            cell.level3.isHidden = false
            break
        case 4:
            cell.level1.isHidden = false
            cell.level2.isHidden = false
            cell.level3.isHidden = false
            cell.level4.isHidden = false
            break
        case 5:
            cell.level1.isHidden = false
            cell.level2.isHidden = false
            cell.level3.isHidden = false
            cell.level4.isHidden = false
            cell.level5.isHidden = false
        default: break
        }
        
        return cell
    }
}

// MARK: Get all playlists user
extension TrophiesTableViewController {
    func loadTrophies() {
        
        let url = api.getRoute(SounityAPI.ROUTES.TROPHIES) + "/\(user.id)"
        
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]

        Alamofire.request(url, method: .get, headers: headers)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        let alert = DisplayAlert(title: "Load your playlist", message: jsonResponse["message"].stringValue)
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
extension TrophiesTableViewController {
    @IBAction func cancelButton(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Hide Top Bar
extension TrophiesTableViewController {
    override var prefersStatusBarHidden: Bool {
        return false
    }
}
