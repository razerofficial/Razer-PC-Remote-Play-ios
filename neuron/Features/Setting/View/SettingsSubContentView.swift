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

struct SettingsSubContentView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: SettingsViewModel = SettingsViewModel.shared
    private let leftPaddingValue = SettingsUtil.shared.getSubViewLeftPadding()
//    private let rightPaddingValue = SettingsUtil.shared.getSubViewRightPadding()
    
    private var content: AnyView

    public init< Content: View>(content: Content) {
        self.content = AnyView(content)
    }
    
    var body: some View {
        HStack() {
            Spacer().frame(width: leftPaddingValue)
            content
            Spacer().frame(width: rightPaddingValue)
        }
        .background(Color.black)
//        .navigationBarBackButtonHidden()
    }
    
    private var rightPaddingValue : CGFloat {
        
        if horizontalSizeClass == .compact {
            return leftPaddingValue
        }else {
            return SettingsUtil.shared.getSubViewRightPadding()
        }
    }
}
