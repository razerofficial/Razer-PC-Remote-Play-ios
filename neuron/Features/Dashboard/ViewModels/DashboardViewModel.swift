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
import Combine
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI
import SwiftBridging


//每行显示的个数
let HostRowLimit : Int = IsIpad() ? 6 : 4
//宽高乘以缩放系数，否则小屏幕会显示不全
let HostCellWidth:CGFloat = 155//CGFloat(155 * HScale)
let HostCellHeight:CGFloat = 165//CGFloat(165 * HScale)
let HHostCellSpace:CGFloat = 20
let VHostCellSpace:CGFloat = 10//CGFloat(14 * HScale)
let HostCellMoveStep = HostCellHeight + VHostCellSpace

class DashboardViewModel: RZHandleResponder {
    
    fileprivate var bag = Set<AnyCancellable>()
    //scroll 
    weak var scroll:UIScrollView?
    //host list
    @Published var pairedHosts:[TemporaryHost] = [TemporaryHost]()
    @Published var netHosts:[TemporaryHost] = [TemporaryHost]()
    //height light
    @Published var deviceSection:HostDevicesSection = .Unknow
    @Published var selectedIndex:Int = 0
    //bottom overlay button view model
    @Published var bottomMenuViewModel = BottomMenuViewModel()
    
    let localNetworkAuthorization = LocalNetworkAuthorization()
    
    var isDashboardAppear: Bool = false
    
    var addressAlertView:SwiftAlertView?
    var wolAlertView:SwiftAlertView?
    
    @Published var noLocalNetworkPermissionAlert: SwiftAlertView? = nil
    @Published var isNeedShowNoNetworkPermissonAlert: Bool = false
    @Published var isShowWakeOnLanLoading: Bool = false
    
    @Published var isShowAddManualHostView:Bool = false
    
    //MARK: - init
    override init() {
        super.init()
        delegate = self
        registerObservers()
    }
    
    func goToSettingVC() {
        let vc = SettingsMenuVC()
        vc.title = "Settings".localize()
        SettingsRouter.shared.navigationController?.pushViewController(vc, animated: true)
    }
    
    func updateBottoMenu(){
        DispatchQueue.main.async { [self] in
            if deviceSection == .PairedSection {
                if selectedIndex < pairedHosts.count {
                    if let host = pairedHosts[safe: selectedIndex], host.state == .online {
                        bottomMenuViewModel.updateItems([BottomMenuItem.init(type: .unpair),BottomMenuItem.init(type: .start_play)])
                    } else {
                        bottomMenuViewModel.updateItems([BottomMenuItem.init(type: .unpair),BottomMenuItem.init(type: .retry)])
                    }
                }else {
                    deviceSection = .NetSection
                }
            }
            
            if deviceSection == .NetSection {
                if selectedIndex < netHosts.count {
                    bottomMenuViewModel.updateItems([BottomMenuItem.init(type: .pair)])
                }else{
                    deviceSection = .AddSection
                }
            }
            
            if deviceSection == .AddSection {
                bottomMenuViewModel.updateItems([])
            }
        }
    }
    
    private func registerObservers() {
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            if RzUtils.isRequestedLocalNetworkPermission() {
                self?.requestLocalNetworkPermission()
            }
        }
        
        HostListManger
            .shared
            .pairHostListSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { hostList in
                self.pairedHosts = hostList
                self.updateBottoMenu()
            }
            .store(in: &bag)
        
        HostListManger
            .shared
            .netHostListSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { hostList in
                self.netHosts = hostList
                self.updateBottoMenu()
            }
            .store(in: &bag)
                
    }

    
    func requestLocalNetworkPermission() {
        
        localNetworkAuthorization.requestAuthorization(isNeedToResetCompletionBlock: false) { [weak self] result in
            
            if UIApplication.shared.applicationState != .active {
                return
            }
            
            RzUtils.setGrantedLocalNetworkPermission(result)
            SettingsRouter.shared.localNetworkAuthSubject.send(result)
            
            if let callback = SettingsRouter.shared.grantedLocalNetworkPermissionCallBack {
                callback()
            }
            
            if result == false {
                self?.showNoLocalNetworkPermissionAlert()
            }
            
            Logger.debug("requestAuthorization result: \(result)")
        }
    }
    
    func showNoLocalNetworkPermissionAlert() {
        isNeedShowNoNetworkPermissonAlert = true
    }
    
    //MARK: - No Local Network Permission Alert
    func initAndShowNoLocalNetworkPermissionAlert(colorScheme: SwiftUI.ColorScheme) {
        
        // do nothing if already showing
        if( noLocalNetworkPermissionAlert != nil && noLocalNetworkPermissionAlert!.isShowing ){
            return
        }
        
        // init buttons
        let continueButtonText = "OK".localize()
        let continueButton = AlertButton(id: "ok", title: continueButtonText, type: .confirm)
        
        // init alert
        let title = "Enable Local Network Access".localize()
        
        let message = "To enable seamless streaming between your PC and Remote Play, please allow Local Network access. Go to Settings > Privacy & Security > Local Network and enable access for Remote Play.".localize()
        
        noLocalNetworkPermissionAlert = SwiftAlertView(title: title,
                                      message: message,
                                      alertButtons:[continueButton],
                                      colorScheme: colorScheme)
        noLocalNetworkPermissionAlert?.onButtonClicked { _, buttonId in
            //self.printLog("Button Clicked: \(buttonId)")
            self.dismissNoLocalNetworkPermissionAlert()
        }
        // show
        noLocalNetworkPermissionAlert?.show()
        noLocalNetworkPermissionAlert?.setFocusToButton(buttonId: "ok")
    }
    
    func dismissNoLocalNetworkPermissionAlert() {
        noLocalNetworkPermissionAlert?.dismiss()
        self.isNeedShowNoNetworkPermissonAlert = false
    }
    
    func executeConfirmActionForNoLocalNetworkPermissionAlert() {
        dismissNoLocalNetworkPermissionAlert()
    }
}
