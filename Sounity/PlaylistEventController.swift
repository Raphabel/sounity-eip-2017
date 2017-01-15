//
//  PlaylistEventController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftDate
import UIKit
import SwiftMoment
import PullToRefresh
import DZNEmptyDataSet

class PlaylistEventController: UIViewController, UITableViewDelegate, DZNEmptyDataSetDelegate  {
    
    // MARK: UIElements functions
    @IBOutlet var tableview: UITableView!
    
    // MARK: Id event received
    var idEventSent: NSInteger = -1
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: Playlist event table
    var playlist = [MusicPlaylistEvent]()
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.idEventSent = user.eventJoined
        
        tableview.dataSource = self
        tableview.delegate = self
        tableview.emptyDataSetSource = self
        tableview.emptyDataSetDelegate = self
        tableview.tableFooterView = UIView()
        
        self.getPlaylistEvent()

        self.listenNewMessageSocket()
        self.listenNewMusicAddedSocket()
        self.listenNewJoined()
        self.listenMusicLiked()
        self.listenBanSocket()
        self.listenBannedSocket()
        self.listenLeftSocket()
        self.listenStopSocket()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let tabArray = self.tabBarController?.tabBar.items as NSArray!
        let tabItem = tabArray?.object(at: EventController.TABITEM.playlist.rawValue) as! UITabBarItem
        tabItem.badgeValue = nil
        
        tableview.reloadData()
        
        let refresher = PullToRefresh()
        tableview.addPullToRefresh(refresher) {
            let controllerEvent = self.parent?.parent as! EventController
            controllerEvent.reloadEvent()
        }
    }
    
    deinit {
        self.tableview.removePullToRefresh(tableview.topPullToRefresh!)
    }
}

// MARK: Tab Bar badge handler
extension PlaylistEventController {
    /// Generic function to add badge on the bottom bar in order to notify the user
    ///
    /// - Parameter position: Enum of the tab item where to add the badge
    func addNewBadgeOnTabBar(_ position: EventController.TABITEM) {
        if (self.tabBarController?.tabBar.selectedItem == self.tabBarController?.tabBar.items?[position.rawValue]) {
            return
        }
        
        if let badgeValue = self.tabBarController?.tabBar.items?[position.rawValue].badgeValue {
            let nextValue: Int = (Int(badgeValue)! + 1)
            self.tabBarController?.tabBar.items?[position.rawValue].badgeValue = String(nextValue)
        } else {
            self.tabBarController?.tabBar.items?[position.rawValue].badgeValue = "1"
        }
    }
}

