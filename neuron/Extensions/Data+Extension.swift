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

extension Data {
    var uiImage: UIImage? { UIImage(data: self) }
    var unsafeRawPointer: UnsafeMutablePointer<UnsafeRawPointer?> {
        let buf = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: self.count)
        buf.initialize(to: self.toBytes)
        return buf
    }
    
    public var toBytes : [UInt8] {
        return Array(self)
    }
    public static var empty : [UInt8] {
        return [UInt8]()
    }
}
