//
//  ViewController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 18/06/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import InteractivePlayerView
import GuillotineMenu
import AVFoundation
import Alamofire
import SCLAlertView
import SwiftyJSON

class EventController: UIViewController, InteractivePlayerViewDelegate {
    
    // MARK: StoryBoard UIElements
    @IBOutlet var blurImage: UIImageView!
    @IBOutlet var pauseButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var InteractivePView: InteractivePlayerView!
    @IBOutlet weak var viewIPV: UIView!
    @IBOutlet weak var playPauseView: UIView!
    @IBOutlet var titleMusic: UILabel!
    @IBOutlet var typeMusic: UILabel!
    @IBOutlet var navItem: UINavigationItem!
    @IBOutlet var barButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var addPlaylistButton: UIBarButtonItem!
    
    
    // MARK: Media player variables
    var playerItem:AVPlayerItem?
    var player:AVPlayer?
    var trackPlayed: SounityTrackResearch!
    
    // Infos user connected variable
    var user = UserConnect()
    
    // MARK: Infos event varibales
    var idEventSent: NSInteger = -1
    var nameEvent: String = ""
    var owner: Bool = true
    
    // MARK: Enum Tab Bar Item
    enum TABITEM: NSInteger {
        case playlist = 0
        case search = 1
        case chat = 2
        case activity = 3
    }
    
    //MARK: User's playlist
    var ownPlaylist = [Playlist]()
    
    //MARK: Tableview prgramatically created to display user's playlists
    var tableviewPopup = UITableView()
    
    // MARK: Guillotine menu variable
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init Controller and its values
        self.navItem.title = nameEvent
        self.view.backgroundColor = UIColor.clear

        self.initPlayer()
        self.getUserOwnPlaylists()
        
        self.listenMusicPlayed()
        self.listenMusicPaused()
        self.listenMusicChanged()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // In order to make user aware the user has left the event
        print("Restart socket connection")
        SocketIOManager.sharedInstance.restartConnection()
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
        // Dispose of any resources that can be recreated.
    }
    
    // Allow to handle the stop a AVPlayerItem when this last one has finished
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(EventController.finishedPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (self.player?.rate == 1) {
            if (owner) {
                self.sendPauseMusicToUsersEvent()
            } else {
                self.InteractivePView.stop()
                if (self.player != nil) {
                    self.player!.pause();
                }
            }
        }
    }
    
    // Allow to listen when a music is stop / pause or play
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if let rate = change?[NSKeyValueChangeKey.newKey] as? Float {
                if rate == 0.0 { /*print("playback stopped")*/ }
                if rate == 1.0 { /*print("normal playback")*/ }
                if rate == -1.0 { /*print("reverse playback")*/ }
            }
        }
    }
}

