/*
 * Copyright (C) 2025 Razer Inc.
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
import SwiftUI


public class SettingsUtil {
    
    static let shared = SettingsUtil()
    
    private init() {
        
    }
    
    func getSubViewRightPadding() -> CGFloat {
        
        return CGFloat(10 + (hasSafeArea ? 70 : 30))
        
    }
    
    func getSubViewSpaceBetweenView() -> CGFloat {
        return CGFloat(16)
    }
    
    func getSubViewLeftPadding() -> CGFloat {
        return getMenuButtonRightPadding()
    }
    
    func getMenuButtonRightPadding() -> CGFloat {
        return CGFloat(25)
    }
    
    func getMenuBGHeight() -> CGFloat {
        return 52.0
    }

    func getMenuButtonLeftPadding() -> CGFloat {
        if safeAreaLeft == 0 {
            return getNavBarLeftPadding()
        }
        return safeAreaLeft
    }
    
    func getNavBarLeftPadding() -> CGFloat {
        return CGFloat(25)
    }
    
    private var safeAreaLeft: CGFloat {
        if let window = UIApplication.shared.keyWindowInConnectedScenes {
            return window.safeAreaInsets.left
        }else {
            return 0
        }
    }
    
    //MARK: - Glass Color Values
    func glassBgColor() -> Color {
        //return (colorScheme == .dark) ? Color.hex(0x222222) : Color.clear
        return Color.black.opacity(0.2)//Color.clear
    }
    
    //LetterGuideButtonBackgroundColor
    func lgBtnBgColor() -> Color {
        return IsIOS26() ?  SettingsUtil.shared.glassBgColor() : Color.Onyx.opacity(0.5)
    }
}

func currentWindowScene() -> UIWindowScene? {
    let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    let scene = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).compactMap({$0 as? UIWindowScene}).first ?? firstScene
    return scene
}