// MARK: Playlist handler functions
extension PlaylistEventController {
    func getBackHomePage () {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "HomeViewID") as! HomeController
        self.present(vc, animated: true, completion: nil)
    }
    
    /// send a socket event:join in order to get all the information related to the event 
    func getPlaylistEvent () {
        print("getPlaylistEvent")
        SocketIOManager.sharedInstance.connectToEventWithToken(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Event", message: datasList["message"].stringValue)
                        alert.openAlertConfirmationWithCallbackNoOption(self.getBackHomePage)
                        return
                    } else {
                        print(datasList)
                        SocketIOManager.sharedInstance.setCurrentTransactionId(idTransactionReceived: datasList["transactionId"].intValue)
                        self.playlist.removeAll()
                        for (_,subJson):(String, JSON) in datasList["musics"] {
                            self.playlist.append(MusicPlaylistEvent(_id: subJson["id"].intValue, _apiId: subJson["apiId"].intValue, _artist: subJson["artist"].stringValue, _title: subJson["title"].stringValue, _url: subJson["url"].stringValue, _cover: subJson["cover"].stringValue, _duration: subJson["duration"].doubleValue, _addedBy: subJson["addedBy"].stringValue, _addedAt: subJson["addedAt"].stringValue, _like: subJson["like"].intValue, _dislike: subJson["dislike"].intValue, _liked: subJson["liked"].boolValue , _disliked: subJson["disliked"].boolValue ))
                        }
                        self.tableview.endRefreshing(at: Position.top)
                        self.tableview.reloadData()
                        
                        let controllerEvent = self.parent?.parent as! EventController
                        controllerEvent.setMediaPlayerFromEventJoin(datasList["music"], timeMusic: datasList["time"].int64Value, statusMusic: datasList["status"].stringValue)
                    }
                }
            })
        })
    }
    
    /// Remove a music from the event's playlist
    ///
    /// - Parameters:
    ///   - idMusic: id of the music that should be removed
    ///   - apiId: apiId of the music that should be removed
    func removeMusicInPlaylistById(_ idMusic: Int, apiId: Int) {
        if (self.playlist.count > 0 && self.playlist[0].id == idMusic && self.playlist[0].apiId == apiId) {
            print("removeMusicInPlaylistById -> \(self.playlist[0].title)")
            self.playlist.remove(at: 0)
        }
        self.tableview.reloadData()
    }
    
    /// Function that sorts out the table in order to play the most releant music
    ///
    /// - Parameters:
    ///   - _idMusic: id of the music where the datas changed
    ///   - _apiId: api id of the music where the datas changed
    ///   - _newPosition: the new position where the music changed should be
    func sortPlaylistEvent (_ _idMusic: Int, _apiId: Int, _newPosition: Int) {
        print("sortPlaylistEvent [idMusic -> \(_idMusic)] [_apiId -> \(_apiId)] [_newPosition -> \(_newPosition)]")
        
        var musicToMove: MusicPlaylistEvent?
        var indexMusicToMove: Int?
        
        for (index, music) in self.playlist.enumerated() {
            if (music.id == _idMusic && music.apiId == _apiId) {
                musicToMove = music
                indexMusicToMove = index
            }
        }
        if (indexMusicToMove < self.playlist.count) {
            self.playlist.remove(at: indexMusicToMove!)
        }
        if (self.playlist.count >= _newPosition) {
            print("Move music [title -> \(musicToMove)] from position[\(indexMusicToMove)] to [\(_newPosition)]")
            self.playlist.insert(musicToMove!, at: (_newPosition))
        } else {
            print("Insert at [\(_newPosition)] whereas playlist contains [\(self.playlist.count)]")
            let controllerEvent = self.parent?.parent as! EventController
            controllerEvent.reloadEvent()
        }
    }
}

// MARK: Broadcasts received
extension PlaylistEventController {
    /// Listen on broadcast chat:newmesage
    /// Add log on the bottom bar to notify the user
    func listenNewMessageSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.NEW_MESSAGE.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            print("New message received -> \(data)")
            