// MARK: Playlists User Manager
extension EventController: UITableViewDelegate, UITableViewDataSource {
    @IBAction func displayPopupAddToPlaylist(_ sender: AnyObject) {
        let appearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Create the subview
        let subview = UIView(frame: CGRect(x: 0,y: 10,width: 200,height: 250))
        
        // Add subtitle
        let label = UILabel(frame: CGRect(x: ((subview.frame.width - 180) / 2),y: 0,width: 190,height: 20))
        label.font = UIFont(name: "TimesNewRomanPS-ItalicMT", size: 12)
        label.text = "Add this playlist to your event"
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        subview.addSubview(label)
        
        // Add tableview
        self.tableviewPopup.frame =  CGRect(x: ((subview.frame.width - 180) / 2),y: 40,width: 180,height: 200)
        self.tableviewPopup.delegate = self
        self.tableviewPopup.dataSource = self
        self.tableviewPopup.allowsSelection = true
        self.tableviewPopup.register(UITableViewCell.self, forCellReuseIdentifier: "cellPlaylistName")
        if (self.ownPlaylist.count > 0) {
            subview.addSubview(self.tableviewPopup)
        } else {
            // Add message no playlist
            let labelEmptyPlaylistsList = UILabel(frame: CGRect(x: ((subview.frame.width - 180) / 2),y: 40,width: 190,height: 20))
            labelEmptyPlaylistsList.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 12)
            labelEmptyPlaylistsList.text = "You don't have any playlist"
            labelEmptyPlaylistsList.textAlignment = .center
            labelEmptyPlaylistsList.lineBreakMode = .byWordWrapping
            labelEmptyPlaylistsList.numberOfLines = 0
            
            subview.addSubview(labelEmptyPlaylistsList)
            subview.frame = CGRect(x: 0,y: 10,width: 200,height: 90)
        }
        alert.customSubview = subview
        _ = alert.showCustom(self.nameEvent, subTitle: "", color: ColorSounity.navigationBarColor, icon: UIImage(named: "iconSounityWhite")!, closeButtonTitle: "Cancel")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellPlaylistName", for: indexPath)
        cell.isUserInteractionEnabled = true
        cell.textLabel?.text = self.ownPlaylist[indexPath.row].name
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(EventController.addPlaylistToUserEvent)))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ownPlaylist.count
    }
    
    /// Get all the playlist of the current user in order to eventually add one or few of them to the event
    func getUserOwnPlaylists() {
        let api = SounityAPI()
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)/playlists"
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
                        for (_,subJson):(String, JSON) in jsonResponse {
                            self.ownPlaylist.append(Playlist(name: subJson["name"].stringValue, create_date: subJson["create_date"].stringValue, id: subJson["id"].intValue, desc: subJson["description"].stringValue, _picture: subJson["picture"].stringValue))
                        }
                    }
                }
        }
    }
    
    /// Function call when the user wants to add a playlist to the current event
    ///
    /// - Parameter sender: reference of the cell where the user clicked on on the playlists table view
    func addPlaylistToUserEvent(_ sender: UITapGestureRecognizer) {
        let touch = sender.location(in: tableviewPopup)
        if let indexPath = tableviewPopup.indexPathForRow(at: touch) {
            let api = SounityAPI()
            let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
            let parameters : [String : AnyObject] = [
                "id": self.ownPlaylist[indexPath.row].id as AnyObject,
            ]
            
            Alamofire.request(api.getRoute(SounityAPI.ROUTES.GET_INFO_EVENT) + "/" + "\(self.idEventSent)" + "/" + "playlist", method: .post, parameters : parameters, headers: headers)
                .validate(statusCode: 200..<500)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    if let apiResponse = response.result.value {
                        let jsonResponse = JSON(apiResponse)
                        if ((response.response?.statusCode)! == 400) {
                            let alert = DisplayAlert(title: "Add playlist", message: jsonResponse["message"].stringValue)
                            alert.openAlertError()
                        }
                        else {
                            let alert = DisplayAlert(title: "Add Playlist", message: ("The playlist : '\(self.ownPlaylist[indexPath.row].name)' has been added to the event."))
                            alert.openAlertSuccess()
                        }
                    }
            }
            
        }
    }
}

// MARK: Media player functions
extension EventController {
    /// Allows to initialise the entire player available for the event's owner
    func initPlayer() {
        self.InteractivePView!.delegate = self
        self.InteractivePView.progress = 120
        self.InteractivePView.isUserInteractionEnabled = true
        self.InteractivePView.progressFullColor = ColorSounity.orangeSounity
        
        self.InteractivePView.actionOne_icon_selected = UIImage(named: "RepeatSelected")
        self.InteractivePView.actionOne_icon_unselected = UIImage(named: "RepeatSelected")
        
        self.InteractivePView.actionTwo_icon_selected = UIImage(named: "ShuffleSelected")
        self.InteractivePView.actionTwo_icon_unselected = UIImage(named: "ShuffleUnselected")
        
        if (owner) {
            self.InteractivePView.actionThree_icon_selected = UIImage(named: "Next")
            self.InteractivePView.actionThree_icon_unselected = UIImage(named: "Next")
        }
        
        self.InteractivePView.coverImage = UIImage(named: "defaultCoverIPV")
        MakeBlurImage().makeImageBlurry(self.blurImage)
        
        self.playPauseView.backgroundColor = ColorSounity.orangeSounity
        MakeElementRounded().makeElementRounded(self.playPauseView, newSize: self.playPauseView.frame.width)
        if (owner == false) {
            self.playPauseView.isHidden = true
            self.player?.isMuted = true
            self.settingsButton.isHidden = true
            self.addPlaylistButton.isEnabled = false
        }
    }
    
    @IBAction func playMusic() {
        self.sendPlayMusicToUsersEvent()
    }
    
    @IBAction func pauseButtonTapped(_ sender: AnyObject) {
        self.sendPauseMusicToUsersEvent()
    }
    
