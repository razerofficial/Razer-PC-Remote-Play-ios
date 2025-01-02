/*
 * Copyright (C) 2024 Razer Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import UIKit
import SwiftUI

enum ItemViewTag:Int {
case StatsDes = 10000
}
class DevOptionItemView {
    
    class func itemView(_ title:String) -> UIView {
        let view = UIView.init()
        view.layer.cornerRadius = 10.0
        view.layer.masksToBounds = true
        view.backgroundColor = Color.hex(0x222222).uiColor()
        
        let label = UILabel.init()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textColor = .white
        label.text = title
        label.isUserInteractionEnabled = true
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20))
        }
        
        return view
    }
    
    class func changeableItemView(_ title:String) -> (UIView, UILabel){
        let view = UIView.init()
        view.layer.cornerRadius = 10.0
        view.layer.masksToBounds = true
        view.backgroundColor = Color.hex(0x222222).uiColor()
        
        let label = UILabel.init()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textColor = .white
        label.text = title
        label.isUserInteractionEnabled = true
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20))
        }
        
        return (view, label)
    }
    
    class func titleLab(_ title:String) -> UILabel {
        let label = UILabel.init()
        label.text = title
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .white
        label.numberOfLines = 0
        label.backgroundColor = Color.hex(0x222222).uiColor()
        return label
    }
    
    
    class func desLab(_ title:String ,_ size:CGFloat) -> UILabel {
        let label = UILabel.init()
        label.text = title
        label.font = UIFont.systemFont(ofSize: size)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }
    
}
