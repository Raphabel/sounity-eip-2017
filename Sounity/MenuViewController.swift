//
//  MenuViewController.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 07/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit
import GuillotineMenu

class MenuViewController: UIViewController {
    // MARK: UIELements variables
    var dismissButton: UIButton!
    var titleLabel: UILabel!
    
    // MARK: Override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dismissButton = UIButton(frame: CGRect.zero)
        dismissButton.setImage(UIImage(named: "ic_menu"), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped(_:)), for: .touchUpInside)
        
        titleLabel = UILabel()
        titleLabel.numberOfLines = 1;
        titleLabel.text = "Event"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.white
        titleLabel.sizeToFit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}

// MARK: Go to Home Button
extension MenuViewController {
    @IBAction func homeButtonTapped(_ sender: UIButton) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Search", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "HomeViewID") as! HomeController
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: Go to Timeline Button
extension MenuViewController {
    @IBAction func timelineButtonTapped(sender: UIButton) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Timeline", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "TimelineViewID") as! TimelineController
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: Go to My Profile Button
extension MenuViewController {
    @IBAction func profileButtonTapped(sender: UIButton) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "ProfileViewID") as! UserHomeViewController
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: Go to Around Me Button
extension MenuViewController {
    @IBAction func aroundMeButtonTapped(sender: AnyObject) {
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "AroundMe", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "AroundMeViewID") as! AroundMeViewController
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: Logout Button
extension MenuViewController {
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        let user = UserConnect();
        user.logout();
        
        let eventStoryBoard: UIStoryboard = UIStoryboard(name: "Authentication", bundle: nil)
        let vc = eventStoryBoard.instantiateViewController(withIdentifier: "LoginSignUpViewID") as! LoginSignUpController
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: Close menu
extension MenuViewController {
    func dismissButtonTapped(_ sende: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeMenu(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: Hide Top Bar
extension MenuViewController {
    override var prefersStatusBarHidden: Bool {
        return false
    }
}
