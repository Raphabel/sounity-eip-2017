//
//  PlaylistSelectedController.swift
//  Sounity
//
//  Created by Alix FORNIELES on 14/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import GuillotineMenu
import AVFoundation
import Alamofire
import SwiftyJSON
import PullToRefresh
import SCLAlertView
import DZNEmptyDataSet

class ConsultMusicsInPlaylistController: UIViewController, UITableViewDelegate, DZNEmptyDataSetDelegate, InteractivePlayerViewDelegate {

    //MARK: UIElements variables
    @IBOutlet weak var InteractivePView: InteractivePlayerView!
    @IBOutlet weak var blurImage: UIImageView!
    @IBOutlet weak var viewIPV: UIView!
    @IBOutlet var playMusicButton: UIButton!
    @IBOutlet var playedMusicButton: UIButton!
    @IBOutlet var nbMusicsPlaylist: UILabel!
    @IBOutlet var nbLikesPlaylist: UILabel!
    @IBOutlet var likeBtn: UIImageView!
    @IBOutlet var nextButton: UIImageView!
    @IBOutlet var previousButton: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var musics = [Music]()
    var api = SounityAPI()
    
    //MARK: Variable in order to manage add music to own playlist
    var tableviewPopup = UITableView()
    var ownPlaylist = [Playlist]()
    var musicSelectedToAdd: Music?
    
    //MARK: Playlist handling variables
    var id_playlist: Int?
    var playlistLiked: Bool = false
    var owner_playlist: Bool = false
    var shuffle = false
    var repeatPlaylist = true
    var idMusicPlayed = 0
    
    //MARK: Variables related to the media player
    var playerItem:AVPlayerItem?
    var player:AVPlayer?
    var trackPlayed: SounityTrackResearch!
    
    //MARK: Infos user connected
    var user = UserConnect()
  
    fileprivate lazy var presentationAnimator = GuillotineTransitionAnimation()
  
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        self.intiIPV()
        self.getUserOwnPlaylists()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getAllMusicsPlaylists(id_playlist!)
        NotificationCenter.default.addObserver(self, selector: #selector(ConsultMusicsInPlaylistController.finishedPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        if (self.player?.rate > 0) {
            self.InteractivePView.stop()
            self.player?.pause()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let refresher = PullToRefresh()
        tableView.addPullToRefresh(refresher) {
            self.getAllMusicsPlaylists(self.id_playlist!)
        }
        
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
    
    deinit {
        self.tableView.removePullToRefresh(tableView.topPullToRefresh!)
    }
    
    // Allow to listen when a music is stop / pause or play
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if let rate = change?[NSKeyValueChangeKey.newKey] as? Float {
                if rate == 0.0 {  }
                if rate == 1.0 {  }
                if rate == -1.0 {  }
            }
        }
    }
}

//MARK: Navigation functions
extension ConsultMusicsInPlaylistController {
    @IBAction func backButton(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: Initialisation functions
extension ConsultMusicsInPlaylistController {
    /// Allows to initialise the entire player available
    func intiIPV() {
        self.InteractivePView!.delegate = self
        self.InteractivePView.progress = 120.0
        self.InteractivePView.progressFullColor = ColorSounity.orangeSounity
        
        self.InteractivePView.actionOne_icon_selected = UIImage(named: "ShuffleSelected")
        self.InteractivePView.actionOne_icon_unselected = UIImage(named: "ShuffleUnselected")
        
        self.InteractivePView.actionTwo_icon_selected = UIImage(named: "Pause")
        self.InteractivePView.actionTwo_icon_unselected = UIImage(named: "Play")
        
        self.InteractivePView.actionThree_icon_selected = UIImage(named: "RepeatSelected")
        self.InteractivePView.actionThree_icon_unselected = UIImage(named: "RepeatSelected")
        
        self.InteractivePView.coverImage = UIImage(named: "defaultCoverIPV")
        MakeBlurImage().makeImageBlurry(self.blurImage)
        
        self.likeBtn.isUserInteractionEnabled = true
        self.likeBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ConsultMusicsInPlaylistController.likePlaylist)))
        
