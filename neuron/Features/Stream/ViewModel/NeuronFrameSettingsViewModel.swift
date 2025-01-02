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
import StoreKit
import SwiftUI
import AVFoundation

var hasSafeArea: Bool {
    if #available(iOS 11.0, tvOS 11.0, *) {
//        return (UIApplication.shared.delegate?.window??.safeAreaInsets.left ?? 0 > 20 || UIApplication.shared.delegate?.window??.safeAreaInsets.right ?? 0 > 20)
        return (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaInsets.left ?? 0 > 20 || UIApplication.shared.keyWindowInConnectedScenes?.safeAreaInsets.right ?? 0 > 20)
    }
    return false
}

class NeuronFrameSettingsViewModel: NSObject, ObservableObject {
    
    private static var single: NeuronFrameSettingsViewModel? = nil
    
    class func shared() -> NeuronFrameSettingsViewModel {
        
        if single == nil {
            single = NeuronFrameSettingsViewModel()
        }
        return single!
    }
    
    @Published var highlightedUIComponent: FrameSettingsUIComponents.FrameSettingsHightlightedComponent = .NeuronStreamingSettings
    
    let remotePlayToggleUserDefaultKey = "NeuronRemotePlayToggleStatus"
    
    @Published var remotePlayToggle: Bool = {
        
        let remotePlayToggleCache = UserDefaults.standard.object(forKey: "NeuronRemotePlayToggleStatus")
        if remotePlayToggleCache == nil {
            return true
        }else {
            return UserDefaults.standard.bool(forKey: "NeuronRemotePlayToggleStatus")
        }
        
    }()

    @Published var frameSettings: NeuronFrameSettings = NeuronFrameSettings() {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    @Published var isShowDownloadOverlay = false
    
    @Published var isShowUnavailibleToast = false
    
    var isAtFrontMost: Bool = false
    
    @Published var bitrate = 0.0
    @Published var frameRate: FrameRate = .frameRate60fps
    @Published var framePacingPreference: FramePacingPreference = .lowestLatency
    @Published var touchModel: TouchMode = .touchscreen
    @Published var mutiControllerMode: MultiControllerMode = .auto
    @Published var resolution: Resolution = .resolution360p
    @Published var displayMode: PCDisplayStreamingMode = .DuplicatePCDisplayMode
    @Published var LimitScreenResolutionTtoSafeArea: Bool = false
    @Published var videoRefreshRate: VideoRefreshRate = .refreshRateMatchDisplay
    @Published var limitRefreshRate: Bool = false
    @Published var MuteHostPC: Bool = true
    @Published var autoQuit: AutoQuit = .after30s;
    
    private override init() {
        super.init()
        
        reloadSettings()
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.reloadSettings()
        }
    }
    
    func saveSettings() {
        ShareDataDB.shared().save(frameSettings)
    }
    
    func reloadSettings() {
        var cacheFrameSettings = ShareDataDB.shared().readFrameSettings()
        frameSettings = cacheFrameSettings
        ShareDataDB.shared().readSettingDataFromShare()
        
        bitrate = Double(frameSettings.bitrate)/1000.0
        framePacingPreference = frameSettings.useFramePacing == false ? .lowestLatency : .smoothestVideo
        touchModel = frameSettings.absoluteTouchMode == false ? .touchpad : .touchscreen
        mutiControllerMode = frameSettings.multiController == false ? .single : .auto
        frameRate = FrameRate(frameInt: frameSettings.framerate)
        let resolutionSize = CGSize(width: Double(frameSettings.width), height: Double(frameSettings.height))
        resolution = Resolution(resolutionSize: resolutionSize)
        displayMode = PCDisplayStreamingMode(rawValue: frameSettings.displayMode) ?? .DeviceOptimized
        LimitScreenResolutionTtoSafeArea = resolution == .resolutionFull ? false : true
        videoRefreshRate = VideoRefreshRate(rawValue: frameSettings.videoRefreshRate) ?? (isNeedShowLimitScreenResolutionToSafeAreaToggle() ? .refreshRateMatchDisplay : .PCDisplayRefreshRate)
        MuteHostPC = !frameSettings.playAudioOnPC
        limitRefreshRate = (frameRate == .frameRate60fps ? true : false)
        autoQuit = AutoQuit(timeToTerminateApp: frameSettings.timeToTerminateApp)
    }
    
