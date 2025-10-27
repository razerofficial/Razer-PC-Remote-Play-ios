//
//  SwiftAlertView.swift
//  SwiftAlertView
//
//  Created by Dinh Quan on 8/26/15.
//  Copyright (c) 2015 Dinh Quan. All rights reserved.
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import SwiftUI
import CocoaLumberjack
import SnapKit

public class SwiftAlertView: UIView {
    /// 根據 SettingsUtil.shared.windowsScale 設定縮放比例
    private func applyWindowScale() {
        let scale = DashboardViewModel.shared.portraitBaseScale//SettingsUtil.shared.windowsScale
        print("SwiftAlertView applyWindowScale: \(scale)")
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    public enum Style {
        //case auto
        case light
        case dark
    }

    public enum TransitionType {
        case `default`
        case fade
        case vertical
    }

    public enum ActionButtonType {
        case normal  // blue
        case cancel  // red
        case confirm // blue + bold
    }
    
    // MARK: Public Properties
    
    public weak var delegate: SwiftAlertViewDelegate?
    
    public var style: Style = .light
    //{ // default is based on system color
        //didSet {
        //    updateAlertStyle()
        //}
    //}

    public var titleLabel: UILabel! // access titleLabel to customize the title font, color
    public var messageLabel: UILabel! // access messageLabel to customize the message font, color
    
    public var isShowing = false
    //public var backgroundImage: UIImage?
    // public var backgroundColor: UIColor? // inherits from UIView
    
    /*
    public var cancelButtonIndex = 0 { // default is 0, set this property if you want to change the position of cancel button
        didSet {
            updateCancelButtonIndex()
        }
    }*/
    //public var buttonTitleColor = UIColor(red: 0, green: 0.478431, blue: 1, alpha: 1) // to change the title color of all buttons
    public var buttonHeight: CGFloat = 44.0
    
    public var separatorColor = UIColor(red: 196.0/255, green: 196.0/255, blue: 201.0/255, alpha: 1.0) // to change the separator color
    public var isHideSeparator = false
    public var cornerRadius: CGFloat = 12.0

    // default is true, if you want the alert to not be dismissed
    // when clicking on action buttons, set this property to false
    public var isDismissOnActionButtonClicked = false
    
    public var isHighlightOnButtonClicked = true
    public var isDimBackgroundWhenShowing = true
    public var isDismissOnOutsideTapped = false
    public var dimAlpha: CGFloat = 0.4
    public var dimBackgroundColor: UIColor? = .init(white: 0, alpha: 0.4)

    public var appearTime = 0.2
    public var disappearTime = 0.1
    
    public var transitionType: TransitionType = .fade
    
    // customize the margin & spacing of title & message
    public var titleSideMargin: CGFloat = 20.0
    public var messageSideMargin: CGFloat = 20.0
    public var titleTopMargin: CGFloat = 20.0
    public var messageBottomMargin: CGFloat = 20.0
    public var titleToMessageSpacing: CGFloat = 20.0
    
    // customize text fields
    public var textFieldHeight: CGFloat = 34.0
    public var textFieldSideMargin: CGFloat = 15.0
    public var textFieldBottomMargin: CGFloat = 15.0
    public var textFieldSpacing: CGFloat = 10.0
    public var isFocusTextFieldWhenShowing = true
    public var isEnabledValidationLabel = false
    public var validationLabel: UILabel! // access to validation label to customize font, color
    public var validationLabelTopMargin: CGFloat = 8.0
    public var validationLabelSideMargin: CGFloat = 15.0

    
    // MARK: Constants
    
    private let kSeparatorWidth: CGFloat = 0.5
    private var kDefaultWidth: CGFloat = IsIOS26() ? 300.0 : 270.0
    private let kDefaultHeight: CGFloat = 144.0
    private let kDefaultTitleSizeMargin: CGFloat = 20.0
    private let kDefaultMessageSizeMargin: CGFloat = 20.0
    private let kDefaultButtonHeight: CGFloat = 44.0
    private let kDefaultCornerRadius: CGFloat = 12.0
    private let kDefaultTitleTopMargin: CGFloat = 20.0
    private let kDefaultTitleToMessageSpacing: CGFloat = 10.0
    private let kDefaultMessageBottomMargin: CGFloat = 20.0
    private let kDefaultDimAlpha: CGFloat = 0.2
    private let kDefaultAppearTime = 0.2
    private let kDefaultDisappearTime = 0.1
    private var kMoveUpWithKeyboardDistance: CGFloat = 150.0
    private let darkModeBackgroundColor = UIColor(white: 0.16, alpha: 1)
    private let lightModeBackgroundColor = UIColor(red: 218.0/255, green: 218.0/255, blue: 218.0/255, alpha: 1)

    // MARK: Private Properties
    
    // buttons
    private var alertButtons: [AlertButton] = []
    private var focusedButtonId = ""
    private let buttonTagDictionary = ButtonTagDictionary()
    // others
    private var textFields: [UITextField] = []
    private var backgroundImageView: UIImageView?
    private var dimView: UIView?
    private var title: String?
    private var message: String?
    private var attributedMessage: NSAttributedString?
    private var viewWidth: CGFloat = 0
    private var viewHeight: CGFloat = 0
    // private var isMoveUpWithKeyboard = false
    
    private var onButtonClicked: ((_ buttonId: String) -> Void)?
    var onCancelClicked: (() -> Void)?
    private var onActionButtonClicked: ((_ buttonIndex: Int) -> (Void))?
    private var onTextChanged: ((_ text: String?, _ textFieldIndex: Int) -> Void)?
    
    private var bgView:UIView?//UIVisualEffectView?

    // MARK: Initialization
    
    // The parameter "colorScheme" can be obtained in SwiftUI View classes with the syntax:
    @Environment(\.colorScheme) var colorScheme
    public init(title: String? = nil, message: String? = nil, alertButtons: [AlertButton], colorScheme: SwiftUI.ColorScheme) {
        super.init(frame: CGRect(x: 0, y: 0, width: kDefaultWidth, height: kDefaultHeight))
        applyWindowScale()
        // observe keyboard show/hide notifications to move up the alert view
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // cache params
        self.title = title
        self.message = message
        self.alertButtons = alertButtons
        
        var maxWidth = kDefaultWidth
        for alertbutton in alertButtons {
            let text = alertbutton.title
            let textWidth = text.boundingRect(with: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), options: .usesFontLeading, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)], context: nil).width + 20.0
            maxWidth = max(textWidth, maxWidth)
        }
        
        let orginFrame = frame
        kDefaultWidth = maxWidth
        let newFrame = CGRect(x: orginFrame.minX, y: orginFrame.minY, width: maxWidth, height: orginFrame.height)
        frame = newFrame
        
        setNeedsLayout()
        
        // init buttonTagDictionary
        self.buttonTagDictionary.clear()
        for (index, alertButton) in alertButtons.enumerated() {
            self.buttonTagDictionary.append(tagValue: index, buttonId: alertButton.id)
        }
        
        // set style
        if( colorScheme == .dark ){
            printLog("colorScheme == dark")
            self.style = .dark
        }else{
            printLog("colorScheme == light")
            self.style = .light
        }

        setUpDefaultValue()
        setUpElements()
        setUpDefaultAppearance()
        updateAlertStyle()

        if title == nil || message == nil {
            titleToMessageSpacing = 0
        }
    }
    
    // The parameter "colorScheme" can be obtained in SwiftUI View classes with the syntax:
    // @Environment(\.colorScheme) var colorScheme
    public init(title: String? = nil, attributedMessage: NSAttributedString? = nil, alertButtons: [AlertButton], colorScheme: SwiftUI.ColorScheme) {
        super.init(frame: CGRect(x: 0, y: 0, width: kDefaultWidth, height: kDefaultHeight))
    applyWindowScale()
        
        // cache params
        self.title = title
        self.attributedMessage = attributedMessage
        self.alertButtons = alertButtons
        
        // init buttonTagDictionary
        self.buttonTagDictionary.clear()
        for (index, alertButton) in alertButtons.enumerated() {
            self.buttonTagDictionary.append(tagValue: index, buttonId: alertButton.id)
        }
        
        // set style
        if( colorScheme == .dark ){
            printLog("colorScheme == dark")
            self.style = .dark
        }else{
            printLog("colorScheme == light")
            self.style = .light
        }

        setUpDefaultValue()
        setUpElements()
        setUpDefaultAppearance()
        updateAlertStyle()

        if title == nil || attributedMessage == nil {
            titleToMessageSpacing = 0
        }
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public Methods
    
    public func getFocusedButtonId() -> String {
        return focusedButtonId
    }
    
    public func setFocusToButton(buttonId: String) {
        
        if( alertButtons.isEmpty ){
            printLog("Alert has no button")
            return
        }
        
        // cache focused button id
        if( focusedButtonId.isEmpty ){
            // was not focused, set focus to the left most button
            focusedButtonId = alertButtons[0].id
        } else {
            focusedButtonId = buttonId
        }
        
        // update bg colors
        for alertButton in alertButtons {
            if alertButton.id == focusedButtonId {
                let focusColor = color(light: UIColor(red: 192.0/255, green: 195.0/255, blue: 199.0/255, alpha: 1.0),
                                       dark: UIColor(red: 75.0/255, green: 77.0/255, blue: 79.0/255, alpha: 1.0))
                alertButton.view!.backgroundColor = focusColor
            } else{
                var bgColor = color(light: lightModeBackgroundColor, dark: darkModeBackgroundColor)
                if #available(iOS 26.0, *) {
                    bgColor = color(light: UIColor(red: 192.0/255, green: 195.0/255, blue: 199.0/255, alpha: 0.1),
                                    dark: UIColor(red: 75.0/255, green: 77.0/255, blue: 79.0/255, alpha: 0.1))
                }
                alertButton.view!.backgroundColor = bgColor
            }
        }
    }
    
    /*
    // access the buttons to customize their font & color
    public func button(at index: Int) -> UIButton? {
        if index >= 0 && index < buttons.count {
            return buttons[index]
        }
        
        return nil
    }*/
    
    // access the text fields to customize their font & color
    public func textField(at index: Int) -> UITextField? {
        if index >= 0 && index < textFields.count {
            return textFields[index]
        }
        
        return nil
    }
    
    public func addTextField(configurationHandler: ((UITextField) -> Void)? = nil) {
        let textField = UITextField(frame: CGRect(x: textFieldSideMargin, y: 0, width: viewWidth - textFieldSideMargin * 2, height: textFieldHeight))
        textField.font = .systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.delegate = self
        textField.tag = textFields.count
        textField.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
        configurationHandler?(textField)
        textFields.append(textField)
        addSubview(textField)
    }
    
    // show the alert view at center of screen
    public func show() {
        isShowing = true
        if let window = currentWindowScene()?.windows.filter({$0.isKeyWindow}).first {
            show(in: window)
        } else {
            isShowing = false
        }
    }
    
    // show the alert view at center of a view
    public func show(in view: UIView) {
        layoutElementBeforeShowing()
        
        let isFocusTextField = isFocusTextFieldWhenShowing && !textFields.isEmpty
        // var showY = (view.frame.size.height - viewHeight)/2
        // if isFocusTextField {
        //     showY -= kMoveUpWithKeyboardDistance
        //     isMoveUpWithKeyboard = true
        // }
        
        frame = CGRect(x: (view.frame.size.width - viewWidth)/2, y: (view.frame.size.height - viewHeight)/2, width: viewWidth, height: viewHeight)

        if isDimBackgroundWhenShowing {
            dimView = UIView(frame: view.bounds)
            if let color = dimBackgroundColor {
                dimView!.backgroundColor = color
            } else {
                dimView!.backgroundColor = UIColor(white: 0, alpha: CGFloat(dimAlpha))
            }
            view.addSubview(dimView!)
            dimView?.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(outsideTapped(_:)))
            dimView!.addGestureRecognizer(recognizer)
        }
        
        if isFocusTextField {
            textFields[0].becomeFirstResponder()
        }
        
        delegate?.willPresentAlertView?(self)

        view.addSubview(self)
        view.bringSubviewToFront(self)
        
        snp.makeConstraints { make in
            // make.center.equalTo(view) will cause alert view position change when use tap text field again and behind the keyboard
            make.centerX.equalTo(view)
//            make.top.equalTo(view).offset((view.frame.size.height - viewHeight)/2)
            make.centerY.equalTo(view)
            make.width.equalTo(viewWidth)
            make.height.equalTo(viewHeight)
        }
        
        switch transitionType {
        case .default:
            if isFocusTextField {
                alpha = 0
                transform = CGAffineTransform(translationX: 0, y: 60)
                    .concatenating(CGAffineTransform(scaleX: 1.1, y: 1.1))
                UIView.animate(withDuration: appearTime, delay: 0, options: .curveEaseInOut) {
                    self.transform = CGAffineTransform.identity
                    self.alpha = 1
                } completion: { _ in
                    self.delegate?.didPresentAlertView?(self)
                }
            } else {
                transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                alpha = 0.6

                UIView.animate(withDuration: appearTime) {
                    self.transform = CGAffineTransform.identity
                    self.alpha = 1
                } completion: { _ in
                    self.delegate?.didPresentAlertView?(self)
                }
            }
        case .fade:
            alpha = 0

            UIView.animate(withDuration: appearTime, delay: 0, options: .curveEaseInOut) {
                self.alpha = 1
            } completion: { _ in
                self.delegate?.didPresentAlertView?(self)
            }
        case .vertical:
            let tempFrame = frame
            frame = CGRect(x: frame.origin.x, y: superview!.frame.size.height + 10, width: frame.size.width, height: frame.size.height)

            UIView.animate(withDuration: appearTime, delay: 0, options: .curveEaseInOut) {
                self.frame = tempFrame
            } completion: { _ in
                self.delegate?.didPresentAlertView?(self)
            }
        }
    }
    
    // dismiss the alert view programmatically
    public func dismiss() {
        
        isShowing = false
        // stop observing keyboard notifications
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)

        self.delegate?.willDismissAlertView?(self)

        for textField in textFields {
            textField.resignFirstResponder()
        }
        
        if dimView != nil {
            UIView.animate(withDuration: disappearTime) {
                self.dimView?.alpha = 0
            } completion: { _ in
                self.dimView?.removeFromSuperview()
                self.dimView = nil
            }
        }

        switch transitionType {
        case .default:
            transform = CGAffineTransform.identity

            UIView.animate(withDuration: disappearTime, delay: 0.02, options: .curveEaseOut) {
                self.alpha = 0
            } completion: { _ in
                self.removeFromSuperview()
                self.delegate?.didDismissAlertView?(self)
            }
        case .fade:
            self.alpha = 1

            UIView.animate(withDuration: disappearTime, delay: 0.02, options: .curveEaseOut) {
                self.alpha = 0
            } completion: { _ in
                self.removeFromSuperview()
                self.delegate?.didDismissAlertView?(self)
            }
        case .vertical:
            UIView.animate(withDuration: disappearTime, delay: 0.02, options: .curveEaseOut) {
                self.frame = CGRect(x: self.frame.origin.x, y: self.superview!.frame.size.height + 10, width: self.frame.size.width, height: self.frame.size.height)
            } completion: { _ in
                self.removeFromSuperview()
                self.delegate?.didDismissAlertView?(self)
            }
        }
    }
    
    // handle events
    @discardableResult
    public func onButtonClicked(_ handler: @escaping (_ alertView: SwiftAlertView, _ buttonId: String) -> Void) -> SwiftAlertView {
        self.onButtonClicked = { buttonId in
            handler(self, buttonId)
        }
        return self
    }
    
    @discardableResult
    public func onActionButtonClicked(_ handler: @escaping (_ alertView: SwiftAlertView, _ buttonIndex: Int) -> Void) -> SwiftAlertView {
        self.onActionButtonClicked = { index in
            handler(self, index)
        }
        return self
    }
    
    @discardableResult
    public func onTextChanged(_ handler: @escaping (_ alertView: SwiftAlertView, _ text: String?, _ textFieldIndex: Int) -> Void) -> SwiftAlertView {
        self.onTextChanged = { text, index in
            handler(self, text, index)
        }
        return self
    }
}

