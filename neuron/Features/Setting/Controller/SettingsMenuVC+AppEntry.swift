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
import StoreKit


extension SettingsMenuVC {
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .retryStreamingNotification, object: nil, queue: .main) { [weak self]  not in
            self?.retryStreaming(not)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self]  not in
            self?.dimissDownloadOverlay()
        }
        
        NotificationCenter.default.addObserver(forName: .debugModeUpdateNotification, object: nil, queue: .main) { [weak self]  not in
            self?.debugModeUpdate()
        }
        
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
    
    func debugModeUpdate() {
        updateMenuArray()
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        setupView()
        reloadContentView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dimissDownloadOverlay()
    }

    func prepareToStreamApp( _ app: TemporaryApp) {
        streamConfig = RzUtils.streamConfig(forStreamApp: app)
    }
    
    func gotoTutorialPage() {
        let tutorialVC = TutorialViewController(nibName: "TutorialViewController", bundle: nil)
        tutorialVC.modalPresentationStyle = .fullScreen
        tutorialVC.lastHandel = self.handel
        self.present(tutorialVC, animated: false, completion: nil)
    }


    func _navigateToStreamViewController(_ app: TemporaryApp, shouldReturnToNexus: Bool = true) {
        let storyboard = UIStoryboard(name: "StreamFrame", bundle: nil)
        if let streamFrameVC = storyboard.instantiateViewController(withIdentifier: "StreamFrameViewController") as? RZStreamFrameViewController {
            streamFrameVC.streamConfig = streamConfig
            streamFrameVC.shouldReturnToNexus = shouldReturnToNexus
            self.navigationController?.pushViewController(streamFrameVC, animated: false)
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

        self.present(alertController, animated: true, completion: nil)
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

extension SettingsMenuVC: DownloadOverlayDelegate {
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
