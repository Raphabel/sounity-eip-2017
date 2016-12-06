//
//  LoadingView.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 19/11/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class LoadingView: TemplateView {
    var label: UILabel = UILabel()
    
    init(_view: UIView) {
        super.init(_frame: _view.frame)
        self.addCustomView(_view)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addCustomView(_ _view: UIView) {
        label.text = "Loading..."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        centerView.addSubview(label)
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        centerView.addSubview(activityIndicator)
        
        centerView.autoCenterInSuperview()
        
        label.autoAlignAxis(toSuperviewAxis: .horizontal)
        label.autoAlignAxis(toSuperviewAxis: .vertical)
        activityIndicator.autoAlignAxis(toSuperviewAxis: .horizontal)
        activityIndicator.autoPinEdge(.left, to: .left, of: label, withOffset: -30)
    }
}
