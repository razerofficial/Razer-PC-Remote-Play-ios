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
    
    @Published var isShowUnavailibleToast = false
    
    var isAtFrontMost: Bool = false
    
    @Published var bitrate = 1.0
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
    @Published var autoQuit: AutoQuit = .after30s
    @Published var videoEncoder: RZPreferredCodec = .Auto
    @Published var enableCoreHaptics: Bool = true
    
    let isCoreHapticsSupported: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    
    //用于点击选项时候让Setting menu失去焦点
    weak var lastVC:RZStreamFrameSettingsViewController?
    
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
        videoEncoder = RZPreferredCodec(rawValue: frameSettings.preferredCodec) ?? .Auto
        enableCoreHaptics = frameSettings.enableCoreHaptics
    }
    
    func toggleShowUnAvailibleToast(status: Bool) {
        printLog("⚠️====showUnAvailibleToast====")
        self.isShowUnavailibleToast = status
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
        components += [.NeuronStreamingSettingsFramePacingPicker, .NeuronStreamingSettingsVideoEncoderPicker]

        if isCoreHapticsSupported {
            components += [.NeuronStreamingSettingsCoreHapticsToggle]
        }

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
        //update menu
        lastVC?.updateLastVCHandel()
    }

    func isDeviceSupportHDR() -> Bool {
//        return AVPlayer.eligibleForHDRPlayback == true && displayMode == .DuplicatePCDisplayMode
        return AVPlayer.eligibleForHDRPlayback == true
    }
    
    private func printLog(_ msg:String){
        BiancaLogger.shared.logInfo("SettingsLauncherView - " + msg)
    }

    @objc static func isDuplicateDisplayMode() -> Bool {
        return NeuronFrameSettingsViewModel.shared().frameSettings.displayMode == 0
    }

    @objc static func isCoreHapticsEnabled() -> Bool {
        return NeuronFrameSettingsViewModel.shared().enableCoreHaptics
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
        case NeuronStreamingSettingsVideoEncoderPicker
        case NeuronStreamingSettingsCoreHapticsToggle

        var description: String {
            switch self{
            case .NeuronStreamingSettings:
                return "NeuronStreamingSettings"
            case .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay:
                return "NeuronStreamingSettingsDisplayModeVideoSettingsDisplay"
            case .NeuronStreamingSettingsDisplayModeSeparateScreen:
                return "NeuronStreamingSettingsDisplayModeSeparateScreen"
            case .NeuronStreamingSettingsDisplayModeDeviceOptimized:
                return "NeuronStreamingSettingsDisplayModeDeviceOptimized"
            case .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle:
                return "NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle"
            case .NeuronStreamingSettingsRefreshRateToggle:
                return "NeuronStreamingSettingsRefreshRateToggle"
            case .NeuronStreamingSettingsBitrateSlider:
                return "NeuronStreamingSettingsBitrateSlider"
            case .NeuronStreamingSettingsFramePacingPicker:
                return "NeuronStreamingSettingsFramePacingPicker"
            case .NeuronStreamingSettingsHDRToggle:
                return "NeuronStreamingSettingsHDRToggle"
            case .NeuronStreamingSettingsMutePCToggle:
                return "NeuronStreamingSettingsMutePCToggle"
            case .NeuronStreamingSettingsTouchScreenPicker:
                return "NeuronStreamingSettingsTouchScreenPicker"
            case .NeuronStreamingSettingsAutoConfigureSettingsToggle:
                return "NeuronStreamingSettingsAutoConfigureSettingsToggle"
            case .NeuronStreamingSettingsAutoQuitPicker:
                return "NeuronStreamingSettingsAutoQuitPicker"
            case .NeuronStreamingSettingsVideoEncoderPicker:
                return "NeuronStreamingSettingsVideoEncoderPicker"
            case .NeuronStreamingSettingsCoreHapticsToggle:
                return "NeuronStreamingSettingsCoreHapticsToggle"
            }
        }
    }
    
}
