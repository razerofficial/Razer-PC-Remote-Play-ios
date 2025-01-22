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

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI
import IQKeyboardManager

class SettingsAdddHostVC: RZBaseVC , PairCallback {

    var selectedHost:TemporaryHost?
    let queue = OperationQueue.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //enable keyboard auto change
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
        setupView()
        setupData()
    }
    
    func setupView() {
        view.backgroundColor = .black
        
        let textFieldBg = UIView.init()
        textFieldBg.backgroundColor = .white
        textFieldBg.addSubview(textField)
        
        textField.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.height.equalToSuperview()
        }
        //add views
        view.addSubview(descLab)
        view.addSubview(textFieldBg)
        view.addSubview(errorTips)
        view.addSubview(addButton)
        view.addSubview(loadingView)
        view.addSubview(customNavBar)

        customNavBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
            if IsIpad() {
                make.top.equalTo(20)
            } else {
                make.top.equalToSuperview()
            }
        }
        
        descLab.snp.makeConstraints { make in
            make.left.equalTo(IsIpad() ? 40 : DeviceLeftSpace + 25)
            make.top.equalTo(IsIpad() ? 114 : 66)
        }
        
        textFieldBg.snp.makeConstraints { make in
            make.left.equalTo(descLab)
            make.top.equalTo(descLab.snp.bottom).offset(10)
            make.height.equalTo(44)
            if IsIpad() {
                make.right.equalTo(addButton.snp.left).offset(-30)
            }else{
                make.width.greaterThanOrEqualTo(350)
            }
        }
        
        errorTips.snp.makeConstraints { make in
            make.left.equalTo(descLab)
            make.top.equalTo(textField.snp.bottom).offset(15)
        }
        
        addButton.snp.makeConstraints { make in
            if IsIpad() {
                make.centerY.equalTo(descLab)
                make.right.equalTo(-35)
            } else {
                make.centerY.equalTo(descLab)
                make.right.equalTo(-50)
            }
            make.height.equalTo(44)
        }
        
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
    }
    
    func setupData() {
        
        textField.rx.text.orEmpty
            .subscribe(onNext: { [self] text in
                addButton.isEnabled = !text.isEmpty
                addButton.layer.opacity = text.isEmpty ? 0.5 : 1.0
            })
            .disposed(by: disposed)
        
    }
    
    //MARK: funcs
    func closeVC() {
        if loadingView.isHidden == false {return}
        SettingsRouter.shared.navigationController?.popViewController(animated: true)
    }
    
    @objc func addHost() {
        
        textField.resignFirstResponder()
        
        if isWifiAndSameLocalAddress(textField.text ?? "") == false {
            //Forbidden pairing when not the same wifi
            self.loadingView.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.loadingView.isHidden = true
                self.errorTips.isHidden = false
            }
            return
        }
        
        loadingView.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) { [self] in
            //let discoveryManager = DiscoveryManager.init()
            HostListManger.shared.discoveryManager.discoverHost(textField.text) { [self] host, message in
                
                loadingView.isHidden = true
                //成功
                if host != nil {
                    pairHost(host!)
                    errorTips.isHidden = true
                }else{
                    
                    var found:Bool = false
                    //errorTips.isHidden = false
                    if message == "Host information updated" {
                        
                        for netHost in HostListManger.shared.netHosts {
                            if netHost.address == textField.text || netHost.activeAddress == textField.text || netHost.localAddress == textField.text {
                                pairHost(host!)
                                errorTips.isHidden = true
                                found = true
                                break
                            }
                        }
                    }
                    if found == false {
                        errorTips.isHidden = false
                    }
                    
                }
            }
        }
    }
    
    func pairHost(_ host:TemporaryHost) {
        let httpManger = HttpManager.init(host: host)
//        let uuid:String = UIDevice.current.identifierForVendor?.uuidString ?? ""
//        httpManger?.setuniqueId(uuid)
        selectedHost = host
        let pairManager = PairManager.init(manager: httpManger, clientCert: CryptoManager.readCertFromFile(), callback: self)
        queue.addOperation(pairManager!)
    }
    
    //MARK: - Pair call back
    func startPairing(_ PIN: String!) {
        DispatchQueue.main.async { [self] in
            SettingsRouter.shared.showHostPairAlert(pin: PIN, hostName: selectedHost?.name ?? "")
        }
    }
    
    func pairSuccessful(_ serverCert: Data!) {
        selectedHost?.serverCert = serverCert
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: { [self] in
            if let host = selectedHost {
                SettingsRouter.shared.dataManager.update(host)
                SettingsRouter.shared.hostDevicesPairedHostCallBack?(host)
            }
            
            if handel.shouleTracking() {
                lastHandel?.reloadCallBack?()
            }
            
            SettingsRouter.shared.closePairAlertView()
            SettingsRouter.shared.navigationController?.popViewController(animated: true)
        })
    }
    
    func pairFailed(_ message: String!) {
        DispatchQueue.main.async { [self] in
            SettingsRouter.shared.closePairAlertView()
            let alertVC = UIAlertController(title: "Pairing Failed".localize(), message: message, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "OK".localize(), style: .cancel))
            present(alertVC, animated: true)
        }
    }
    
    func alreadyPaired() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: { [self] in
            if let host = selectedHost {
                SettingsRouter.shared.hostDevicesPairedHostCallBack?(host)
            }
            SettingsRouter.shared.closePairAlertView()
            SettingsRouter.shared.navigationController?.popViewController(animated: true)
        })
    }
    
    //MARK: - Lazy - UI    
    lazy var customNavBar:CustomNavigationBar = {
        let nav = CustomNavigationBar(title: "Add PC manually".localize(), leftButtonTitle: "Settings".localize(), rightButtonTitle: nil, delegate: self)
        return nav
    }()
    
    lazy var addButton : UIButton = {
        
        let button = UIButton.init(type: .custom)
        button.isUserInteractionEnabled = true
        button.layer.cornerRadius = 22.0
        button.backgroundColor = Color.hex(0x44d62c).uiColor()
        button.isEnabled = false
        button.layer.opacity = 0.5
        
        let title = SettingsRouter.titleLab("Add".localize().uppercased())
        title.textColor = .black
        button.addSubview(title)
        title.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
        }
        button.addTarget(self, action: #selector(addHost), for: .touchUpInside)
        return button
    }()
    
    lazy var errorTips : UIView = {
        let view = UIView.init()
        view.isHidden = true
        let label = SettingsRouter.desLab("Could not connect to host".localize(), 14)
        label.textColor = Color.hex(0xff0000).uiColor()
        let imageView = UIImageView(image: UIImage(named: "settings_devices_warning"))
        
        view.addSubview(label)
        view.addSubview(imageView)
        
        label.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right).offset(10)
            make.centerY.equalToSuperview()
        }
        
        return view
    }()
    
    lazy var descLab : UILabel = {
        let label = SettingsRouter.desLab("Input PC IP address".localize(), 15.0)
        return label
    }()
    
    lazy var textField : UITextField = {
        let field = UITextField.init()
        field.font = UIFont.italicSystemFont(ofSize: 14)
        field.placeholder = "Enter the IP address of your computer.".localize()
        field.placeholderColor = Color.hex(0x999999).uiColor()
        field.backgroundColor = .white
        field.textColor = .black
        return field
    }()
    
    lazy var loadingView : UIView = {
        let view = UIView.init()
        view.isHidden = true
        view.backgroundColor = Color.hex(0x000000, alpha: 0.5).uiColor()
        let title = SettingsRouter.titleLab("Connecting…".localize())
        title.font = UIFont.systemFont(ofSize: 18)
        
        let des = SettingsRouter.desLab("Please ensure Razer Cortex is running on the same network.".localize(), 14)
        
        let indicator = UIActivityIndicatorView.init(style: .large)
        indicator.color = .gray
        indicator.startAnimating()
        
        view.addSubview(title)
        view.addSubview(des)
        view.addSubview(indicator)
        
        title.snp.makeConstraints { make in
            make.bottom.equalTo(des.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
        
        des.snp.makeConstraints { make in
            make.width.equalTo(400.0)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
        
        indicator.snp.makeConstraints { make in
            make.top.equalTo(des.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.width.equalTo(60.0)
        }
        return view
    }()
    
}


//MARK: - RZHandleResponderDelegate
extension SettingsAdddHostVC : RZHandleResponderDelegate {
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .B :
            closeVC()
        case .A:
            
            if SettingsRouter.shared.pairAlertView != nil {
                SettingsRouter.shared.closePairAlertView()
                return
            }
            
            if addButton.isEnabled {
                addHost()
            }
            
        default:
            break
        }
    }
}

//MARK: - RZHandleResponderDelegate - handels actions
extension SettingsAdddHostVC {
        
}

extension SettingsAdddHostVC: CustomNavigationBarDelegate {
    func backButtonTapped() {
        self.closeVC()
    }
    
    func rightButtonTapped() {
        //do nothing
    }
}