// MARK: Private Functions

extension SwiftAlertView {

    private func printLog(_ msg:String) {
        DDLogInfo("SwiftAlertView > " + msg)
    }

    private func setUpDefaultValue() {
        clipsToBounds = true
        viewWidth = kDefaultWidth
        viewHeight = kDefaultHeight
        titleSideMargin = kDefaultTitleSizeMargin
        messageSideMargin = kDefaultMessageSizeMargin
        buttonHeight = kDefaultButtonHeight
        titleTopMargin = kDefaultTitleTopMargin
        titleToMessageSpacing = kDefaultTitleToMessageSpacing
        messageBottomMargin = kDefaultMessageBottomMargin
        dimAlpha = kDefaultDimAlpha
        isDimBackgroundWhenShowing = true
        isDismissOnActionButtonClicked = true
        isHighlightOnButtonClicked = true
        isDismissOnOutsideTapped = false
        isHideSeparator = false
        cornerRadius = kDefaultCornerRadius
        appearTime = kDefaultAppearTime
        disappearTime = kDefaultDisappearTime
        transitionType = .default
        //buttonTitleColor = UIColor(red: 0, green: 0.478431, blue: 1, alpha: 1)
        layer.cornerRadius = CGFloat(cornerRadius)
        
        //ios26
        if #available(iOS 26.0, *) {
            self.cornerConfiguration = .uniformCorners(radius: 34.0)
            isHideSeparator = true
        }
    }
    
    private func setUpElements() {
        titleLabel = UILabel(frame: .zero)
        messageLabel = UILabel(frame: .zero)
        validationLabel = UILabel(frame: .zero)

        if title != nil {
            titleLabel.text = title
            addSubview(titleLabel)
        }
        if message != nil {
            messageLabel.text = message
            addSubview(messageLabel)
        }
        if attributedMessage != nil {
            messageLabel.attributedText = attributedMessage
            addSubview(messageLabel)
        }
        
        for alertButton in alertButtons {
            let buttonView = UIButton(type: .custom)
            buttonView.setTitle(alertButton.title, for: .normal)
            alertButton.view = buttonView
            //GlassEffect
            if #available(iOS 26.0, *) {
//                var config = UIButton.Configuration.glass()
//                config.title = alertButton.title
//                buttonView.configuration = config
                buttonView.layer.cornerRadius = buttonHeight / 2.0
                buttonView.layer.masksToBounds = true
            }
            addSubview(alertButton.view!)
        }
    }
    
    private func setUpDefaultAppearance() {
        self.backgroundColor = lightModeBackgroundColor// UIColor(red: 245.0/255, green: 245.0/255, blue: 245.0/255, alpha: 1)
        
        if #available(iOS 26.0, *) {
            
            self.backgroundColor = .clear
            
            if bgView == nil {
                
//                bgView = UIVisualEffectView()
//                bgView?.contentView.backgroundColor = .clear
//                bgView?.backgroundColor = .init(hex: 0x000000, alpha: 0.1)
//                bgView?.layer.cornerRadius = 34.0
//
//                let glassEffect = UIGlassEffect.init(style: .regular)
//                glassEffect.tintColor = .clear
//                glassEffect.isInteractive = true
//                bgView?.effect = glassEffect
//
//                insertSubview(bgView!, at: 0)
//                bgView?.snp.makeConstraints { make in
//                    make.edges.equalToSuperview()
//                }
                
                let hostingController = UIHostingController(rootView: GlassEffectView.init(radius:34.0,color: SettingsUtil.shared.glassBgColor()))
                hostingController.view.backgroundColor = .clear
                if let view = hostingController.view {
                    bgView = view
                    insertSubview(view, at: 0)
                    view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
                
//                backgroundColor = .clear
//                layer.cornerRadius = 0.0
//                clipsToBounds = false
            }

        }
        
        if title != nil {
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            titleLabel.textColor = UIColor.black
            titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
            if #available(iOS 26.0, *) {
                titleLabel.textAlignment = NSTextAlignment.left
            } else {
                titleLabel.textAlignment = NSTextAlignment.center
            }
            
            titleLabel.backgroundColor = .clear
        }
        
        if message != nil {
            messageLabel.numberOfLines = 0
            messageLabel.lineBreakMode = .byWordWrapping
            messageLabel.textColor = .black
            messageLabel.font = UIFont.systemFont(ofSize: 14)
            //if title == nil {
            //    messageLabel.font = UIFont.boldSystemFont(ofSize: 17)
            //}
            if #available(iOS 26.0, *) {
                messageLabel.textAlignment = .left
            } else {
                messageLabel.textAlignment = .center
            }
            messageLabel.backgroundColor = .clear
        }
        
        if attributedMessage != nil {
            messageLabel.numberOfLines = 0
            messageLabel.lineBreakMode = .byWordWrapping
            messageLabel.textColor = .black
            messageLabel.font = UIFont.systemFont(ofSize: 14)
            //if title == nil {
            //    messageLabel.font = UIFont.boldSystemFont(ofSize: 17)
            //}
            if #available(iOS 26.0, *) {
                messageLabel.textAlignment = .left
            } else {
                messageLabel.textAlignment = .center
            }
            messageLabel.backgroundColor = .clear
        }
        
        validationLabel.text = " "
        validationLabel.numberOfLines = 0
        validationLabel.lineBreakMode = .byWordWrapping
        validationLabel.textColor = .red
        validationLabel.font = .systemFont(ofSize: 14)
        validationLabel.textAlignment = .left
        
        // buttons
        for alertButton in alertButtons {
            // update tag
            alertButton.view?.tag = buttonTagDictionary.getTagValue(buttonId: alertButton.id)
            // set view colors
            alertButton.view?.backgroundColor = .clear
            
            // set text style
            if alertButton.type == .confirm {
                alertButton.view?.setTitleColor(blueTextColor, for: .normal)
                alertButton.view?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            }
            if alertButton.type == .normal {
                alertButton.view?.setTitleColor(blueTextColor, for: .normal)
                alertButton.view?.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            }
            if alertButton.type == .cancel {
                alertButton.view?.setTitleColor(redTextColor, for: .normal)
                alertButton.view?.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            }
            //if button.tag == cancelButtonIndex {
            //    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            //} else {
            //    button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            //}
            
            //
            if #available(iOS 26.0, *) {
               let bgColor = color(light: UIColor(red: 192.0/255, green: 195.0/255, blue: 199.0/255, alpha: 0.1),
                                dark: UIColor(red: 75.0/255, green: 77.0/255, blue: 79.0/255, alpha: 0.1))
                alertButton.view?.backgroundColor = bgColor
                
                // set text style
                if alertButton.type == .confirm {
                    alertButton.view?.setTitleColor(Color.hex(0x44D62C).uiColor(), for: .normal)
                }
                if alertButton.type == .normal {
                    alertButton.view?.setTitleColor(.white, for: .normal)
                }
                if alertButton.type == .cancel {
                    alertButton.view?.setTitleColor(.white, for: .normal)
                }
            }
        }
    }
    
    private func layoutElementBeforeShowing() {
        //if let backgroundImage = backgroundImage {
        //    backgroundImageView = UIImageView(frame: self.bounds)
        //    backgroundImageView?.image = backgroundImage
        //    addSubview(backgroundImageView!)
        //    sendSubviewToBack(backgroundImageView!)
        //}

        /*
        var i = 0
        for button in buttons {
            button.tag = i
            i += 1
            
            if !buttonTitleColor.isEqual(UIColor(red: 0, green: 0.478431, blue: 1, alpha: 1)) {
                button.setTitleColor(buttonTitleColor, for: .normal)
            }
            
            button.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        }*/
        for alertButton in alertButtons {
            // update tag
            alertButton.view?.tag = buttonTagDictionary.getTagValue(buttonId:  alertButton.id)
            // set view color
            //if !buttonTitleColor.isEqual(UIColor(red: 0, green: 0.478431, blue: 1, alpha: 1)) {
            //    alertButton.view?.setTitleColor(buttonTitleColor, for: .normal)
            //}
            alertButton.view?.addTarget(self, action: #selector(buttonClicked(_:)), for: .touchUpInside)
        }
        
        
        if title != nil {
            titleLabel.frame = CGRect(x: 0, y: 0, width: viewWidth - titleSideMargin*2, height: 0)
            labelHeightToFit(titleLabel)
        }
        if message != nil {
            messageLabel.frame = CGRect(x: 0, y: 0, width: viewWidth - messageSideMargin*2, height: 0)
            labelHeightToFit(messageLabel)
        }
        if attributedMessage != nil {
            messageLabel.frame = CGRect(x: 0, y: 0, width: viewWidth - messageSideMargin*2, height: 0)
            labelHeightToFit(messageLabel)
        }
        if title != nil {
            titleLabel.center = CGPoint(x: viewWidth/2, y: titleTopMargin + titleLabel.frame.size.height/2)
        }
        if message != nil {
            messageLabel.center = CGPoint(x: viewWidth/2, y: titleTopMargin + titleLabel.frame.size.height + titleToMessageSpacing + messageLabel.frame.size.height/2)
        }
        if attributedMessage != nil {
            messageLabel.center = CGPoint(x: viewWidth/2, y: titleTopMargin + titleLabel.frame.size.height + titleToMessageSpacing + messageLabel.frame.size.height/2)
        }
        
        let titleMessageHeight = titleTopMargin + titleLabel.frame.size.height + titleToMessageSpacing + messageLabel.frame.size.height + messageBottomMargin
        for i in 0..<textFields.count {
            let textField = textFields[i]
            textField.frame = CGRect(x: textField.frame.minX, y: titleMessageHeight + CGFloat(i) * (textField.frame.height + textFieldSpacing), width: textField.frame.width, height: textField.frame.height)
        }
        
        let textFieldPartHeight = textFields.isEmpty ? 0 : (textFields[0].frame.height + textFieldSpacing) * CGFloat(textFields.count) + textFieldBottomMargin - textFieldSpacing
        //var topPartHeight = (contentView == nil) ? (titleMessageHeight + textFieldPartHeight) : contentView!.frame.size.height
        var topPartHeight = (titleMessageHeight + textFieldPartHeight)
        
        if isEnabledValidationLabel {
            addSubview(validationLabel)
            validationLabel.frame = CGRect(x: validationLabelSideMargin, y: topPartHeight + validationLabelTopMargin - textFieldBottomMargin, width: viewWidth - validationLabelSideMargin * 2, height: 0)
            labelHeightToFit(validationLabel)
            topPartHeight += validationLabel.frame.height + validationLabelTopMargin
        }
        
        // buttons
        if alertButtons.count == 2 {
            
            var buttonWidth = viewWidth/2
            var letfSpace = 0.0
            var midSpace = 0.0
            var buttonBottomSpace = 0.0
            //ios26
            if #available(iOS 26.0, *) {
                letfSpace = 14.0
                midSpace = 16.0
                buttonWidth = buttonWidth - letfSpace - midSpace / 2.0
                buttonBottomSpace = 14.0
            }
            
            var singleLine:Bool = false
            for button in alertButtons {
                if let font = button.view?.titleLabel?.font {
                    let width = button.title.textAutoWidth(height: buttonHeight, font: font)
                    if width > (buttonWidth - 20) {
                        singleLine = true
                    }
                }
            }
            
            drawButtonInSingleLine(singleLine, topPartHeight: topPartHeight)

        } else {
            drawButtonInSingleLine(true, topPartHeight: topPartHeight)
        }
    }
    
    func drawButtonInSingleLine(_ single: Bool , topPartHeight: CGFloat ) {
        if single {
            var buttonWidth = viewWidth
            var letfSpace = 0.0
            var buttonBottomSpace = 0.0
            var buttonSpace = 0.0
            //ios26
            if #available(iOS 26.0, *) {
                letfSpace = 14.0
                buttonWidth = buttonWidth - letfSpace * 2.0
                buttonBottomSpace = 14.0
                buttonSpace = 10.0
            }
            
            viewHeight = topPartHeight + (buttonHeight + buttonSpace) * CGFloat(alertButtons.count) + buttonBottomSpace
            
            var j = 1
            for alertButton in alertButtons.reversed() {
                let button = alertButton.view!
                button.frame = CGRect(x: letfSpace , y: viewHeight - (buttonHeight + buttonSpace) * CGFloat(j) - buttonBottomSpace, width: buttonWidth, height: buttonHeight)
                j += 1
                if !isHideSeparator {
                    let lineView = UIView(frame: CGRect(x: 0, y: button.frame.origin.y, width: viewWidth, height: kSeparatorWidth))
                    lineView.backgroundColor = separatorColor
                    addSubview(lineView)
                }
            }
            
        }else{
            
            var buttonWidth = viewWidth/2
            var letfSpace = 0.0
            var midSpace = 0.0
            var buttonBottomSpace = 0.0
            //ios26
            if #available(iOS 26.0, *) {
                letfSpace = 14.0
                midSpace = 16.0
                buttonWidth = buttonWidth - letfSpace - midSpace / 2.0
                buttonBottomSpace = 14.0
            }
            
            viewHeight = topPartHeight + buttonHeight + buttonBottomSpace
            let leftButton = alertButtons[0].view!
            let rightButton = alertButtons[1].view!
            
            leftButton.frame = CGRect(x: letfSpace, y: viewHeight-buttonHeight - buttonBottomSpace, width: buttonWidth, height: buttonHeight)
            rightButton.frame = CGRect(x: viewWidth/2 + midSpace / 2.0 , y: viewHeight-buttonHeight - buttonBottomSpace, width: buttonWidth, height: buttonHeight)
            
            if !isHideSeparator {
                let horLine = UIView(frame: CGRect(x: 0, y: leftButton.frame.origin.y, width: viewWidth, height: kSeparatorWidth))
                horLine.backgroundColor = separatorColor
                addSubview(horLine)
                
                let verLine = UIView(frame: CGRect(x: viewWidth/2, y: leftButton.frame.origin.y, width: kSeparatorWidth, height: leftButton.frame.size.height))
                verLine.backgroundColor = separatorColor
                addSubview(verLine)
            }
        }
    }
    
    /*
    private func updateCancelButtonIndex() {
        for i in 0..<buttons.count {
            let button = buttons[i]
            if i == cancelButtonIndex {
                button.titleLabel?.font = .boldSystemFont(ofSize: button.titleLabel?.font.pointSize ?? 17)
            } else {
                button.titleLabel?.font = .systemFont(ofSize: button.titleLabel?.font.pointSize ?? 17)
            }
        }
    }*/
    
    // red text color for cancel button
    private var redTextColor: UIColor {
        color(light: UIColor(red: 255.0/255, green: 59.0/255, blue: 48.0/255, alpha: 1),
                     dark: UIColor(red: 255.0/255, green: 69.0/255, blue: 58.0/255, alpha: 1))
    }
    
    // blue text color for confirm/normal button
    private var blueTextColor: UIColor {
        color(light: UIColor(red: 0/255, green: 122.0/255, blue: 255.0/255, alpha: 1),
              dark: UIColor(red: 10.0/255, green: 132.0/255, blue: 255.0/255, alpha: 1))
    }
    
    private func updateAlertStyle() {
        titleLabel.textColor = color(light: .black, dark: .white)
        messageLabel.textColor = color(light: .black, dark: .white)
        if IsIOS26() == false {
            backgroundColor = color(light: lightModeBackgroundColor, dark: darkModeBackgroundColor)
        }
        separatorColor = color(light: UIColor(red: 196.0/255, green: 196.0/255, blue: 201.0/255, alpha: 1.0), dark: UIColor(white: 0.4, alpha: 1))
        
        for textField in textFields {
            textField.backgroundColor = color(light: .white, dark: UIColor(white: 0.1, alpha: 1))
            textField.textColor = color(light: .black, dark: .white)
        }
        
        if style == .dark {
            dimAlpha = 0.4
            for textField in textFields {
                textField.layer.borderColor = UIColor(white: 0.4, alpha: 1).cgColor
                textField.layer.borderWidth = 0.5
                textField.layer.cornerRadius = 6
            }
        }
    }
    
    
    // MARK: Actions
    
    @objc private func buttonClicked(_ button: UIButton) {
        
        let tagValue = button.tag
        let buttonId = buttonTagDictionary.getButtonId(tagValue: tagValue)
        
        //let buttonIndex = button.tag
        
        //delegate?.alertView?(self, clickedButtonAtIndex: buttonIndex)

        onButtonClicked?(buttonId)

        /*
        if buttonIndex == cancelButtonIndex {
            onCancelClicked?()
        } else {
            onActionButtonClicked?(buttonIndex)
        }*/

        /*
        if isDismissOnActionButtonClicked {
            dismiss()
        } else if buttonIndex == cancelButtonIndex {
            dismiss()
        }*/
        dismiss()
    }
    
    @objc func outsideTapped(_ recognizer: UITapGestureRecognizer) {
        if isDismissOnOutsideTapped {
            dismiss()
            onCancelClicked?()
        }
    }
    
    @objc private func textChanged(_ textField: UITextField) {
        let index = textField.tag
        onTextChanged?(textField.text, index)
    }
    
    
    // MARK: Utils
    
    private func labelHeightToFit(_ label: UILabel) {
        let maxWidth = label.frame.size.width
        let maxHeight : CGFloat = 10000
        let rect = label.attributedText?.boundingRect(with: CGSize(width: maxWidth, height: maxHeight),
                                                      options: .usesLineFragmentOrigin, context: nil)
        var frame = label.frame
        frame.size.height = rect?.size.height ?? .zero
        label.frame = frame
    }
    
    func updateFrame(width:CGFloat,height:CGFloat){
        self.frame = CGRect.init(x: 0, y: 0, width: width, height: height)
        viewWidth = width
        viewHeight = height
    }
    
    func updateMessageLabelAlignment(_ alignment:NSTextAlignment){
        self.messageLabel.textAlignment = alignment
    }
    
}

