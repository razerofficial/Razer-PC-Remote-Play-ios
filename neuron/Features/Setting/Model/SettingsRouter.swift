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
import Combine

class SettingsRouter: NSObject {
    
    @objc static let shared = SettingsRouter()
    //传送navigationController给Setting子页面
    @objc var navigationController:UINavigationController?
    //用于其他页面同时SettingsHostDevicesVC刷新页面
    @objc var hostDevicesRemoveHostCallBack : ((TemporaryHost)->Void)?
    //用于其他页面同时SettingsHostDevicesVC刷新页面
    @objc var hostDevicesPairedHostCallBack : ((TemporaryHost)->Void)?
    //用于页面刷新读取共享数据后刷新
    @objc var hostDevicesReadShareDataCallBack : (()->Void)?
    
    //用于页面网络授权完成之后开始mdns服务，搜索hosts
    @objc var grantedLocalNetworkPermissionCallBack : (()->Void)? = nil
    
    //次级页面使用同一个dataManager
    @objc let dataManager = DataManager()
    //使用同一个discoveryManager
    @objc let discoveryManager = DiscoveryManager()
    
    //Pair alert View
    @objc var pairAlertView:UIView?
    
    let disposeBag = DisposeBag()
    let navigateToStreamVCSubject = BehaviorSubject<(TemporaryApp?,Bool?)>(value: (nil,nil))
    
    
    //streaming
    var localNetworkAuthorization: LocalNetworkAuthorization = LocalNetworkAuthorization()
    var isShowDownloadOverlay: Bool = false
    var streamConfig: StreamConfiguration = StreamConfiguration()
    var alertView:RZAlertView? = nil
    var alertViewConfirmAction:(()->Void)? = nil
    var alertViewCancelAction:(()->Void)? = nil
    
    var startStreamingLoadingView : UIView? = nil
    @objc var startingStream = false
    
    override init() {
        super.init()
        // // 这里调用容易写进错误的数据，先关闭掉
//        //调试过程如果直接断开调试，是不会保存到共享数据库
//        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
//            .sink { [weak self] _ in
//                //同步Hostlist数据到共享数据库
//                ShareDataDB.shared().wirteHostListDataToShare()
//                print("wirteHostListDataToShare : neuro - 1")
//            }
//            .store(in: &bag)
//        
//        //调试过程如果直接断开调试，是不会保存到共享数据库
//        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
//            .sink { [weak self] _ in
//                //同步Hostlist数据到共享数据库
//                ShareDataDB.shared().wirteHostListDataToShare()
//                print("wirteHostListDataToShare : neuro - 2")
//            }
//            .store(in: &bag)
        navigateToStreamVCSubject
            .filter { $0.0 != nil }
            .throttle(.seconds(2), latest: true, scheduler: MainScheduler.instance)
            .subscribe { [weak self](temporaryApp, shouldReturnToNexus) in
                guard let self = self, let app = temporaryApp else { return }
                self.navigateToStreamViewController(app, shouldReturnToNexus: shouldReturnToNexus ?? false)
            }.disposed(by: disposeBag)
    }

    
    //MARK: - class functions
    class func titleLab(_ title:String) -> UILabel {
        let label = UILabel.init()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }
    
    class func desLab(_ title:String ,_ size:CGFloat) -> UILabel {
        let label = UILabel.init()
        label.text = title
        label.font = UIFont.systemFont(ofSize: size)
        label.textColor = Color.hex(0x999999).uiColor()
        label.numberOfLines = 0
        return label
    }
    
    
    //MARK: - show alert for pin
    func showHostPairAlert(pin:String , hostName:String , action: ((UIAlertAction) -> Void)? = nil) {
        
        HostListManger.shared.dismissLoadingViewCallBack?()
        pairAlertView?.removeFromSuperview()
        
        pairAlertView = UIView.init()
        pairAlertView?.backgroundColor = Color.hex(0x000000, alpha: 0.3).uiColor()
        pairAlertView?.frame = CGRectMake(0, 0, UIScreen.screenWidth, UIScreen.screenHeight)
        
        let custonView = UIView()
        pairAlertView?.addSubview(custonView)
        custonView.isUserInteractionEnabled = true
        custonView.backgroundColor = Color.hex(0x222222).uiColor()
        custonView.layer.cornerRadius = 10.0
        custonView.layer.masksToBounds = true
        
        let titleLab = UILabel.init()
        titleLab.text = "Pairing Request".localize()
        titleLab.textColor = .white
        titleLab.textAlignment = .center
        titleLab.font = UIFont.boldSystemFont(ofSize: 16)
        
        let messageLab = UILabel.init()
        messageLab.text = String(format: "Enter the code on \"%@\" to complete pairing with your device.\n\nPin Code".localize(), hostName)
        messageLab.numberOfLines = 0
        messageLab.textColor = .white
        messageLab.textAlignment = .center
        messageLab.font = UIFont.systemFont(ofSize: 15)
        
        let codeLab = UILabel.init()
        codeLab.text = pin
        codeLab.textColor = Color.hex(0x44D62C).uiColor()
        codeLab.textAlignment = .center
        codeLab.font = UIFont.boldSystemFont(ofSize: 40)
        
        let line = UIView()
        line.backgroundColor = Color.hex(0x999999).uiColor()
        
        let button = UIButton(type: .custom)
        button.setTitle("OK".localize().uppercased(), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(Color.hex(0x007AFF).uiColor(), for: .normal)
        button.addTarget(self, action: #selector(closePairAlertView), for: .touchUpInside)
        let color = ControllerInputTracker.shared.isConnected ? Color.hex(0xffffff, alpha: 0.3).uiColor() : UIColor.clear
        button.backgroundColor = color
 
        custonView.addSubview(titleLab)
        custonView.addSubview(messageLab)
        custonView.addSubview(codeLab)
        custonView.addSubview(line)
        custonView.addSubview(button)
        
        custonView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualTo(250)
        }
        
        titleLab.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.left.right.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        messageLab.snp.makeConstraints { make in
            make.top.equalTo(titleLab.snp_bottomMargin).offset(10)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.centerX.equalToSuperview()
        }
        
        codeLab.snp.makeConstraints { make in
            make.top.equalTo(messageLab.snp_bottomMargin).offset(10)
            make.left.right.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        line.snp.makeConstraints { make in
            make.top.equalTo(codeLab.snp_bottomMargin).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.6)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        button.snp.makeConstraints { make in
            //make.top.equalTo(line.snp_bottomMargin)
            make.left.right.equalToSuperview()
            make.height.equalTo(40.0)
            make.bottom.equalToSuperview()
        }
                
        DispatchQueue.main.async {
            if let alert = self.pairAlertView {
                UIApplication.shared.keyWindow?.addSubview(alert)
            }
        }
        
    }

    @objc func closePairAlertView(){
        DispatchQueue.main.async {
            self.pairAlertView?.removeFromSuperview()
            self.pairAlertView = nil
        }
    }
    
}
