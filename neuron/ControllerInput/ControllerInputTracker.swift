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
import GameController
import CocoaLumberjack
import Combine
import ExternalAccessory

public protocol ControllerInputTrackerDelegates : NSObject {
    func trackingStatusChanged(isTracking status: Bool)
    func handleFaceButtonInputs(button: GamePadButton, state: ButtonState)
    func handleLeftJoystickValueEvents(xAxis: CGFloat, yAxis: CGFloat)
    func handleRightJoystickValueEvents(xAxis: CGFloat, yAxis: CGFloat)
    func handleLeftTriggerValue(value: Float, pressed: Bool)   //L2
    func handleRightTriggerValue(value: Float, pressed: Bool)  //R2
}

enum ComboStatusEnum {
    case START
    case STOP
}

let DEFAUT_COMBO_TIME_INTERVAL: Float = 0.1
let DEFAUT_COMBO_DEBOUNCE_INTERVAL: Float = 0.2

public class ControllerInputTracker {
    
    private enum ELEMENT {
        case LEFT_THUMBSTICK
        case RIGHT_THUMBSTICK
    }
    let MINI_THUMBSTICK_THRESHOLD : Float = 0.1
    let THUMBSTICK_THRESHOLD : Float = 0.2
    let THUMBSTICK_COMBO_THRESHOLD : Float = 0.8
//    let COMBO_TIME_INTERVAL: Float = 0.15
    var leftThumbstickLetGo = true  // true if thumbstick is at the default position
    var rightThumbstickLetGo = true // true if thumbstick is at the default position
    
    public static let shared = ControllerInputTracker()
    private(set) var connectedController: GCController?
    private var trackingStarted: Bool = false
    public var isTraking: Bool { get { return trackingStarted } }
    public var isConnected: Bool { get { 
        return (connectedController != nil)
    } }
    public var shouldPassThumbstickEvent : Bool = false
    
    public weak var delegate: ControllerInputTrackerDelegates? = nil
    lazy var trackingQueue:OperationQueue = {
        let op = OperationQueue.init()
        op.maxConcurrentOperationCount = 1
        return op
    }()
    
    private var shortTermSubcriptions = Set<AnyCancellable>()
    private var debounceSubject = PassthroughSubject<GamePadButton, Never>()
    private var joystickSubject = PassthroughSubject<(GCControllerDirectionPad, ELEMENT), Never>()
    private var longTermSubcriptions = Set<AnyCancellable>()
    private var comboStatus: ComboStatusEnum = .STOP
    private var comboTimer: DispatchSourceTimer?
    private var comboTimerQueue: DispatchQueue = DispatchQueue(label: "com.combo.timer.queue")
    private var lastTriggerButton: GamePadButton?
    private var lastTriggerElement: ELEMENT?
    private var isDapadPressing: Bool = false
    
