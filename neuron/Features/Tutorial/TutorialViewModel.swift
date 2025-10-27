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
import SwiftUI

class TutorialViewModel: ObservableObject {
    //MARK: other property
    @Published var isGrantedLocalNetworkPermission: Bool = false {
        willSet {
            if tutorialStep == .permission {
                bottomButtons = newValue ? [.continue] : [.allow]
            }
        }
    }
    @Published var isRequestedLocalNetworkPermission: Bool = false
    @Published var isAcceptedTOS: Bool = false
    @Published var isDownloadNexus: Bool = false
    @Published var isAlreadySetDisplayMode: Bool = false
    
    @Published var tutorialStep: TutorialStep = .tos {
        willSet {
            switch newValue {
            case .tos: bottomButtons = [.accept]
            case .permission: bottomButtons = isGrantedLocalNetworkPermission ? [.continue] : [.allow]
            case .downloadNexus: bottomButtons = [.skip, .download]
            case .displayMode: bottomButtons = [.done]
            default: bottomButtons = []
            }
        }
    }

//    @Published var isShowPermissionAlert: Bool = false
    @Published var currentDisplayMode: TutorialPCDisplayMode = .duplicate{
        willSet {
            switch newValue {
            case .separateScreen:
                currentDisplayModeImage = IsIpad() ? "streaming_separate_screen" : "streaming_separate_screen"
                displayModelDescription =  "Extend your PC display to your phone for seamless multitasking. Use your phone as a second screen to view different content, ideal for productivity and gaming on the go.".localize()
            case .phoneOnly:
                currentDisplayModeImage = IsIpad() ? "streaming_phone_only_ipad" : "streaming_phone_only"
                displayModelDescription = "Your PC will create a virtual display matching your [iPhone/iPad]’s resolution and refresh rate of %1$s at %2$sHz and stream it to your [iPhone/iPad].\n\nAny screen connected to your PC will be temporarily disabled while streaming."
                    .localize().replacingOccurrences(of: "[iPhone/iPad]", with: deviceType)
                    .localize().replacingOccurrences(of: "%1$s", with: PCDisplayStreamingMode.DeviceOptimized.resolutionRate())
                    .localize().replacingOccurrences(of: "%2$s", with: PCDisplayStreamingMode.DeviceOptimized.refreshRate())
            default:
                // For duplicate mode or any other case, use the default image
                currentDisplayModeImage = IsIpad() ? "streaming_duplicate_screen_ipad" : "streaming_duplicate_screen"
                displayModelDescription =  "Your PC’s connected display will be streamed to your [iPhone/iPad].".localize().replacingOccurrences(of: "[iPhone/iPad]", with: deviceType)
            }
        }
    }
    @Published var currentDisplayModeImage: String = "streaming_duplicate_screen"
    @Published var displayModelDescription: String = ""

    @Published var isAlreadyShowDownloadNexus = false
    
    var noLocalNetworkPermissionAlert: SwiftAlertView? = nil
    
    @Published var bottomButtons: [TutorialBottomButtonType] = [.accept]
    
    let dismissTutorial: ()->Void
    
    let onTermsOfServiceClicked: ()->Void
    
    let onPrivacyPolicyClicked: ()->Void
    
    let localNetworkAuthorization = LocalNetworkAuthorization()
    
    let deviceType = IsIpad() ? "iPad" : "iPhone"
    
