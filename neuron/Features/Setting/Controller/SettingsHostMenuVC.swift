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
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI

class SettingsHostMenuVC: RZBaseVC {
    

    var host:TemporaryHost?
    fileprivate var selectedButton: UIButton?
    var isExecutingRemoveDevice = false
    
    convenience init(host: TemporaryHost? = nil) {
        self.init()
        self.host = host
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
    }
    
    func setupView() {
        view.backgroundColor = .black
        
        //add views
        view.addSubview(customNavBar)

        customNavBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44.0)
            if IsIpad() {
                make.top.equalTo(20)
            } else {
                make.top.equalToSuperview()
            }
            
        }
        
        let buttonStackView = UIStackView(arrangedSubviews: [startPlayButton,buttonDivider,removeButton])
        buttonStackView.axis = .vertical
        buttonStackView.layer.cornerRadius = 10.0
        buttonStackView.clipsToBounds = true
        view.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { make in
            make.left.equalTo(IsIpad() ? 25 : DeviceLeftSpace + 50)
            make.right.equalTo( IsIpad() ? -25 : -(DeviceLeftSpace + 50))
            make.top.equalTo(customNavBar.snp.bottom).offset(44)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectedButton = startPlayButton
        updateSelectedButtonStatus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissLoadingView()
    }
    
    //MARK: funcs
    func closeVC() {
        SettingsRouter.shared.navigationController?.popViewController(animated: true)
    }
    
    @objc func removeDecice() {
        if self.isExecutingRemoveDevice == true {
            return
        }
        
        guard let host = self.host else { return }
        showLoadingView()
        ShareDataDB.shared().writeManuallyUnpairedHostDataToshareDB(host.uuid)
        self.isExecutingRemoveDevice = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [weak self] in
            if let self = self {
                SettingsRouter.shared.hostDevicesRemoveHostCallBack?(host)
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
                self.isExecutingRemoveDevice = false
                dismissLoadingView()
            }
        }
    }
    
    @objc func startPlay() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if self.host?.state != .online {
                return
            }
            if self.host != nil {
                SettingsRouter.shared.navigationController?.popToRootViewController(animated: false)
                RzApp.shared().launchDesktopStreaming(self.host!)
            }
        }
    }
    
    func updateSelectedButtonStatus() {
        let heighted = handel.shouleTracking()
        guard heighted else {
            removeButton.backgroundColor = Color.hex(0x222222).uiColor()
            startPlayButton.backgroundColor = Color.hex(0x222222).uiColor()
            return
        }
        
        if selectedButton == removeButton {
            removeButton.backgroundColor = Color.hex(0xffffff, alpha: 0.3).uiColor()
            startPlayButton.backgroundColor = Color.hex(0x222222).uiColor()
        } else {
            removeButton.backgroundColor = Color.hex(0x222222).uiColor()
            startPlayButton.backgroundColor = Color.hex(0xffffff, alpha: 0.3).uiColor()
        }
    }
    
    func showLoadingView() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func dismissLoadingView() {
        loadingView.removeFromSuperview()
    }
    
    //MARK: - Lazy - UI
    lazy var customNavBar:CustomNavigationBar = {
        let nav = CustomNavigationBar(title: host?.name ?? "", leftButtonTitle: "Settings".localize(), rightButtonTitle: nil, delegate: self)
        return nav
    }()
    
    lazy var loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = Color.hex(0x000000, alpha: 0.5).uiColor()
        let activity = UIActivityIndicatorView(style: .large)
        activity.color = .white
        view.addSubview(activity)
        activity.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(50)
            make.height.equalTo(50)
        }
        activity.startAnimating()
        return view
    }()
    
    lazy var removeButton : UIButton = {
        
        let button = UIButton.init(type: .custom)
        button.isUserInteractionEnabled = true
        button.backgroundColor = Color.hex(0x222222).uiColor()
        
        let title = SettingsRouter.titleLab("Unpair".localize().uppercased())
        title.textColor = Color.hex(0x007aff).uiColor()
        button.addSubview(title)
        title.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(10)
        }
        button.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        button.addTarget(self, action: #selector(removeDecice), for: .touchUpInside)
        return button
    }()
    
    lazy var startPlayButton : UIButton = {
        
        let button = UIButton.init(type: .custom)
        button.isUserInteractionEnabled = true
        button.backgroundColor = Color.hex(0x222222).uiColor()
        
        let title = SettingsRouter.titleLab("Remote Play".localize().uppercased())
        title.textColor = Color.hex(0x007aff).uiColor()
        button.addSubview(title)
        title.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(10)
        }
        
        button.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        button.addTarget(self, action: #selector(startPlay), for: .touchUpInside)
        return button
    }()
    
    lazy var buttonDivider: UIView  = {
        let view = UIView()
        view.backgroundColor = Color.hex(0x999999).uiColor()
        view.snp.makeConstraints { make in
            make.height.equalTo(0.5)
        }
        return view
    }()
    
}


//MARK: - RZHandleResponderDelegate
extension SettingsHostMenuVC : RZHandleResponderDelegate {
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .B :
            closeVC()
        case .A:
            if selectedButton == removeButton {
                removeDecice()
            } else {
                startPlay()
            }
            
            lastHandel?.startTracking()
            lastHandel?.reloadCallBack?()
        case .up:
            if selectedButton == removeButton {
                selectedButton = startPlayButton
            }
            updateSelectedButtonStatus()
        case .down:
            if selectedButton == startPlayButton {
                selectedButton = removeButton
            }
            updateSelectedButtonStatus()
        default:
            break
        }
    }
}

//MARK: - RZHandleResponderDelegate - handels actions
extension SettingsHostMenuVC {
        
}

extension SettingsHostMenuVC: CustomNavigationBarDelegate {
    func backButtonTapped() {
        self.closeVC()
    }
    
    func rightButtonTapped() {
        //do nothing
    }
}
