//
//  Reachability.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 17/09/16.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
        
    }
}
//    class func isUserConnected() {
//        let user = UserConnect()
//        
//        if (!user.checkUserConnected()) {
//            DispatchQueue.main.async(execute: { () -> Void in
//                print("On ajoute les fichiers qu'il faut")
//                /*let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Authentication", bundle: nil)
//                let vc = eventStoryBoard.instantiateViewControllerWithIdentifier("LoginSignUpViewID") as! LoginSignUpController
//                UIApplication.sharedApplication().windows[0].rootViewController!.presentViewController(vc, animated: true, completion: nil)*/
//            })
//            return
//        }
//        
//        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
//        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
//        zeroAddress.sin_family = sa_family_t(AF_INET)
//        
//        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
//            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
//                SCNetworkReachabilityCreateWithAddress(nil, $0)
//            }
//        }) else {
//            return
//        }
//        
//        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
//        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
//            print("oucocu")
//        }
//        
//        let isReachable = flags == .reachable
//        let needsConnection = flags == .connectionRequired
//        
//        if (!isReachable && needsConnection) {
//            print("On ajoute les fichiers qu'il faut")
//            /*let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
//            let vc = eventStoryBoard.instantiateViewControllerWithIdentifier("HomeViewID") as! HomeController
//            UIApplication.sharedApplication().windows[0].rootViewController!.presentViewController(vc, animated: true, completion: nil)*/
//        }
//    }
//}
