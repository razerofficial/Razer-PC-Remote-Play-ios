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
import VideoToolbox
import UIKit


enum RZHostPairState: Int, Codable {
    case PairStateUnknown = 0
    case PairStateUnpaired
    case PairStatePaired
    
}

enum RZHostState: Int, Codable {
    case StateUnknown = 0
    case StateOffline
    case StateOnline
    case StateUnpaired
    
    var name: String {
        switch self {
        case .StateOffline:
            return "OFFLINE"
        case .StateOnline:
            return "ONLINE"
        case .StateUnknown:
            return "UNKNOWN"
        case .StateUnpaired:
            return "UNPAIRED"
        }
    }
}

enum Resolution: Int, Codable {
    case resolution360p = 0
    case resolution720p
    case resolution1080p
    case resolution4k
    case resolutionSafeArea
    case resolutionFull
    case resolutionCustom
    
    func displayName() -> String {
        
        switch self {
        case .resolution360p :
            return "360p"
        case .resolution720p:
            return "720p"
        case .resolution1080p:
            return "1080p"
        case .resolution4k:
            return "4k"
        case .resolutionSafeArea :
            return "Safe Area"
        case .resolutionFull:
            return "Full"
        case .resolutionCustom:
            return "Custom"
        }
    }
    
    func resolutionSize() -> CGSize {
        
//        let window = UIApplication.shared.delegate?.window
        let window = UIApplication.shared.keyWindowInConnectedScenes
        let screenScale = window?.screen.scale ?? 1
        let leftArea = window?.safeAreaInsets.left ?? 0
        let rightArea = window?.safeAreaInsets.right ?? 0
        
        switch self {
        case .resolution360p:
            return CGSize(width: 640, height: 360)
        case .resolution720p:
            return CGSize(width: 1280, height: 720)
        case .resolution1080p:
            return CGSize(width: 1920, height: 1080)
        case .resolution4k:
            return CGSize(width: 3840, height: 2160)
        case .resolutionSafeArea:
            let safeAreaWidth = ((window?.frame.size.width ?? 0) - leftArea - rightArea) * screenScale
            return CGSize(width: safeAreaWidth, height: (window?.frame.size.height ?? 0) * screenScale)
        case .resolutionFull:
            return CGSize(width: (window?.frame.size.width ?? 0) * screenScale, height: (window?.frame.size.height ?? 0) * screenScale)
        case .resolutionCustom:
            return CGSize(width: (window?.frame.size.width ?? 0) * screenScale, height: (window?.frame.size.height ?? 0) * screenScale)
        }
    }
    
    init(resolutionSize: CGSize) {
        
        let window = UIApplication.shared.keyWindowInConnectedScenes
        let screenScale = window?.screen.scale ?? 1
        let leftArea = window?.safeAreaInsets.left ?? 0
        let rightArea = window?.safeAreaInsets.right ?? 0
        let safeAreaWidth = ((window?.frame.size.width ?? 0) - leftArea - rightArea) * screenScale
        
        switch resolutionSize {
        case CGSize(width: 640, height: 360):
            self = .resolution360p
        case CGSize(width: 1280, height: 720):
            self = .resolution720p
        case CGSize(width: 1920, height: 1080):
            self = .resolution1080p
        case CGSize(width: 3840, height: 2160):
            self = .resolution4k
        case CGSize(width: (window?.frame.size.width ?? 0) * screenScale, height: (window?.frame.size.height ?? 0) * screenScale):
            self = .resolutionFull
        case CGSize(width: safeAreaWidth, height: (window?.frame.size.height ?? 0) * screenScale):
            self = .resolutionSafeArea
        default:
            self = .resolutionCustom
        }
    }
    
    static var all: [Resolution] {
        return [.resolution360p, .resolution720p, .resolution1080p, .resolution4k, .resolutionSafeArea, .resolutionFull, .resolutionCustom]
    }
}

enum FrameRate: Int, Codable {
    case frameRate30fps = 0
    case frameRate60fps
    case frameRate120fps
    
    func displayName() -> String {
        switch self {
        case .frameRate30fps:
            return "30 FPS"
        case .frameRate60fps:
            return "60 FPS"
        case .frameRate120fps:
            return "120 FPS"
        }
    }
    
    func frameInt() -> Int32 {
        switch self {
        case .frameRate30fps:
            return 30
        case .frameRate60fps:
            return 60
        case .frameRate120fps:
            return 120
        }
    }
    
    init(frameInt: Int32) {
        if frameInt == 60 {
            self = .frameRate60fps
        }else if frameInt == 120 {
            self = .frameRate120fps
        }else {
            self = .frameRate30fps
        }
    }
    
    static var all: [FrameRate] {
        
        if UIScreen.main.maximumFramesPerSecond > 62 {
            return [.frameRate30fps, .frameRate60fps, .frameRate120fps]
        }else {
            return [.frameRate30fps, .frameRate60fps]
        }
    }
}

enum TouchMode: Int, Codable {
    
