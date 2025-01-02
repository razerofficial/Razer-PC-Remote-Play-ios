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


open class RzLocalizedStringsTable {
    public static let sharedInstance = RzLocalizedStringsTable()
    private var localizedToCoder: Dictionary<String, String> = [:]
    private var semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    private func lock() {
        semaphore.wait()
    }
    
    private func unlock() {
        semaphore.signal()
    }
    
    func localize(localized: String, coder: String) {
        self.lock()
        self.localizedToCoder[localized] = coder
        self.unlock()
    }
    
    func unlocalize(coder: String) ->String {
        var ret = ""
        self.lock()
        ret = self.localizedToCoder[coder] ?? coder
        self.unlock()
        return ret
    }
}

public extension String {
    
    var isNotEmpty: Bool {
        !self.isEmpty
    }
    
    func isEmail() -> Bool {
        let range = self.range(of: "@")
        
        return (range?.lowerBound != nil &&
                    self.lengthOfBytes(using: String.Encoding.utf8) >= 3 )
    }
    
    func localize() -> String {
        
        let localStr = Bundle(for: RzLocalizedStringsTable.self).localizedString(forKey: self, value: "", table: nil)
        //let localStr = NSLocalizedString(self, comment:"")
        RzLocalizedStringsTable.sharedInstance.localize(localized: localStr, coder: self)
        return localStr
    }
    
    func unlocalize() -> String {
        return RzLocalizedStringsTable.sharedInstance.unlocalize(coder: self)
        
    }
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: self)
        return result
    }
    
    //字符串replace⽅法
    func kStringByReplaceString(replaceStr:String,willReplaceStr:String) ->String{
        
        //return string.stringByReplacingOccurrencesOfString(replaceStr, withString: willReplaceStr)
        //    使⽤NSString⽅法
        return String((self as NSString).replacingOccurrences(of: replaceStr, with: willReplaceStr))
    }
    
    ///根据宽度跟字体，计算文字的高度
      func textAutoHeight(width:CGFloat, font:UIFont) ->CGFloat{

            let string = self as NSString
            let origin = NSStringDrawingOptions.usesLineFragmentOrigin
            let lead = NSStringDrawingOptions.usesFontLeading
            let ssss = NSStringDrawingOptions.usesDeviceMetrics
            let rect = string.boundingRect(with:CGSize(width: width, height:0), options: [origin,lead,ssss], attributes: [NSAttributedString.Key.font:font], context:nil)
            return rect.height
        
          }

     ///根据高度跟字体，计算文字的宽度
     func textAutoWidth(height:CGFloat, font:UIFont) ->CGFloat{

       let string = self as NSString
       let origin = NSStringDrawingOptions.usesLineFragmentOrigin
       let lead = NSStringDrawingOptions.usesFontLeading
       let rect = string.boundingRect(with:CGSize(width:0, height: height), options: [origin,lead], attributes: [NSAttributedString.Key.font:font], context:nil)

       return rect.width

     }
    
    func toUrl() -> URL? {
        return URL.init(string: self)
    }
    
    func base64ToData() -> Data {
        guard let decodedData = Data(base64Encoded: self) else {
            Logger.error("Failed to convert Base64 string to Data")
            return Data()
        }
        return decodedData
    }
        
    func toNumberString() -> String {
        return self.filter { "0123456789".contains($0) }
    }
}