        self.nextButton.isUserInteractionEnabled = true
        self.previousButton.isUserInteractionEnabled = true
        
        self.nextButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ConsultMusicsInPlaylistController.playNextSong)))
        self.previousButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ConsultMusicsInPlaylistController.playPreviousSong)))
    }
    
    /// Get all the playlist of the current user in order to eventually add one music to one of his playlists
    func getUserOwnPlaylists() {
        let url = api.getRoute(SounityAPI.ROUTES.CREATE_USER) + "/" + "\(user.id)"
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
                        for (_,subJson):(String, JSON) in jsonResponse["playlists"] {
                            if (subJson["id"].intValue != self.id_playlist) {
                                self.ownPlaylist.append(Playlist(name: subJson["name"].stringValue, create_date: subJson["create_date"].stringValue, id: subJson["id"].intValue, desc: subJson["description"].stringValue, _picture: subJson["picture"].stringValue))
                            }
                        }
                    }
                }
        }
    }
    
    
    /// Fetxhed all the musics of a specific playlist
    ///
    /// - Parameter id_playlist: id of the playlist
    func getAllMusicsPlaylists(_ id_playlist: Int)  {
        let url = api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER) + "/\(id_playlist)"
        let headers = [ "Authorization": "Bearer \(user.token)", "Content-Type": "application/x-www-form-urlencoded"]
        
        Alamofire.request(url, method: .get, headers: headers).validate(statusCode: 200..<501)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! != 200) {
                        self.dismiss(animated: true, completion: nil)
                        let alert = DisplayAlert(title: "Playlist", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    } else {
                        self.navigationItem.title = jsonResponse["name"].stringValue
                        
                        self.playlistLiked = jsonResponse["liked"].boolValue
                        if (self.playlistLiked == false) {
                            self.likeBtn.image = UIImage(named: "LikeUnselected")
                        }
                        
                        if (jsonResponse["id_user"].intValue == self.user.id) {
                            self.owner_playlist = true
                        }
                        
                        self.musics.removeAll()
                        for (_,subJson):(String, JSON) in jsonResponse["musics"] {
                            self.musics.append(Music(id: subJson["id"].intValue, title: subJson["title"].stringValue, artist: subJson["artist"].stringValue, IDMusic: subJson["id_music"].intValue, apiId: subJson["apiId"].intValue, played: false, cover: subJson["cover"].stringValue, duration: subJson["duration"].doubleValue))
                        }
                        if (self.musics.count > 0) {
                            if (self.musics[0].cover == "") {
                                self.InteractivePView.coverImage = UIImage(named: "defaultCoverIPV")
                            }
                            else if (Reachability.isConnectedToNetwork() == true) {
                                self.blurImage.imageFromServerURL(urlString: self.musics[0].cover)
                                self.InteractivePView.coverImage = self.blurImage.image
                            }
                        }
                        
                        let nbLikes = jsonResponse["nbLikes"].intValue
                        self.nbLikesPlaylist.text = String(nbLikes) == "" ? "0" : String(nbLikes)
                        self.nbMusicsPlaylist.text = (String(self.musics.count) + " SONGS")
                        
                        self.tableView.reloadData()
                        self.tableView.endRefreshing(at: Position.top)
                    }
                }
        }
    }
}

//MARK: Function to handle media player
extension ConsultMusicsInPlaylistController {
    func finishedPlaying(_ myNotification:Notification) {
        self.InteractivePView.stop()
        if (self.player != nil) {
            self.player?.pause()
        }
        
        let stopedPlayerItem: AVPlayerItem = myNotification.object as! AVPlayerItem
        stopedPlayerItem.seek(to: kCMTimeZero)
        
        self.playNextSong()
    }
    
