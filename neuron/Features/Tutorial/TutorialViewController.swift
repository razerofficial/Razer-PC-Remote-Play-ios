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
import SwiftBridging
import UIKit
import SwiftUI

let TermOfServiceUrl = "https://www.razer.com/legal/services-and-software-terms-of-use-mobile"
let PrivacyPolicyUrl = "https://www.razer.com/legal/customer-privacy-policy-mobile"
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

class TutorialViewController: RZBaseVC, RZHandleResponderDelegate {
    //MARK: TOS & Welcome page
    @IBOutlet var welcomeView: UIView!
    @IBOutlet weak var welcomeTitleLabel: UILabel!
    @IBOutlet weak var welcomeSubtitleLabel: UILabel!
    @IBOutlet weak var acceptButtonTitle: UILabel!
    @IBOutlet weak var tosButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    //MARK: Permission page
    @IBOutlet var permissionView: UIView!
    @IBOutlet weak var tickImageView: UIImageView! // show when granted permission
    @IBOutlet weak var allowButtonView: RZView!
    @IBOutlet weak var permissionBottomButtonTitle: UILabel!
    @IBOutlet weak var permissionBottomButtonName: UILabel!
    @IBOutlet var permissionAlertView: UIView!
    @IBOutlet weak var permissionBottomButtonView: RZView!
    @IBOutlet weak var permissionContentLabel: UILabel!
    @IBOutlet weak var permissionTitleLabel: UILabel!
    @IBOutlet weak var permissionSubtitleLabel: UILabel!
    @IBOutlet weak var allowButtonTitle: UILabel!
    @IBOutlet weak var imageTextLabel: UILabel!
    @IBOutlet weak var continueButtonLabel: UILabel!
    @IBOutlet weak var permissionAlertTitleLabel: UILabel!
    @IBOutlet weak var permissionAlertContentLabel: UILabel!
    @IBOutlet weak var permissionAlertButtonLabel: UIButton!
    
    
    //MARK: Download Nexus page
    @IBOutlet var downloadNexusView: UIView!
    @IBOutlet weak var downloadTitleLabel: UILabel!
    @IBOutlet weak var downloadSubtitleLabel: UILabel!
    @IBOutlet weak var downloadSkipButtonLabel: UILabel!
    @IBOutlet weak var downloadButtonLabel: UILabel!
    
    //MARK: PC model Page
    @IBOutlet var tutorialDisplayModeView: UIView!
    @IBOutlet weak var displayModeImageView: UIImageView!
    @IBOutlet weak var duplicateDisplayModeView: RZView!
    @IBOutlet weak var separateDisplayModeView: RZView!
    @IBOutlet weak var phoneOnlyDisplayModeView: RZView!
    @IBOutlet weak var duplicateSelectedImageView: UIImageView!
    @IBOutlet weak var separateSelectedImageView: UIImageView!
    @IBOutlet weak var phoneOnlySelectedImageView: UIImageView!
    @IBOutlet weak var displayModelContentLabel: UILabel!
    @IBOutlet weak var displayModeTitleLabel: UILabel!
    @IBOutlet weak var phoneOnlyTitleLabel: UILabel!
    @IBOutlet weak var separateTitleLabel: UILabel!
    @IBOutlet weak var duplicateTitleLabel: UILabel!
    @IBOutlet weak var doneButtonLabel: UILabel!
    @IBOutlet weak var phoneOnlyIconImageView: UIImageView!
    
    //MARK: other property
    var isGrantedLocalNetworkPermission: Bool = false
    var isRequestedLocalNetworkPermission: Bool = false
    var isAcceptedTOS: Bool = false
    var isDownloadNexus: Bool = false
    var isAlreadySetDisplayMode: Bool = false
    var tutorialStep: TutorialStep = .tos
    var currentStepView: UIView?
    var tutorialCompeletedCount: Int = 0
    var isShowPermissionAlert: Bool = false
    var currentDisplayMode: TutorialPCDisplayMode = .duplicate
    var isAlreadyShowDownloadNexus = false
    
