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

import Foundation

extension SettingsViewModel: RZHandleResponderDelegate {
    
    func handleClickButton(_ button: GamePadButton) {
        
        printLog("settings action: \(button)")
        
        switch self.highlightedUIComponent {
            
        case .NeuronStreamingMenu, .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay, .NeuronStreamingSettingsDisplayModeSeparateScreen, .NeuronStreamingSettingsDisplayModeDeviceOptimized, .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle, .NeuronStreamingSettingsRefreshRateToggle, .NeuronStreamingSettingsBitrateSlider, .NeuronStreamingSettingsFramePacingPicker, .NeuronStreamingSettingsHDRToggle, .NeuronStreamingSettingsMutePCToggle, .NeuronStreamingSettingsTouchScreenPicker, .NeuronStreamingSettingsAutoConfigureSettingsToggle, .NeuronStreamingSettingsAutoQuitPicker, .NeuronStreamingSettingsVideoEncoderPicker, .NeuronStreamingSettingsCoreHapticsToggle:
            self.actWhenNeuronSettingsComponentsAreHighlighted(button, highlightedUIComponent)
            
        case .NeuronStreamingHostMenu, .NeuronStreamingLocalHost, .NeuronStreamingNetHost, .NeuronStreamingAddHost:
            self.actWhenNeuronHostsComponentsAreHighlighted(button, highlightedUIComponent)
            
        case .AboutMenu, .AboutButtonTermsOfService, .AboutButtonPrivacyPolicy, .AboutButtonOpenSource, .AboutTermsOfServiceWebView, .AboutPrivacyWebView, .AboutOpenSourceWebView:
            self.actWhenAboutComponentsAreHighlighted(button, highlightedUIComponent)
        case .DevMenu:
            switch button {
            case .B:
                self.highlightedUIComponent = .AboutButtonTermsOfService
                popView()
            default:break
            }
        }
    }
    