    func toggleShowUnAvailibleToast(status: Bool) {
        printLog("⚠️====showUnAvailibleToast====")
        self.isShowUnavailibleToast = status
    }
    
    //SKOverlay
    func dismissAppStoreOverlay() {
        if let scene = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).compactMap({$0 as? UIWindowScene}).first {
            SKOverlay.dismiss(in: scene)
        }
        isShowDownloadOverlay = false
    }
    
    func getAllComponent() -> [FrameSettingsUIComponents.FrameSettingsHightlightedComponent] {
        
        var components: [FrameSettingsUIComponents.FrameSettingsHightlightedComponent] = [.NeuronStreamingSettingsDisplayModeDeviceOptimized, .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay, .NeuronStreamingSettingsDisplayModeSeparateScreen]
        
        components += [.NeuronStreamingSettingsBitrateSlider]
        
        
        if isDeviceSupportHDR() {
            components += [.NeuronStreamingSettingsHDRToggle]
        }
        
        if displayMode != .DeviceOptimized {
            components += [.NeuronStreamingSettingsMutePCToggle]
        }
        
        components += [.NeuronStreamingSettingsTouchScreenPicker, .NeuronStreamingSettingsAutoQuitPicker]
        
        if isNeedShowLimitRefreshRateToggle() {
            components += [.NeuronStreamingSettingsRefreshRateToggle]
        }
        if isNeedShowLimitScreenResolutionToSafeAreaToggle() {
            components += [.NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle]
        }
        components += [.NeuronStreamingSettingsFramePacingPicker]
        
        return components
    }
    
    func getCurrentIndex(currentComponent: FrameSettingsUIComponents.FrameSettingsHightlightedComponent) -> Int {
        
        return (getAllComponent().firstIndex(where: {$0 == currentComponent}) ?? 0)
        
    }
    
    func isNeedShowLimitScreenResolutionToSafeAreaToggle() -> Bool {
        return (displayMode != .DuplicatePCDisplayMode && hasSafeArea == true)
    }
    
    func isNeedShowLimitRefreshRateToggle() -> Bool {
        let refreshRate = UIScreen.main.maximumFramesPerSecond
        return refreshRate > 62 ? true : false
    }
    
    func updateDisplayMode(_ displayMode: PCDisplayStreamingMode) {
        self.displayMode = displayMode
        
        switch displayMode {
        case .DuplicatePCDisplayMode:
            frameSettings.displayMode = PCDisplayStreamingMode.DuplicatePCDisplayMode.rawValue
        case .DeviceOptimized:
            frameSettings.displayMode = PCDisplayStreamingMode.DeviceOptimized.rawValue
        case .SeparateScreenMode:
            frameSettings.displayMode = PCDisplayStreamingMode.SeparateScreenMode.rawValue
        }
        saveSettings()
    }

    func isDeviceSupportHDR() -> Bool {
        return AVPlayer.eligibleForHDRPlayback == true && displayMode == .DuplicatePCDisplayMode
    }
    
    private func printLog(_ msg:String){
        BiancaLogger.shared.logInfo("SettingsLauncherView - " + msg)
    }
    
    func handleClickButton(_ action: GamePadButton) {
        
        
        if highlightedUIComponent == .NeuronStreamingSettingsDisplayModeDeviceOptimized {
            switch action {
            case .A:
                updateDisplayMode(.DeviceOptimized)
//                displayMode = .DeviceOptimized
//                frameSettings.displayMode = PCDisplayStreamingMode.DeviceOptimized.rawValue
//                saveSettings()
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
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
                updateDisplayMode(.SeparateScreenMode)
//                displayMode = .SeparateScreenMode
//                frameSettings.displayMode = PCDisplayStreamingMode.SeparateScreenMode.rawValue
//                saveSettings()
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
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
                updateDisplayMode(.DuplicatePCDisplayMode)
//                displayMode = .DuplicatePCDisplayMode
//                frameSettings.displayMode = PCDisplayStreamingMode.DuplicatePCDisplayMode.rawValue
//                saveSettings()

            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
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
                LimitScreenResolutionTtoSafeArea.toggle()
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
            case .up:
                if isNeedShowLimitRefreshRateToggle() {
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
                limitRefreshRate.toggle()
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsAutoQuitPicker
            case .down:
                if isNeedShowLimitScreenResolutionToSafeAreaToggle() {
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
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsDisplayModeDeviceOptimized
            case .down:
                if isDeviceSupportHDR() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsHDRToggle
                }
                else if displayMode != .DeviceOptimized {
                    self.highlightedUIComponent = .NeuronStreamingSettingsMutePCToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsTouchScreenPicker
                }
            case .left:
                if bitrate > 0.5 {
                    bitrate -= 0.5
                }else {
                    bitrate = 0
                }
            case .right:
                if bitrate < 149.5 {
                    bitrate += 0.5
                }else {
                    bitrate = 150.0
                }
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsHDRToggle {
            switch action {
            case .A:
                frameSettings.enableHdr.toggle()
            case .B:
                self.highlightedUIComponent = .NeuronStreamingSettings
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
            case .down:
                if displayMode != .DeviceOptimized {
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
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
            case .up:
                if isNeedShowLimitScreenResolutionToSafeAreaToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
                }else if isNeedShowLimitRefreshRateToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsRefreshRateToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsAutoQuitPicker
                }
            default:
                break
            }
            return
        }
        
        if highlightedUIComponent == .NeuronStreamingSettingsMutePCToggle {
            switch action {
            case .A:
                MuteHostPC.toggle()
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
            case .up:
                if isDeviceSupportHDR() {
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
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
            case .up:
                if displayMode != .DeviceOptimized {
                    self.highlightedUIComponent = .NeuronStreamingSettingsMutePCToggle
                }else if isDeviceSupportHDR() {
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
            case .B:
                SettingsRouter.shared.navigationController?.popViewController(animated: true)
            case .up:
                self.highlightedUIComponent = .NeuronStreamingSettingsTouchScreenPicker
            case .down:
                
                if isNeedShowLimitRefreshRateToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsRefreshRateToggle
                }else if isNeedShowLimitScreenResolutionToSafeAreaToggle() {
                    self.highlightedUIComponent = .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
                }else {
                    self.highlightedUIComponent = .NeuronStreamingSettingsFramePacingPicker
                }
            default:
                break
            }
            return
        }
        
    }

    @objc static func isDuplicateDisplayMode() -> Bool {
        return NeuronFrameSettingsViewModel.shared().frameSettings.displayMode == 0
    }
}


extension NeuronFrameSettingsViewModel: SKOverlayDelegate {
    
    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: Error) {
        self.toggleShowUnAvailibleToast(status: true)
        self.isShowDownloadOverlay = false
    }
    
    func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        self.isShowDownloadOverlay = false
        
    }
    
}

class FrameSettingsUIComponents {
    
    let defaultHighlightedMenuType = FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsDisplayModeDeviceOptimized
    enum FrameSettingsHightlightedComponent {
        
        case NeuronStreamingSettings
        case NeuronStreamingSettingsDisplayModeVideoSettingsDisplay
        case NeuronStreamingSettingsDisplayModeSeparateScreen
        case NeuronStreamingSettingsDisplayModeDeviceOptimized
        case NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
        case NeuronStreamingSettingsRefreshRateToggle
        case NeuronStreamingSettingsBitrateSlider
        case NeuronStreamingSettingsFramePacingPicker
        case NeuronStreamingSettingsHDRToggle
        case NeuronStreamingSettingsMutePCToggle
        case NeuronStreamingSettingsTouchScreenPicker
        case NeuronStreamingSettingsAutoConfigureSettingsToggle
        case NeuronStreamingSettingsAutoQuitPicker
        
    }
}