            self.addNewBadgeOnTabBar(EventController.TABITEM.chat)
            
            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                let controllerEvent = self.parent?.parent as! EventController
                controllerEvent.reloadEvent()
            }
        }
    }
    
    /// Listen on broadcast event:banned
    /// Add log on the bottom bar to notify the user || redirect the banned user to the home page
    func listenBannedSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.BANNED.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            if (data["userId"].intValue == self.user.id) {
                print("you have been banned -> \(data)")
                
                let alert = DisplayAlert(title: "Event", message: data["message"].stringValue)
                alert.openAlertConfirmationWithCallbackNoOption(self.getBackHomePage)

            } else {
                print("user has been banned -> \(data)")
                
                let barViewControllers = self.tabBarController?.viewControllers
                let svc = barViewControllers![EventController.TABITEM.activity.rawValue] as! ActivitiesEventController
                svc.addActivitiesTimeline("User has been banned", content: data["message"].stringValue, type: ActivitiesEventController.TYPE_ACTIVITY_ICON.BANNED, extra: "")
                
                if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                    let controllerEvent = self.parent?.parent as! EventController
                    controllerEvent.reloadEvent()
                }
            }
        }
    }
    
    /// Listen on broadcast event:ban
    func listenBanSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.BAN.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            print("User has been banned -> \(data)")
        }
    }
    
    /// Listen on broadcast event:stop
    func listenStopSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.STOP.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            print("The event has stopped -> \(data)")
            
            let alert = DisplayAlert(title: "Event", message: data["message"].stringValue)
            alert.openAlertConfirmationWithCallbackNoOption(self.getBackHomePage)
        }
    }
    
    /// Listen on broadcast event:left
    /// Add log on the bottom bar to notify the user
    func listenLeftSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.LEFT.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            print("User has left -> \(data)")
            
            let barViewControllers = self.tabBarController?.viewControllers
            let svc = barViewControllers![EventController.TABITEM.activity.rawValue] as! ActivitiesEventController
            svc.addActivitiesTimeline("User has left", content: data["message"].stringValue, type: ActivitiesEventController.TYPE_ACTIVITY_ICON.LEFT, extra: "")
            
            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                let controllerEvent = self.parent?.parent as! EventController
                controllerEvent.reloadEvent()
            }
        }
    }
    
    /// Listen on broadcast music:liked
    /// Add log on the bottom bar to notify the user
    /// Change data related to the music concerned
    func listenMusicLiked() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.MUSIC_LIKED.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            print("New music liked -> \(data)")

            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                let controllerEvent = self.parent?.parent as! EventController
                controllerEvent.reloadEvent()
            } else {
                let barViewControllers = self.tabBarController?.viewControllers
                let svc = barViewControllers![EventController.TABITEM.activity.rawValue] as! ActivitiesEventController
                
                for music in self.playlist {
                    if (music.id == data["id"].intValue && music.apiId == data["apiId"].intValue) {
                        if (data["liked"].boolValue) {
                            svc.addActivitiesTimeline(data["nickname"].stringValue, content: music.liked == true ? ActivitiesEventController.TYPE_ACTIVITY.UNLIKE : ActivitiesEventController.TYPE_ACTIVITY.LIKE, type: ActivitiesEventController.TYPE_ACTIVITY_ICON.LIKE, extra: music.title)
                        } else {
                            svc.addActivitiesTimeline(data["nickname"].stringValue, content: music.disliked == true ? ActivitiesEventController.TYPE_ACTIVITY.UNDISLIKE : ActivitiesEventController.TYPE_ACTIVITY.DISLIKE, type: ActivitiesEventController.TYPE_ACTIVITY_ICON.DISLIKE, extra: music.title)
                        }
                        
                        music.like = data["like"].intValue
                        music.dislike = data["dislike"].intValue
                    }
                }
                self.sortPlaylistEvent(data["id"].intValue, _apiId: data["apiId"].intValue, _newPosition: data["newPos"].intValue)
                self.tableview.reloadData()
                self.addNewBadgeOnTabBar(EventController.TABITEM.playlist)
            }
        }
    }
    
    /// Listen on broadcast event:joined
    /// Add log on the activity bar to notify the user
    func listenNewJoined() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.NEW_JOINED.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            print("New user joinned -> \(data)")
            
            let barViewControllers = self.tabBarController?.viewControllers
            let svc = barViewControllers![EventController.TABITEM.activity.rawValue] as! ActivitiesEventController
            svc.addActivitiesTimeline(data["nickname"].stringValue, content: ActivitiesEventController.TYPE_ACTIVITY.JOINED, type: ActivitiesEventController.TYPE_ACTIVITY_ICON.JOINED, extra: "")
        }
    }
    
    /// Listen on broadcast music:added
    /// Add log on the bottom bar to notify the user
    /// Add the new song within the event's playlist
    func listenNewMusicAddedSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.MUSIC_ADDED.rawValue) { (dataArray, Socket) -> Void in
            let subJson = JSON(dataArray[0])
            
            print("New music added -> \(subJson)")
            
            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: subJson["transactionId"].intValue)) {
                let controllerEvent = self.parent?.parent as! EventController
                controllerEvent.reloadEvent()
            } else {
                let dateFormatter = DateFormatter()
                let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
                dateFormatter.locale = enUSPosixLocale as Locale!
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                let myDate = dateFormatter.string(from: NSDate() as Date)
                
                if (self.playlist.count >= subJson["newPos"].intValue) {
                    print("Insert at [\(subJson["newPos"].intValue)] whereas playlist contains [\(self.playlist.count)]")
                    self.playlist.insert(MusicPlaylistEvent(_id: subJson["id"].intValue, _apiId: subJson["apiId"].intValue, _artist: subJson["artist"].stringValue, _title: subJson["title"].stringValue, _url: subJson["url"].stringValue, _cover: subJson["cover"].stringValue, _duration: subJson["duration"].doubleValue, _addedBy: subJson["nickname"].stringValue, _addedAt: myDate, _like: 1, _dislike: 0, _liked: false, _disliked: false), at: subJson["newPos"].intValue)
                } else {
                    print("Insert at [\(subJson["newPos"].intValue)] whereas playlist contains [\(self.playlist.count)]")
                    let controllerEvent = self.parent?.parent as! EventController
                    controllerEvent.reloadEvent()
                }
                
                self.addNewBadgeOnTabBar(EventController.TABITEM.playlist)
                self.tableview.reloadData()
                
                let barViewControllers = self.tabBarController?.viewControllers
                let svc = barViewControllers![3] as! ActivitiesEventController
                svc.addActivitiesTimeline(subJson["nickname"].stringValue, content: ActivitiesEventController.TYPE_ACTIVITY.NEW_SONG, type: ActivitiesEventController.TYPE_ACTIVITY_ICON.NEW_SONG, extra: subJson["title"].stringValue)
            }
        }
    }
}

