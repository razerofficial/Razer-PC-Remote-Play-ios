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

import SwiftUI
import CocoaLumberjack

let DesignHeight = 414.0
let DesignWidth = 896.0
let VScale = UIScreen.screenHeight / DesignHeight
let HScale = UIScreen.screenWidth / DesignWidth
let HScrollOffset = IsIOS13() ? (-50.0):0

func IsIOS13()->Bool {
    if #available(iOS 14.0, *) {
        //高于 iOS 14.0
        return false
    } else {
        //低于 iOS 14.0
        return true
    }
}

func IsIOS132()->Bool {
    if #available(iOS 13.2, *) {
        //高于 iOS 13.2
        return true
    } else {
        //低于 iOS 13.2
        return false
    }
}

func IsIOS14()->Bool {
    if #available(iOS 14.0, *) {
        //高于 iOS 14.0
        return true
    } else {
        //低于 iOS 14.0
        return false
    }
}

func IsBelowIOS16()->Bool {
    if #available(iOS 15.0, *) {
        //高于 iOS 15.0
        if #available(iOS 16.0, *) {
            return false
        }else {
            return true
        }
    } else {
        //低于 iOS 14.0
        return false
    }
}

func IsIOS174()->Bool {
    if #available(iOS 17.4, *) {
        //高于 iOS 17.4
        return true
    } else {
        //低于 iOS 17.4
        return false
    }
}

////如果想要判断设备是ipad，要用如下方法
//func IsIpad() -> Bool
//{
//    let deviceType = UIDevice.current.model
//    
//    if(deviceType == "iPhone") {
//        //iPhone
//        return false
//    }
//    else if(deviceType == "iPod touch") {
//        //iPod Touch
//        return false
//    }
//    else if(deviceType == "iPad") {
//        //iPad
//        return true
//    }
//    return false
//    
//    //这两个防范判断不准，不要用
//    //#define is_iPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
//    //
//    //#define is_iPad (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
//}

func IsIPhone() ->Bool {
    let deviceType = UIDevice.current.model
    
    if(deviceType == "iPhone" || deviceType == "iPod touch") {
        //iPhone
        return true
    }else {
        return false
    }
}
