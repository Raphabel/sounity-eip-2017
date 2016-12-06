//
//  EmptyResearchView.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 19/11/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class EmptyResearchView: TemplateView {
    var title: UILabel = UILabel()
    var subtitle: UILabel = UILabel()
    
    init(_view: UIView, _message: String, _subtitle: String) {
        super.init(_frame: _view.frame)
        self.addCustomView(_view, _message: _message, _subtitle: _subtitle)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addCustomView(_ _view: UIView, _message: String, _subtitle: String) {
        title.text = _message
        title.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 16)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .center
        centerView.addSubview(title)
        
        subtitle.text = _subtitle
        subtitle.font = UIFont(name: "TimesNewRomanPS-ItalicMT", size: 14)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.textAlignment = .center
        centerView.addSubview(subtitle)

        centerView.autoCenterInSuperview()
        
        title.autoAlignAxis(toSuperviewAxis: .horizontal)
        title.autoAlignAxis(toSuperviewAxis: .vertical)

        subtitle.autoAlignAxis(toSuperviewAxis: .vertical)
        subtitle.autoPinEdge(.top, to: .bottom, of: title, withOffset: 20)
    }
}

