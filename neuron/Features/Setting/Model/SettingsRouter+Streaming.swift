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
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI
import StoreKit
import SwiftBridging

extension SettingsRouter {
    @objc func prepareNavigateToStreamViewController(_ app: TemporaryApp, shouldReturnToNexus: Bool = true) {
        self.navigateToStreamVCSubject.onNext((app, shouldReturnToNexus))
    }
    
    @objc func navigateToStreamViewController(_ app: TemporaryApp, shouldReturnToNexus: Bool = true) {
        print("navigateToStreamViewController --\(Date())--\(app.name)")
        self.prepareToStreamApp(app)
        self.localNetworkAuthorization = LocalNetworkAuthorization()
        self.localNetworkAuthorization.requestAuthorization { [weak self] result in
            if result {
                Logger.info("requestAuthorization result:\(result)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?._navigateToStreamViewController(app, shouldReturnToNexus: shouldReturnToNexus)
                }
            }
        }
        RzUtils.setRequestedLocalNetworkPermission()
    }
    
    @objc func showStreamLoadingView() {
        if self.startStreamingLoadingView == nil {
            self.startStreamingLoadingView = Bundle.main.loadNibNamed("StreamLoadingView", owner: nil)?.first as? StreamLoadingView
            self.startStreamingLoadingView?.frame = UIApplication.shared.keyWindow?.bounds ?? .zero
            UIApplication.shared.keyWindow?.addSubview(self.startStreamingLoadingView!)
        }
    }
    
    @objc func hideStreamLoadingView() {
        startStreamingLoadingView?.removeFromSuperview()
        startStreamingLoadingView = nil
    }
}

extension SettingsRouter {
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .retryStreamingNotification, object: nil, queue: .main) { [weak self]  not in
            self?.retryStreaming(not)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self]  not in
            self?.dimissDownloadOverlay()
        }
        
//        NotificationCenter.default.addObserver(forName: .debugModeUpdateNotification, object: nil, queue: .main) { [weak self]  not in
//            self?.debugModeUpdate()
//        }
        
    }
    
    func retryStreaming(_ not: Notification) {
        let storyboard = UIStoryboard.init(name: "StreamFrame", bundle: nil)
        
        let streamFrameVC: RZStreamFrameViewController? = storyboard.instantiateViewController(withIdentifier: "StreamFrameViewController") as? RZStreamFrameViewController
        streamFrameVC?.haveRetry = true
        
        streamFrameVC?.streamConfig = streamConfig
        if let streamFrameVC = streamFrameVC {
            navigationController?.pushViewController(streamFrameVC, animated: false)
        }
    }
    
    /*
     *case1:app resign active
     *case2:user click on the blank space
     *case3:view disappear
     */
    func dimissDownloadOverlay() {
        DownloadOverlayManager.shared.dismissOverlay()
    }
    
//    func debugModeUpdate() {
//        updateMenuArray()
//        for subview in view.subviews {
//            subview.removeFromSuperview()
//        }
//        setupView()
//        reloadContentView()
//    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        dimissDownloadOverlay()
//    }
    
    
//    func maybeGotoTutorialPage() {
//        if !RzUtils.isAcceptedTOS() {
//            gotoTutorialPage()
//        } else if !RzUtils.isRequestedLocalNetworkPermission() {
//            gotoTutorialPage()
//        } else {
//            let localNetworkAuthorization = LocalNetworkAuthorization()
//            localNetworkAuthorization.requestAuthorization { [weak self] result in
//                Logger.debug("maybeGotoTutorialPage requestAuthorization result:\(result)")
//                RzUtils.setGrantedLocalNetworkPermission(result)
//                SettingsRouter.shared.grantedLocalNetworkPermissionCallBack?()
//                if !result || !RzUtils.checkIsNexusInstalled() || !RzUtils.isAlreadySetDisplayMode() {
//                    self?.gotoTutorialPage()
//                }
//            }
//        }
//    }

    func prepareToStreamApp( _ app: TemporaryApp) {
        streamConfig = RzUtils.streamConfig(forStreamApp: app)
    }

    func _navigateToStreamViewController(_ app: TemporaryApp, shouldReturnToNexus: Bool = true) {
        let storyboard = UIStoryboard(name: "StreamFrame", bundle: nil)
        if let streamFrameVC = storyboard.instantiateViewController(withIdentifier: "StreamFrameViewController") as? RZStreamFrameViewController {
            streamFrameVC.streamConfig = streamConfig
            streamFrameVC.shouldReturnToNexus = shouldReturnToNexus
            self.navigationController?.pushViewController(streamFrameVC, animated: false)
            hideStreamLoadingView()
            startingStream = false
        }
    }

    func showNexusNotInstalledAlert() {
        let alertController = UIAlertController(title: "Razer recommends that users download Razer Nexus, a launcher specifically designed for gaming, to enhance the use of Razer PC Remote Play", message: "", preferredStyle: .alert)

        weak var weakSelf = self
        let okAction = UIAlertAction(title: "Download Razer Nexus", style: .default) { _ in
            weakSelf?.showDownloadOverlay()
        }
        let cancelAction = UIAlertAction(title: "No Thanks", style: .cancel, handler: nil)

        alertController.addAction(cancelAction)
        alertController.addAction(okAction)

        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    func showDownloadOverlay() {
        if (self.isShowDownloadOverlay) {
            Logger.debug("isShowDownloadOverlay is YES, return...")
            return;
        }
        let nexusAppId = "1565916457"
        DownloadOverlayManager.shared.showOverlay(appid: nexusAppId, delegate: self)
    }
    
}