    @IBAction func nextButtonTapped(_ sender: AnyObject) {
        self.sendNextMusicToUsersEvent()
    }
    
    /// Call when a song has stopped playing
    ///
    /// - Parameter myNotification: notification element set during page loading
    func finishedPlaying(_ myNotification:Notification) {
        self.InteractivePView.stop()
        self.playButton.isHidden = false
        self.pauseButton.isHidden = true
        
        if (self.player != nil) {
            self.player!.pause();
        }
        
        if (owner) {
            self.sendNextMusicToUsersEvent()
        }
    }
    
    /// Allows to reload the event by making a event:joined
    func reloadEvent() {
        if (self.player != nil) {
            self.InteractivePView.stop()
            self.playButton.isHidden = false
            self.pauseButton.isHidden = true
            
            self.player!.pause();
        }
        
        let tabBar = self.childViewControllers[0] as! UITabBarController
        let barViewControllers = tabBar.viewControllers
        let svc = barViewControllers![EventController.TABITEM.playlist.rawValue] as! PlaylistEventController
        svc.getPlaylistEvent()
    }
}

// MARK: Listen functions
extension EventController {
    /// Listen the broadcast music:played
    func listenMusicPlayed() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.MUSIC_PLAYED.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            if (self.player != nil) {
                self.player!.play();
            }
            
            self.gatherDataMusicAndPlay(data["id"].stringValue, apiId: data["apiId"].intValue, time: data["time"].int64Value)
            
            print("Music Played : [\(data)]")
            
            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                self.reloadEvent()
            }
        }
    }
    
    /// Listen the broadcast music:paused
    func listenMusicPaused() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.MUSIC_PAUSED.rawValue) { (dataArray, Socket) -> Void in
            //NSNotificationCenter.defaultCenter().removeObserver(self)
            self.InteractivePView.stop()
            self.playButton.isHidden = false
            self.pauseButton.isHidden = true
            
            if (self.player != nil) {
                self.player!.pause();
            }
            
            let data = JSON(dataArray[0])
            print("Music Paused : [\(data)]")
            
            if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                self.reloadEvent()
            }
        }
    }
    
    /// Listen the broadcast music:changed
    func listenMusicChanged() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.MUSIC_CHANGED.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            if (!self.owner) {
                print("Music changed : [\(data)]")
                
                if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: data["transactionId"].intValue)) {
                    self.reloadEvent()
                } else {
                    self.gatherDataMusicAndPlay(data["id"].stringValue, apiId: data["apiId"].intValue, time: 0)
                }
            }
        }
    }
}

// MARK: Sockets functions
extension EventController {
    /// send socket music:play
    func sendPlayMusicToUsersEvent() {
        SocketIOManager.sharedInstance.playMusicInEvent(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Play music", message: datasList["message"].stringValue)
                        alert.openAlertError()
                    } else {
                        print("Socket Play event ok [\(datasList)]")
                        
                        if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: datasList["transactionId"].intValue)) {
                            self.reloadEvent()
                        } else {
                            if (self.player != nil) {
                                self.InteractivePView.start()
                                self.playButton.isHidden = true
                                self.pauseButton.isHidden = false
                                
                                let timeToSeek: CMTime = CMTimeMake((datasList["time"].int64Value / 1000), 1)
                                self.playerItem!.seek(to: timeToSeek)
                                self.player?.play()
                            } else {
                                self.gatherDataMusicAndPlay(datasList["id"].stringValue, apiId: datasList["apiId"].intValue, time: datasList["time"].int64Value)
                            }
                        }
                    }
                }
            })
        })
    }
    
    /// send socket music:pause
    func sendPauseMusicToUsersEvent() {
        SocketIOManager.sharedInstance.pauseMusicInEvent(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject, "time": Int((self.playerItem?.currentTime().seconds)! * 1000) as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Pause music", message: datasList["message"].stringValue)
                        alert.openAlertError()
                    } else {
                        print("Socket Pause event ok [\(datasList)]")
                        
                        if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: datasList["transactionId"].intValue)) {
                            self.reloadEvent()
                        } else {
                            //NSNotificationCenter.defaultCenter().removeObserver(self)
                            self.InteractivePView.stop()
                            self.playButton.isHidden = false
                            self.pauseButton.isHidden = true
                            
                            self.player!.pause();
                        }
                    }
                }
            })
        })
    }
    
    /// send socket event:next
    func sendNextMusicToUsersEvent() {
        SocketIOManager.sharedInstance.nextMusicInEvent(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Next music", message: datasList["message"].stringValue)
                        alert.openAlertError()
                    } else {
                        print("Socket Next event ok [\(datasList)]")
                        
                        if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: datasList["transactionId"].intValue)) {
                            self.reloadEvent()
                        } else {
                            self.gatherDataMusicAndPlay(datasList["id"].stringValue, apiId: datasList["apiId"].intValue, time: 0)
                        }
                    }
                }
            })
        })
    }
}

