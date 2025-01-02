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
import SwiftUI

extension DashboardViewModel: RZHandleResponderDelegate {
    
    func handleClickButton(_ action: GamePadButton) {
        
        print("action:\(action.description)")
        
        if noLocalNetworkPermissionAlert?.isShowing == true {
            switch action {
            case .A:
                executeConfirmActionForNoLocalNetworkPermissionAlert()
            default:
                break
            }
            return
        }
        
        if wolAlertView?.isShowing == true {
            switch action {
            case .A:
                wolAlertView?.dismiss()
            default:
                break
            }
            return
        }
        
        //pin code alertview showing
        if SettingsRouter.shared.pairAlertView != nil {
            switch action {
            case.A :
                SettingsRouter.shared.closePairAlertView()
            default:
                break
            }
            return
        }
        
        if self.addressAlertView?.isShowing == true {
            switch action {
            case .A , .Y :
                let address = self.addressAlertView?.textField(at: 0)?.text ?? ""
                if address.isEmpty {
                    return
                }
                self.addressAlertView?.dismiss()
                self.onManualIpEnter(address: address)
            case .B:
                self.addressAlertView?.dismiss()
            default:
                break
            }
            return
        }
        
        if SettingsRouter.shared.alertView != nil {
            switch action {
            case .A:
                if SettingsRouter.shared.alertView?.isConfirmSelected ?? false{
                    SettingsRouter.shared.alertViewConfirmAction?()
                } else {
                    SettingsRouter.shared.alertViewCancelAction?()
                }
            case .up , .down:
                SettingsRouter.shared.alertView?.switchSelectedButton()
            default:
                break
            }
            return
        }
        
        switch action {
        case .left:
            lastMenu()
        case .right:
            nextMenu()
        case .A:
            clickA()
        case .B:
            break
        case .Y:
            clickY()
        case .up:
            lastRowMenu()
        case .down:
            nextRowMenu()
        case .menu:
            goToSettingVC()
        default:
            break
        }
        //update bottom menu view
        updateBottoMenu()
    }
    
}

//MARK: - RZHandleResponderDelegate - handels actions
extension DashboardViewModel {
    
    func nextMenu() {
        DispatchQueue.main.async { [self] in
            if deviceSection == .Unknow {
                deviceSection = .PairedSection
            }
            
            if deviceSection == .PairedSection {
                if selectedIndex + 1 < pairedHosts.count {
                    selectedIndex = selectedIndex + 1
                }else if netHosts.count > 0 {
                    deviceSection = .NetSection
                    selectedIndex = 0
                }else{
                    deviceSection = .AddSection
                    selectedIndex = 0
                }
            }else if deviceSection == .NetSection {
                
                if selectedIndex + 1 < netHosts.count {
                    selectedIndex = selectedIndex + 1
                }else{
                    deviceSection = .AddSection
                    selectedIndex = 0
                }
            }
            
            scrollToSelectedMenu()
        }
    }
    
    func lastMenu() {
        DispatchQueue.main.async { [self] in
            if deviceSection == .Unknow {
                deviceSection = .PairedSection
            }
            
            if deviceSection == .PairedSection {
                if selectedIndex - 1 >= 0 {
                    selectedIndex = selectedIndex - 1
                }
            }else if deviceSection == .NetSection {
                if selectedIndex - 1 >= 0 {
                    selectedIndex = selectedIndex - 1
                }else if pairedHosts.count > 0{
                    deviceSection = .PairedSection
                    selectedIndex = pairedHosts.count - 1
                }
            }else if deviceSection == .AddSection {
                if netHosts.count > 0 {
                    deviceSection = .NetSection
                    selectedIndex = netHosts.count - 1
                }else if pairedHosts.count > 0{
                    deviceSection = .PairedSection
                    selectedIndex = pairedHosts.count - 1
                }
            }
            scrollToSelectedMenu()
        }
    }
    
