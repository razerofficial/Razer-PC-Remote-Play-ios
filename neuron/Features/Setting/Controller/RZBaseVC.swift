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
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI
import Combine

class RZBaseVC : UIViewController {
 
    var bag = Set<AnyCancellable>()
    let disposed = DisposeBag()
    let handel = RZHandleResponder.init()
    weak var lastHandel:RZHandleResponder?
    weak var nextHandel:RZHandleResponder?
    weak var lastVC:RZBaseVC?

    override func viewDidLoad() {
        super.viewDidLoad()
        handel.resetInputTracker()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handelStart()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        handelStop()
    }

    func handelStart() {
        if nextHandel == nil { // || ( nextHandel?.shouleTracking() == false )
            handel.startTracking()
        }
        
        if let handelDelegate = self as? RZHandleResponderDelegate {
            handel.delegate = handelDelegate
        }
    }
    
    func handelStop() {
        handel.stopTracking()
        lastHandel?.startTracking()
    }
    
    func updateNextHandel(_ handel:RZHandleResponder?) {
        nextHandel = handel
    }
    
    @objc func handelReset() {
        //re get cgcontroller
        //print("restart ......... ControllerInputTracker")
        if let extendedGamepad = GCController.controllers().first?.extendedGamepad {
            ControllerInputTracker.shared.setupButtonsMonitor(gamepad: extendedGamepad)
        }
    }
}