    func playNextSong() {
        var indexMusic = -1
        
        self.InteractivePView.stop()
        if (self.player != nil) {
            self.player?.pause()
        }
        
        if (self.musics.count == 0) {
            self.InteractivePView.isActionTwoSelected = false
            let alert = DisplayAlert(title: "Play music", message: "There is no music in the playlist")
            alert.openAlertError()
            return
        } else if (self.musics.count == 1) {
            self.gatherDataMusicAndPlay(String(self.musics[0].IDMusic), apiId: self.musics[0].apiId, time: 0)
            return
        }
        
        for (index, music) in musics.enumerated() {
            if (music.IDMusic == self.idMusicPlayed) {
                indexMusic = index
            }
        }
        
        if (self.shuffle) {
            var tmp = -1
            while (tmp == -1 || tmp == indexMusic) {
                tmp = Int(arc4random_uniform(UInt32(musics.count)))
            }
            self.setMusicPlaylistDesign(tmp)
        } else {
            if ((indexMusic + 1) > (musics.count - 1)) {
                self.setMusicPlaylistDesign(0)
            } else {
                self.setMusicPlaylistDesign(indexMusic + 1)
            }
        }
    }
    
    func playPreviousSong() {
        var indexMusic = -1
        
        self.InteractivePView.stop()
        if (self.player != nil) {
            self.player?.pause()
        }
        
        if (self.musics.count == 0) {
            let alert = DisplayAlert(title: "Play music", message: "There is no music in the playlist")
            alert.openAlertError()
            return
        } else if (self.musics.count == 1) {
            self.gatherDataMusicAndPlay(String(self.musics[0].IDMusic), apiId: self.musics[0].apiId, time: 0)
            return
        }
        
        for (index, music) in musics.enumerated() {
            if (music.IDMusic == self.idMusicPlayed) {
                indexMusic = index
            }
        }
        
        if (self.shuffle) {
            var tmp = -1
            while (tmp == -1 || tmp == indexMusic) {
                tmp = Int(arc4random_uniform(UInt32(musics.count - 1)))
            }
            self.setMusicPlaylistDesign(tmp)
        } else {
            if ((indexMusic - 1) < 0) {
                self.setMusicPlaylistDesign(musics.count - 1)
            } else {
                self.setMusicPlaylistDesign(indexMusic - 1)
            }
        }
    }
    
