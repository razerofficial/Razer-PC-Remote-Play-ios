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

extension DashboardViewModel {
    
    func pairHost(_ host:TemporaryHost) {
        HostListManger.shared.pairNetHost(host)
    }
    
    func unpairHost(_ host:TemporaryHost) {
        HostListManger.shared.unpairNetHost(host)
    }
    
    func startPlayHost(_ host:TemporaryHost) {
        if SettingsRouter.shared.startingStream { return }
        RzApp.shared().launchDesktopStreaming(host)
    }
    
    func retryConnectToHost(_ host:TemporaryHost) {
        var wolMsg = ""
        if host.mac?.count == 0 || host.mac == "00:00:00:00:00:00" {
            wolMsg = "Host MAC unknown, unable to send WOL Packet".localize()
            Logger.error("retry connect to host fail: \(wolMsg)")
        } else {
            self.isShowWakeOnLanLoading = true
            DispatchQueue.global().async {
                WakeOnLanManager.wake(host)
                DispatchQueue.main.async {
                    self.isShowWakeOnLanLoading = false
                }
            }
//            wolMsg = "Successfully sent wake-up request. It may take a few moments for the PC to wake. If it never wakes up, ensure it's properly configured for Wake-on-LAN.".localize()
        }
        
//        let okButton = AlertButton(id: "ok", title: "ok".localize(), type: .confirm)
//        wolAlertView = SwiftAlertView(title: "Wake-On-LAN".localize(),
//                                          message: wolMsg,
//                                   alertButtons:[okButton],
//                                   colorScheme: SwiftUI.ColorScheme.dark)
//        
//        wolAlertView?.onButtonClicked { _, buttonId in
//            if( buttonId == "ok" ){
//                self.wolAlertView?.dismiss()
//            }
//        }
//        wolAlertView?.show()
//        wolAlertView?.setFocusToButton(buttonId: "ok")
    }
    
    func manuallyAddPC() {
        
        let okButton = AlertButton(id: "ok", title: "Add".localize(), type: .confirm)
        let cancelButton = AlertButton(id: "cancel", title: "Cancel".localize(), type: .confirm)
        addressAlertView = SwiftAlertView(title: "Add PC manually".localize(),
                                   message: "Input PC IP address".localize(),
                                   alertButtons:[cancelButton,okButton],
                                   colorScheme: SwiftUI.ColorScheme.dark)
        
        addressAlertView?.addTextField { textField in
            textField.placeholder = "Enter the IP address of your computer.".localize()
        }
        
        addressAlertView?.respondOnOkClickWhenTextFiledIsEmpty = false
        
        addressAlertView?.onButtonClicked { _, buttonId in
            if( buttonId == "ok" ){
                let address = self.addressAlertView?.textField(at: 0)?.text ?? ""
                if address.isEmpty {
                    return
                }
                self.addressAlertView?.dismiss()
                self.onManualIpEnter(address:address)
            }
        }
        addressAlertView?.show()
    }
    
    func onManualIpEnter(address: String) {
        
        
        if isWifiAndSameLocalAddress(address) == false {
            //Forbidden pairing when not the same wifi
            HostListManger.shared.showHostConnetingView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                HostListManger.shared.removeHostConnectingView()
                let alertVC = UIAlertController(title: "Could not connect to host".localize(), message: "", preferredStyle: .alert)
                //alertVC.addAction(UIAlertAction.init(title: "OK".localize(), style: .cancel))
                UIApplication.shared.keyWindow?.rootViewController?.present(alertVC, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    alertVC.dismiss(animated: true)
                }
            }
            return
        }
        
        HostListManger.shared.showHostConnetingView()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) { [self] in
            //let discoveryManager = DiscoveryManager.init()
            HostListManger.shared.discoveryManager.discoverHost(address) { [self] host, message in
                //loadingView.isHidden = true
                HostListManger.shared.removeHostConnectingView()
                //成功
                if host != nil {
                    HostListManger.shared.pairNetHost(host!)
                    //errorTips.isHidden = true
                }else{
                    
                    var found:Bool = false
                    //errorTips.isHidden = false
                    if message == "Host information updated" {
                        for netHost in self.netHosts {
                            if netHost.address == address || netHost.activeAddress == address || netHost.localAddress == address{
                                HostListManger.shared.pairNetHost(netHost)
                                found = true
                                break
                            }
                        }
                    }
                    if found == false {
                        let alertVC = UIAlertController(title: "Could not connect to host".localize(), message: message, preferredStyle: .alert)
                        //alertVC.addAction(UIAlertAction.init(title: "OK".localize(), style: .cancel))
                        UIApplication.shared.keyWindow?.rootViewController?.present(alertVC, animated: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            alertVC.dismiss(animated: true)
                        }
                    }
                }
            }
        }
    }
}
