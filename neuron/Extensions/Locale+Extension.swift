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

extension Locale {
    static var preferredLanguageCode: String {
        guard var preferredLanguage = preferredLanguages.first else {
            return "en"
        }
        
        //remove region code ex:zh-Hant-TW to zh-Hant
        if let index = preferredLanguage.lastIndex(of: "-") {
            let end = preferredLanguage.index(before: preferredLanguage.endIndex)
            preferredLanguage.replaceSubrange(index...end, with: "")
        }
        return preferredLanguage
    }
    
    static var preferredLanguageCodes: [String] {
        return Locale.preferredLanguages
    }
}