    case touchpad = 0
    case touchscreen
    
    func displayName() -> String {
        switch self {
        case .touchpad:
            return "Virtual Trackpad".localize()
        case .touchscreen:
            return "Direct Touch".localize()
        }
    }
    
    static var all: [TouchMode] {
        return [.touchscreen, .touchpad]
    }
}

@objc enum RZOnScreenControls: Int, Codable {
    case off = 0
    case auto
    case simple
    case full
    
    func displayName() -> String {
        
        switch self {
        case .off:
            return "Off"
        case .auto:
            return "Auto"
        case .simple:
            return "Simple"
        case .full:
            return "Full"
        }
    }
    
    static var all: [RZOnScreenControls] {
        return [.off, .auto, .simple, .full]
    }
}

@objc enum RZPreferredCodec: Int, Codable {
    case H264 = 1
    case Hevc = 2
    case Auto = 0
    case AV1 = 3
    
    func displayName() -> String {
        switch self {
        case .H264:
            return "H264"
        case .Hevc:
            return "HEVC"
        case .Auto:
            return "Automatic"
        case .AV1:
            return "AV1"
        }
    }
    
    static var all: [RZPreferredCodec] {
        
        var all: [RZPreferredCodec] = [.Auto]
        if #available(iOS 16.0, tvOS 16.0, *) {
            if VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1) {
                all.append(.AV1)
            }
        }
        
        if VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC) {
            all.append(.Hevc)
        }
        
        all.append(.H264)
        
        return all
    }
}

enum FramePacingPreference: Int, Codable {
    case lowestLatency = 0
    case smoothestVideo
    
    func displayName() -> String {
        switch self {
        case .lowestLatency:
            return "Low Latency".localize()
        case .smoothestVideo:
            return "Smoothest Video".localize()
        }
    }
    
    static var all: [FramePacingPreference] {
        return [.lowestLatency, .smoothestVideo]
    }
}

enum MultiControllerMode: Int, Codable {
    
    case single = 0
    case auto
    
    func displayName() -> String {
        switch self {
        case .single:
            return "Single"
        case .auto:
            return "Auto"
        }
    }
    
    static var all: [MultiControllerMode] {
        return [.single, .auto]
    }
}

enum DisplayModel: Int, Codable {
    
    case virtualDisplay = 1
    case streamPCDisplay = 0
    
    func displayName() -> String {
        switch self {
        case .virtualDisplay:
            return "Virtual Display"
        case .streamPCDisplay:
            return "PC Display"
        }
    }
    
    static var all: [DisplayModel] {
        return [.virtualDisplay, .streamPCDisplay]
    }
}

enum PCDisplayStreamingMode: Int, Codable {
    
    case DuplicatePCDisplayMode = 0
    case SeparateScreenMode = 1
    case DeviceOptimized = 2
    
    func displayName() -> String {
        switch self {
        case .DuplicatePCDisplayMode:
            return "Duplicate PC Display".localize()
        case .SeparateScreenMode:
            return "Separate Screen"
        case .DeviceOptimized:
            let deviceString = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
            return "[iPhone/iPad] Optimized".localize().kStringByReplaceString(replaceStr: "[iPhone/iPad]", willReplaceStr: deviceString+"\n")
        }
    }
    
    func resolutionRate() -> String {
        switch self {
        case .DuplicatePCDisplayMode:
//            let resolution = Resolution.resolution720p.resolutionSize()
////            let refreshRate = NeuronFrameSettingsViewModel.shared().frameSettings.framerate
//            return "\(Int(resolution.width))x\(Int(resolution.height))(60fps)"
            return " "
        case .SeparateScreenMode:
            let resolution = NeuronFrameSettingsViewModel.shared().resolution.resolutionSize()
            let refreshRate = NeuronFrameSettingsViewModel.shared().limitRefreshRate == false ? Int32(UIScreen.main.maximumFramesPerSecond) : 60
            return "\(Int(resolution.width))x\(Int(resolution.height))"
//            return "\(resolution.width)x\(resolution.height)x\(refreshRate)"
        case .DeviceOptimized:
            let resolution = NeuronFrameSettingsViewModel.shared().resolution.resolutionSize()
            let refreshRate = NeuronFrameSettingsViewModel.shared().limitRefreshRate == false ? Int32(UIScreen.main.maximumFramesPerSecond) : 60
//            return "%1$s at %2$sHz".kStringByReplaceString(replaceStr: "%1$s", willReplaceStr: "\(Int(resolution.width))x\(Int(resolution.height))").kStringByReplaceString(replaceStr: "%2$s", willReplaceStr: "\(refreshRate)")
            return  "\(Int(resolution.width))x\(Int(resolution.height))"
        }
    }
    
