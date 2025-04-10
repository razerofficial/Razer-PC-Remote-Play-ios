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
import SnapKit
import SwiftBridging
extension NSNotification.Name {
    static let START_STREAMING_NEED_SHOW_TUTORIAL = Notification.Name(rawValue: "START_STREAMING_NEED_SHOW_TUTORIAL")
}


class DashboardVC: RZBaseVC {
    
    let dashboardViewModel = DashboardViewModel()
    let localNetworkAuthorization = LocalNetworkAuthorization()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ControllerInputTracker.shared.startTracking()

        // Do any additional setup after loading the view.
        
        //Swift-UI
        let contentView = DashboardView(viewModel: dashboardViewModel )
        let hostingController = UIHostingController(rootView: contentView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.snp.makeConstraints { make in
            make.left.top.bottom.right.equalTo(0)
        }
        hostingController.didMove(toParent: self)
        
        title = "Home".localize()
        //
        maybeGotoTutorialPage()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willStartStreaming), name: .START_STREAMING_NEED_SHOW_TUTORIAL, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dashboardViewModel.isDashboardAppear = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppStoreReviewHandler.shared.checkIsStartAppReiew()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dashboardViewModel.isDashboardAppear = false
    }
    
    @objc func willStartStreaming() {
        maybeGotoTutorialPage()
    }
    
    func maybeGotoTutorialPage() {
        if let tutorialVC = UIApplication.shared.topMostViewController() as? TutorialViewController {
            tutorialVC.reset()
            return
        }
        if !RzUtils.isAcceptedTOS() {
            gotoTutorialPage()
        } else if !RzUtils.isRequestedLocalNetworkPermission() {
            gotoTutorialPage()
        } else {
//            let localNetworkAuthorization = LocalNetworkAuthorization()
            localNetworkAuthorization.requestAuthorization(isNeedToResetCompletionBlock: false) { [weak self] result in
                Logger.debug("maybeGotoTutorialPage requestAuthorization result:\(result)")
                RzUtils.setGrantedLocalNetworkPermission(result)
                SettingsRouter.shared.localNetworkAuthSubject.send(result)
                SettingsRouter.shared.grantedLocalNetworkPermissionCallBack?()
                if !result ||
                    (!RzUtils.checkIsNexusInstalled() && !RzUtils.isAlreadyShowDownloadNexus()) ||
                    (!RzUtils.isAlreadySetDisplayMode() && !RzUtils.isNeedContinueLaunchGame()) {
                    self?.gotoTutorialPage()
                }
            }
        }
    }
    
    func gotoTutorialPage() {
        dashboardViewModel.isDashboardAppear = false
        dashboardViewModel.dismissNoLocalNetworkPermissionAlert()
        let tutorialVC = TutorialViewController.create()
        tutorialVC.modalPresentationStyle = .fullScreen
        tutorialVC.tutorialDismissCallBack = {
            if RzUtils.isNeedContinueLaunchGame(){
                SettingsRouter.shared.showStreamLoadingView()
                RzApp.shared().startStreaming()
                RzUtils.setNeedContinueLaunchGame(false)
            }
            self.dashboardViewModel.dismissNoLocalNetworkPermissionAlert()
            self.dashboardViewModel.isDashboardAppear = true
            
        }
        self.present(tutorialVC, animated: false, completion: nil)
    }
    
}
