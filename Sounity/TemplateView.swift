//
//  TemplateView.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 19/11/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

import Foundation
import UIKit

class TemplateView: UIView {
    let centerView: UIView = UIView()
    
    init (_frame: CGRect) {
        super.init(frame: _frame)
        customView(_frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func customView(_ _frame: CGRect) {
        centerView.backgroundColor = UIColor.white
        centerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(centerView)
        centerView.autoSetDimension(.height, toSize: _frame.height)
        centerView.autoSetDimension(.width, toSize: _frame.width)
        centerView.autoPinEdge(.bottom, to: .bottom, of: self)
    }
}