    /// Setup the media player according to the music played
    ///
    /// - Parameter position: position of th emusic within the playlist
    func setMusicPlaylistDesign(_ position: Int) {
        for music in musics {
            music.played = false
        }
        self.idMusicPlayed = musics[position].IDMusic
        self.musics[position].played = true
        
        if (musics[position].cover == "") {
            self.InteractivePView.coverImage = UIImage(named: "defaultCoverIPV")
        }
        else if (Reachability.isConnectedToNetwork() == true) {
            self.blurImage.imageFromServerURL(urlString: musics[position].cover)
            self.InteractivePView.coverImage = self.blurImage.image
        }
        
        gatherDataMusicAndPlay(String(musics[position].IDMusic), apiId: musics[position].apiId, time: 0)
        
        self.tableView.reloadData()
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
                        self.InteractivePView.isActionTwoSelected = false
                        let alert = DisplayAlert(title: "Play music", message: "Error in loading track")
                        alert.openAlertError()
                    } else {
                        self.trackPlayed = SounityTrackResearch(_jsonResponse: jsonResponse, _music_provider: MusicProvider.sharedInstance.getNameMusicProviderById(apiId), _apiId: apiId)
                        
                        if (self.trackPlayed.cover == "") {
                            self.InteractivePView.coverImage = UIImage(named: "defaultCoverIPV")
                        }
                        else if (Reachability.isConnectedToNetwork() == true) {
                            self.blurImage.imageFromServerURL(urlString: self.trackPlayed.cover)
                            self.InteractivePView.coverImage = self.blurImage.image
                        }
                        
                        self.playerItem = AVPlayerItem( url:NSURL( string:self.trackPlayed.streamLink )! as URL )
                        self.player = AVPlayer(playerItem:self.playerItem!)
                        
                        let playerLayer = AVPlayerLayer(player: self.player)
                        playerLayer.frame = CGRect(0, 0, 300, 50)
                        self.view.layer.addSublayer(playerLayer)
                        
                        self.InteractivePView.restartWithProgress(duration: self.trackPlayed.preview ? 30 : self.trackPlayed.duration, _progress: Double(time / 1000), _play: true) // Music Time
                        let timeToSeek: CMTime = CMTimeMake((time / 1000), 1)
                        self.playerItem!.seek(to: timeToSeek)
                        
                        self.player!.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
                        self.player?.play()
                        
                        self.idMusicPlayed = Int(idMusic)!
                    }
                }
        }
    }
    
    /// Actions as Shuffled or unshuffled playlist
    ///
    /// - Parameters:
    ///   - sender: sender related to the button
    ///   - isSelected: is the shuffled button is on or not
    func actionOneButtonTapped(sender: UIButton, isSelected: Bool) {
        self.shuffle = !self.shuffle
    }
    
    /// Actions as play or pause
    ///
    /// - Parameters:
    ///   - sender: sender related to the button
    ///   - isSelected: is the playlist supposed to play or not
    func actionTwoButtonTapped(sender: UIButton, isSelected: Bool) {
        if (self.player != nil && self.player?.rate > 0) {
            self.InteractivePView.stop()
            self.player?.pause()
        } else if (self.player != nil) {
            self.InteractivePView.start()
            self.player?.play()
        } else {
            self.playNextSong()
        }
    }
    func actionThreeButtonTapped(sender: UIButton, isSelected: Bool) {
        //self.repeatPlaylist = !self.repeatPlaylist
    }
    func interactivePlayerViewDidChangedDuration(playerInteractive: InteractivePlayerView, currentDuration: Double) {
        
    }
    func interactivePlayerViewDidStartPlaying(playerInteractive: InteractivePlayerView) {
        self.InteractivePView.isActionTwoSelected = true
    }
    func interactivePlayerViewDidStopPlaying(playerInteractive: InteractivePlayerView) {
        self.InteractivePView.isActionTwoSelected = false
    }
}

//MARK: Actions to do within the playlist
extension ConsultMusicsInPlaylistController {
    /// Function that allows to like or dislikes a playlist
    func likePlaylist() {
        let api = SounityAPI()
        let url = (api.getRoute(SounityAPI.ROUTES.PLAYLIST_USER) + "/" + String(self.id_playlist!) + "/" + "like")
        let headers = [ "Authorization": "Bearer \(user.token)", "Accept": "application/json"]
        
        Alamofire.request(url, method: self.playlistLiked == false ? .post: .delete, headers: headers)
            .validate(statusCode: 200..<500)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                if let apiResponse = response.result.value {
                    let jsonResponse = JSON(apiResponse)
                    if ((response.response?.statusCode)! == 400) {
                        if (jsonResponse["message"].stringValue == "You already have liked this playlist") {
                            self.likeBtn.image = UIImage(named: "LikeSelected")
                            self.playlistLiked = true
                        }
                        let alert = DisplayAlert(title: "Like Playlist", message: jsonResponse["message"].stringValue)
                        alert.openAlertError()
                    }
                    else {
                        if (!self.playlistLiked) {
                            self.playlistLiked = true
                            self.likeBtn.image = UIImage(named: "LikeSelected")
                            self.nbLikesPlaylist.text = String(Int(self.nbLikesPlaylist.text!)! + 1)
                        } else {
                            self.playlistLiked = false
                            self.likeBtn.image = UIImage(named: "LikeUnselected")
                            self.nbLikesPlaylist.text = String(Int(self.nbLikesPlaylist.text!)! - 1)
                        }
                        
                        let alert = DisplayAlert(title: "Like Playlist", message: jsonResponse["message"].stringValue)
                        alert.openAlertSuccess()
                    }
                }
        }
    }
    
    func displayPopupAddToPlaylist() {
        let appearance = SCLAlertView.SCLAppearance(
            showCircularIcon: true,
            kCircleIconHeight: 30,
            kCircleHeight: 55,
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        
        let alert = SCLAlertView(appearance: appearance)
        let subview = UIView(frame: CGRect(x: 0,y: 10,width: 200,height: 250))
        
        let label = UILabel(frame: CGRect(x: ((subview.frame.width - 180) / 2),y: 0,width: 190,height: 20))
        label.font = UIFont(name: "TimesNewRomanPS-ItalicMT", size: 12)
        label.text = "Add this song to one of your playlist"
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
            labelEmptyPlaylistsList.text = "No other playlist registred..."
            labelEmptyPlaylistsList.textAlignment = .center
            labelEmptyPlaylistsList.lineBreakMode = .byWordWrapping
            labelEmptyPlaylistsList.numberOfLines = 0
            
            subview.addSubview(labelEmptyPlaylistsList)
            subview.frame = CGRect(x: 0,y: 10,width: 200,height: 90)
        }
        
        // Add the subview to the alert's UI property
        alert.customSubview = subview
        _ = alert.showCustom(self.musicSelectedToAdd!.title, subTitle: "", color: ColorSounity.navigationBarColor, icon: UIImage(named: "iconSounityWhite")!, closeButtonTitle: "Cancel")
    }
}

