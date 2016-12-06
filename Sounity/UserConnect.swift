//
//  UserConnect.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import Fabric
import Crashlytics

class UserConnect {
    var token = ""
    var username = ""
    var id = -1
    var eventJoined = -1
    var picture = ""
    var birthday = ""
    var lastname = ""
    var firstname = ""
    var descriptionUser = ""
    
    init() {
        self.token = UserDefaults.standard.string(forKey: "tokenUser") ?? ""
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
        self.lastname = UserDefaults.standard.string(forKey: "lastname") ?? ""
        self.firstname = UserDefaults.standard.string(forKey: "firstname") ?? ""
        self.descriptionUser = UserDefaults.standard.string(forKey: "descriptionUser") ?? ""
        self.id = UserDefaults.standard.integer(forKey: "idUser") 
        self.picture = UserDefaults.standard.string(forKey: "pictureUser") ?? ""
        self.birthday = UserDefaults.standard.string(forKey: "birthday") ?? ""
        self.eventJoined = UserDefaults.standard.integer(forKey: "eventJoined") 
        
        if (self.token != "") {
            self.logUserCrashlystics()
        }
    }
    
    func logUserCrashlystics() {
        Crashlytics.sharedInstance().setUserIdentifier(String(self.id))
        Crashlytics.sharedInstance().setUserName(self.username)
    }
    
    func checkUserConnected() -> Bool {
        if (token == "") {
            return false;
        }
        return true;
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "tokenUser")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "idUser")
        UserDefaults.standard.removeObject(forKey: "pictureUser")
        UserDefaults.standard.removeObject(forKey: "birthday")
        UserDefaults.standard.removeObject(forKey: "eventJoined")
    }
    
    func setHisToken(_ _token: String) {
        UserDefaults.standard.set(_token, forKey: "tokenUser")
        self.token = _token
    }
    
    func setHisEventJoined(_ _eventJoined: Int) {
        UserDefaults.standard.set(_eventJoined, forKey: "eventJoined")
        self.eventJoined = _eventJoined
    }
    
    func setHisId(_ _id: Int) {
        UserDefaults.standard.set(_id, forKey: "idUser")
        self.id = _id
    }
    
    func setHisUsername(_ _username: String) {
        UserDefaults.standard.set(_username, forKey: "username")
        self.username = _username
    }
    
    func setHisPicture(_ _picture: String) {
        UserDefaults.standard.set(_picture, forKey: "pictureUser")
        self.picture = _picture
    }
    
    func setHisBirthday(_ _birthday: String) {
        UserDefaults.standard.set(_birthday, forKey: "birthday")
        self.birthday = _birthday
    }
    
    func setHisLastName(_ _lastname: String) {
        UserDefaults.standard.set(_lastname, forKey: "lastname")
        self.lastname = _lastname
    }
    
    func setHisFirstName(_ _firstname: String) {
        UserDefaults.standard.set(_firstname, forKey: "firstname")
        self.firstname = _firstname
    }
    
    func setHisDescription(_ _descriptionUser: String) {
        UserDefaults.standard.set(_descriptionUser, forKey: "descriptionUser")
        self.descriptionUser = _descriptionUser
    }
}

class checkNickname {
    var nickname: String = ""
    var hidden: Bool = false
    
    init() {
        self.nickname = UserDefaults.standard.string(forKey: "nickname") ?? ""
        self.hidden = UserDefaults.standard.bool(forKey: "hidden") 
    }
    
    func setHisNickname(_ _nickname: String) {
        UserDefaults.standard.set(_nickname, forKey: "nickname")
        self.nickname = _nickname
    }
    
    func setHisHidden(_ _hidden: Bool) {
        UserDefaults.standard.set(_hidden, forKey: "hidden")
        self.hidden = _hidden
    }
    
}
