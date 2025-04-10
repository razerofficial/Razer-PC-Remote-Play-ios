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

struct ChangeObserver<Content: View, Value: Equatable>: View {
    let content: Content
    let value: Value
    let action: (Value) -> Void
    
    init(value: Value, action: @escaping (Value) -> Void, content: @escaping () -> Content) {
        self.value = value
        self.action = action
        self.content = content()
        _oldValue = State(initialValue: value)
    }
    
    @SwiftUI.State private var oldValue: Value
    
    var body: some View {
        Logger.info("ChangeObserver updating view")
        if oldValue != value {
            DispatchQueue.main.async {
                oldValue = value
                self.action(self.value)
            }
        }
        else{
            Logger.info("ChangeObserver is failing since oldValue == value")
        }
        return content
    }
}
