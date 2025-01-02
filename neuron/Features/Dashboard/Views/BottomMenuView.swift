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

struct BottomMenuView: View {
    
    @ObservedObject var viewModel: BottomMenuViewModel
    let onButtonClicked: (BottomMenuItemType) -> Void
    
    var body: some View {
//        guard viewModel.isControllerConnected else { return EmptyView().eraseToAnyView() }
//        guard ControllerInputTracker.shared.isConnected else { return EmptyView().eraseToAnyView() }
        return HStack() {
            Spacer()
            ForEach(viewModel.menuItems, id: \.type) { item in
                BlurLetterGuideButton(
                    buttonType: viewModel.connected ? item.buttonType : .None ,
                    title: item.title.localize().uppercased(),
                    action: {
                        onButtonClicked(item.type)
                    })
                Spacer().frame(width: 20.0)
            }
            Spacer().frame(width: 8.0)
        }
        .frame(alignment: .leading)
        .eraseToAnyView()
    }
}
