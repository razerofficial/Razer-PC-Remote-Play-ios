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

//适配灵动岛和刘海屏的边距
let SaveAreaLeft = UIWindow.key?.safeAreaInsets.left ?? 0.0
let DeviceLeftSpace = SaveAreaLeft > 0 ? SaveAreaLeft : 5.0 + 20.0
let ScreenScale = UIScreen.screenScale

final class ScreencastConfig: NSObject {
    private static var _ScreencastExtBundleIDkey: String?
    private static var _AppGroupkey: String?

    private static let plistKeyScreencastExtBundleIDkey = "SCREENCAST_EXT_BUNDLE_ID"
    private static let plistKeyAppGroupkey = "APP_GROUP"
    
    static var ScreencastExtBundleIDkey: String {
        if ScreencastConfig._ScreencastExtBundleIDkey == nil {
            ScreencastConfig._ScreencastExtBundleIDkey = getInfo(plistKeyScreencastExtBundleIDkey)
        }
        assert(ScreencastConfig._ScreencastExtBundleIDkey != nil, "Please put your Screencast Ext Bundle ID key to the ScreencastConfig.plist!")
        return ScreencastConfig._ScreencastExtBundleIDkey!
    }
    
    static var AppGroupkey: String {
        if ScreencastConfig._AppGroupkey == nil {
            ScreencastConfig._AppGroupkey = getInfo(plistKeyAppGroupkey)
        }
        assert(ScreencastConfig._AppGroupkey != nil, "Please put your App Group key to the ScreencastConfig.plist!")
        return ScreencastConfig._AppGroupkey!
    }

    static private func getInfo(_ key: String) -> String? {
        if let plist = getPlist("Info"), let info = plist[key] as? String, !info.isEmpty {
            return info
        } else if let plist = getPlist("ScreencastConfig"), let info = plist[key] as? String, !info.isEmpty {
            return info
        } else {
            return nil
        }
    }

    static private func getPlist(_ name: String) -> NSDictionary? {
        var plist: NSDictionary?
        if let path = Bundle.main.path(forResource: name, ofType: "plist") {
            if let content = NSDictionary(contentsOfFile: path) as NSDictionary? {
                plist = content
            }
        }
        return plist
    }
}

