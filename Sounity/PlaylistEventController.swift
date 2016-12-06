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
    func addNewBadgeOnTabBar(_ position: EventController.TABITEM) {
        if (self.tabBarController?.tabBar.selectedItem == self.tabBarController?.tabBar.items?[position.rawValue]) {
            return
        }
        
        if let badgeValue = self.tabBarController?.tabBar.items?[position.rawValue].badgeValue {
            if let nextValue: Int = ((Int(badgeValue))! + 1) {
                self.tabBarController?.tabBar.items?[position.rawValue].badgeValue = String(nextValue)
            }
        } else {
            self.tabBarController?.tabBar.items?[position.rawValue].badgeValue = "1"
        }
    }
}

// MARK: Playlist handler functions
extension PlaylistEventController {
    func getPlaylistEvent () {
        SocketIOManager.sharedInstance.connectToEventWithToken(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Event", message: datasList["message"].stringValue)
                        alert.openAlertError()
                        return
                    } else {
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
    
    func removeMusicInPlaylistById(_ idMusic: Int, apiId: Int) {
        if (self.playlist.count > 0 && self.playlist[0].id == idMusic && self.playlist[0].apiId == apiId) {
            self.playlist.remove(at: 0)
        }
        self.tableview.reloadData()
    }
    
    func sortPlaylistEvent (_ _idMusic: Int, _apiId: Int, _newPosition: Int) {
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
        self.playlist.insert(musicToMove!, at: (_newPosition))
    }
}

// MARK: Broadcasts received
extension PlaylistEventController {
    func listenNewMessageSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.NEW_MESSAGE.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            self.addNewBadgeOnTabBar(EventController.TABITEM.chat)
            
            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                let controllerEvent = self.parent?.parent as! EventController
                controllerEvent.reloadEvent()
            }
        }
    }
    
    func listenMusicLiked() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.MUSIC_LIKED.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
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
    
    func listenNewJoined() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.NEW_JOINED.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            let barViewControllers = self.tabBarController?.viewControllers
            let svc = barViewControllers![EventController.TABITEM.activity.rawValue] as! ActivitiesEventController
            svc.addActivitiesTimeline(data["nickname"].stringValue, content: ActivitiesEventController.TYPE_ACTIVITY.JOINED, type: ActivitiesEventController.TYPE_ACTIVITY_ICON.JOINED, extra: "")
        }
    }
    
    func listenNewMusicAddedSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.MUSIC_ADDED.rawValue) { (dataArray, Socket) -> Void in
            let subJson = JSON(dataArray[0])
            
            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: subJson["transactionId"].intValue)) {
                let controllerEvent = self.parent?.parent as! EventController
                controllerEvent.reloadEvent()
            } else {
                let dateFormatter = DateFormatter()
                let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
                dateFormatter.locale = enUSPosixLocale as Locale!
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                let myDate = dateFormatter.string(from: NSDate() as Date)
                
                print("pourquoi tu ajoutes")
                
                self.playlist.insert(MusicPlaylistEvent(_id: subJson["id"].intValue, _apiId: subJson["apiId"].intValue, _artist: subJson["artist"].stringValue, _title: subJson["title"].stringValue, _url: subJson["url"].stringValue, _cover: subJson["cover"].stringValue, _duration: subJson["duration"].doubleValue, _addedBy: subJson["nickname"].stringValue, _addedAt: myDate, _like: 1, _dislike: 0, _liked: false, _disliked: false), at: subJson["newPos"].intValue)
                
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
        
        cell.trackArtist.text = self.playlist[indexPath.row].artist
        cell.trackTitle.text = self.playlist[indexPath.row].title
        cell.addedBy.text = self.playlist[indexPath.row].addedBy
        cell.addedAt.text = moment(self.playlist[indexPath.row].addedAt)?.format("yyyy-MM-dd'T'HH:mm:ss.SSSZ")

        cell.likePicture.isUserInteractionEnabled = true
        cell.likePicture.image = UIImage(named: "musicNotLike")!
        cell.likePicture.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlaylistEventController.likeSongInPlaylistEvent)))
        
        cell.dislikePicture.isUserInteractionEnabled = true
        cell.dislikePicture.image = UIImage(named: "musicNotDislike")!
        cell.dislikePicture.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PlaylistEventController.dislikeSongInPlaylistEvent)))
        if (self.playlist[indexPath.row].liked) {
            cell.likePicture.image = UIImage(named: "musicLiked")!
            cell.likePicture.isUserInteractionEnabled = false
        }
        if (self.playlist[indexPath.row].disliked) {
            cell.dislikePicture.image = UIImage(named: "musicDisliked")!
            cell.dislikePicture.isUserInteractionEnabled = false
        }
        
        cell.numberDislikes.text = String(self.playlist[indexPath.row].dislike)
        cell.numberLikes.text = String(self.playlist[indexPath.row].like)
        
        cell.trackPicture.isUserInteractionEnabled = true
        if (self.playlist[indexPath.row].cover != ""  && Reachability.isConnectedToNetwork() == true) {
            cell.trackPicture.imageFromServerURL(urlString: self.playlist[indexPath.row].cover)
            MakeElementRounded().makeElementRounded(cell.trackPicture, newSize: cell.trackPicture.frame.width)
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist.count
    }
}
