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


var isCNRegion: Bool {
    let regionCode = Locale.current.regionCode?.uppercased() ?? ""
    return regionCode == "CN"
}

var isShowSeparateScreenDisplayMode: Bool {
    if let devOption = ShareDataDB.shared().readDevOptionsDataFromShare() as? [String: Any],
    let isShowSeparateScreenInSetting = devOption["isShowSeparateScreenInSetting"] as? Bool{
        return isShowSeparateScreenInSetting
    }
    return false
}

func setShowSeparateScreenDisplayMode(value: Bool) {
    if var devOption = ShareDataDB.shared().readDevOptionsDataFromShare() as? [String: Any]{
        devOption["isShowSeparateScreenInSetting"] = value
        ShareDataDB.shared().writeDevOptionsDataToshareDB(devOption)
    } else {
        ShareDataDB.shared().writeDevOptionsDataToshareDB(["isShowSeparateScreenInSetting": value])
    }
}

func getCurrentDeviceTypeString() -> String {
    return UIDevice.current.model == "iPad" ? "iPad" : "iPhone"
}
