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

class SettingsUIComponents {
    
    static let defaultHighlightedMenuType = SettingsUIComponents.ComponentType.NeuronStreamingMenu
 
    enum ComponentType: Equatable, Hashable {
        //Streaming host
        case NeuronStreamingHostMenu
        case NeuronStreamingLocalHost
        case NeuronStreamingNetHost
        case NeuronStreamingAddHost
        
        //Streaming settings
        case NeuronStreamingMenu
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
        case NeuronStreamingSettingsAutoQuitPicker
        case NeuronStreamingSettingsAutoConfigureSettingsToggle
        case NeuronStreamingSettingsVideoEncoderPicker
        case NeuronStreamingSettingsCoreHapticsToggle

        // About
        case AboutMenu
        case AboutButtonTermsOfService
        case AboutButtonPrivacyPolicy
        case AboutButtonOpenSource
        case AboutTermsOfServiceWebView
        case AboutPrivacyWebView
        case AboutOpenSourceWebView
        
        //dev
        case DevMenu
        
        var description: String {
         
            switch self {
            case .NeuronStreamingHostMenu:
                return "NeuronStreamingHostMenu"
            case .NeuronStreamingLocalHost:
                return "NeuronStreamingLocalHost"
            case .NeuronStreamingNetHost:
                return "NeuronStreamingNetHost"
            case .NeuronStreamingAddHost:
                return "NeuronStreamingAddHost"
            case .NeuronStreamingMenu:
                return "NeuronStreamingMenu"
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
            case .NeuronStreamingSettingsAutoQuitPicker:
                return "NeuronStreamingSettingsAutoQuitPicker"
            case .NeuronStreamingSettingsAutoConfigureSettingsToggle:
                return "NeuronStreamingSettingsAutoConfigureSettingsToggle"
            case .NeuronStreamingSettingsVideoEncoderPicker:
                return "NeuronStreamingSettingsVideoEncoderPicker"
            case .NeuronStreamingSettingsCoreHapticsToggle:
                return "NeuronStreamingSettingsCoreHapticsToggle"
            case .AboutMenu:
                return "AboutMenu"
            case .AboutButtonTermsOfService:
                return "AboutButtonTermsOfService"
            case .AboutButtonPrivacyPolicy:
                return "AboutButtonPrivacyPolicy"
            case .AboutButtonOpenSource:
                return "AboutButtonOpenSource"
            case .DevMenu:
                return "DevMenu"
            case .AboutTermsOfServiceWebView:
                return "AboutTermsOfServiceWebView"
            case .AboutPrivacyWebView:
                return "AboutPrivacyWebView"
            case .AboutOpenSourceWebView:
                return "AboutOpenSourceWebView"
            }
        }
        
        func isMenuItem() -> Bool {
            switch self {
            case .NeuronStreamingMenu:
                return true
            case .NeuronStreamingHostMenu:
                return true
            case .AboutMenu:
                return true
            case .DevMenu:
                return true
            default:
                return false
            }
        }
        
        func getTitle() -> String {
         
            switch self {
            case .NeuronStreamingMenu:
                return "Streaming Options".localize()
            case .NeuronStreamingHostMenu:
                return "Computers".localize()
            case .AboutMenu:
                return "About".localize()
            case .DevMenu:
                return "Dev".localize()
            default:
                return ""
            }
        }
        
        func getParentMenuItem() -> SettingsUIComponents.ComponentType {
         
            switch self {
            case .DevMenu:
                return .DevMenu
            case .NeuronStreamingMenu, .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay, .NeuronStreamingSettingsDisplayModeSeparateScreen, .NeuronStreamingSettingsDisplayModeDeviceOptimized, .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle, .NeuronStreamingSettingsRefreshRateToggle, .NeuronStreamingSettingsBitrateSlider, .NeuronStreamingSettingsFramePacingPicker, .NeuronStreamingSettingsHDRToggle, .NeuronStreamingSettingsMutePCToggle, .NeuronStreamingSettingsTouchScreenPicker, .NeuronStreamingSettingsAutoConfigureSettingsToggle, .NeuronStreamingSettingsAutoQuitPicker, .NeuronStreamingSettingsVideoEncoderPicker, .NeuronStreamingSettingsCoreHapticsToggle:
                return .NeuronStreamingMenu
            case .NeuronStreamingHostMenu,.NeuronStreamingLocalHost,.NeuronStreamingNetHost,.NeuronStreamingAddHost:
                return .NeuronStreamingHostMenu
            case .AboutMenu, .AboutButtonOpenSource, .AboutButtonPrivacyPolicy, .AboutButtonTermsOfService, .AboutPrivacyWebView, .AboutTermsOfServiceWebView, .AboutOpenSourceWebView:
                return .AboutMenu
            }
        }
    }
    
}
