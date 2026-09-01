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


class TutorialViewController: RZBaseVC, RZHandleResponderDelegate {
    
    var tutorialDismissCallBack:(()->Void)? = nil
    
    var tutorialCompeletedCount: Int = 0
    
    var defaultStepViewSize = CGSize.zero
    
    fileprivate(set) var viewModel: TutorialViewModel?
    fileprivate(set) var hostingController: UIHostingController<TutorialView>?
//    let gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tutorialCompeletedCount = RzUtils.getTutorialCompletedCount()
        
        //Swift-UI
        let tutorialViewModel = TutorialViewModel(dismissTutorial: {
            self.dismissTutorial()
        }, onTermsOfServiceClicked: {
            self.onTermsOfServiceClicked()
        }, onPrivacyPolicyClicked: {
            self.onPrivacyPolicyClicked()
        })
        
        viewModel = tutorialViewModel
        let contentView = TutorialView(viewModel: tutorialViewModel)
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.view.backgroundColor = .clear
        self.hostingController = hostingController
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.snp.makeConstraints { make in
            make.left.top.bottom.right.equalTo(0)
        }
        hostingController.didMove(toParent: self)
        
//        //背景渐变色放到vc，使ui缩放不会影响背景
//        gradientLayer.frame = self.view.bounds
//        gradientLayer.colors = [UIColor(Color.hex(0x555555)).cgColor, UIColor.black.cgColor]
//        
//        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
//        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
//        
//        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }

    func reset() {
        guard let vm = viewModel else { return }
        if vm.tutorialStep != vm.getFirstStep() {
            vm.tutorialStep = vm.getFirstStep()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        hostingController?.view.bounds = view.bounds
//        gradientLayer.frame = view.bounds

//        scaleContentForStageManager()
    }
    
    private func scaleContentForStageManager() {
        guard let contentView = hostingController?.view else { return }

        // 原始設計的 Landscape 比例（例如 16:9）
        let originalAspectRatio: CGFloat = 16.0 / 9.0

        // 取得當前視窗的寬高
        let viewWidth = view.bounds.width
        let viewHeight = view.bounds.height
        let currentAspectRatio = viewWidth / viewHeight
        
        // **等比例縮放計算**
        let scaleFactor: CGFloat
//        let width = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
//        let height = min(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        if currentAspectRatio < originalAspectRatio {
            // **視窗變窄（Portrait 模式）時，依據 width 進行縮放**
            scaleFactor = viewWidth / UIScreen.main.bounds.width
        } else {
            // **維持 Landscape 模式時，依據 height 進行縮放**
            scaleFactor = viewHeight / UIScreen.main.bounds.height
        }

        // **應用縮放**
        hostingController?.view.bounds = UIScreen.main.bounds//CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))
        contentView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        contentView.center = CGPoint(x: viewWidth / 2, y: viewHeight / 2)
        
//        gradientLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: viewWidth, height: viewHeight))
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
        handelStart()
    }
    

    func onTermsOfServiceClicked() {
        #if !os(tvOS)
        let webVC = WebVC()
        webVC.modalPresentationStyle = .fullScreen
        webVC.url = TermOfServiceUrl.toUrl()!
        webVC.lastHandel = self.handel
        webVC.webViewTitle = "Terms of Service".localize()
        present(webVC, animated: true, completion: nil)
        #else
        // WebVC is not available on tvOS
        #endif
    }
    
    func onPrivacyPolicyClicked() {
        #if !os(tvOS)
        let webVC = WebVC()
        webVC.modalPresentationStyle = .fullScreen
        webVC.url = PrivacyPolicyUrl.toUrl()!
        webVC.lastHandel = self.handel
        webVC.webViewTitle = "Privacy Policy".localize()
        present(webVC, animated: true, completion: nil)
        #else
        // WebVC is not available on tvOS
        #endif
    }
    
    func dismissTutorial() {
        RzUtils.setTutorialCompleted(tutorialCompeletedCount + 1)
        handel.stopTracking()
        lastHandel?.startTracking()
        lastHandel?.reloadCallBack?()
        tutorialDismissCallBack?()
        dismiss(animated: false, completion: nil)
    }
    
    // MARK: - Game Controller Integration
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .A:
            viewModel?.onGameControllerButtonAClicked()
        case .Y:
            viewModel?.onGameControllerButtonYClicked()
        case .left:
            viewModel?.onGameControllerLeftClicked()
        case .right:
            viewModel?.onGameControllerRightClicked()
        default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
