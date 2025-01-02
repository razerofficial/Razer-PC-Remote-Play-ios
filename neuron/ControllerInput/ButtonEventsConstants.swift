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

public enum GamePadButton {
    case A, B, X, Y, left, right, up, down, menu, home, options, L1, R1, L4, R4
    
    var description: String {
        switch self {
        case .A:
            return "A"
        case .B:
            return "B"
        case .X:
            return "X"
        case .Y:
            return "Y"
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .up:
            return "Up"
        case .down:
            return "Down"
        case .menu:
            return "Menu"
        case .home:
            return "Home"
        case .options:
            return "Options"
        case .L1:
            return "L1"
        case .R1:
            return "R1"
        case .L4:
            return "L4"
        case .R4:
            return "R4"
        }
    }
}

public enum ButtonState {
    case Up, Down
    
    var description: String {
        switch self {
        case .Up:
            return "Up"
        case .Down:
            return "Down"
        }
    }
}