    func nextRowMenu() {
        DispatchQueue.main.async { [self] in
            if deviceSection == .Unknow {
                deviceSection = .PairedSection
            }
            
            if deviceSection == .PairedSection {
                if selectedIndex + HostRowLimit < pairedHosts.count {
                    selectedIndex = selectedIndex + HostRowLimit
                }else if selectedIndex < pairedHosts.count - 1 {
                    selectedIndex = pairedHosts.count - 1
                }else if netHosts.count > 0 {
                    deviceSection = .NetSection
                    selectedIndex = 0
                }else{
                    deviceSection = .AddSection
                    selectedIndex = 0
                }
            }else if deviceSection == .NetSection {
                
                if selectedIndex + HostRowLimit < netHosts.count {
                    selectedIndex = selectedIndex + HostRowLimit
                }else if selectedIndex < netHosts.count - 1 {
                    selectedIndex = netHosts.count - 1
                }else{
                    deviceSection = .AddSection
                    selectedIndex = 0
                }
            }
            
            scrollToSelectedMenu()
        }
    }
    
    func lastRowMenu() {
        DispatchQueue.main.async { [self] in
            if deviceSection == .Unknow {
                deviceSection = .PairedSection
            }
            
            if deviceSection == .PairedSection {
                if selectedIndex - HostRowLimit >= 0 {
                    selectedIndex = selectedIndex - HostRowLimit
                }else {
                    selectedIndex = 0
                }
            }else if deviceSection == .NetSection {
                if selectedIndex - HostRowLimit >= 0 {
                    selectedIndex = selectedIndex - HostRowLimit
                }else if selectedIndex > 0 {
                    selectedIndex = 0
                }else if pairedHosts.count > 0{
                    deviceSection = .PairedSection
                    selectedIndex = pairedHosts.count - 1
                }
            }else if deviceSection == .AddSection {
                if netHosts.count > 0 {
                    deviceSection = .NetSection
                    selectedIndex = netHosts.count - 1
                }else if pairedHosts.count > 0{
                    deviceSection = .PairedSection
                    selectedIndex = pairedHosts.count - 1
                }
            }
            scrollToSelectedMenu()
        }
    }

    
    func scrollToSelectedMenu(){
        DispatchQueue.main.async { [self] in
            let conentHeihgt = scroll?.contentSize.height ?? UIScreen.screenHeight
            var topY = 0
            
            if deviceSection == .PairedSection {
                topY = Int(HostCellMoveStep) * (selectedIndex / HostRowLimit)
            }else if deviceSection == .NetSection {
                
                var topSapce = 0
                if pairedHosts.count > 0 {
                    topSapce = Int(HostCellMoveStep) * ((pairedHosts.count / HostRowLimit) + 1) + 40
                }
                topY = Int(HostCellMoveStep) * (selectedIndex / HostRowLimit) + topSapce
                
            }else if deviceSection == .AddSection {
                topY = Int(conentHeihgt - UIScreen.screenHeight)
            }
            topY = min(topY, Int(conentHeihgt - UIScreen.screenHeight) > 0  ? Int(conentHeihgt - UIScreen.screenHeight) : 0)
            topY = topY < 0 ? 0 : topY
            scroll?.contentOffset = CGPoint(x: 0, y: topY)
        }
    }
    
    func clickY() {
        
//        if SettingsRouter.shared.pairAlertView != nil {
//            SettingsRouter.shared.closePairAlertView()
//            return
//        }
//        
//        if self.addressAlertView?.isShowing == true {
//            self.addressAlertView?.dismiss()
//            self.onManualIpEnter(address: self.addressAlertView?.textField(at: 0)?.text ?? "")
//            return
//        }
        
        switch deviceSection {
            
        case .PairedSection:
            if let host = pairedHosts[safe: selectedIndex] {
                unpairHost(host)
            }
        default:
            break
        }
        
    }
    
    func clickA() {
        
//        if SettingsRouter.shared.pairAlertView != nil {
//            SettingsRouter.shared.closePairAlertView()
//            return
//        }
//        
//        if self.addressAlertView?.isShowing == true {
//            self.addressAlertView?.dismiss()
//            self.onManualIpEnter(address: self.addressAlertView?.textField(at: 0)?.text ?? "")
//            return
//        }
        
        switch deviceSection {
            
        case .PairedSection:
            if let host = pairedHosts[safe: selectedIndex] {
                if host.state == .online {
                    startPlayHost(host)
                } else {
                    retryConnectToHost(host)
                }
            }
        case .NetSection:
            if let host = netHosts[safe: selectedIndex] {
                pairHost(host)
            }
        case .AddSection:
            manuallyAddPC()
        default:
            break
        }
    }
    
}


//MARK: - UIScrollViewDelegate
extension DashboardViewModel:UIScrollViewDelegate {
    
}
