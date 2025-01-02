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

class RZStreamFrameSettingsViewController: RZBaseVC {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let contentView = NeuronFrameSettingsView(viewModel: NeuronFrameSettingsViewModel.shared())
        let hostVC = UIHostingController(rootView: contentView)
        
        addChild(hostVC)
        view.addSubview(hostVC.view)
        hostVC.view.translatesAutoresizingMaskIntoConstraints = false
        hostVC.view.snp.makeConstraints { make in
            make.left.top.bottom.right.equalTo(0)
        }
        hostVC.didMove(toParent: self)
        view.backgroundColor = .black
        
        handel.reloadCallBack = { [self] in
            handel.delegate = self
            NeuronFrameSettingsViewModel.shared().highlightedUIComponent = .NeuronStreamingSettingsDisplayModeDeviceOptimized
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

}

extension RZStreamFrameSettingsViewController: RZHandleResponderDelegate {
    
    func handleClickButton(_ action: GamePadButton) {
     
        switch action {
        case .B:
            NeuronFrameSettingsViewModel.shared().highlightedUIComponent = .NeuronStreamingSettings
            handel.stopTracking()
            lastHandel?.startTracking()
            lastHandel?.reloadCallBack?()
        case .left:
            if NeuronFrameSettingsViewModel.shared().highlightedUIComponent != .NeuronStreamingSettingsDisplayModeSeparateScreen &&  NeuronFrameSettingsViewModel.shared().highlightedUIComponent != .NeuronStreamingSettingsDisplayModeVideoSettingsDisplay && NeuronFrameSettingsViewModel.shared().highlightedUIComponent != .NeuronStreamingSettingsBitrateSlider {
                NeuronFrameSettingsViewModel.shared().highlightedUIComponent = .NeuronStreamingSettings
                handel.stopTracking()
                lastHandel?.startTracking()
                lastHandel?.reloadCallBack?()
            }
        default:
            break
        }
        
        NeuronFrameSettingsViewModel.shared().handleClickButton(action)
    }
    
}