// MARK: Sockets sent
extension PlaylistEventController {
    /// Like the selected music on the event's playlist
    ///
    /// - Parameter sender: sender from UIGestureRecognizer
    func likeSongInPlaylistEvent(_ sender: UIGestureRecognizer) {
        let tapLocation = sender.location(in: self.tableview)
        let indexPath = self.tableview.indexPathForRow(at: tapLocation)
        
        SocketIOManager.sharedInstance.likeMusicInEventPlaylist(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject, "like": true as AnyObject, "id": self.playlist[(indexPath?.row)!].id as AnyObject], completionHandler: { (datasList) -> Void in DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Event", message: datasList["message"].stringValue)
                        alert.openAlertError()
                        return
                    } else {
                        if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: datasList["transactionId"].intValue)) {
                            let controllerEvent = self.parent?.parent as! EventController
                            controllerEvent.reloadEvent()
                        } else {
                            self.playlist[(indexPath?.row)!].liked = true
                            self.playlist[(indexPath?.row)!].like = (self.playlist[(indexPath?.row)!].like) + 1
                            if (self.playlist[(indexPath?.row)!].disliked) {
                                self.playlist[(indexPath?.row)!].disliked = false
                                self.playlist[(indexPath?.row)!].dislike = (self.playlist[(indexPath?.row)!].dislike) - 1
                            }
                            self.sortPlaylistEvent(self.playlist[(indexPath?.row)!].id, _apiId: self.playlist[(indexPath?.row)!].apiId, _newPosition: datasList["newPos"].intValue)
                            self.tableview.reloadData()
                        }
                    }
                }
            })
        })
    }
    
    /// Dislike the selected music on the event's playlist
    ///
    /// - Parameter sender: sender from UIGestureRecognizer
    func dislikeSongInPlaylistEvent(_ sender: UIGestureRecognizer) {
        let tapLocation = sender.location(in: self.tableview)
        let indexPath = self.tableview.indexPathForRow(at: tapLocation)
        
        SocketIOManager.sharedInstance.likeMusicInEventPlaylist(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject, "like": false as AnyObject, "id": self.playlist[(indexPath?.row)!].id as AnyObject], completionHandler: { (datasList) -> Void in DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Event", message: datasList["message"].stringValue)
                        alert.openAlertError()
                        return
                    } else {
                        if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: datasList["transactionId"].intValue)) {
                            let controllerEvent = self.parent?.parent as! EventController
                            controllerEvent.reloadEvent()
                        } else {
                            self.playlist[(indexPath?.row)!].disliked = true
                            self.playlist[(indexPath?.row)!].dislike = (self.playlist[(indexPath?.row)!].dislike) + 1
                            if (self.playlist[(indexPath?.row)!].liked) {
                                self.playlist[(indexPath?.row)!].liked = false
                                self.playlist[(indexPath?.row)!].like = (self.playlist[(indexPath?.row)!].like) - 1
                            }
                            self.sortPlaylistEvent(self.playlist[(indexPath?.row)!].id, _apiId: self.playlist[(indexPath?.row)!].apiId, _newPosition: datasList["newPos"].intValue)
                            self.tableview.reloadData()
                        }
                    }
                }
            })
        })
    }
}

// MARK: Empty Table view
extension PlaylistEventController: DZNEmptyDataSetSource {
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No music added to the playlist for the moment."
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
}

// MARK: Table view functions
extension PlaylistEventController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:PlaylistMusicEventTableViewCell = tableView.dequeueReusableCell(withIdentifier: "PlaylistMusicEventTableViewCell", for: indexPath) as! PlaylistMusicEventTableViewCell
        
        cell.music = self.playlist[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        cell.likePicture.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlaylistEventController.likeSongInPlaylistEvent)))
        cell.dislikePicture.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlaylistEventController.dislikeSongInPlaylistEvent)))
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist.count
    }
}
