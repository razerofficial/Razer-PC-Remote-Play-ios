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
import CocoaLumberjack
import Kingfisher

enum SettingsMenuItemIconStyle {
    case none
    case availableFWUpdate
    case noController
    case unkonwnController
}

enum SettingsMenuItemStyle {
    case rectangle
    case roundedRectangle
    case topHalfRoundedRectangle
    case bottomHalfRoundedRectangle
    case none
    case NeuronHosts
}

struct SettingsMenuItemButton: View {
    var fontSize : CGFloat = 16.0
    var description : String = ""
    var fontLeftPadding : CGFloat = SettingsUtil.shared.getMenuFontLetPadding()
    var bottomLineLeftPadding : CGFloat = 16
    var bottomLineRightPadding : CGFloat = 11
    var imageSize : CGSize = CGSize(width: 20.0, height: 20.0)
    var isSelected : Bool
    var textColor = Color.white
    var selectedTextColor = Color.white
    var selectedBackgroundColor = Color.SettingMenuFocus
    var height : CGFloat = 52
    var cornerRadius : CGFloat = 26
    var isDisable = false
    var style: SettingsMenuItemStyle = .roundedRectangle
    var iconStyle: SettingsMenuItemIconStyle = .none
    var isNeedBottomLine = false
    var isBottomLineFull = false
    @ObservedObject var settingsVM: SettingsViewModel
    var action: (()->Void)? = nil
    
    var buttonView: some View {
        return HStack() {
            Text("\(description)")
                .foregroundColor(isDisable ? Color.SettingMenuDisable:isSelected ? selectedTextColor: textColor)
                .font(.system(size: fontSize))
                .frame(maxHeight: .infinity)
                .padding(.leading, fontLeftPadding)
                .padding(.top, 10)
                .padding(.bottom, 10)
            Spacer()
            if iconStyle != .none {
                getSubButtonStyle
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: .infinity)
        .frame(alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.clear)
        .onTapGesture {
            if isDisable {
                return
            }
            action?()
        }
    }
    
    var body: some View {
//        if action != nil {
//            buttonView.onTapGesture {
//                self.action?()
//            }
//        }
//        else{
//            buttonView
//        }
        
        switch style {
        case .roundedRectangle:
            VStack (alignment: .leading, spacing: 0) {
                buttonView
                if isNeedBottomLine {
                    Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale).padding(.leading, isBottomLineFull ? 0:bottomLineLeftPadding).padding(.trailing, isBottomLineFull ? 0:bottomLineRightPadding)
                }
            }.background(isSelected ? selectedBackgroundColor : Color.SettingMenuBG)
                .cornerRadius(cornerRadius, corners: .topLeft)
                .cornerRadius(cornerRadius, corners: .topRight)
                .cornerRadius(cornerRadius, corners: .bottomLeft)
                .cornerRadius(cornerRadius, corners: .bottomRight)
                .onTapGesture {
                    action?()
                }
        case .topHalfRoundedRectangle:
            VStack (alignment: .leading, spacing: 0) {
                buttonView
                if isNeedBottomLine {
                    Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale).padding(.leading, isBottomLineFull ? 0:bottomLineLeftPadding).padding(.trailing, isBottomLineFull ? 0:bottomLineRightPadding)
                }
            }.background(isSelected ? selectedBackgroundColor : Color.SettingMenuBG)
                .cornerRadius(cornerRadius, corners: .topLeft)
                .cornerRadius(cornerRadius, corners: .topRight)
                .onTapGesture {
                    action?()
                }
        case .bottomHalfRoundedRectangle:
            VStack (alignment: .leading, spacing: 0) {
                buttonView
                if isNeedBottomLine {
                    Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale).padding(.leading, isBottomLineFull ? 0:bottomLineLeftPadding).padding(.trailing, isBottomLineFull ? 0:bottomLineRightPadding)
                }
            }.background(isSelected  ? selectedBackgroundColor : Color.SettingMenuBG)
                .cornerRadius(cornerRadius, corners: .bottomLeft)
                .cornerRadius(cornerRadius, corners: .bottomRight)
                .onTapGesture {
                    action?()
                }
        case .rectangle:
            VStack (alignment: .leading, spacing: 0) {
                buttonView
                if isNeedBottomLine {
                    Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale).padding(.leading, isBottomLineFull ? 0:bottomLineLeftPadding).padding(.trailing, isBottomLineFull ? 0:bottomLineRightPadding)
                }
            }.background(isSelected ? selectedBackgroundColor : Color.SettingMenuBG)
                .onTapGesture {
                    action?()
                }
        case .none:
            VStack (alignment: .leading, spacing: 0) {
                buttonView
                if isNeedBottomLine {
                    Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale).padding(.leading, isBottomLineFull ? 0:bottomLineLeftPadding).padding(.trailing, isBottomLineFull ? 0:bottomLineRightPadding)
                }
            }.background(Color.clear)
                .onTapGesture {
                    action?()
                }
        case .NeuronHosts:
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<settingsVM.hosts.count, id: \.self) { i in
                    let host = settingsVM.hosts[i]
                    VStack (alignment: .leading, spacing: 0) {
                        HStack() {
                            Text("\(host.name)")
                                .foregroundColor(isDisable ? Color.SettingMenuDisable:isSelected ? selectedTextColor: textColor)
                                .font(.system(size: fontSize))
                                .frame(maxHeight: .infinity)
                                .padding(.leading, fontLeftPadding)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                            Spacer()
                            if iconStyle != .none {
                                getSubButtonStyle
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: height, maxHeight: .infinity)
                        .frame(alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(Color.clear)
                        .onTapGesture {
                            if isDisable {
                                return
                            }
                            settingsVM.NeuronSettingsMenuselectHost(index: i)
                        }
                        if isNeedBottomLine {
                            Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale).padding(.leading, isBottomLineFull ? 0:bottomLineLeftPadding).padding(.trailing, isBottomLineFull ? 0:bottomLineRightPadding)
                        }
                    }.background((settingsVM.selectedHostIndex == i && settingsVM.highlightedUIComponent == .NeuronStreamingHostMenu) ? selectedBackgroundColor : Color.SettingMenuBG)
                        .cornerRadius(i == 0 ? cornerRadius : 0, corners:[.topLeft, .topRight])
                        .onTapGesture {
                            settingsVM.NeuronSettingsMenuselectHost(index: i)
                        }
                }
            }
        }
    }
    
    var getSubButtonStyle: some View {
        
        var imageName = ""
        
        switch iconStyle {
            
        case .none:
            imageName = ""
        case .availableFWUpdate:
            imageName = "iconAvailableFWUpdate"
        case .noController:
            imageName = "noControllerDot"
        case .unkonwnController:
            imageName = "noControllerDot"
        }
        
        return Image(imageName)
                .resizable()
                .frame(width: 26, height: 26)
                .padding(.trailing, 16.0)
                .padding(.leading, 2.0)
    }
}
