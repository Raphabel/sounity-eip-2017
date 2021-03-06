//
//  ActivitiesEventController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 21/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import UIKit
import DZNEmptyDataSet

class ActivitiesEventController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: Id event received variable
    var idEventSent: NSInteger = -1
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: Activities table
    var activities = [Activity]()
    
    // MARK: Storyboard UIElements
    @IBOutlet var tableview: UITableView!
    
    // MARK: Enumeration about activity icon and title
    enum TYPE_ACTIVITY_ICON: String {
        case NEW_SONG = "activitiesSong"
        case LIKE = "activitiesLiked"
        case DISLIKE = "activitiesDisliked"
        case UNDO = "activitiesUndo"
        case JOINED = "activitiesJoinned"
        case BANNED = "activitiesBanned"
        case LEFT = "activitiesLeft"
    }

    enum TYPE_ACTIVITY: String {
        case NEW_SONG = "Added a new song to the playlist."
        case LIKE = "Liked a song in the playlist."
        case UNLIKE = "Unliked a song in the playlist."
        case DISLIKE = "Disliked a song in the playlist."
        case UNDISLIKE = "Undisliked a song in the playlist."
        case JOINED = "Joined the event."
    }
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.idEventSent = user.eventJoined
        
        self.view.backgroundColor = UIColor.clear
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.emptyDataSetSource = self
        tableview.emptyDataSetDelegate = self
        tableview.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let tabArray = self.tabBarController?.tabBar.items as NSArray!
        let tabItem = tabArray?.object(at: 3) as! UITabBarItem
        tabItem.badgeValue = nil
        
        self.tableview.reloadData()
    }
}

// MARK: Add new feed to the event timeline
extension ActivitiesEventController {
    /// Generic function that adds activities to the event's timeline of the user
    ///
    /// - Parameters:
    ///   - username: name of the user involved with the activity
    ///   - content: message of the activity based on [TYPE_ACTIVITY]
    ///   - type: type of activity based on [TYPE_ACTIVITY_ICON]
    ///   - extra: secondary message of the activity
    func addActivitiesTimeline(_ username: String, content: TYPE_ACTIVITY, type: TYPE_ACTIVITY_ICON, extra: String) {
        self.activities.append(Activity(_username: username, _content: content.rawValue, _picture: type.rawValue, _extra: extra))
        self.tableview?.reloadData()
        
        if (self.tabBarController?.tabBar.selectedItem == self.tabBarController?.tabBar.items?[3]) {
            return
        }
        
        if let badgeValue = self.tabBarController?.tabBar.items?[3].badgeValue {
            let nextValue: Int = (Int(badgeValue)! + 1)
            self.tabBarController?.tabBar.items?[3].badgeValue = String(nextValue)
        } else {
            self.tabBarController?.tabBar.items?[3].badgeValue = "1"
        }
    }
    
    /// Generic function that adds activities to the event's timeline of the user
    ///
    /// - Parameters:
    ///   - username: name of the user involved with the activity
    ///   - content: message of the activity [string]
    ///   - type: type of activity based on [TYPE_ACTIVITY_ICON]
    ///   - extra: secondary message of the activity

    func addActivitiesTimeline(_ username: String, content: String, type: TYPE_ACTIVITY_ICON, extra: String) {
        self.activities.append(Activity(_username: username, _content: content, _picture: type.rawValue, _extra: extra))
        self.tableview?.reloadData()
        
        if (self.tabBarController?.tabBar.selectedItem == self.tabBarController?.tabBar.items?[3]) {
            return
        }
        
        if let badgeValue = self.tabBarController?.tabBar.items?[3].badgeValue {
            let nextValue = ((Int(badgeValue))! + 1)
            self.tabBarController?.tabBar.items?[3].badgeValue = String(nextValue)
        } else {
            self.tabBarController?.tabBar.items?[3].badgeValue = "1"
        }
    }
}

// MARK: Empty table view
extension ActivitiesEventController {
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No activity registered since you have joined the event."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
}

// MARK: Table view functions
extension ActivitiesEventController {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ActivitiesEventTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ActivitiesEventTableViewCell", for: indexPath) as! ActivitiesEventTableViewCell
        
        cell.activity = self.activities[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activities.count
    }
}