// MARK: Set Up & Play music
extension EventController {
    /// Request to play music from Music Provider API when the user joins the event
    ///
    /// - Parameters:
    ///   - infoMusic: info related to the music that should be played first
    ///   - statusMusic: music's status in order to now i the music should be played or not [PLAY | PAUSE | EMPTY]
    ///   - timeMusic: time where the music is supposed to play first
    func setMediaPlayerFromEventJoin(_ infoMusic: JSON, timeMusic: Int64, statusMusic: String) {
        if (statusMusic == "EMPTY") {
            return
        }
        
        Alamofire.request(MusicProvider.sharedInstance.getUrlTrackByMusicProvider(infoMusic["id"].stringValue, _apiId: infoMusic["apiId"].intValue), method: .get)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if (jsonResponse["error"].exists() || jsonResponse["errors"].exists()) {
                        let alert = DisplayAlert(title: "Play music", message: "Error in loading track")
                        alert.openAlertError()
                    } else {
                        self.trackPlayed = SounityTrackResearch(_jsonResponse: jsonResponse, _music_provider: MusicProvider.sharedInstance.getNameMusicProviderById(infoMusic["apiId"].intValue), _apiId: infoMusic["apiId"].intValue)
                        
                        self.titleMusic.text = self.trackPlayed.title
                        self.typeMusic.text = self.trackPlayed.artist
                        if (self.trackPlayed.cover.isEmpty) {
                            self.InteractivePView.coverImage = UIImage(named: "defaultCoverIPV")
                        }
                        else if (Reachability.isConnectedToNetwork() == true) {
                            self.blurImage.imageFromServerURL(urlString: self.trackPlayed.cover)
                            
                            let urlCover = URL(string: self.trackPlayed.cover)
                            DispatchQueue.global().async {
                                let data = try? Data(contentsOf: urlCover!)
                                DispatchQueue.main.async {
                                    self.InteractivePView.coverImage = UIImage(data: data!)
                                }
                            }
                        }
                        
                        self.playerItem = AVPlayerItem( url:NSURL( string:self.trackPlayed.streamLink )! as URL )
                        self.player = AVPlayer(playerItem:self.playerItem!)
                        
                        let playerLayer=AVPlayerLayer(player: self.player)
                        playerLayer.frame=CGRect(0, 0, 300, 50)
                        self.view.layer.addSublayer(playerLayer)
                        
                        let timeToSeek: CMTime = CMTimeMake((timeMusic / 1000), 1)
                        self.playerItem!.seek(to: timeToSeek)
                        
                        if (self.owner == false) {
                            self.player?.isMuted = true
                        }
                        
                        self.player!.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
                        if (statusMusic == "PLAY") {
                            if (self.owner) {
                                self.InteractivePView.restartWithProgress(duration: self.trackPlayed.preview ? 30 : self.trackPlayed.duration, _progress: Double(timeMusic / 1000), _play: true) // Music Time
                            }
                            self.playButton.isHidden = true
                            self.pauseButton.isHidden = false
                            
                            self.player?.play()
                        } else if (statusMusic == "PAUSE") {
                            if (self.owner) {
                                self.InteractivePView.restartWithProgress(duration: self.trackPlayed.preview ? 30 : self.trackPlayed.duration, _progress: Double(timeMusic / 1000), _play: false) // Music Time
                            }
                            self.InteractivePView.stop()
                            self.playButton.isHidden = false
                            self.pauseButton.isHidden = true
                            
                            self.player?.pause()
                        }
                    }
                }
        }
    }
    
    /// Request to play music from Music Provider API when the user joins the event
    ///
    /// - Parameters:
    ///   - idMusic: id of the music to play
    ///   - apiId: id api of the music [Deezer | Soundcloud]
    ///   - time: time where the music is supposed to play first
    func gatherDataMusicAndPlay(_ idMusic: String, apiId: Int, time: Int64) {
        Alamofire.request(MusicProvider.sharedInstance.getUrlTrackByMusicProvider(idMusic, _apiId: apiId), method: .get)
            .validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if (jsonResponse["error"].exists() || jsonResponse["errors"].exists()) {
                        let alert = DisplayAlert(title: "Play music", message: "Error in loading track")
                        alert.openAlertError()
                    } else {
                        self.playButton.isHidden = true
                        self.pauseButton.isHidden = false
                        
                        self.trackPlayed = SounityTrackResearch(_jsonResponse: jsonResponse, _music_provider: MusicProvider.sharedInstance.getNameMusicProviderById(apiId), _apiId: apiId)
                        
                        self.titleMusic.text = self.trackPlayed.title
                        self.typeMusic.text = self.trackPlayed.artist
                        if (self.trackPlayed.cover.isEmpty) {
                            self.InteractivePView.coverImage = UIImage(named: "defaultCoverIPV")
                        }
                        else if (Reachability.isConnectedToNetwork() == true) {
                            self.blurImage.imageFromServerURL(urlString: self.trackPlayed.cover)
                            
                            let urlCover = URL(string: self.trackPlayed.cover)
                            DispatchQueue.global().async {
                                let data = try? Data(contentsOf: urlCover!)
                                DispatchQueue.main.async {
                                    self.InteractivePView.coverImage = UIImage(data: data!)
                                }
                            }
                        }
                        
                        self.playerItem = AVPlayerItem( url:NSURL( string:self.trackPlayed.streamLink )! as URL )
                        self.player = AVPlayer(playerItem:self.playerItem!)
                        
                        let playerLayer=AVPlayerLayer(player: self.player)
                        playerLayer.frame=CGRect(0, 0, 300, 50)
                        self.view.layer.addSublayer(playerLayer)
                        
                        if (self.owner) {
                            self.InteractivePView.restartWithProgress(duration: self.trackPlayed.preview ? 30 : self.trackPlayed.duration, _progress: Double(time / 1000), _play: true) // Music Time
                        }
                        let timeToSeek: CMTime = CMTimeMake((time / 1000), 1)
                        self.playerItem!.seek(to: timeToSeek)
                        
                        if (self.owner == false) {
                            self.player?.isMuted = true
                        }
                        
                        self.player!.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
                        self.player?.play()
                        
                        if (self.trackPlayed.idTrack >= 0) {
                            let tabBar = self.childViewControllers[0] as! UITabBarController
                            let barViewControllers = tabBar.viewControllers
                            let svc = barViewControllers![EventController.TABITEM.playlist.rawValue] as! PlaylistEventController
                            svc.removeMusicInPlaylistById(Int(idMusic)!, apiId: apiId)
                        }
                    }
                }
        }
    }
}

