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
//import SwiftUICore

protocol CustomNavigationBarDelegate:AnyObject {
    func backButtonTapped()
    func rightButtonTapped()
}

class CustomNavigationBar: UIView {
    private var titleLabel: UILabel!
    private var rightButton: UIButton?
    private var backButton: UIButton!
    weak var delegate: CustomNavigationBarDelegate?

    // Initialization method
    init(title: String, leftButtonTitle: String? = nil, rightButtonTitle: String? = nil, delegate: CustomNavigationBarDelegate? = nil) {
        super.init(frame: .zero)
        self.backgroundColor = .black // Set background color to black
        self.setupViews(title: title, leftButtonTitle: leftButtonTitle, rightButtonTitle: rightButtonTitle, delegate: delegate)
        self.setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Setup views
    private func setupViews(title: String, leftButtonTitle: String?, rightButtonTitle: String?, delegate: CustomNavigationBarDelegate?) {
        // Back button
        backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal) // Use system icon
        backButton.tintColor = .white // Set icon color to white
        backButton.imageView?.contentMode = .center // Keep icon aspect ratio
//        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        backButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
        backButton.setTitle(leftButtonTitle, for: .normal)
        backButton.titleLabel?.font = UILabel().font
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        self.addSubview(backButton)

        // Title
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white // Set text color to white
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)

        // Right button
        if let rightTitle = rightButtonTitle {
            rightButton = UIButton(type: .system)
            rightButton?.setTitle(rightTitle, for: .normal)
            rightButton?.setTitleColor(.white, for: .normal) // Set text color to white
            rightButton?.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
            self.addSubview(rightButton!)
        }
        
        self.delegate = delegate
    }

    // Setup constraints
    private func setupConstraints() {
        // Back button constraints
        backButton.snp.makeConstraints { make in
            make.left.equalTo(DeviceLeftSpace)
            make.centerY.equalToSuperview()
        }

        // Title label constraints
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        // Right button constraints
        rightButton?.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    // Back button tap event handler
    @objc private func backButtonTapped() {
        print("Back button tapped")
        // Use Delegate pattern to notify the parent view controller
        self.delegate?.backButtonTapped()
    }

    // Right button tap event handler
    @objc private func rightButtonTapped() {
        print("Right button tapped")
        // You can add specific logic for the right button here
        self.delegate?.rightButtonTapped()
    }
}
