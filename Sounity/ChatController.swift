//
//  ChatController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//


import UIKit
import Foundation
import SwiftyJSON
import SwiftDate
import DZNEmptyDataSet
import SwiftMoment

class ChatController: UIViewController, UITableViewDelegate, DZNEmptyDataSetDelegate, UITextViewDelegate {
    
    // MARK: UIElements variables
    @IBOutlet var tableview: UITableView!
    @IBOutlet var TextMessage: UITextView!
    @IBOutlet var buttonSendMessage: UIButton!

    // MARK: Messages table
    var chatMessages = [MessageChat]()
    
    // MARK: Id evetn variable
    var idEventSent: NSInteger = -1
    
    // MARK: Infos user connected
    var user = UserConnect()
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.idEventSent = user.eventJoined
        
        TextMessage.delegate = self
        tableview.dataSource = self
        tableview.delegate = self
        tableview.emptyDataSetSource = self
        tableview.emptyDataSetDelegate = self
        tableview.tableFooterView = UIView()
        tableview.estimatedRowHeight = 70
        tableview.rowHeight = UITableViewAutomaticDimension
        
        self.TextMessage.layer.cornerRadius = 6
        self.buttonSendMessage.layer.cornerRadius = 6
        
        self.listenNewMessageSocket()
        self.getAllMessages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    /**
     * Called when the user click on the view (outside the UITextField).
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    
    override func viewDidAppear(_ animated: Bool) {
        let tabArray = self.tabBarController?.tabBar.items as NSArray!
        let tabItem = tabArray?.object(at: 2) as! UITabBarItem
        tabItem.badgeValue = nil
        
        self.tableview.reloadData()
    }
}

// MARK: Initialisation functions
extension ChatController {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    /// Function that fetches all the messages on the current event
    func getAllMessages () {
        SocketIOManager.sharedInstance.connectToEventWithToken(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Event", message: datasList["message"].stringValue)
                        alert.openAlertError()
                        return
                    } else {
                        for (_,subJson):(String, JSON) in datasList["chatHistory"] {
                            self.chatMessages.append(MessageChat(_message: subJson["message"].stringValue, _picture: subJson["picture"].stringValue, _nickname: subJson["nickname"].stringValue, _time: subJson["time"].stringValue))
                        }
                        self.tableview.reloadData()
                        self.tableview.scrollToBottom()
                    }
                }
            })
        })
    }
}

// MARK: Sockets functions
extension ChatController {
    func listenNewMessageSocket() {
        SocketIOManager.sharedInstance.socket.on(SounityAPI.SOCKET.NEW_MESSAGE.rawValue) { (dataArray, Socket) -> Void in
            let data = JSON(dataArray[0])
            
            self.chatMessages.append(MessageChat(_message: data["message"].stringValue, _picture: data["picture"].stringValue, _nickname: data["nickname"].stringValue, _time: data["time"].stringValue))
            self.tableview.reloadData()
            self.tableview.scrollToBottom()
        }
    }
    
    @IBAction func sendMessageToChat(_ sender: AnyObject) {
        if (self.TextMessage.text == "") {
            return;
        }
        
        SocketIOManager.sharedInstance.sendMessageToEventChat(datas: ["eventId": self.idEventSent as AnyObject, "token": self.user.token as AnyObject, "message": self.TextMessage.text as AnyObject], completionHandler: { (datasList) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if !(datasList.null != nil) {
                    if (datasList["status"] == 400) {
                        let alert = DisplayAlert(title: "Send Message", message: datasList["message"].stringValue)
                        alert.openAlertError()
                        return
                    } else {
                        self.chatMessages.append(MessageChat(_message: datasList["message"].stringValue, _picture: self.user.picture, _nickname: self.user.username, _time: datasList["time"].stringValue))
                        self.tableview.reloadData()
                        self.tableview.scrollToBottom()
                        self.TextMessage.text = ""
                        
                        if (!SocketIOManager.sharedInstance.registerNewTransaction(idTransactionReceived: datasList["transactionId"].intValue)) {
                            let barViewControllers = self.tabBarController?.viewControllers
                            let svc = barViewControllers![EventController.TABITEM.playlist.rawValue] as! PlaylistEventController
                            svc.getPlaylistEvent()
                        }
                    }
                }
            })
        })
    }
}

// MARK: Empty table view function
extension ChatController: DZNEmptyDataSetSource {
    // Function that fulfilles the tableview when it's empty
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "There is no message sent for the moment"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
}

// MARK: Table view functions
extension ChatController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell:ChatMessageTableCell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCustomTableCell", for: indexPath) as! ChatMessageTableCell
        
        cell.message = self.chatMessages[indexPath.row]
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.chatMessages.count
    }
}

// MARK: Setup of the keyboard
extension ChatController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(notification: NSNotification) {

        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height - 50
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height - 50
            }
        }
    }
}
