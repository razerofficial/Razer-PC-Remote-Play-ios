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
struct MenuItemList {
    var list : [SettingsUIComponents.ComponentType]
    
    init() {
        list = [.NeuronStreamingMenu, .NeuronStreamingHostMenu, .AboutMenu]
    }
    
    func getPreviousMenuItem(currentItem:SettingsUIComponents.ComponentType) -> SettingsUIComponents.ComponentType {
        let currentItemIndex = list.firstIndex(where: {$0 == currentItem}) ?? 0
        if( currentItemIndex == 0 ){
            // at first item, do nothing
            return currentItem
        }
        return list[currentItemIndex - 1]
    }
    
    func getNextMenuItem(currentItem:SettingsUIComponents.ComponentType) -> SettingsUIComponents.ComponentType {
        let currentItemIndex = list.firstIndex(where: {$0 == currentItem}) ?? (list.count - 1)
        if( currentItemIndex == list.count - 1 ){
            // at last item, do nothing
            return currentItem
        }
        return list[currentItemIndex + 1]
    }
    
    func getCurrentMenuItemIndex(currentItem:SettingsUIComponents.ComponentType) -> Int {
        let currentItemIndex = list.firstIndex(where: {$0 == currentItem}) ?? (list.count - 1)
        return currentItemIndex
    }
}
