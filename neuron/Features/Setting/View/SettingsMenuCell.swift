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

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import CocoaLumberjack
import SwiftUI

enum SettingsMenuCellStyle {
    case rectangle
    case roundedRectangle
    case topHalfRoundedRectangle
    case bottomHalfRoundedRectangle
    case none
}

class SettingsMenuCell: UITableViewCell {
    
    var cellStyle: SettingsMenuCellStyle = .roundedRectangle
    
    var isNeedSeparator: Bool = false

    class func cell(style: SettingsMenuCellStyle, isNeedSeparator: Bool) -> SettingsMenuCell {
        
        let cell = SettingsMenuCell()
        cell.cellStyle = style
        cell.isNeedSeparator = isNeedSeparator
        cell.setupView()
        return cell
    }
    // 初始化方法
    private override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 配置UI元素
    private func setupView() {
        
        contentView.backgroundColor = .black
        
        let view = UIView.init()
        
        switch cellStyle {
        case .rectangle:
            view.layer.cornerRadius = 0
        case .roundedRectangle:
            view.layer.cornerRadius = 10.0
        case .topHalfRoundedRectangle:
            view.layer.cornerRadius = 10.0
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .bottomHalfRoundedRectangle:
            view.layer.cornerRadius = 10.0
            view.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        case .none:
            view.layer.cornerRadius = 0
        }
        heightLightBg = view
        contentView.addSubview(heightLightBg)
        contentView.addSubview(titleLabel)
        
        heightLightBg.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.init(top: 0, left: 20, bottom: 0, right: 20))
        }
        
        if isNeedSeparator {
            let separator = UIView()
            separator.backgroundColor = Color.SettingsLine.uiColor()
            contentView.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.bottom.right.equalTo(contentView)
                make.left.equalTo(20)
                make.height.equalTo(0.5)
            }
        }
    }
    
    //MARK: - 设置内容
    func configure(with title: String) {
        titleLabel.text = title
    }
    
    func isHeightLight(_ heightLight:Bool) {
        let color = heightLight ? Color.hex(0xffffff, alpha: 0.3).uiColor() : Color.hex(0x222222).uiColor()
        heightLightBg.backgroundColor = color
    }
    
    //MARK: - 添加UI元素属性
    lazy var titleLabel : UILabel = {
        let label = UILabel.init()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .white
        return label
    }()
    
    lazy var heightLightBg : UIView = UIView()
    
    
}
