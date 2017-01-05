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
    
    // MARK: Guillotine menu variable
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
    
    // MARK: Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init Controller and its values
        self.navItem.title = nameEvent
        self.view.backgroundColor = UIColor.clear

        self.initPlayer()
        
        self.listenMusicPlayed()
        self.listenMusicPaused()
        self.listenMusicChanged()
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

// MARK: Media player functions
extension EventController {
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
    
    /*
     ** Request to play music from Music Provider API
     */
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
        return true
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
