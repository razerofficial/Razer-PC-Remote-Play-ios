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
    // Custom alert view to handle dynamic reposition
    class PairAlertView: UIView {
        private var displayLink: CADisplayLink?
        private weak var parentWindow: UIWindow?
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            parentWindow = window
            if window != nil {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
        
        private func startMonitoring() {
            displayLink = CADisplayLink(target: self, selector: #selector(checkForWindowBoundsChange))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        private func stopMonitoring() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc private func checkForWindowBoundsChange() {
            if let window = parentWindow {
                // window size changed, update frame layout (position)
                if self.frame != window.bounds {
                    self.frame = window.bounds
                    self.setNeedsLayout()
                }
            }
        }
        
        deinit {
            stopMonitoring()
        }
    }
    
    @objc static let shared = SettingsRouter()
    //save root , use for reset of dashboardview
    @objc var rootNavigationController:UINavigationController?
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
    let localNetworkAuthSubject = PassthroughSubject<Bool, Never>()
    var streamConfig: StreamConfiguration = StreamConfiguration()
    var alertView:RZAlertView? = nil
    var alertViewConfirmAction:(()->Void)? = nil
    var alertViewCancelAction:(()->Void)? = nil
    
    var startStreamingLoadingView : UIView? = nil
    @objc var startingStream = false
    
    @objc var shareLogData:Data = ShareDataDB.shared().readData(fromPath: shareLogPath)
    @objc var shareLogEnableSave:Bool = isEnableSaveLogDisplayMode
    @objc var shareLogExcportIng:Bool = false
    
    @objc let wWidth = WindowWidth
    @objc let wHeight = WindowHeight
    @objc let wRatio = WindowRatio
    
//    var portraitBaseScale = 1.0
    var ScaleX = 1.0
    var ScaleY = 1.0
    
    
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
    
    class func subTitleLab(_ title:String ,_ size:CGFloat) -> UILabel {
        let label = UILabel.init()
        label.text = title
        label.font = UIFont.systemFont(ofSize: size)
        label.textColor = Color.white.uiColor()
        label.numberOfLines = 0
        return label
    }
    
    
    //MARK: - show alert for pin
    func showHostPairAlert(pin:String , hostName:String , action: ((UIAlertAction) -> Void)? = nil) {
        
        HostListManger.shared.dismissLoadingViewCallBack?()
        pairAlertView?.removeFromSuperview()
        
        pairAlertView = PairAlertView()
        pairAlertView?.backgroundColor = Color.hex(0x000000, alpha: 0.3).uiColor()
        // set initial frame
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            pairAlertView?.frame = window.bounds
        }
        
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
        titleLab.font = UIFont.dynamic(size: 16, weight: .bold)
        
        let messageLab = UILabel.init()
        messageLab.text = String(format: "Enter the code on \"%@\" to complete pairing with your device.\n\nPin Code".localize(), hostName)
        messageLab.numberOfLines = 0
        messageLab.textColor = .white
        messageLab.textAlignment = .center
        messageLab.font = UIFont.dynamic(size: 15)
        
        let codeLab = UILabel.init()
        codeLab.text = pin
        codeLab.textColor = Color.hex(0x44D62C).uiColor()
        codeLab.textAlignment = .center
        codeLab.font = UIFont.dynamic(size: 40, weight: .bold)
        
        let line = UIView()
        line.backgroundColor = Color.hex(0x999999).uiColor()
        
        let button = UIButton(type: .custom)
        button.setTitle("OK".localize().uppercased(), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.dynamic(size: 16)
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
        
        if #available(iOS 26.0, tvOS 26.0, *) {
            
            let codeHeight = 52.0
            
            let bgView = UIVisualEffectView()
            let glassEffect = UIGlassEffect.init(style: .regular)
            glassEffect.isInteractive = true
            bgView.effect = glassEffect
            //bgView?.backgroundColor = .init(hex: 0x000000, alpha: 0.5)
            bgView.layer.cornerRadius = 34.0
            custonView.insertSubview(bgView, at: 0)
            bgView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            custonView.backgroundColor = .clear
            custonView.layer.cornerRadius = 0.0
            custonView.clipsToBounds = false
            
            titleLab.textAlignment = .left
            titleLab.font = UIFont.systemFont(ofSize: 17)
            
            messageLab.textAlignment = .left
            messageLab.text = String(format: "Enter the code on \"%@\" to complete pairing with your device.".localize(), hostName)
            messageLab.font = UIFont.systemFont(ofSize: 17)
            
            
            let pinTipLab = UILabel.init()
            pinTipLab.text = String(format:"Pin Code".localize(), hostName)
            pinTipLab.numberOfLines = 0
            pinTipLab.textColor = .white
            pinTipLab.textAlignment = .center
            pinTipLab.font = UIFont.systemFont(ofSize: 17)
            custonView.addSubview(pinTipLab)

            
            line.removeFromSuperview()
            //codeLab.backgroundColor = UIColor.init(hex: 0x44D62C)
            //codeLab.textColor = .black
            codeLab.font = .systemFont(ofSize: 24)
            //codeLab.layer.cornerRadius = codeHeight / 2.0
            //codeLab.layer.masksToBounds = true
            
            button.backgroundColor = Color.hex(0x787880 , alpha: 0.32).uiColor()
            button.setTitleColor(Color.hex( 0x44D62C).uiColor(), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17)
            button.layer.cornerRadius = codeHeight / 2.0
            
            custonView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.lessThanOrEqualTo(300.0)
            }
            
            titleLab.snp.remakeConstraints { make in
                make.top.equalTo(20)
                make.left.equalTo(20)
                make.right.equalTo(-20)
            }
            
            messageLab.snp.remakeConstraints { make in
                make.top.equalTo(titleLab.snp_bottomMargin).offset(20)
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.centerX.equalToSuperview()
            }
            
            pinTipLab.snp.remakeConstraints { make in
                make.top.equalTo(messageLab.snp_bottomMargin).offset(20)
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.centerX.equalToSuperview()
            }
            
            codeLab.snp.remakeConstraints { make in
                make.top.equalTo(pinTipLab.snp_bottomMargin).offset(10)
                make.left.equalTo(14)
                make.right.equalTo(-14)
                //make.height.equalTo(codeHeight)
            }
            
            button.snp.remakeConstraints { make in
                make.top.equalTo(codeLab.snp.bottom).offset(16)
                make.left.equalTo(14)
                make.right.equalTo(-14)
                make.height.equalTo(codeHeight)
                make.bottom.equalTo(-14)
            }
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
    
    @objc func isDeviceIpad() -> Bool {
        return IsIpad()
    }
    
    @objc func getWindowRatioWidth(_ size:CGSize) -> CGFloat {
        // get window ratio width
        let height = size.width / (WindowRatio)
        if height > size.height {
            return size.height * WindowRatio
        }else{
            return size.width
        }
    }
    
    func currentAppWindowSize() -> CGSize {
        // Traverse all the connected scenes
        for scene in UIApplication.shared.connectedScenes {
            // Find the UIWindowScene that is currently active at the front desk.
            if scene.activationState == .foregroundActive,
               let windowScene = scene as? UIWindowScene {
                return windowScene.coordinateSpace.bounds.size
            }
        }
        return CGSize.init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
    
    func updateWindowSize() {
        if IsIpad() {
            // 获取当前窗口尺寸
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                DispatchQueue.main.async {
                    let windowSize = windowScene.windows.first?.frame.size ?? .zero
                    let currentWidth = windowSize.width
                    let currentHeight = windowSize.height
                    let screenSize = UIScreen.main.bounds.size

                    // since orientation is not reliable when app first launch, we use window size to determine portrait/landscape
                    let isWindowPortrait = screenSize.height > screenSize.width

                    if isWindowPortrait {
                        // self.scale = currentWidth / max(screenSize.height, screenSize.width) //since we use dynamic layout, so doesn't need to scale anymore
                        let portraitBaseScaleY = currentHeight / max(screenSize.height, screenSize.width)
                        let portraitBaseScaleX = currentWidth / min(screenSize.height, screenSize.width)
                        DashboardViewModel.shared.portraitBaseScale = min(portraitBaseScaleY, portraitBaseScaleX)  // SettingsPage: Scale based on physical portrait screen width and height length and which is minium
                        DashboardViewModel.shared.portraitHeight = max(UIScreen.screenHeight, UIScreen.screenWidth)
//                        self.portraitBaseScale = min(portraitBaseScaleY, portraitBaseScaleX)
                        self.ScaleX = portraitBaseScaleX
                        self.ScaleY = portraitBaseScaleY
                        
                        print("portraitBaseScale set to \(DashboardViewModel.shared.portraitBaseScale)")
                    } else {
                        // self.scale = currentWidth / max(screenSize.height, screenSize.width)//since we use dynamic layout, so doesn't need to scale anymore
                        let portraitBaseScaleY = currentHeight / min(screenSize.height, screenSize.width)
                        let portraitBaseScaleX = currentWidth / max(screenSize.height, screenSize.width)
                        DashboardViewModel.shared.portraitBaseScale = min(portraitBaseScaleY, portraitBaseScaleX)  // SettingsPage: Scale based on physical portrait screen width and height length and which is minium
                        DashboardViewModel.shared.portraitHeight = min(UIScreen.screenHeight, UIScreen.screenWidth)
//                        self.portraitBaseScale = min(portraitBaseScaleY, portraitBaseScaleX)
                        self.ScaleX = portraitBaseScaleX
                        self.ScaleY = portraitBaseScaleY
                        
                        print("portraitBaseScale set to \(DashboardViewModel.shared.portraitBaseScale)")
                    }

                    print("updateWindowSize isWindowPortrait: \(isWindowPortrait ? "Portrait" : "Landscape"), currentWidth: \(currentWidth), screenSize.width: \(screenSize.width), currentHeight: \(currentHeight), screenSize.height: \(screenSize.height)")
                }
            }
        }
    }
}