// MARK: Go to settings 
extension EventController {
    @IBAction func goToSettingsEvent (_ sender: UIButton) {
        let vc:ConsultEventController = ConsultEventController()
        vc.idEventSent = self.idEventSent
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: Delegate functions for InteractivePlayerView
extension EventController {
    func actionOneButtonTapped(sender: UIButton, isSelected: Bool) { }
    func actionTwoButtonTapped(sender: UIButton, isSelected: Bool) { }
    func actionThreeButtonTapped(sender: UIButton, isSelected: Bool) {
        self.InteractivePView.stop()
        self.playButton.isHidden = false
        self.pauseButton.isHidden = true
        
        if (self.player != nil) {
            player!.pause();
        }
        
        self.sendNextMusicToUsersEvent()
    }
    
    func interactivePlayerViewDidChangedDuration(playerInteractive: InteractivePlayerView, currentDuration: Double) { }
    func interactivePlayerViewDidStartPlaying(playerInteractive: InteractivePlayerView) { }
    func interactivePlayerViewDidStopPlaying(playerInteractive: InteractivePlayerView) { }
}
// MARK: Guillotine menu
extension EventController {
    @IBAction func showMenuAction(_ sender: UIButton) {
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
}

// MARK: Hide status bar
extension EventController {
    override var prefersStatusBarHidden : Bool {
        return false
    }
}

// MARK: Transition delegate functions
extension EventController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .presentation
        return presentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentationAnimator.mode = .dismissal
        return presentationAnimator
    }
}
