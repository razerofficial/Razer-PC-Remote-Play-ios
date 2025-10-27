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
import UIKit
import CocoaLumberjack
import Combine

public class KeyboardHandlingViewController: UIViewController {
    @Published var hasReceivedHardwareKeyboardEvent: Bool = false {
        didSet {
            if hasReceivedHardwareKeyboardEvent {
                debounceKeyboardEventReset()
            }
        }
    }
    private var keyboardEventResetWorkItem: DispatchWorkItem?

    private func debounceKeyboardEventReset() {
        keyboardEventResetWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hasReceivedHardwareKeyboardEvent = false
        }
        keyboardEventResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        becomeFirstResponder()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.debug("🎹KeyboardHandlingViewController viewDidAppear, try becomeFirstResponder")
        becomeFirstResponder()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Logger.debug("🎹KeyboardHandlingViewController viewWillDisappear, resignFirstResponder")
        resignFirstResponder()
    }

    public override var canBecomeFirstResponder: Bool {
        Logger.debug("🎹KeyboardHandlingViewController canBecomeFirstResponder")
        return true
    }

    public override func resignFirstResponder() -> Bool {
        Logger.debug("🎹KeyboardHandlingViewController resignFirstResponder called")
        return super.resignFirstResponder()
    }

    private func isTextInputActive() -> Bool {
        if let window = UIApplication.shared.keyWindowInConnectedScenes,
           let firstResponder = window.findFirstResponder() {
            Logger.debug("🎹Active text field detected: \(firstResponder is UITextView || firstResponder is UITextField)")
            return firstResponder is UITextView || firstResponder is UITextField
        }
        Logger.debug("🎹No active text field detected")
        return false
    }

    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        hasReceivedHardwareKeyboardEvent = true
        for press in presses {
            guard let key = press.key else { continue }
            let input = key.charactersIgnoringModifiers
            Logger.debug("🎹KeyboardHandlingViewController keyboard pressesBegan: \(input)")
            switch input {
            case UIKeyCommand.inputUpArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .up, pressed: true)
            case UIKeyCommand.inputDownArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .down, pressed: true)
            case UIKeyCommand.inputLeftArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .left, pressed: true)
            case UIKeyCommand.inputRightArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .right, pressed: true)
            case "\r", " ", "A", "a":
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .A, state: .Down)
            case UIKeyCommand.inputEscape:
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .B)
            case "B", "b":
                if isTextInputActive() {
                    Logger.debug("🎹KeyboardHandlingViewController Ignored keyboard key: \(input) because text field is active")
                } else {
                    ControllerInputTracker.shared.handleFaceButtonInputs(button: .B)
                }
            case "X", "x":
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .X)
            case "Y", "y":
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .Y)
            default:
                Logger.debug("🎹KeyboardHandlingViewController Ignored keyboard key: \(input)")
            }
        }
        super.pressesBegan(presses, with: event)
    }

    public override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            let input = key.charactersIgnoringModifiers
            Logger.debug("🎹KeyboardHandlingViewController keyboard pressesEnded : \(input)")
            switch input {
            case UIKeyCommand.inputUpArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .up, pressed: false)
            case UIKeyCommand.inputDownArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .down, pressed: false)
            case UIKeyCommand.inputLeftArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .left, pressed: false)
            case UIKeyCommand.inputRightArrow:
                ControllerInputTracker.shared.handleFaceButtonInputsCombo(button: .right, pressed: false)
            case "\r", " ", "A", "a":
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .A, state: .Up)
            case UIKeyCommand.inputEscape, "B", "b":
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .B, state: .Up)
            case "X", "x":
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .X, state: .Up)
            case "Y", "y":
                ControllerInputTracker.shared.handleFaceButtonInputs(button: .Y, state: .Up)
                break
            default:
                break
            }
        }
        super.pressesEnded(presses, with: event)
    }
}
extension UIView {
    public func findFirstResponder() -> UIView? {
        if self.isFirstResponder { return self }
        for subview in subviews {
            if let responder = subview.findFirstResponder() {
                return responder
            }
        }
        return nil
    }
}