    init(dismissTutorial: @escaping ()->Void, onTermsOfServiceClicked: @escaping ()->Void, onPrivacyPolicyClicked: @escaping ()->Void) {
        self.dismissTutorial = dismissTutorial
        self.onTermsOfServiceClicked = onTermsOfServiceClicked
        self.onPrivacyPolicyClicked = onPrivacyPolicyClicked

        setupLifeCycleNotification()
        isRequestedLocalNetworkPermission = RzUtils.isRequestedLocalNetworkPermission()
        isAcceptedTOS = RzUtils.isAcceptedTOS()
        isDownloadNexus = RzUtils.checkIsNexusInstalled()
        isGrantedLocalNetworkPermission = RzUtils.isGrantedLocalNetworkPermission()
        isAlreadySetDisplayMode = RzUtils.isAlreadySetDisplayMode()
        isAlreadyShowDownloadNexus = RzUtils.isAlreadyShowDownloadNexus()
        
        tutorialStep = getFirstStep()
        
        currentDisplayMode = TutorialPCDisplayMode(rawValue: NeuronFrameSettingsViewModel.shared().frameSettings.displayMode) ?? .phoneOnly
        
    }
    //MARK: LifeCycle
    func setupLifeCycleNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        print("Tutorial - Application did become active")
        if RzUtils.isRequestedLocalNetworkPermission() {
            requestLocalNetworkPermission()
        }
        
//        handelStart()
    }
    
    func requestLocalNetworkPermission() {
        RzUtils.setRequestedLocalNetworkPermission()
        isRequestedLocalNetworkPermission = true
        
        localNetworkAuthorization.requestAuthorization(isNeedToResetCompletionBlock: false) { [weak self] result in
            guard let strongSelf = self else { return }
            
            if UIApplication.shared.applicationState != .active {
                return
            }
            
            strongSelf.isGrantedLocalNetworkPermission = result
            RzUtils.setGrantedLocalNetworkPermission(result)
            SettingsRouter.shared.localNetworkAuthSubject.send(result)
            
            if let callback = SettingsRouter.shared.grantedLocalNetworkPermissionCallBack {
                callback()
            }
            
            if strongSelf.tutorialStep == .permission {
//                strongSelf.updatePermissionView(isGrantedLocalNetworkPermission: result)
            }
            
            Logger.debug("requestAuthorization result: \(result)")
        }
    }
    
    func getFirstStep() -> TutorialStep {
        print("requestAuthorization result: \(isRequestedLocalNetworkPermission), \(isGrantedLocalNetworkPermission)")
        
        if !isAcceptedTOS {
            return .tos
        } else if !isRequestedLocalNetworkPermission || !isGrantedLocalNetworkPermission {
            return .permission
        } else if !isDownloadNexus && !isAlreadyShowDownloadNexus {
            return .downloadNexus
        } else {
            return .displayMode
        }
    }
    
    func nextStep() -> TutorialStep {
        switch tutorialStep {
        case .tos:
            if !RzUtils.isGrantedLocalNetworkPermission() {
                return .permission
            } else if !isDownloadNexus && !isAlreadyShowDownloadNexus {
                return .downloadNexus
            } else if !isAlreadySetDisplayMode {
                return .displayMode
            } else {
                return .done
            }
        case .permission:
            if !isDownloadNexus && !isAlreadyShowDownloadNexus {
                return .downloadNexus
            } else if !isAlreadySetDisplayMode && !RzUtils.isNeedContinueLaunchGame(){
                return .displayMode
            } else {
                return .done
            }
        case .downloadNexus:
            return isAlreadySetDisplayMode ? .done : .displayMode
        default:
            return .done
        }
    }
    
    func onTOSAcceptButtonClicked() {
        RzUtils.setAcceptedTOS()
        let nextStep = self.nextStep()
        if nextStep == .done {
            dismissTutorial()
        } else {
            tutorialStep = nextStep
        }  
    }
    
    func onPermissionContinueButtonClicked() {
        let nextStep = self.nextStep()
        if nextStep == .done {
            dismissTutorial()
        } else {
            tutorialStep = nextStep
        }
    }
    
    func onPermissionAllowButtonClicked() {
        if isRequestedLocalNetworkPermission && !isGrantedLocalNetworkPermission {
            showNoLocalNetworkPermissionAlert()
        } else {
            requestLocalNetworkPermission()
        }
    }
    
    func onDownloadButtonClicked() {
        onDownloadPageSkipButtonClicked()
        if let url = URL(string: "https://apps.apple.com/in/app/razer-nexus/id1565916457") {
            UIApplication.shared.open(url)
        }
    }
    
    func onDownloadPageSkipButtonClicked() {
        let nextStep = self.nextStep()
        if nextStep == .done {
            dismissTutorial()
        } else {
            tutorialStep = nextStep
        }
        RzUtils.setAlreadyShowDownloadNexus()
    }
    
    func onDoneButtonClicked() {
        RzUtils.setAlreadySetDisplayMode()
        NeuronFrameSettingsViewModel.shared().updateDisplayMode(PCDisplayStreamingMode(rawValue: currentDisplayMode.rawValue) ?? .DeviceOptimized)
        dismissTutorial()
    }
    
    //MARK: - No Local Network Permission Alert
    
    func showNoLocalNetworkPermissionAlert() {
        guard noLocalNetworkPermissionAlert == nil else {
            self.dismissNoLocalNetworkPermissionAlert()
            return
        }
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
                                                       colorScheme: .dark)
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
        noLocalNetworkPermissionAlert = nil
    }
    
    func executeConfirmActionForNoLocalNetworkPermissionAlert() {
        dismissNoLocalNetworkPermissionAlert()
    }
    
    // MARK: - Game Controller Integration
    
    func onGameControllerButtonAClicked() {
        
        if let noLocalNetworkPermissionAlert = self.noLocalNetworkPermissionAlert, noLocalNetworkPermissionAlert.isShowing {
            executeConfirmActionForNoLocalNetworkPermissionAlert()
            return
        }
        
        switch tutorialStep {
        case .tos:
            onTOSAcceptButtonClicked()
        case .permission:
            if isRequestedLocalNetworkPermission && !isGrantedLocalNetworkPermission {
                showNoLocalNetworkPermissionAlert()
            } else if isGrantedLocalNetworkPermission {
                onPermissionContinueButtonClicked()
            } else {
                onPermissionAllowButtonClicked()
            }
        case .downloadNexus:
            onDownloadButtonClicked()
        case .displayMode:
            onDoneButtonClicked()
        default:
            break
        }
    }
    
    func onGameControllerButtonYClicked() {
        if tutorialStep == .downloadNexus {
            onDownloadPageSkipButtonClicked()
        }
    }
    
    func onGameControllerLeftClicked() {
        if tutorialStep == .displayMode {
            switch currentDisplayMode {
            case .duplicate:
                currentDisplayMode = .phoneOnly
            default:
                break
            }
        }
    }
    
    func onGameControllerRightClicked() {
        if tutorialStep == .displayMode {
            switch currentDisplayMode {
            case .phoneOnly:
                currentDisplayMode = .duplicate
            default:
                break
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

enum TutorialStep: Int {
    case tos
    case permission
    case downloadNexus
    case displayMode
    case done
}

// TutorialPCDisplayMode 枚举
enum TutorialPCDisplayMode: Int {
    case duplicate
    case separateScreen
    case phoneOnly
}


enum TutorialBottomButtonType: Int {
    case `continue`
    case done
    case accept
    case skip
    case allow
    case download
}