    var tutorialDismissCallBack:(()->Void)? = nil
    
    let deviceType = IsIpad() ? "iPad" : "iPhone"
    
    private static let tutorialXibName = {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "TutorialViewController_iPadMini"
        } else {
            return "TutorialViewController"
        }
    }()
    
    static func create() -> TutorialViewController {
        return TutorialViewController(nibName: TutorialViewController.tutorialXibName, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLifeCycleNotification()
        
        isRequestedLocalNetworkPermission = RzUtils.isRequestedLocalNetworkPermission()
        isAcceptedTOS = RzUtils.isAcceptedTOS()
        isDownloadNexus = RzUtils.checkIsNexusInstalled()
        tutorialCompeletedCount = RzUtils.getTutorialCompletedCount()
        isGrantedLocalNetworkPermission = RzUtils.isGrantedLocalNetworkPermission()
        isAlreadySetDisplayMode = RzUtils.isAlreadySetDisplayMode()
        isAlreadyShowDownloadNexus = RzUtils.isAlreadyShowDownloadNexus()
        
        separateDisplayModeView.isHidden = isShowSeparateScreenDisplayMode ? false : true
        
        tutorialStep = getFirstStep()
        currentStepView = getStepView(step: tutorialStep)
        if let currentStepView = currentStepView {
            view.addSubview(currentStepView)
        }
        
        
        welcomeTitleLabel.text = "Welcome to &applabel;".localize().kStringByReplaceString(replaceStr:"&applabel;",willReplaceStr:"Razer PC Remote Play")
        welcomeSubtitleLabel.text = "To continue using Razer software and services you must first accept the Terms of Service and Privacy Policy agreement".localize()
        acceptButtonTitle.text = "Accept".localize().uppercased()
        tosButton.setTitle("Terms of Service".localize(), for: .normal)
        privacyPolicyButton.setTitle("Privacy Policy".localize(), for: .normal)
        
        permissionContentLabel.text = "To unlock additional functionality, Razer PC Remote Play requires the following permissions:".localize()
        permissionTitleLabel.text = "Local Network".localize()
        permissionSubtitleLabel.text = "Enable seamless streaming between your PC and Nexus.".localize()
        allowButtonTitle.text = "ALLOW".localize().uppercased()
        imageTextLabel.text = "Allow Remote Play to access this device’s network.".localize()
        permissionAlertTitleLabel.text = "Enable Local Network Access".localize()
        permissionAlertContentLabel.text = "To enable seamless streaming between your PC and Remote Play, please allow Local Network access. Go to Settings > Privacy & Security > Local Network and enable access for Remote Play.".localize()
        permissionAlertButtonLabel.setTitle("OK".localize().uppercased(), for: .normal)
        
        downloadTitleLabel.text = "Download &nexus;".localize().kStringByReplaceString(replaceStr: "&nexus;", willReplaceStr: "Razer Nexus")
        downloadSubtitleLabel.text = "Remote Play is designed to enhance PC gaming on your mobile device through seamless integration with Razer Nexus.".localize()
        downloadSkipButtonLabel.text = "Skip".localize().uppercased()
        downloadButtonLabel.text = "Download".localize().uppercased()
        
        displayModeTitleLabel.text = "Streaming Display Mode".localize()
        phoneOnlyTitleLabel.text = "[iPhone/iPad] Optimized".localize().replacingOccurrences(of: "[iPhone/iPad]", with: deviceType)
        separateTitleLabel.text = "Separate Screen\n".localize()
        duplicateTitleLabel.text = "Duplicate PC Display".localize()
        doneButtonLabel.text = "Done".localize().uppercased()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
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
        
        handelStart()
        separateDisplayModeView.isHidden = isShowSeparateScreenDisplayMode ? false : true
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
    
    // MARK: - Get Step View
    func getStepView(step: TutorialStep) -> UIView {
        let viewFrame = UIApplication.shared.keyWindow?.bounds ?? .zero
        switch step {
        case .tos:
            welcomeView.frame = viewFrame
            return welcomeView
        case .permission:
            permissionView.frame = viewFrame
            permissionBottomButtonView.isHidden = true
            return permissionView
        case .downloadNexus:
            downloadNexusView.frame = viewFrame
            return downloadNexusView
        case .displayMode:
            tutorialDisplayModeView.frame = viewFrame
            setupDisplayModeView()
            return tutorialDisplayModeView
        default:
            return UIView()
        }
    }
    
    func updateTutorialStepView(_ nextStep: TutorialStep) {
        currentStepView?.removeFromSuperview()
        
        tutorialStep = nextStep
        currentStepView = getStepView(step: tutorialStep)
        if let currentStepView = currentStepView {
            view.addSubview(currentStepView)
        }
    }
    
    func reset() {
        if tutorialStep != getFirstStep() {
            updateTutorialStepView(getFirstStep())
        }
    }
    
    func setupDisplayModeView() {
        currentDisplayMode = TutorialPCDisplayMode(rawValue: NeuronFrameSettingsViewModel.shared().frameSettings.displayMode) ?? .phoneOnly
        switch currentDisplayMode {
        case .duplicate:
            updateDuplicateModeView()
        case .separateScreen:
            updateSeparateModeView()
        case .phoneOnly:
            updatePhoneOnlyModeView()
        default:
            updateDuplicateModeView()
        }
    }
    
    // MARK: - Button Actions
    @IBAction func onTermsOfServiceClicked(_ sender: Any) {
        let webVC = WebVC()
        webVC.url = TermOfServiceUrl.toUrl()!
        webVC.lastHandel = self.handel
        webVC.webViewTitle = "Terms of Service".localize()
        present(webVC, animated: true, completion: nil)
    }
    
    @IBAction func onPrivacyPolicyClicked(_ sender: Any) {
        let webVC = WebVC()
        webVC.url = PrivacyPolicyUrl.toUrl()!
        webVC.lastHandel = self.handel
        webVC.webViewTitle = "Privacy Policy".localize()
        present(webVC, animated: true, completion: nil)
    }
    
    @IBAction func onTosAcceptClicked(_ sender: Any) {
        RzUtils.setAcceptedTOS()
        let nextStep = self.nextStep()
        if nextStep == .done {
            dismissTutorial()
        } else {
            updateTutorialStepView(nextStep)
        }
    }
    
    // MARK: - Display Mode Views
    @IBAction func onDuplicateModeButtonClicked(_ sender: Any) {
        updateDuplicateModeView()
    }
    
    func updateDuplicateModeView() {
        currentDisplayMode = .duplicate
        duplicateDisplayModeView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        separateDisplayModeView.backgroundColor = Color.hex(0x222222).uiColor()
        phoneOnlyDisplayModeView.backgroundColor = Color.hex(0x222222).uiColor()
        
        duplicateSelectedImageView.image = UIImage(named: "tutorial_pc_model_selected")
        separateSelectedImageView.image = UIImage(named: "tutorial_pc_model_unselected")
        phoneOnlySelectedImageView.image = UIImage(named: "tutorial_pc_model_unselected")
        phoneOnlyIconImageView.image = UIImage(named: "tutorial_pc_phone_only")
        
        displayModelContentLabel.text = "Your PC’s connected display will be streamed to your [iPhone/iPad] ".localize().replacingOccurrences(of: "[iPhone/iPad]", with: deviceType)
        
        displayModeImageView.image = UIImage(named: "streaming_duplicate_screen")
    }
    
    @IBAction func onSeparateModeButtonClicked(_ sender: Any) {
        updateSeparateModeView()
    }
    
    func updateSeparateModeView() {
        currentDisplayMode = .separateScreen
        duplicateDisplayModeView.backgroundColor = Color.hex(0x222222).uiColor()
        separateDisplayModeView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        phoneOnlyDisplayModeView.backgroundColor = Color.hex(0x222222).uiColor()
        
        duplicateSelectedImageView.image = UIImage(named: "tutorial_pc_model_unselected")
        separateSelectedImageView.image = UIImage(named: "tutorial_pc_model_selected")
        phoneOnlySelectedImageView.image = UIImage(named: "tutorial_pc_model_unselected")
        phoneOnlyIconImageView.image = UIImage(named: "tutorial_pc_phone_only")
        
        displayModelContentLabel.text = "Extend your PC display to your phone for seamless multitasking. Use your phone as a second screen to view different content, ideal for productivity and gaming on the go.".localize()
        
        displayModeImageView.image = UIImage(named: "streaming_separate_screen")
    }
    
    @IBAction func onPhoneOnlyModeButtonClicked(_ sender: Any) {
        updatePhoneOnlyModeView()
    }
    
    func updatePhoneOnlyModeView() {
        currentDisplayMode = .phoneOnly
        duplicateDisplayModeView.backgroundColor = Color.hex(0x222222).uiColor()
        separateDisplayModeView.backgroundColor = Color.hex(0x222222).uiColor()
        phoneOnlyDisplayModeView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        
        duplicateSelectedImageView.image = UIImage(named: "tutorial_pc_model_unselected")
        separateSelectedImageView.image = UIImage(named: "tutorial_pc_model_unselected")
        phoneOnlySelectedImageView.image = UIImage(named: "tutorial_pc_model_selected")
        phoneOnlyIconImageView.image = UIImage(named: "tutorial_pc_phone_only_dark")
        
        displayModelContentLabel.text = "Your PC will create a virtual display matching your [iPhone/iPad]’s resolution and refresh rate of %1$s at %2$sHz and stream it to your [iPhone/iPad].\n\nAny screen connected to your PC will be temporarily disabled while streaming."
            .localize().replacingOccurrences(of: "[iPhone/iPad]", with: deviceType)
            .localize().replacingOccurrences(of: "%1$s", with: PCDisplayStreamingMode.DeviceOptimized.resolutionRate())
            .localize().replacingOccurrences(of: "%2$s", with: PCDisplayStreamingMode.DeviceOptimized.refreshRate())
        
        displayModeImageView.image = UIImage(named: "streaming_phone_only")
    }
    
    @IBAction func onDisplayModeDoneButtonClicked(_ sender: Any) {
        RzUtils.setAlreadySetDisplayMode()
//        NeuronFrameSettingsViewModel.shared().frameSettings.displayMode = currentDisplayMode.rawValue
//        NeuronFrameSettingsViewModel.shared().saveSettings()
        NeuronFrameSettingsViewModel.shared().updateDisplayMode(PCDisplayStreamingMode(rawValue: currentDisplayMode.rawValue) ?? .DeviceOptimized)
        dismissTutorial()
    }
    
    func dismissTutorial() {
        RzUtils.setTutorialCompleted(tutorialCompeletedCount + 1)
        handel.stopTracking()
        lastHandel?.startTracking()
        lastHandel?.reloadCallBack?()
        tutorialDismissCallBack?()
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func onPermissionBottomButtonClicked(_ sender: Any) {
        let nextStep = self.nextStep()
        if nextStep == .done {
            dismissTutorial()
        } else {
            updateTutorialStepView(nextStep)
        }
    }
    
    @IBAction func onDownloadPageSkipClicked(_ sender: Any) {
        let nextStep = self.nextStep()
        if nextStep == .done {
            dismissTutorial()
        } else {
            updateTutorialStepView(nextStep)
        }
        RzUtils.setAlreadyShowDownloadNexus()
    }
    
    @IBAction func onDownloadButtonClicked(_ sender: Any) {
        onDownloadPageSkipClicked(UIButton())
        if let url = URL(string: "https://apps.apple.com/in/app/razer-nexus/id1565916457") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func onLocalNetworkPermissionAllowClicked(_ sender: Any) {
        if isRequestedLocalNetworkPermission {
            isShowPermissionAlert = true
            permissionAlertView.frame = UIApplication.shared.keyWindow?.bounds ?? .zero
            view.addSubview(permissionAlertView)
        } else {
            requestLocalNetworkPermission()
        }
    }
    
    @IBAction func onPermissionAlertOkClicked(_ sender: Any) {
        permissionAlertView?.removeFromSuperview()
        isShowPermissionAlert = false;
    }
    
    func requestLocalNetworkPermission() {
        RzUtils.setRequestedLocalNetworkPermission()
        isRequestedLocalNetworkPermission = true
        
        let localNetworkAuthorization = LocalNetworkAuthorization()
        localNetworkAuthorization.requestAuthorization { [weak self] result in
            guard let strongSelf = self else { return }
            
            if UIApplication.shared.applicationState != .active {
                return
            }
            
            strongSelf.isGrantedLocalNetworkPermission = result
            RzUtils.setGrantedLocalNetworkPermission(result)
            
            if let callback = SettingsRouter.shared.grantedLocalNetworkPermissionCallBack {
                callback()
            }
            
            if strongSelf.tutorialStep == .permission {
                strongSelf.updatePermissionView(isGrantedLocalNetworkPermission: result)
            }
            
            Logger.debug("requestAuthorization result: \(result)")
        }
    }
    
    func updatePermissionView(isGrantedLocalNetworkPermission: Bool) {
        if isGrantedLocalNetworkPermission {
            permissionBottomButtonView.isHidden = false
            permissionBottomButtonName.text = "A"
            permissionBottomButtonTitle.text = "Continue".localize().uppercased()
            tickImageView.isHidden = false
            allowButtonView.isHidden = true
            onPermissionAlertOkClicked(self)
        } else {
            //hide skip button BIA-1342
            permissionBottomButtonView.isHidden = true
//            permissionBottomButtonName.text = "Y"
//            permissionBottomButtonTitle.text = "SKIP"
            tickImageView.isHidden = true
            allowButtonView.isHidden = false
        }
    }
    
    // MARK: - Game Controller Integration
    
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .A:
            onGameControllerButtonAClicked()
        case .Y:
            onGameControllerButtonYClicked()
        case .left:
            onGameControllerLeftClicked()
        case .right:
            onGameControllerRightClicked()
        default:
            break
        }
    }
    
    func onGameControllerButtonAClicked() {
        switch tutorialStep {
        case .tos:
            onTosAcceptClicked(UIButton())
        case .permission:
            if isShowPermissionAlert {
                // Handle permission alert
            } else if isGrantedLocalNetworkPermission {
                onPermissionBottomButtonClicked(UIButton())
            } else {
                onLocalNetworkPermissionAllowClicked(UIButton())
            }
        case .downloadNexus:
            onDownloadButtonClicked(UIButton())
        case .displayMode:
            onDisplayModeDoneButtonClicked(UIButton())
        default:
            break
        }
    }
    
    func onGameControllerButtonYClicked() {
        if tutorialStep == .permission && !isShowPermissionAlert && !isGrantedLocalNetworkPermission {
            onPermissionBottomButtonClicked(UIButton())
        } else if tutorialStep == .downloadNexus {
            onDownloadPageSkipClicked(UIButton())
        }
    }
    
    func onGameControllerLeftClicked() {
        if currentStepView == tutorialDisplayModeView {
            switch currentDisplayMode {
            case .separateScreen:
                updateDuplicateModeView()
            case .duplicate:
                updatePhoneOnlyModeView()
            default:
                break
            }
        }
    }
    
    func onGameControllerRightClicked() {
        if currentStepView == tutorialDisplayModeView {
            switch currentDisplayMode {
            case .phoneOnly:
                updateDuplicateModeView()
            case .duplicate:
                if isShowSeparateScreenDisplayMode {
                    updateSeparateModeView()
                } 
            default:
                break
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
