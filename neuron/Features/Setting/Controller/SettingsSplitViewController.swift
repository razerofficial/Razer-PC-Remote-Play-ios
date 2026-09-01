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

@objcMembers
public class SettingsSplitViewController: UIHostingController<SettingsNavigationSplitView> {
    
    private let dismissCallback = DismissCallback()
    
    @objc public init() {
        let rootView = SettingsNavigationSplitView(onDismiss: dismissCallback)
        super.init(rootView: rootView)
        modalPresentationStyle = .fullScreen
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingsViewModel.shared.highlightedUIComponent = .NeuronStreamingMenu
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handelStart()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        handelStop()
        NotificationCenter.default.post(name: .settingsPageDismissNotification, object: nil)
        // use this custom UIHostingController to update SettingsRouter.shared.navigationController after change by settings
        SettingsRouter.shared.navigationController = SettingsRouter.shared.rootNavigationController
    }
    
    func handelStart() {
        SettingsViewModel.shared.delegate = SettingsViewModel.shared
        SettingsViewModel.shared.startTracking()
    }
    
    func handelStop() {
        SettingsViewModel.shared.stopTracking()
    }

    @MainActor
    @objc public required dynamic init?(coder aDecoder: NSCoder) {
        let rootView = SettingsNavigationSplitView(onDismiss: dismissCallback)
        super.init(coder: aDecoder, rootView: rootView)
    }
    
    @objc public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dismissCallback.callback = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        UIBarButtonItem.appearance(
            whenContainedInInstancesOf: [Self.self]
        ).setTitleTextAttributes([
            .foregroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 0.1)
        ], for: .normal)
        
        
        UIBarButtonItem.appearance(
            whenContainedInInstancesOf: [Self.self]
        ).setTitleTextAttributes([
            .foregroundColor: UIColor.clear,
            .font: UIFont.systemFont(ofSize: 0.1)
        ], for: .highlighted)
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }
    
}

