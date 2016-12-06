//
//  User.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 16/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation

class User {
    
    var description: String
    var first_name: String
    var last_name: String
    var picture: String
    var nickname: String

    var id: Int
    var id_country: Int
    var id_language: Int
   
    init() {
        self.description = UserDefaults.standard.string(forKey: "") ?? ""
        self.first_name = UserDefaults.standard.string(forKey: "firstname") ?? ""

        self.last_name = UserDefaults.standard.string(forKey: "") ?? ""
        self.id = UserDefaults.standard.integer(forKey: "IDProfile") 
        self.picture = UserDefaults.standard.string(forKey: "") ?? ""
        self.id_country = UserDefaults.standard.integer(forKey: "") 
        self.nickname = UserDefaults.standard.string(forKey: "nickname") ?? ""
        self.id_language = UserDefaults.standard.integer(forKey: "") 
        
    }

    init(_description: String, _first_name: String, _last_name: String, _picture: String, _nickname: String, _id: Int, _id_country: Int, _id_language: Int) {
        self.description = _description
        self.first_name = _first_name
        self.last_name = _last_name
        self.picture = _picture
        self.nickname = _nickname
        
        self.id = _id
        self.id_country = _id_country
        self.id_language = _id_language
    }
    
    func setIDprofile(_ _id: Int) {
        UserDefaults.standard.set(_id, forKey: "IDProfile")
        self.id = _id
    }
    
    func setNickname(_ _nickname: String) {
        UserDefaults.standard.set(_nickname, forKey: "nickname")
        self.nickname = _nickname
    }
    
    func setFirstName(_ _firstname: String) {
        UserDefaults.standard.set(_firstname, forKey: "firstname")
        self.first_name = _firstname
    }
    
}