    private func actWhenNeuronSettingsComponentsAreHighlighted(_ action: GamePadButton,_ highlightedUIComponent:SettingsUIComponents.ComponentType){
     
        let neuronSettingsVM = NeuronFrameSettingsViewModel.shared()
        
        if highlightedUIComponent == .NeuronStreamingMenu {
            switch action {
            case .A, .right:
                self.highlightedUIComponent = .NeuronStreamingSettingsDisplayModeDeviceOptimized
            case .B:
                self.dismissThisView()
            case .down:
                self.highlightedUIComponent = .NeuronStreamingHostMenu
            default: break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsDisplayModeDeviceOptimized {
            switch action {
            case .A:
                neuronSettingsVM.updateDisplayMode(.DeviceOptimized)
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .down:
                self.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
            case .right:
                self.highlightedUIComponent = .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsDisplayModeSeparateScreen {
            switch action {
            case .A:
                neuronSettingsVM.updateDisplayMode(.SeparateScreenMode)
            case .B:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .down:
                self.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
            case .left:
                self.highlightedUIComponent = .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay {
            switch action {
            case .A:
                neuronSettingsVM.updateDisplayMode(.DuplicatePCDisplayMode)
            case .B:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .down:
                self.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
            case .left:
                self.highlightedUIComponent = .NeuronStreamingSettingsDisplayModeDeviceOptimized
            case .right:
                self.highlightedUIComponent = isShowSeparateScreenDisplayMode ? .NeuronStreamingSettingsDisplayModeSeparateScreen : .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle {
            switch action {
            case .A:
                neuronSettingsVM.LimitScreenResolutionTtoSafeArea.toggle()
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                if neuronSettingsVM.isNeedShowLimitRefreshRateToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsRefreshRateToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsAutoQuitPicker
                }
            case .down:
                self.highlightedUIComponent = .NeuronStreamingSettingsFramePacingPicker
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsRefreshRateToggle {
            switch action {
            case .A:
                neuronSettingsVM.limitRefreshRate.toggle()
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsAutoQuitPicker
            case .down:
                if neuronSettingsVM.isNeedShowLimitScreenResolutionToSafeAreaToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsFramePacingPicker
                }
            default:
                break
            }
            return
        }
        
        if self.highlightedUIComponent == .NeuronStreamingSettingsBitrateSlider {
            switch action {
            case .B:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsDisplayModeDeviceOptimized
            case .down:
                if neuronSettingsVM.isDeviceSupportHDR() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsHDRToggle
                }
                else if neuronSettingsVM.displayMode != .DeviceOptimized {
                    self.highlightedUIComponent = .NeuronStreamingSettingsMutePCToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsTouchScreenPicker
                }
            case .left:
                if neuronSettingsVM.bitrate > 1.0 {
                    neuronSettingsVM.bitrate = max(neuronSettingsVM.bitrate - 0.5, 1.0)
                }else {
                    neuronSettingsVM.bitrate = 1.0
                }
            case .right:
                if neuronSettingsVM.bitrate < 149.5 {
                    neuronSettingsVM.bitrate += 0.5
                }else {
                    neuronSettingsVM.bitrate = 150.0
                }
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsHDRToggle {
            switch action {
            case .A:
                neuronSettingsVM.frameSettings.enableHdr.toggle()
                self.highlightedUIComponent = .NeuronStreamingSettingsHDRToggle
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
            case .down:
                if neuronSettingsVM.displayMode != .DeviceOptimized {
                    self.highlightedUIComponent = .NeuronStreamingSettingsMutePCToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsTouchScreenPicker
                }
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsFramePacingPicker {
            switch action {
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                if neuronSettingsVM.isNeedShowLimitScreenResolutionToSafeAreaToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
                }else if neuronSettingsVM.isNeedShowLimitRefreshRateToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsRefreshRateToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsAutoQuitPicker
                }
            case .down:
                self.highlightedUIComponent = .NeuronStreamingSettingsVideoEncoderPicker
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsMutePCToggle {
            switch action {
            case .A:
                neuronSettingsVM.MuteHostPC.toggle()
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                if neuronSettingsVM.isDeviceSupportHDR() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsHDRToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
                }
            case .down:
                self.highlightedUIComponent = .NeuronStreamingSettingsTouchScreenPicker
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsTouchScreenPicker {
            switch action {
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                if neuronSettingsVM.displayMode != .DeviceOptimized {
                    self.highlightedUIComponent = .NeuronStreamingSettingsMutePCToggle
                }else if neuronSettingsVM.isDeviceSupportHDR() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsHDRToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
                }
            case .down:
                self.highlightedUIComponent = .NeuronStreamingSettingsAutoQuitPicker
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsAutoQuitPicker {
            switch action {
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsTouchScreenPicker
            case .down:
                
                if neuronSettingsVM.isNeedShowLimitRefreshRateToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsRefreshRateToggle
                }else if neuronSettingsVM.isNeedShowLimitScreenResolutionToSafeAreaToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsFramePacingPicker
                }
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsVideoEncoderPicker {
            switch action {
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsFramePacingPicker
            case .down:
                if neuronSettingsVM.isCoreHapticsSupported {
                    self.highlightedUIComponent = .NeuronStreamingSettingsCoreHapticsToggle
                }
            default:
                break
            }
            return
        }

        if highlightedUIComponent == .NeuronStreamingSettingsCoreHapticsToggle {
            switch action {
            case .A:
                neuronSettingsVM.enableCoreHaptics.toggle()
                neuronSettingsVM.frameSettings.enableCoreHaptics = neuronSettingsVM.enableCoreHaptics
                neuronSettingsVM.saveSettings()
            case .B, .left:
                self.highlightedUIComponent = .NeuronStreamingMenu
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsVideoEncoderPicker
            default:
                break
            }
            return
        }
    }
    
    private func actWhenNeuronHostsComponentsAreHighlighted(_ button:GamePadButton,_ highlightedUIComponent:SettingsUIComponents.ComponentType){
     
        if highlightedUIComponent == .NeuronStreamingHostMenu {
            switch button {
            case .A, .right:
                // TODO: wait for host page
                if DashboardViewModel.shared.pairedHosts.count > 0 {
                    self.highlightedUIComponent = .NeuronStreamingLocalHost
                    self.selectedHostIndex = 0
                }else if DashboardViewModel.shared.netHosts.count > 0 {
                    self.highlightedUIComponent = .NeuronStreamingNetHost
                    self.selectedHostIndex = 0
                }else {
                    self.highlightedUIComponent = .NeuronStreamingAddHost
                }
                updateHostScrollViewOffset()

                break
            case .B:
                self.dismissThisView()
            case .down:
                self.highlightedUIComponent = .AboutMenu
            case .up:
                self.highlightedUIComponent = .NeuronStreamingMenu
            default: break
            }
            return
        }
        
        //NeuronStreamingLocalHost
        if highlightedUIComponent == .NeuronStreamingLocalHost {
            
            if DashboardViewModel.shared.isWaitForHostResponse {
                return
            }
            
//            if DashboardViewModel.shared.shouldShowAlert {
//                if button == .A {
//                    PairViewModel.shared.closePairAlertView(isNeedShowLoadingView: false)
//                }
//                return
//            }
            
            switch button {
            case .A :
                if let host = DashboardViewModel.shared.pairedHosts[safe: selectedHostIndex] {
                    
                    selectedHostAddress = host.localAddress
                    //goToLocalHostMenuView(host: host)
                    SettingsViewModel.shared.pushToNewPageWith(path: SettingsRoute.PairedComputer(host: host))
                }
            case .left,.B:
                self.highlightedUIComponent = .NeuronStreamingHostMenu
            case .down:
                let index = selectedHostIndex + 1
                if index < DashboardViewModel.shared.pairedHosts.count {
                   selectedHostIndex = index
                }else if DashboardViewModel.shared.netHosts.count > 0 {
                    self.highlightedUIComponent = .NeuronStreamingNetHost
                    self.selectedHostIndex = 0
                }else {
                    self.highlightedUIComponent = .NeuronStreamingAddHost
                }
                //updateHostScrollViewOffset()
            case .up:
                let index = selectedHostIndex - 1
                if index >= 0  && index < DashboardViewModel.shared.pairedHosts.count{
                   selectedHostIndex = index
                }
                updateHostScrollViewOffset()
            default: break
            }
            return
        }
        
        //NeuronStreamingNetHost
        if highlightedUIComponent == .NeuronStreamingNetHost {
            
            if DashboardViewModel.shared.isWaitForHostResponse {
                return
            }
            
            //pin code alertview showing
            if SettingsRouter.shared.pairAlertView != nil {
                switch button {
                case.A :
                    SettingsRouter.shared.closePairAlertView()
                default:
                    break
                }
                return
            }
            
            switch button {
            case .A :
                if let host = DashboardViewModel.shared.netHosts[safe: selectedHostIndex] {
                    selectedHostAddress = host.localAddress
                    DashboardViewModel.shared.pairHost(host)
                }
            case .left,.B:
                self.highlightedUIComponent = .NeuronStreamingHostMenu
            case .down:
                let index = selectedHostIndex + 1
                if index < DashboardViewModel.shared.netHosts.count {
                   selectedHostIndex = index
                }else {
                    self.highlightedUIComponent = .NeuronStreamingAddHost
                }
                //updateHostScrollViewOffset()
            case .up:
                let index = selectedHostIndex - 1
                if index >= 0  && index < DashboardViewModel.shared.netHosts.count{
                   selectedHostIndex = index
                }else if DashboardViewModel.shared.pairedHosts.count > 0 {
                    self.highlightedUIComponent = .NeuronStreamingLocalHost
                    self.selectedHostIndex = DashboardViewModel.shared.pairedHosts.count - 1
                }
                updateHostScrollViewOffset()
            default: break
            }
            return
        }
        
        //NeuronStreamingAddHost
        if highlightedUIComponent == .NeuronStreamingAddHost {
            
            if DashboardViewModel.shared.isWaitForHostResponse {
                return
            }
            
//            if PairViewModel.shared.shouldShowAlert {
//                if button == .A {
//                    PairViewModel.shared.closePairAlertView(isNeedShowLoadingView: false)
//                }
//                return
//            }
            
            switch button {
            case .A :
                DashboardViewModel.shared.settingsManuallyAddPC()
            case .left,.B:
                self.highlightedUIComponent = .NeuronStreamingHostMenu
            case .up:
                if DashboardViewModel.shared.netHosts.count > 0 {
                    self.highlightedUIComponent = .NeuronStreamingNetHost
                    self.selectedHostIndex = DashboardViewModel.shared.netHosts.count - 1
                }else if DashboardViewModel.shared.pairedHosts.count > 0 {
                    self.highlightedUIComponent = .NeuronStreamingLocalHost
                    self.selectedHostIndex = DashboardViewModel.shared.pairedHosts.count - 1
                }
                updateHostScrollViewOffset()
            default: break
            }
            return
        }
    }
    
    private func actWhenAboutComponentsAreHighlighted(_ button:GamePadButton,_ highlightedUIComponent:SettingsUIComponents.ComponentType){
        
        if highlightedUIComponent == .AboutMenu {
            switch button {
            case .A, .right:
                self.highlightedUIComponent = .AboutButtonTermsOfService
            case .B:
                self.dismissThisView()
            case .up:
                self.highlightedUIComponent = .NeuronStreamingHostMenu
            default: break
            }
            return
        }
        
        if highlightedUIComponent == .AboutButtonTermsOfService {
            switch button {
            case .A:
                goToTermsOfService()
            case .right:
                self.highlightedUIComponent = .AboutButtonPrivacyPolicy
            case .B, .left:
                self.highlightedUIComponent = .AboutMenu
            case .down:
                self.highlightedUIComponent = .AboutButtonOpenSource
            default: break
            }
        }

        if highlightedUIComponent == .AboutButtonPrivacyPolicy {
            switch button {
            case .A:
                goToPrivacyPolicy()
            case .left:
                self.highlightedUIComponent = .AboutButtonTermsOfService
            case .B:
                self.highlightedUIComponent = .AboutMenu
            case .down:
                self.highlightedUIComponent = .AboutButtonOpenSource
            default: break
            }
        }

        if highlightedUIComponent == .AboutButtonOpenSource {
            switch button {
            case .A:
                goToOpenSource()
            case .B, .left:
                self.highlightedUIComponent = .AboutMenu
            case .up:
                self.highlightedUIComponent = .AboutButtonTermsOfService
            default: break
            }
        }
        
        if highlightedUIComponent == .AboutOpenSourceWebView {
            switch button {
            case.B:
                self.highlightedUIComponent = .AboutButtonOpenSource
                popView()
                
            default:break
            }
        }
        
        if highlightedUIComponent == .AboutPrivacyWebView {
            switch button {
            case.B:
                self.highlightedUIComponent = .AboutButtonPrivacyPolicy
                popView()
                
            default:break
            }
        }
        
        if highlightedUIComponent == .AboutTermsOfServiceWebView {
            switch button {
            case.B:
                self.highlightedUIComponent = .AboutButtonTermsOfService
                popView()
                
            default:break
            }
        }
    }
    
    
    func dismissThisView(){
        self.dismissScreen = true
    }
}
