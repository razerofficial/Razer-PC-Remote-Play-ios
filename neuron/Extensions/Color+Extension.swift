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
import SwiftUI

extension Color {
    
    static let ButtonNormal = Color("ButtonNormal")
    
    static let AshGray = Color("AshGray")
    static let Azure = Color("Azure")
    static let Black = Color("Black")
    static let Brandeisblue = Color("Brandeisblue")
    static let CanaryYellow = Color("CanaryYellow")
    static let DarkGrey = Color("DarkGrey")
    static let DarkJungleGreen = Color("DarkJungleGreen")
    static let DarkJungleGreen27 = Color("DarkJungleGreen27")
    static let DarkJungleGreen28 = Color("DarkJungleGreen28")
    static let DavyGray = Color("DavyGray")
    static let DimGrey = Color("DimGrey")
    static let Gainsboro = Color("Gainsboro")
    static let JungleBlack = Color("JungleBlack")
    static let JungleGreen = Color("JungleGreen")
    static let KellyGreen = Color("KellyGreen")
    static let Lemon = Color("Lemon")
    static let LimeGreen = Color("LimeGreen")
    static let Manatee = Color("Manatee")
    static let Onyx = Color("Onyx")
    static let PastelGreen = Color("PastelGreen")
    static let PersianRed = Color("PersianRed")
    static let RazerGreen = Color.hex(0x44D62C, alpha: 1.0)
    static let Red = Color("Red")
    static let Silver = Color("Silver")
    static let Taupe = Color("Taupe")
    static let TaupeGray = Color("TaupeGray")
    static let Timberwolf = Color("Timberwolf")
    static let TrolleyGrey = Color("TrolleyGrey")
    static let TrueBlue = Color("TrueBlue")
    static let UFOGreen = Color("UFOGreen")
    static let USCGold = Color("USCGold")
    static let White = Color("White")
    static let WhiteSmoke = Color("WhiteSmoke")
    static let RifleGreen = Color("RifleGreen")
    static let DarkerGrey = Color("DarkerGrey")
    static let VeryDarkGrey = Color("VeryDarkGrey")
    static let VeryLightGrey = Color("VeryLightGrey")
    
    static let GoldenYellow = Color("GoldenYellow")
    static let DeepSkyBlue = Color("DeepSkyBlue")
    static let AuroMetalSaurus = Color("AuroMetalSaurus")
    static let Liver = Color("Liver")

    static let SettingMenuGrey = Color("SettingMenuGrey")
    static let SettingMenuDisable = Color("SettingMenuDisable")
    static let SettingsLine = Color.hex(0x999999, alpha: 0.5)
    static let SettingMenuFocus = Color.hex(0xFFFFFF, alpha: 0.3)
    static let SettingMenuBG = Color.hex(0x222222, alpha: 1.0)
    static let SettingText = Color(red: 153/255, green: 153/255, blue: 153/255, opacity: 1.0)
    static let SettingTextBlue = Color.hex(0x007AFF, alpha: 1.0)    
    
    static let Coquelicot = Color("Coquelicot")
    static let DebianRed = Color("DebianRed")
    static let DukeBlue = Color("DukeBlue")
    static let Indigo = Color("Indigo")
    static let SmokyBlack = Color("SmokyBlack")
    static let CathodeGreen = Color("CathodeGreen")
    static let PeaSoup = Color("PeaSoup")
    static let MagicInk = Color("MagicInk")
    static let DarkJungleGreen34 = Color("DarkJungleGreen34")
    
    static let Silver196 = Color.hex(0xc4c4c4)
    
    static let StreanLightGray:Color = Color.hex(0xededed, alpha: 0.8)
    static let StreanDarkGray:Color = Color.hex(0xc8c8c8, alpha: 0.8)
    
    static let ManageGameLightGray:Color = Color.hex(0xededed, alpha: 0.8)
    
    static let RemapTrayGray:Color = Color.hex(0x141414, alpha: 1.0)
    static let SettingsLineGray:Color = Color(red: 153/255, green: 153/255, blue: 153/255, opacity: 1.0)
    static let SettingsSelectedBackground:Color =  Color(red: 116/255, green: 116/255, blue: 128/255, opacity: 0.2)

    static let ActionCandidateDefaultBgColor:Color = Color.hex(0x000000, alpha: 1.0)
    
    static let DeadzoneCircleBackground:Color = Color(red: 1.0, green: 1.0, blue: 1.0, opacity:0.3)
    
    static func getRandomColor() -> Color {
        return Color(hue: Double(drand48()), saturation: 1, brightness: 1, opacity: 1)
    }
    
    static func hex(_ hex: Int, alpha: Double = 1) -> Color {
        let components = (
            R: Double((hex >> 16) & 0xff) / 255,
            G: Double((hex >> 08) & 0xff) / 255,
            B: Double((hex >> 00) & 0xff) / 255
        )
        return Color.init(
            .sRGB,
            red: components.R,
            green: components.G,
            blue: components.B,
            opacity: alpha
        )
    }
    
    static func hexString(_ hexString: String?) -> Color? {
        guard let hexString = hexString else { return nil }
        var cleanedString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedString = cleanedString.replacingOccurrences(of: "#", with: "")
        
        if cleanedString.count != 6 {
            return nil
        }
        
        var rgbValue: UInt64 = 0
        guard Scanner(string: cleanedString).scanHexInt64(&rgbValue) else {
            return nil
        }
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue, opacity: 1.0)
    }
    
    func uiColor() -> UIColor {
            if #available(iOS 14.0, *) {
                return UIColor(self)
            }

            let components = self.components()
            return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
        }

        private func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {

            let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
            var hexNumber: UInt64 = 0
            var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0

            let result = scanner.scanHexInt64(&hexNumber)
            if result {
                r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000ff) / 255
            }
            return (r, g, b, a)
        }
    
    func toHex() -> String {
        let components = UIColor(self).cgColor.components
        guard let rgba = components, rgba.count >= 3 else {
            return "#FFFFFF"
        }
        let red = UInt8(rgba[0] * 255.0)
        let green = UInt8(rgba[1] * 255.0)
        let blue = UInt8(rgba[2] * 255.0)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