//MARK: Table view functions
extension ConsultMusicsInPlaylistController: UITableViewDataSource, DZNEmptyDataSetSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableView) {
            return musics.count
        } else {
            return ownPlaylist.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView == self.tableView) {
            if (self.player?.rate > 0) {
                self.InteractivePView.stop()
                self.player?.pause()
            }
            
            let indexPathRow = tableView.indexPathForSelectedRow!.row
            self.setMusicPlaylistDesign(indexPathRow)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView == self.tableView) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "mytableCell2", for: indexPath) as? MusicsInPlaylistCell
            
            cell!.music = self.musics[indexPath.row]
            cell!.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ConsultMusicsInPlaylistController.showOptionsSong)))
            
            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellPlaylistName", for: indexPath)
            cell.isUserInteractionEnabled = true
            cell.textLabel?.text = self.ownPlaylist[indexPath.row].name
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MediaPlayerViewController.addMusicToUserPlaylist)))
            return cell
        }
    }
    
    /// Callback when long press gesture is recorded on a music
    ///
    /// - Parameter longPressGestureRecognizer: longPressGestureRecognizer description
    func showOptionsSong(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let optionMenu = UIAlertController(title: nil, message: self.musics[indexPath.row].title, preferredStyle: .actionSheet)
                
                let addMusicToPlaylist = UIAlertAction(title: "Add to another Playlist", style: .default, handler: {
                    (alert: UIAlertAction!) -> Void in
                    self.musicSelectedToAdd = self.musics[indexPath.row]
                    self.displayPopupAddToPlaylist()
                })
                
                let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
                    (alert: UIAlertAction!) -> Void in })
                
                optionMenu.addAction(addMusicToPlaylist)
                optionMenu.addAction(cancel)
                
                self.present(optionMenu, animated: true, completion: nil)
            }
        }
    }
    
    // Function that fulfilles the tableview when it's empty
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.darkGray]
        let attributedString = NSMutableAttributedString(string:"No music in the playlist", attributes: attrsBold)
        
        return attributedString
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        if (!self.owner_playlist) {
            return nil
        }
        let attrsBold = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 14), NSForegroundColorAttributeName: UIColor.darkGray]
        let attributedString = NSMutableAttributedString(string:"You can add new songs from our musical library (Deezer & Soundcloud)", attributes: attrsBold)
        
        return attributedString
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "emptyPlaylist")
    }
    
    func buttonImage(forEmptyDataSet scrollView: UIScrollView, for state: UIControlState) -> UIImage? {
        if (!self.owner_playlist) {
            return nil
        }
        return UIImage(named: "plus")
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView) {
        performSegue(withIdentifier: "unwindSegue", sender: self)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat {
        return -25;
    }
}

extension ConsultMusicsInPlaylistController {
    override var prefersStatusBarHidden : Bool {
        return false
    }
}
