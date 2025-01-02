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
import SwiftUI
import Combine
import CocoaLumberjack

protocol RZHandleResponderDelegate : NSObject {
    
    func handleClickButton(_ action:GamePadButton)
}

public class RZHandleResponder: NSObject , ObservableObject , ControllerButtonDelegate {

    var reloadCallBack:(()->Void)? = nil
    
    var controllerInputs: ControllerInputDelegate = ControllerInputDelegate()
    
    var controlTriggered : ControllerInputDelegate.ActionTriggered = .none
    
    weak var delegate:RZHandleResponderDelegate? = nil
    
    private var isTracking:Bool = false
    
    @Published var connected:Bool = ControllerInputTracker.shared.isConnected
    
    lazy var trackingQueue:OperationQueue = {
        let op = OperationQueue.init()
        op.maxConcurrentOperationCount = 1
        return op
    }()
    
    override init() {
        super.init()
        
        // Subscribe for the Controller Events.
        let ctr = NotificationCenter.default
        ctr.addObserver(forName: .GCControllerDidConnect, object: nil, queue: trackingQueue) { note in
            if let ctrl = note.object as? GCController {
                DispatchQueue.main.async {
                    self.connected = true
                }
            }
        }
        ctr.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: trackingQueue) { note in
            if let ctrl = note.object as? GCController {
                DispatchQueue.main.async {
                    self.connected = false
                }
            }
        }
    }
    
    func shouleTracking() -> Bool {
        return isTracking && isConnected()
    }
    
    func resetInputTracker(){
        
        Logger.info("\(type(of: self)) - resetInputTracker()")
        
        // this line causes new views (pages) to be dismissed, do not add this line!!
        // also, this variable is not related logically to the "rest input tracker" action -_-
        controlTriggered = .none
    }
    
    func isConnected() -> Bool {
        return ControllerInputTracker.shared.isConnected
    }
    
    func stopTracking(){
        Logger.info("\(type(of: self)) - stopTracking")
        self.controllerInputs.stopTracking()
        //self.controlTriggered = .none
        isTracking = false
        // set the delegate variable to nil to avoid circular reference
        controllerInputs.delegate = nil
        NSLog("12---->\(self)")
    }
    
    func startTracking(){
        // we need to set controllerInputs.delegate to self everytime startTracking() is called
        // because we'll set controllerInputs.delegate to nil when stopTracking() is called
        if let extendedGamepad = GCController.controllers().first?.extendedGamepad {
            ControllerInputTracker.shared.setupButtonsMonitor(gamepad: extendedGamepad)
        }
        controllerInputs.delegate = self
        controllerInputs.startTracking()
        isTracking = true
        Logger.info("\(type(of: self)) - startTracking")
        NSLog("11---->\(self)")
    }
    
    func buttonTriggered(controlTriggered : ControllerInputDelegate.ActionTriggered){
        analyzeControllerInputs(controlTriggered)
        self.controlTriggered = controlTriggered
    }
    
    //By default, it is only triggered when the Button State is Down,and subclasses can be overridden as needed
    func shouldTriggered(controlTriggered: ControllerInputDelegate.ActionTriggered) -> Bool {
        var should = false
        switch controlTriggered {
        case .control(button: _, counter: _, state: let state):
            switch state {
            case .Down:should = true
            case .Up:should = false
            }
        default:break
        }
        return should
    }
    
    // this function should be overridden by children classes to perform different tasks
    func analyzeControllerInputs(_ value:ControllerInputDelegate.ActionTriggered){
        NSLog("22---->\(self) self.delegate:\(self.delegate)")
        switch value {
        case .control(button: let button , counter: _, state: let state):
            self.delegate?.handleClickButton(button)
        default:break
        }
        
    }
    
    // this function should be overridden by children classes to perform different tasks
    func leftJoystickTriggered(xAxis: CGFloat, yAxis: CGFloat) {
    }
    
    // this function should be overridden by children classes to perform different tasks
    func rightJoystickTriggered(xAxis: CGFloat, yAxis: CGFloat) {
    }
    
    // this function should be overridden by children classes to perform different tasks
    func handleLeftTriggerValue(value: Float, pressed: Bool) {
    }
    
    // this function should be overridden by children classes to perform different tasks
    func handleRightTriggerValue(value: Float, pressed: Bool) {
    }
    
    func startJoystickTriggered() {
        ControllerInputTracker.shared.shouldPassThumbstickEvent = true
    }
    
    func stopJoystickTriggered() {
        ControllerInputTracker.shared.shouldPassThumbstickEvent = false
    }

    
}