/*
extension SwiftAlertView {

    @discardableResult
    public static func show(title: String? = nil,
                            message: String? = nil,
                            buttonTitles: [String],
                            configure: ((_ alertView: SwiftAlertView) -> Void)? = nil) -> SwiftAlertView {
        let alertView = SwiftAlertView(title: title, message: message, buttonTitles: buttonTitles)
        configure?(alertView)
        alertView.show()
        return alertView
    }

    @discardableResult
    public static func show(title: String? = nil,
                            message: String? = nil,
                            buttonTitles: String...,
                            configure: ((_ alertView: SwiftAlertView) -> Void)? = nil) -> SwiftAlertView {
        return show(title: title, message: message, buttonTitles: buttonTitles, configure: configure)
    }

}*/


@objc public protocol SwiftAlertViewDelegate : NSObjectProtocol {

    @objc optional func alertView(_ alertView: SwiftAlertView, clickedButtonAtIndex buttonIndex: Int)
    
    @objc optional func willPresentAlertView(_ alertView: SwiftAlertView) // before animation and showing view
    @objc optional func didPresentAlertView(_ alertView: SwiftAlertView) // after animation
    
    @objc optional func willDismissAlertView(_ alertView: SwiftAlertView) // before animation and showing view
    @objc optional func didDismissAlertView(_ alertView: SwiftAlertView) // after animation
}

