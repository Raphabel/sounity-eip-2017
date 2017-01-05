//
//  SocketIOManager.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import SwiftyJSON

class SocketIOManager: NSObject {
    
    static let sharedInstance = SocketIOManager()
    var socket: SocketIOClient = SocketIOClient(socketURL: NSURL(string: SounityAPI.API.DEMO.rawValue)! as URL)
    
    var idLastTransaction: Int = 0
    
    override init() {
        super.init()
    }
    
    func establishConnection() {
        socket.connect()
    }
    
    
    func closeConnection() {
        socket.disconnect()
    }

    func restartConnection() {
        socket.disconnect()
        socket.connect()
    }
    
    func setCurrentTransactionId(idTransactionReceived: Int) {
        self.idLastTransaction = idTransactionReceived
    }
    
    func registerNewTransaction(idTransactionReceived: Int) -> Bool {
        if (idTransactionReceived <= (self.idLastTransaction + 1)) {
            self.idLastTransaction = idTransactionReceived
            return true
        } else {
            return false
        }
    }
    
    func connectToEventWithToken(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("event:join", datas).timingOut(after: 10, callback: { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
        })
    }
    
    func sendMessageToEventChat(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("chat:message", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
        }
    }
    
    func banUserFromEvent(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("event:ban", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
        }
    }
    
    func addMusicToEventPlaylist(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("music:add", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
        }
    }
    
    func likeMusicInEventPlaylist(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("music:like", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
        }
    }
    
    func dislikeMusicInEventPlaylist(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("music:like", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
        }
    }
    
    func playMusicInEvent(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("music:play", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
        }
    }
    
    func pauseMusicInEvent(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("music:pause", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
        }
    }
    
    func nextMusicInEvent(datas: [String: AnyObject], completionHandler: @escaping (_ datasList: JSON) -> Void) {
        socket.emitWithAck("music:next", datas).timingOut(after: 10) { data in
            let jsonResponse = JSON(data)
            completionHandler(jsonResponse[0])
            self.idLastTransaction = self.idLastTransaction + 1
            
        }
    }
    
}