extension SettingsRouter {
    
    @objc func maybeLaunch(_ app: TemporaryApp, currentApp: TemporaryApp?) {
        //if new app is Desktop no need show alert
        if app.name?.uppercased() == "DESKTOP" || currentApp?.name?.uppercased() == "DESKTOP"{
//            DispatchQueue.global().async {
//                self.cancelHostRunningGame(app.host)
//            }
            prepareNavigateToStreamViewController(app)
            return
        }
        
        //if dont have running game, direct launch new game
        guard let currentAppId = currentApp?.id else {
            prepareNavigateToStreamViewController(app)
            return
        }
        
        if currentAppId.isEmpty || currentAppId == "0" {
            prepareNavigateToStreamViewController(app)
            return
        }
        
        if app.id == currentAppId {
            showRusumeGameAlert(app)
        } else {
            showLaunchNewGameAlert(app, currentApp: currentApp!)
        }
    }
    
    func showRusumeGameAlert(_ app: TemporaryApp) {
        if alertView != nil {
            hideAlertView()
        }
        
        alertViewCancelAction = { [weak self] in
            guard let self = self else { return }
            self.hideAlertView()
            DispatchQueue.global().async { [weak self] in
                self?.cancelHostRunningGame(app.host)
                DispatchQueue.main.async {
                    RzUtils.gotoNexus()
                    self?.hideStreamLoadingView()
                }
            }
        }
        
        alertViewConfirmAction = { [weak self] in
            guard let self = self else { return }
            self.hideAlertView()
            self.prepareNavigateToStreamViewController(app)
        }

        alertView = RZAlertView()
        alertView?.set(title: "Starting %@".localize().kStringByReplaceString(replaceStr:"%@",willReplaceStr:app.name ?? "")+"?", message: "%@ is already running, would you like to resume or quit the game? All unsaved data will be lost.".localize().kStringByReplaceString(replaceStr: "%@", willReplaceStr: app.name ?? ""), confirmButtonText: "Resume Session".localize(), cancelButtonText: "Quit and Dismiss".localize().localize(), confirmAction: {
            self.alertViewConfirmAction?()
        },cancelAction: {
            self.alertViewCancelAction?()
        })
        //self.view.addSubview(alertView!)
        UIApplication.shared.keyWindow?.addSubview(alertView!)
        alertView?.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        })
        alertView?.isHidden = false
    }
    
    func showLaunchNewGameAlert(_ app: TemporaryApp, currentApp: TemporaryApp) {
        if alertView != nil {
            hideAlertView()
        }
        
        alertViewCancelAction = { [weak self] in
            guard let self = self else { return }
            self.hideAlertView()
            RzUtils.gotoNexus()
            self.hideStreamLoadingView()
        }
        
        alertViewConfirmAction = { [weak self] in
            guard let self = self else { return }
            self.hideAlertView()
            DispatchQueue.global().async {
                self.cancelHostRunningGame(app.host)
                DispatchQueue.main.async {
                    self.prepareNavigateToStreamViewController(app)
                }
            }
        }
        var runningGameName = "running game"
        if let gameName = currentApp.name, gameName.isNotEmpty {
            runningGameName = gameName
        }
        
        alertView = RZAlertView()
        alertView?.set(title: "Start Streaming", message: "Would you like to quit \(runningGameName) first before starting \(app.name ?? "")? All unsaved data will be lost"
, confirmButtonText: "Quit and Start", cancelButtonText: "Cancel",confirmAction: {
            self.alertViewConfirmAction?()
        },cancelAction: {
            self.alertViewCancelAction?()
        })
        //self.view.addSubview(alertView!)
        UIApplication.shared.keyWindow?.addSubview(alertView!)
        alertView?.snp.makeConstraints({ make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        })
        alertView?.isHidden = false

    }
    
    func hideAlertView() {
        alertView?.isHidden = true
        alertView?.removeFromSuperview()
        alertView = nil
        alertViewConfirmAction = nil
        alertViewCancelAction = nil
    }
    
    func cancelHostRunningGame(_ appHost: TemporaryHost?) {
        let hMan = HttpManager.init(host: appHost)
        let quitResponse = HttpResponse();
        let quitRequest = HttpRequest(for: quitResponse, with:hMan?.newQuitAppRequest())
        hMan?.executeRequestSynchronously(quitRequest)
        print("Requesting :\(quitRequest?.request.url?.absoluteString ?? "") -- result:\(quitResponse.isStatusOk())")
    }
    
    @objc func dismissTutorialView() {
        if let tutorialVC = UIApplication.shared.topMostViewController() as? TutorialViewController {
            tutorialVC.dismiss(animated: false)
        }
    }
}

extension SettingsRouter: DownloadOverlayDelegate {
    func storeOverlayDidShow() {
        isShowDownloadOverlay = true
    }
    
    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: any Error) {
        isShowDownloadOverlay = false
    }
    
    func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        isShowDownloadOverlay = false
    }
}

