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

extension View {
    ///Use UIKitAppear To fix onAppear bug
    public func onAppearFix(perform action: (() -> Void)? = nil ) -> some View {
        //self.overlay(UIKitAppear(action: action).disabled(true))
        self.background(UIKitAppear(action: action).disabled(true))
    }
    
    func eraseToAnyView() -> AnyView { AnyView(self) }
}
///Use UIKitAppear To fix onAppear bug
private struct UIKitAppear: UIViewControllerRepresentable {
    let action: (() -> Void)?

    func makeUIViewController(context: Context) -> Controller {
        let vc = Controller()
        vc.action = action
        return vc
    }

    func updateUIViewController(_ controller: Controller, context: Context) {}

    class Controller: UIViewController {
        var action: (() -> Void)? = nil

        override func viewDidLoad() {
            view.addSubview(UILabel())
        }

        override func viewDidAppear(_ animated: Bool) {
            action?()
        }
    }
}
