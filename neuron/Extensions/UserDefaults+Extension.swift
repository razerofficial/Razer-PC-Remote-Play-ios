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

//MARK: - Tutorial 缓存数据
extension UserDefaults {
    enum LocaGameCacheV3: String, UserDefaultSettable {
        case isMigrated
    }
}

//MARK: - Tutorial 缓存数据
extension UserDefaults {
    enum Tutorial: String, UserDefaultSettable {
//        case isCompleted
        case isCompletedV2// for 4.0
        case allLegalTermsAccepted
        case isRequestedLocalNetworkPermission
        case isRequestedNotificationPermission
    }
}

//MARK: - Dashboard Background
extension UserDefaults {
    enum Dashboard: String, UserDefaultSettable {
        case backgroundStyle
    }
}

extension UserDefaults {
    enum DisplayApps: String, UserDefaultSettable {
        case DisplayAllApps
    }
}

public protocol UserDefaultSettable {
    var uniqueKey: String { get }
}

public extension UserDefaultSettable where Self: RawRepresentable, Self.RawValue == String {

    /// UserDefaults SetAnyValue
    ///
    /// - parameter value: anyValue
    func set(value: Any?) {
        UserDefaults.standard.set(value, forKey: uniqueKey)
    }

    /// UserDefaults SetUrl
    ///
    /// - parameter url: url
    func set(url: URL?) {
        UserDefaults.standard.set(url, forKey: uniqueKey)
    }

    /// UserDefaults Anyvalue
    var value: Any? {
        return UserDefaults.standard.value(forKey: uniqueKey)
    }

    /// UserDefaults stringValue
    var stringValue: String? {
        return value as? String
    }

    /// UserDefaults urlValue
    var urlValue: URL? {
        return UserDefaults.standard.url(forKey: uniqueKey)
    }

    /// UserDefaults intValue
    var intValue: Int? {
        return UserDefaults.standard.integer(forKey: uniqueKey)
    }

    /// UserDefaults boolValue
    var boolValue: Bool? {
        return UserDefaults.standard.bool(forKey: uniqueKey)
    }

    /// UserDefaults floatValue
    var floatValue: Float? {
        return UserDefaults.standard.float(forKey: uniqueKey)
    }

    /// UserDefaults doubleValue
    var doubleValue: Double? {
        return UserDefaults.standard.double(forKey: uniqueKey)
    }

    /// UserDefaults key
    var uniqueKey: String {
        return "\(Self.self).\(rawValue)"
    }

    /// removed object from standard userdefaults
    func removed() {
        UserDefaults.standard.removeObject(forKey: uniqueKey)
    }

}
