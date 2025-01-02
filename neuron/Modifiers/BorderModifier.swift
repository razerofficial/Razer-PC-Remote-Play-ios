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


struct BorderModifier: ViewModifier {
    
    var borderWidth: CGFloat = 1.0
    var borderColor: Color = .White
    var cornerRadius: CGFloat? = nil

    func body(content: Content) -> some View {
        content
            .padding(.all, 0.7)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius ?? 16)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
}
