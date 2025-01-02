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

import UIKit
import Combine
import SwiftUI

class BottomMenuViewModel : RZHandleResponder {

    @Published var menuItems : [BottomMenuItem] = []{
        willSet {
            self.objectWillChange.send()
        }
    }
        
    override init() {
        super.init()
    }
    
    func updateItems(_ items : [BottomMenuItem]) {
        //如果items没有改变，则不更新
        //guard  menuItems != items else { return }
        menuItems = items
    }
    
}

struct BottomMenuItem: Equatable {
    let type: BottomMenuItemType
    let title : String
    let buttonType : ControllerButtonType
    
    init(type: BottomMenuItemType) {
        self.type = type
        self.title = type.title
        self.buttonType = type.controllerButtonType
    }
}

enum BottomMenuItemType: Hashable {
    case favorite(isFavorite: Bool)
    case play
    case detail
    case appStore
    case fullScreen
    case xBox
    case hide
    case view
    case delete
    case setup
    case pair
    case unpair
    case start_play
    case retry
}

fileprivate
extension BottomMenuItemType {
    var controllerButtonType: ControllerButtonType {
        switch self {
        case .favorite: return .Button_X
        case .play: return .Button_A
        case .detail: return .Button_A
        case .appStore: return .Button_Y
        case .fullScreen: return .Button_A
        case .xBox: return .Button_Y
        case .hide : return .Button_Y
        case .view : return .Button_A
        case .delete : return .Button_Y
        case .setup : return .Button_A
        case .pair: return .Button_A
        case .unpair: return .Button_Y
        case .start_play: return  .Button_A
        case .retry: return  .Button_A
        }
    }
    var title: String {
        switch self {
        case .favorite(let isSelected): return isSelected ? "Unfavorite".localize() : "Favorite".localize()
        case .play: return "Play".localize()
        case .detail: return "Details".localize()
        case .appStore: return "View on App Store".localize().uppercased()
        case .fullScreen: return "Full Screen View".localize().uppercased()
        case .xBox: return "Play Xbox Cloud Game".localize().uppercased()
        case .hide: return "Hide".localize().uppercased()
        case .view: return "View".localize().uppercased()
        case .delete: return "Remove".localize().uppercased()
        case .setup: return "Setup".localize().uppercased()
        case .pair: return "Pair".localize().uppercased()
        case .unpair: return "Unpair".localize().uppercased()
        case .start_play: return "Remote Play".localize().uppercased()
        case .retry: return "Retry".localize().uppercased()
        }
    }
}