extension SwiftAlertView: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // public func textFieldDidBeginEditing(_ textField: UITextField) {
    //     if isMoveUpWithKeyboard { return }
    //     self.isMoveUpWithKeyboard = true
    //     UIView.animate(withDuration: 0.2) {
    //         self.frame = self.frame.offsetBy(dx: 0, dy: -self.kMoveUpWithKeyboardDistance)
    //     }
    // }
    
    // public func textFieldDidEndEditing(_ textField: UITextField) {
    //     if !isMoveUpWithKeyboard { return }
    //     self.isMoveUpWithKeyboard = false
    //     UIView.animate(withDuration: 0.2) {
    //         self.frame = self.frame.offsetBy(dx: 0, dy: self.kMoveUpWithKeyboardDistance)
    //     }
    // }

    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        let keyboardHeight = keyboardFrame.height
        let windowHeight = window.bounds.height
        let alertHeight = self.bounds.height
        let minTop: CGFloat = 20
        let newTopOffset = max((windowHeight - alertHeight - keyboardHeight) / 2, minTop)

        guard let superview = self.superview else {
            print("[SwiftAlertView] keyboardWillShow: superview is nil, skip updating constraints.")
            return
        }

        snp.updateConstraints { make in
            make.centerY.equalTo(superview).offset(-keyboardHeight/2)
        }

        UIView.animate(withDuration: 0.2) {
            superview.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let windowHeight = window.bounds.height
            let newTopOffset = (windowHeight - self.bounds.height) / 2
            
            snp.updateConstraints { make in
                make.centerY.equalToSuperview()
            }
            
            UIView.animate(withDuration: 0.2) {
                self.superview?.layoutIfNeeded()
            }
        }
    }
}

extension SwiftAlertView {
    func color(light: UIColor, dark: UIColor) -> UIColor {
        //if #available(iOS 13, *), style == .auto {
        //    return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
        //} else
        if style == .dark {
            return dark
        } else {
            return light
        }
    }
}

public class AlertButton {
    var id = ""
    var title = ""
    var view : UIButton? = nil
    var type: SwiftAlertView.ActionButtonType
    
    init(id: String, title: String, type: SwiftAlertView.ActionButtonType) {
        self.id = id
        self.title = title
        self.type = type
    }
}

private class ButtonTagDictionary {
    private var buttonIdDict = [Int : String]() // [tag_value : button_id]
    private var tagValueDict = [String: Int]() // [button_id : tag_value]
    
    func append(tagValue: Int, buttonId : String){
        buttonIdDict[tagValue] = buttonId
        tagValueDict[buttonId] = tagValue
    }
    
    func getButtonId(tagValue: Int) -> String {
        return buttonIdDict[tagValue] ?? ""
    }
    
    func getTagValue(buttonId: String) -> Int {
        return tagValueDict[buttonId] ?? -1
    }
    
    func clear() {
        buttonIdDict.removeAll()
        tagValueDict.removeAll()
    }
}