    func refreshRate() -> String {
        switch self {
        case .DuplicatePCDisplayMode:
            let refreshRate = NeuronFrameSettingsViewModel.shared().limitRefreshRate == false ? Int32(UIScreen.main.maximumFramesPerSecond) : 60
            return "\(refreshRate)"
        case .SeparateScreenMode:
            let refreshRate = NeuronFrameSettingsViewModel.shared().limitRefreshRate == false ? Int32(UIScreen.main.maximumFramesPerSecond) : 60
            return "\(refreshRate)"
        case .DeviceOptimized:
            let refreshRate = NeuronFrameSettingsViewModel.shared().limitRefreshRate == false ? Int32(UIScreen.main.maximumFramesPerSecond) : 60
            return "\(refreshRate)"
        }
    }
    
    func descriptionString() -> String {
        switch self {
        case .DuplicatePCDisplayMode:
            return "Your PC’s connected display will be streamed to your [iPhone/iPad] ".localize().kStringByReplaceString(replaceStr: "[iPhone/iPad]", willReplaceStr: getCurrentDeviceTypeString())
        case .SeparateScreenMode:
            return ""
        case .DeviceOptimized:
            return "Your PC will create a virtual display matching your [iPhone/iPad]’s resolution and refresh rate of %1$s at %2$sHz and stream it to your [iPhone/iPad].\n\nAny screen connected to your PC will be temporarily disabled while streaming."
                .localize().replacingOccurrences(of: "[iPhone/iPad]", with: getCurrentDeviceTypeString())
                .localize().replacingOccurrences(of: "%1$s", with: resolutionRate())
                .localize().replacingOccurrences(of: "%2$s", with: refreshRate())
        }
    }
    
    func displayImageName() -> String {
        switch self {
        case .DuplicatePCDisplayMode:
            return "PCDisplayModeDuplicate"
        case .SeparateScreenMode:
            return "PCDisplayModeSeparateScreen"
        case .DeviceOptimized:
            return "PCDisplayModePhoneOnly"
        }
    }
    
    func highlightedImageName() -> String {
        switch self {
        case .DuplicatePCDisplayMode:
            return "PCDisplayModeDuplicate"
        case .SeparateScreenMode:
            return "PCDisplayModeSeparateScreen"
        case .DeviceOptimized:
            return "PCDisplayModePhoneOnly- highlighted"
        }
    }
    
    func highlightedUIComponent() -> FrameSettingsUIComponents.FrameSettingsHightlightedComponent {
        switch self {
        case .DuplicatePCDisplayMode:
            return .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay
        case .SeparateScreenMode:
            return .NeuronStreamingSettingsDisplayModeSeparateScreen
        case .DeviceOptimized:
            return .NeuronStreamingSettingsDisplayModeDeviceOptimized
        }
    }
    
    static var all: [PCDisplayStreamingMode] {
        if isShowSeparateScreenDisplayMode {
            return [.DeviceOptimized, .DuplicatePCDisplayMode, .SeparateScreenMode]
        } else {
            return [.DeviceOptimized, .DuplicatePCDisplayMode]
        }
        
    }
}

enum VideoRefreshRate: Int, Codable {
    case refreshRateMatchDisplay = 0
    case PCDisplayRefreshRate
    case refreshRate60
    
    
    func displayName() -> String {
        switch self {
        case .refreshRateMatchDisplay:
            return "Match display"
        case .PCDisplayRefreshRate:
            return "Don’t change PC display refresh rate"
        case .refreshRate60:
            return "60 FPS"
        }
    }
    
    func frameInt() -> Int32 {
        switch self {
        case .refreshRateMatchDisplay:
            return 60
        case .PCDisplayRefreshRate:
            return 60
        case .refreshRate60:
            return 60
        }
    }
    
//    init(frameInt: Int32) {
//        if frameInt == 60 {
//            self = .frameRate60fps
//        }else if frameInt == 120 {
//            self = .frameRate120fps
//        }else {
//            self = .frameRate30fps
//        }
//    }
    
    static var virtualDisplayAll: [VideoRefreshRate] {
        return [.refreshRateMatchDisplay, .refreshRate60]
    }
    
    static var PCDisplayAll: [VideoRefreshRate] {
        return [.PCDisplayRefreshRate, .refreshRateMatchDisplay, .refreshRate60]
    }
}

enum AutoQuit: Int, Codable {
    case immediately = 0
    case after30s
    case after5min
    case never
    
    
    func displayName() -> String {
        switch self {
        case .immediately:
            return "Instantly"
        case .after30s:
            return "Wait 30s"
        case .after5min:
            return "Wait 5min"
        case .never:
            return "Never"
        }
    }
    
    func autoQuitTime() -> Int {
        switch self {
            
        case .immediately:
            return 0
        case .after30s:
            return 30
        case .after5min:
            return 300
        case .never:
            return -1
        }
    }
    
    init(timeToTerminateApp: Int) {
        switch timeToTerminateApp {
        case 0:
            self = .immediately
        case 30:
            self = .after30s
        case 300:
            self = .after5min
        case -1:
            self = .never
        default:
            self = .after30s
        }
    }
    
    static var all: [AutoQuit] {
        return [.immediately, .after30s, .after5min, .never]
    }
}
