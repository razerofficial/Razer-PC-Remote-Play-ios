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

@objc protocol DownloadOverlayDelegate {
    func storeOverlayDidShow()
    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: Error)
    func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext)
}

@objc class DownloadOverlayManager:NSObject {
    @objc static let shared = DownloadOverlayManager()
    weak var delegate: DownloadOverlayDelegate?
    
    @objc func showOverlay(appid: String, delegate overlayDelegate: DownloadOverlayDelegate) {
        delegate = overlayDelegate
        
        let config = SKOverlay.AppConfiguration(appIdentifier: appid, position: .bottom)
        print("config:\(config.debugDescription) appIdentifier:\(config.appIdentifier)")
        let overlay = SKOverlay(configuration: config)
        overlay.delegate = self
        guard let scene = UIApplication.shared.delegate?.window??.rootViewController?.view.window?.windowScene else {
            print("scene == nil")
            return
        }
        overlay.present(in: scene)
        
        delegate?.storeOverlayDidShow()
    }
    
    @objc func dismissOverlay() {
        if let scene = UIApplication.shared.delegate?.window??.rootViewController?.view.window?.windowScene {
            SKOverlay.dismiss(in: scene)
        }
    }
    
}

extension DownloadOverlayManager : SKOverlayDelegate {
    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: Error) {
        delegate?.storeOverlayDidFailToLoad(overlay, error: error)
    }
    
    
    func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        delegate?.storeOverlayDidFinishDismissal(overlay, transitionContext: transitionContext)
    }
}
