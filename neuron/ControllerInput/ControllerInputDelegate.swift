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

import CocoaLumberjack

protocol ControllerButtonDelegate : NSObject {
    func buttonTriggered(controlTriggered : ControllerInputDelegate.ActionTriggered)
    func shouldTriggered(controlTriggered : ControllerInputDelegate.ActionTriggered) ->Bool
    func leftJoystickTriggered(xAxis: CGFloat, yAxis: CGFloat)
    func rightJoystickTriggered(xAxis: CGFloat, yAxis: CGFloat)
    func handleLeftTriggerValue(value: Float, pressed: Bool)   //L2
    func handleRightTriggerValue(value: Float, pressed: Bool)  //R2
}

class ControllerInputDelegate : NSObject {
    
    public enum ActionTriggered : Equatable{
        case control(button:GamePadButton, counter:Int, state:ButtonState)
        case changeValue(value:Double, counter:Int)
        case none
    }
    
    private var activeButtonControl: String = ""
    private var sliderValue : CGFloat = 0.0
    private var counter : Int = 0
    // defined as a weak property to avoid circular reference and memory leak
    weak var delegate : ControllerButtonDelegate? = nil
    private var shouldTrackInputs : Bool = false
    
    deinit {
       
    }
    
    func stopTracking() {
        shouldTrackInputs = false
        ControllerInputTracker.shared.delegate = nil
    }
    
    func startTracking() {
        shouldTrackInputs = true
        ControllerInputTracker.shared.delegate = self
    }
}

//MARK:-
extension ControllerInputDelegate : ControllerInputTrackerDelegates {
    
    func trackingStatusChanged(isTracking status: Bool) {
        //DDLogInfo("trackingStatusChanged isTracking:\(status)")
    }
    
    func handleFaceButtonInputs(button: GamePadButton, state: ButtonState) {
        if !shouldTrackInputs { return }
        
        if self.activeButtonControl == button.description {
            counter = (counter + 1)
        }
        else{
            counter = 0
        }
        
        let newTrigger : ActionTriggered = .control(button: button, counter:counter, state: state)
        self.activeButtonControl = button.description
        
        //DDLogInfo("\(APP_LOG_VC) ControllerInputDelegate:handleFaceButtonInputs listener:\(String(describing: self.delegate)) button:\(button.description) counter:\(counter)")
        //DDLogInfo("ZZZ Pressed: " + button.description)
        
        guard let ret = self.delegate?.shouldTriggered(controlTriggered: newTrigger), ret == true else {
            Logger.debug("Filter Button Input: delegate:\(String(describing: self.delegate)) \(button) \(state) ")
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.buttonTriggered(controlTriggered: newTrigger)
        }
    }
    
    func handleLeftJoystickValueEvents(xAxis: CGFloat, yAxis: CGFloat) {
        guard shouldTrackInputs else { return }
        //this will be used for slider updates
        
        //guard (xAxis == 1.0 || xAxis == -1.0) else { return }
        //DDLogInfo("\(APP_LOG_VC) handleLeftJoystickValueEvents Left Stick, X = \(xAxis), y = \(yAxis)")

        if self.activeButtonControl ==  "LJoysStick" {
            counter = (counter + 1)
        }
        else{
            counter = 0
        }
        self.activeButtonControl = "LJoysStick"
        DispatchQueue.main.async {
            self.delegate?.leftJoystickTriggered(xAxis: xAxis, yAxis: yAxis)
//            self.delegate?.buttonTriggered(controlTriggered: .changeValue(value:Double(xAxis), counter: self.counter))
        }
    }
    
    func handleRightJoystickValueEvents(xAxis: CGFloat, yAxis: CGFloat) {
        guard shouldTrackInputs else { return }
        //this will be used for slider updates
        
        //guard (sliderValue != xAxis) else { return }
        //sliderValue = xAxis
        
        //guard (xAxis == 1.0 || xAxis == -1.0) else { return }
        //DDLogInfo("\(APP_LOG_VC) handleRightJoystickValueEvents Right Stick, X = \(xAxis), y = \(yAxis)")

        if self.activeButtonControl ==  "RJoysStick" {
            counter = (counter + 1)
        }
        else{
            counter = 0
        }
        self.activeButtonControl = "RJoysStick"
        DispatchQueue.main.async {
            self.delegate?.rightJoystickTriggered(xAxis: xAxis, yAxis: yAxis)
//            self.delegate?.buttonTriggered(controlTriggered: .changeValue(value:Double(xAxis), counter: self.counter))
        }
    }
    
    //L2
    func handleLeftTriggerValue(value: Float, pressed: Bool) {
        guard shouldTrackInputs else { return }
        DispatchQueue.main.async {
            self.delegate?.handleLeftTriggerValue(value: value, pressed: pressed)
        }
    }
    
    //R2
    func handleRightTriggerValue(value: Float, pressed: Bool) {
        guard shouldTrackInputs else { return }
        DispatchQueue.main.async {
            self.delegate?.handleRightTriggerValue(value: value, pressed: pressed)
        }
    }
}

 

