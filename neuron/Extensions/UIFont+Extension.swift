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

extension UIFont {
    
    private static var fontsRegistered: Bool = false
    
    static func registerFontsIfNeeded() {
        let fontBundlePath = (Bundle.main.path(forResource: "Fonts", ofType: "bundle"))!
        
        
        var fontURLs = [URL]()
        
        if let urls = FileManager.allFiles(folder: fontBundlePath, filter: "otf"){
            fontURLs.append(contentsOf: urls)
        }
        if let urls = FileManager.allFiles(folder: fontBundlePath, filter: "ttf"){
            fontURLs.append(contentsOf: urls)
        }
        guard
            !fontsRegistered,
            fontURLs.count > 0
        
        else { return }
        
        fontURLs.forEach({ CTFontManagerRegisterFontsForURL($0 as CFURL, .process, nil) })
        fontsRegistered = true
        
        
    }
}
