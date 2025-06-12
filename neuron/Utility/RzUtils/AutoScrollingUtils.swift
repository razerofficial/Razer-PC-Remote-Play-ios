/*
 * Copyright (C) 2025 Razer Inc.
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

struct autoScrollingModifier: ViewModifier {
    let id: String
    let scrollViewCoordinateSpaceName: String
    @Binding var viewPositions: [String: CGRect]
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ViewPositionKey.self,
                                           value: [id: geo.frame(in: .named(scrollViewCoordinateSpaceName))])
                }
            )
            .id(id)
    }
}

extension View {
    func autoScrollingWith(id: String, scrollViewCoordinateSpaceName: String, positions: Binding<[String: CGRect]>) -> some View {
        self.modifier(autoScrollingModifier(id: id, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, viewPositions: positions))
    }
}

struct ViewPositionKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct ScrollViewPositionKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
