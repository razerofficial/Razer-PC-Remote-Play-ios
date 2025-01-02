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
import SwiftUI


class RZAlertView: UIView {

    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.RazerGreen.uiColor()
        return view
    }()
    
    let alertView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
          label.font = UIFont.boldSystemFont(ofSize: 16)
          label.textColor = .white
          label.textAlignment = .center
          label.numberOfLines = 0
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.systemBlue, for: .normal)
        button.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        return button
    }()

    let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        return button
    }()
    
    var separator: UIView {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.snp.makeConstraints { make in
            make.height.equalTo(0.5)
        }
        return view
    }

    var isConfirmSelected : Bool {
        selectedButton == confirmButton
    }
    
    var selectedButton: UIButton? = nil
    var confirmAction: (()->Void)? = nil
    var cancelAction: (()->Void)? = nil
    
    func set(title: String, message:String, confirmButtonText: String, cancelButtonText: String, confirmAction: @escaping ()->Void, cancelAction:@escaping ()->Void) {
        titleLabel.text = title
        messageLabel.text = message
        confirmButton.setTitle(confirmButtonText, for: .normal)
        cancelButton.setTitle(cancelButtonText, for: .normal)
        
        self.switchSelectedButton()
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
        
        self.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(alertView)
        alertView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
        }
        
        alertView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(alertView.snp.top).offset(20)
            make.left.equalTo(alertView.snp.left).offset(20)
            make.right.equalTo(alertView.snp.right).offset(-20)
        }
        
        alertView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalTo(alertView.snp.left).offset(20)
            make.right.equalTo(alertView.snp.right).offset(-20)
        }
        
        let buttonStackView = UIStackView(arrangedSubviews: [separator,confirmButton,separator,cancelButton])
        buttonStackView.axis = .vertical
        alertView.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { make in
            make.bottom.equalTo(alertView.snp.bottom).offset(0)
            make.left.equalTo(alertView.snp.left).offset(0)
            make.right.equalTo(alertView.snp.right).offset(0)
            make.top.equalTo(messageLabel.snp.bottom).offset(20)
        }

        cancelButton.addTarget(self, action: #selector(onAlertViewCancelButtonClicked), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(onAlertViewConfirmButtonClicked), for: .touchUpInside)
    }
    
    func switchSelectedButton() {
        if selectedButton == nil {
            selectedButton = confirmButton
        } else {
            if selectedButton == confirmButton {
                selectedButton = cancelButton
            } else {
                selectedButton = confirmButton
            }
        }

        confirmButton.backgroundColor = selectedButton == confirmButton ? UIColor.white.withAlphaComponent(0.3) : UIColor.clear
        cancelButton.backgroundColor = selectedButton == cancelButton ? UIColor.white.withAlphaComponent(0.3) : UIColor.clear
    }
    
    @objc func onAlertViewCancelButtonClicked() {
        cancelAction?()
    }
    
    @objc func onAlertViewConfirmButtonClicked() {
        confirmAction?()
    }
}
