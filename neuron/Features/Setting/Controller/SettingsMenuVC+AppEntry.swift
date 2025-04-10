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
    
    func debugModeUpdate() {
        updateMenuArray()
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        setupView()
        reloadContentView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
}