    private init() {
        Logger.info("ControllerInputTracker > init()")
        joystickSubject.throttle(for: RunLoop.SchedulerTimeType.Stride(TimeInterval(DEFAUT_COMBO_TIME_INTERVAL)), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] (thumbstick, element) in
                self?.handleThumbstickEvent(thumbstick: thumbstick, element: element)
            }.store(in: &longTermSubcriptions)
    }

    public func startTracking() {
        
        if trackingStarted {
            Logger.info("Already Tracking")
            return
        }
        
        // Subscribe for the Controller Events.
        let ctr = NotificationCenter.default
        ctr.addObserver(forName: .GCControllerDidConnect, object: nil, queue: trackingQueue) { note in
            if let ctrl = note.object as? GCController {
                self.add(ctrl)
            }
        }
        ctr.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: trackingQueue) { note in
            if let ctrl = note.object as? GCController {
                self.remove(ctrl)
            }
        }
        
        // Subscribe for UIApplication event
        ctr.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.cancelComboTimer()
        }
        
        trackingStarted = true
                
        // If startTracking is not called right at the launch of the Application, it will miss GCControllerDidConnect event, so we need to find and connect manually.
        if self.connectedController == nil && GCController.controllers().count > 0 {
            Logger.info("Controller Connected, GCController = \(GCController.controllers())")
            let controller = GCController.controllers()[0]
            self.add(controller)
        }
        
        Logger.info("Tracking Started")
        self.delegate?.trackingStatusChanged(isTracking: true)

        // Let main App handle the discovery part.
        //GCController.startWirelessControllerDiscovery(completionHandler: {})
    }
    
    public func stopTracking() {
        // Same as the first, 'cept in reverse!
        //GCController.stopWirelessControllerDiscovery()

        if !trackingStarted {
            Logger.info("Already Stopped Tracking")
            return
        }
        
        let ctr = NotificationCenter.default
        ctr.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        ctr.removeObserver(self, name: .GCControllerDidDisconnect, object: nil)
        ctr.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        
        remove(self.connectedController)
        trackingStarted = false
        
        Logger.info("Tracking Stopped")
        
        self.delegate?.trackingStatusChanged(isTracking: false)
    }

    func add(_ controller: GCController) {
        self.connectedController = controller
        startWatchingForControllerEvents()
    }
    
    private func remove(_ controller: GCController?) {
        
        if let gamepadProfile = self.connectedController?.extendedGamepad {
            gamepadProfile.valueChangedHandler = nil
        }
        self.connectedController = nil
    }

    private func startWatchingForControllerEvents() {
        // Only handling extendedGamepad profile, more reference on gamepad profiles can be found here -
        //https://developer.apple.com/library/archive/documentation/ServicesDiscovery/Conceptual/GameControllerPG/ReadingControllerInputs/ReadingControllerInputs.html
        
        if let gamepad = self.connectedController?.extendedGamepad{
            //TODO: remove before release
            setupButtonsMonitor(gamepad: gamepad)
        }
    }
    
    func setupButtonsMonitor(gamepad: GCExtendedGamepad) {
        // ------ Action Buttons ------
        gamepad.valueChangedHandler = { [weak self] (gamePad:GCExtendedGamepad, element: GCControllerElement) in
            switch element {
            case gamePad.buttonA:
                Logger.info("buttonA pressed:\(gamePad.buttonA.isPressed) value:\(gamePad.buttonA.value)")
                let buttonAState = gamePad.buttonA.isPressed ? ButtonState.Down : ButtonState.Up
                self?.handleFaceButtonInputs(button: GamePadButton.A, state: buttonAState)
            case gamePad.buttonB:
                Logger.info("buttonB pressed:\(gamePad.buttonB.isPressed) value:\(gamePad.buttonB.value)")
                if gamePad.buttonB.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.B)
                }
            case gamePad.buttonX:
                Logger.info("buttonX pressed:\(gamePad.buttonX.isPressed) value:\(gamePad.buttonX.value)")
                if gamePad.buttonX.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.X)
                }
            case gamePad.buttonY:
                Logger.info("buttonY pressed:\(gamePad.buttonY.isPressed) value:\(gamePad.buttonY.value)")
                if gamePad.buttonY.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.Y)
                }
            case gamePad.buttonMenu:
                Logger.info("buttonMenu pressed:\(gamePad.buttonMenu.isPressed) value:\(gamePad.buttonMenu.value)")
                if gamePad.buttonMenu.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.menu)
                }
            case gamePad.buttonHome:
                guard let buttonHome = gamepad.buttonHome else { return }
                Logger.info("buttonHome pressed:\(buttonHome.isPressed) value:\(buttonHome.value)")
                if buttonHome.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.home)
                }
            case gamePad.buttonOptions:
                guard let buttonOptions = gamepad.buttonOptions else { return }
                Logger.info("buttonOptions pressed:\(buttonOptions.isPressed) value:\(buttonOptions.value)")
                if buttonOptions.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.options)
                }
            case gamePad.leftShoulder:
                Logger.info("leftShoulder pressed:\(gamePad.leftShoulder.isPressed) value:\(gamePad.leftShoulder.value)")
                if gamePad.leftShoulder.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.L1)
                }
            case gamePad.rightShoulder:
                Logger.info("rightShoulder pressed:\(gamePad.rightShoulder.isPressed) value:\(gamePad.rightShoulder.value)")
                if gamePad.rightShoulder.isPressed {
                    self?.handleFaceButtonInputs(button: GamePadButton.R1)
                }
                // ------ DPad Buttons ------
            case gamePad.dpad:
                if gamePad.dpad.left.isPressed {
                    self?.handleFaceButtonInputsCombo(button: GamePadButton.left, pressed: true)
                }else if gamePad.dpad.right.isPressed {
                    self?.handleFaceButtonInputsCombo(button: GamePadButton.right, pressed: true)
                }else if gamePad.dpad.up.isPressed {
                    self?.handleFaceButtonInputsCombo(button: GamePadButton.up, pressed: true)
                }else if gamePad.dpad.down.isPressed {
                    self?.handleFaceButtonInputsCombo(button: GamePadButton.down, pressed: true)
                } else {
                    self?.cancelComboTimer()
                    self?.isDapadPressing = false
                }
                // ------ Left Thumbstick ------
            case gamePad.leftThumbstick:
                self?.handleThumbstickEventCombo(thumbstick: gamePad.leftThumbstick, element: ELEMENT.LEFT_THUMBSTICK)
                // ------ Right Thumbstick ------
            case gamePad.rightThumbstick:
                self?.handleThumbstickEventCombo(thumbstick: gamePad.rightThumbstick, element: ELEMENT.RIGHT_THUMBSTICK)
                // ------ Left Trigger ------
            case gamePad.leftTrigger:
                self?.delegate?.handleLeftTriggerValue(value: gamePad.leftTrigger.value, pressed: gamePad.leftTrigger.isPressed)
                // ------ Right Thumbstick ------
            case gamePad.rightTrigger:
                self?.delegate?.handleRightTriggerValue(value: gamePad.rightTrigger.value, pressed: gamePad.rightTrigger.isPressed)
            default:
                break
            }
        }
    }
    
    func cleanButtonsMonitor() {
        if let gamepad = self.connectedController?.extendedGamepad{
            gamepad.valueChangedHandler = nil
        }
    }
    
    private func handleThumbstickEvent(thumbstick : GCControllerDirectionPad , element: ELEMENT) {
        // action: let go
        if(abs(thumbstick.xAxis.value) < THUMBSTICK_THRESHOLD && abs(thumbstick.yAxis.value) < THUMBSTICK_THRESHOLD ) {
            if( element == ELEMENT.LEFT_THUMBSTICK ){
                leftThumbstickLetGo = true
            }else if( element == ELEMENT.RIGHT_THUMBSTICK ){
                rightThumbstickLetGo = true
            }
            return
        }
        
        // action: tap left
        if( thumbstick.xAxis.value < -THUMBSTICK_THRESHOLD ) {
            if(leftThumbstickLetGo == true){
                leftThumbstickLetGo = false
                handleFaceButtonInputs(button:  GamePadButton.left)
            }else if(rightThumbstickLetGo == true){
                rightThumbstickLetGo = false
                handleFaceButtonInputs(button:  GamePadButton.left)
            }
        }
        
        // action: tap right
        else if( thumbstick.xAxis.value > THUMBSTICK_THRESHOLD ) {
            if(leftThumbstickLetGo == true){
                leftThumbstickLetGo = false
                handleFaceButtonInputs(button:  GamePadButton.right)
            }else if(rightThumbstickLetGo == true){
                rightThumbstickLetGo = false
                handleFaceButtonInputs(button:  GamePadButton.right)
            }
        }
        
        // action: tap up
        else if( thumbstick.yAxis.value > THUMBSTICK_THRESHOLD ) {
            if(leftThumbstickLetGo == true){
                leftThumbstickLetGo = false
                handleFaceButtonInputs(button:  GamePadButton.up)
            }else if(rightThumbstickLetGo == true){
                rightThumbstickLetGo = false
                handleFaceButtonInputs(button:  GamePadButton.up)
            }
        }
        
        // action: tap down
        else if( thumbstick.yAxis.value < -THUMBSTICK_THRESHOLD ) {
            if(leftThumbstickLetGo == true){
                leftThumbstickLetGo = false
                self.handleFaceButtonInputs(button:  GamePadButton.down)
            }else if(rightThumbstickLetGo == true){
                rightThumbstickLetGo = false
                handleFaceButtonInputs(button:  GamePadButton.down)
            }
        }
    }
    
    
    private func handleFaceButtonInputsCombo(button: GamePadButton, pressed:Bool) {
        //cancel combo timer
        self.cancelComboTimer()
        isDapadPressing = pressed
        if pressed {
            handleFaceButtonInputs(button:  button)
            debounceSendEvent(button: button)
        }
    }
    
    private func handleThumbstickEventCombo(thumbstick : GCControllerDirectionPad , element: ELEMENT) {
        if shouldPassThumbstickEvent {
            self.handleThumbstickInputs(thumbstick: thumbstick, element: element)
            return
        }
        
        if(abs(thumbstick.xAxis.value) < MINI_THUMBSTICK_THRESHOLD && abs(thumbstick.yAxis.value) < MINI_THUMBSTICK_THRESHOLD ) {
            if comboStatus == .START && lastTriggerElement == element && !isDapadPressing {
                cancelComboTimer()
            }
            return
        }
        
        var button: GamePadButton? = nil
        if thumbstick.xAxis.value < -THUMBSTICK_COMBO_THRESHOLD {
            button = GamePadButton.left
        } else if thumbstick.xAxis.value > THUMBSTICK_COMBO_THRESHOLD {
            button = GamePadButton.right
        } else if thumbstick.yAxis.value < -THUMBSTICK_COMBO_THRESHOLD {
            button = GamePadButton.down
        } else if thumbstick.yAxis.value > THUMBSTICK_COMBO_THRESHOLD {
            button = GamePadButton.up
        }
        
        //cancel combo timer
        if button != lastTriggerButton {
            self.cancelComboTimer()
        }
        
        //combo
        if let btn = button , btn != lastTriggerButton {
//            DispatchQueue.main.async {
                self.joystickSubject.send((thumbstick, element))
                self.debounceSendEvent(button: btn)
//            }
        } else {
//            DispatchQueue.main.async {
                self.handleThumbstickEvent(thumbstick: thumbstick, element: element)
//            }
        }
        lastTriggerButton = button
        lastTriggerElement = element
        
    }
    
    private func cancelComboTimer() {
        if comboStatus == .STOP {
            return
        }
        Logger.debug("⚠️ cancelComboTimer")
        comboStatus = .STOP
        shortTermSubcriptions.removeAll()
        if let timer = comboTimer,!timer.isCancelled {
            timer.cancel()
            comboTimer = nil
        }
    }
    
    private func debounceSendEvent(button: GamePadButton) {
        comboStatus = .START
        debounceSubject.debounce(for: RunLoop.SchedulerTimeType.Stride(TimeInterval(DEFAUT_COMBO_DEBOUNCE_INTERVAL)), scheduler: RunLoop.main)
            .sink { [weak self] button in
                self?.fireCombo(button: button)
            }.store(in: &shortTermSubcriptions)
        debounceSubject.send(button)
    }
    
    private func fireCombo(button: GamePadButton) {
        comboTimer = DispatchSource.makeTimerSource(queue: comboTimerQueue)
        comboTimer?.schedule(deadline: .now(), repeating: TimeInterval(DEFAUT_COMBO_TIME_INTERVAL))
        comboTimer?.setEventHandler(handler: {
            if self.comboStatus == .STOP {
                self.cancelComboTimer()
                return
            }
            //Sometimes the timer cannot be canceled normally, so a status judgment is added here
            self.handleFaceButtonInputs(button: button)
        })
        comboTimer?.resume()
    }
    
    private func handleFaceButtonInputs(button: GamePadButton, state: ButtonState = .Down) {
        Logger.debug("ZZZ Button Pressed: \(button.description)")
        self.delegate?.handleFaceButtonInputs(button: button, state: state)
    }
    
    private func handleThumbstickInputs(thumbstick : GCControllerDirectionPad , element: ELEMENT) {
//        Logger.debug("Thumbstick Inputs: \(thumbstick.xAxis.value), yAxis: \(thumbstick.yAxis.value)")
        if( element == ELEMENT.LEFT_THUMBSTICK ){
            self.delegate?.handleLeftJoystickValueEvents(xAxis: CGFloat(thumbstick.xAxis.value), yAxis: CGFloat(thumbstick.yAxis.value))
        }else if( element == ELEMENT.RIGHT_THUMBSTICK ){
            self.delegate?.handleRightJoystickValueEvents(xAxis: CGFloat(thumbstick.xAxis.value), yAxis: CGFloat(thumbstick.yAxis.value))
        }
    }
    
}
