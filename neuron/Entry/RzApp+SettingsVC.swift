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

extension RzApp {
    
    @objc
    func getSettingsMenuVC() -> UIViewController {
        let vc = SettingsSplitViewController()
        guard let window = UIApplication.shared.delegate?.window,
              let rootNav = window?.rootViewController as? UINavigationController else {
            return vc
        }
        return rootNav.viewControllers.first { $0 is SettingsSplitViewController }
                       as? SettingsSplitViewController ?? vc
    }
}
