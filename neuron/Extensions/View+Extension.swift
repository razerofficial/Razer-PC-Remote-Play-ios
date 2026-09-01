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
import CocoaLumberjack
import Combine

struct SFProTextModifier: ViewModifier {
    
    var style: UIFont.TextStyle = .body
    var weight: Font.Weight = .regular
    var size: CGFloat = 10.0
    var textColor: Color
    
    func body(content: Content) -> some View {
        content
            //.font(Font.custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: style).pointSize)
            .font(Font.custom("SFProText-Regular", size: size)
                    .weight(weight))
            .foregroundColor(textColor)
    }
    
}

struct RobotoModifier: ViewModifier {
    
    var style: UIFont.TextStyle = .body
    var weight: Font.Weight = .regular
    var size: CGFloat = 10.0
    var textColor: Color
    
    func body(content: Content) -> some View {
        content
            //.font(Font.custom("SFProText-Regular", size: UIFont.preferredFont(forTextStyle: style).pointSize)
            .font(customFont().weight(weight))
            .foregroundColor(textColor)
    }
    
    func customFont() -> Font {
        switch weight {
        case .light: return Font.custom("Roboto-Light", size: size)
        case .regular: return Font.custom("Roboto-Regular", size: size)
        case .medium: return Font.custom("Roboto-Medium", size: size)
        case .bold: return Font.custom("Roboto-Bold", size: size)
        case .black: return Font.custom("Roboto-Black", size: size)
        default:
            return Font.custom("Roboto-Bold", size: size)
        }
    }
    
}

extension View {
    
    //MARK: - 👉 Font Style
    func sfProTextFont(style: UIFont.TextStyle = .body, weight: Font.Weight, size: CGFloat, textColor:Color) -> some View {
        self.modifier(SFProTextModifier(style: style, weight: weight, size: size, textColor: textColor))
    }
    
    func robotoFont(style: UIFont.TextStyle = .body, weight: Font.Weight, size: CGFloat, textColor:Color) -> some View {
        self.modifier(RobotoModifier(style: style, weight: weight, size: size, textColor: textColor))
    }
    
    //MARK: - 👉 Animation
    // Create an immediate animation.
    func animate(using animation: Animation = Animation.easeInOut(duration: 1), _ action: @escaping () -> Void) -> some View {
        onAppear {
            withAnimation(animation) {
                action()
            }
        }
    }
    
    // Create an immediate, looping animation
    func animateForever(using animation: Animation = Animation.easeInOut(duration: 1), autoreverses: Bool = false, _ action: @escaping () -> Void) -> some View {
        let repeated = animation.repeatForever(autoreverses: autoreverses)
        return onAppear {
            withAnimation(repeated) {
                action()
            }
        }
    }
    
    //MARK: - 👉 Text style
//    func titleStyle() -> some View {
//        self.modifier(Title())
//    }
//    
//    func descriptionStyle() -> some View {
//        self.modifier(Description())
//    }
    
    func settingsTitleStyle() -> some View {
        self.robotoFont(style: .body, weight: .regular, size: 13.0, textColor: .white)
    }
    
    func settingsSectionHeaderStyle() -> some View {
        self.robotoFont(style: .body, weight: .bold, size: 15.0, textColor: .white)
    }
    
    func settingsDescriptionStyle() -> some View {
        self.robotoFont(style: .body, weight: .regular, size: 13.0, textColor: Color.SettingText)
    }
    
    func ChromaDescroptionStyle() -> some View {
        self.robotoFont(style: .body, weight: .regular, size: 12.0, textColor: Color.SettingText)
    }
    
    func settingsStyle(textSize:CGFloat, textColor:Color) -> some View {
        self.robotoFont(style: .body, weight: .regular, size: textSize, textColor: textColor)
    }
    
    func eraseToAnyView() -> AnyView { AnyView(self) }
    
//    public func keyboardAware() -> some View {
//        ModifiedContent(content: self, modifier: KeyboardAware())
//    }
    
    func clearModalBackground()->some View {
        self.modifier(ClearBackgroundViewModifier())
    }
    
//    func keyboardAdaptive() -> some View {
//        ModifiedContent(content: self, modifier: KeyboardAdaptive())
//    }

    func onDataChange<Value: Equatable>(of value: Value, perform action: @escaping (_ newValue: Value) -> Void) -> some View {
        Logger.debug("onDataChange old Value:\(value)")
        return Group {
            if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                self.onChange(of: value, perform: action)
            } else {
                ChangeObserver(value: value, action: action) {
                    self
                }
            }
        }
    }
    
    func highlight(borderWidth:CGFloat = 1.5, borderColor:Color = .White, cornerRadius:CGFloat? = nil) -> some View {
        self.modifier(BorderModifier(borderWidth: borderWidth, borderColor: borderColor, cornerRadius:cornerRadius))
    }
    
    func highlightForRoundButton(borderWidth:CGFloat = 1.5, borderColor:Color = .White, cornerRadius:CGFloat? = nil) -> some View {
        self.modifier(BorderModifier(borderWidth: borderWidth, borderColor: borderColor, cornerRadius:20))
    }
    
    func onAppCameToForeground(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
           action()
        }
    }

    func onAppWentToBackground(perform action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
          action()
        }
    }
    
    /// A backwards compatible wrapper for iOS 14 `onChange`
   @ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
       if #available(iOS 14.0, *) {
           self.onChange(of: value, perform: onChange)
       } else {
           self.onReceive(Just(value)) { (value) in
               onChange(value)
           }
       }
   }
    
    var safeAreaBottom: CGFloat {
        
        if let window = UIApplication.shared.keyWindowInConnectedScenes {
            return window.safeAreaInsets.bottom
        }
        return 0
    }

    var safeAreaTop: CGFloat {
         
        if let window = UIApplication.shared.keyWindowInConnectedScenes {
            return window.safeAreaInsets.top
        }
        return 0
    }
    
    var safeAreaLeft: CGFloat {
        
        if let window = UIApplication.shared.keyWindowInConnectedScenes {
            return window.safeAreaInsets.left
        }
        return 0
    }
    
    var safeAreaRight: CGFloat {
         
        if let window = UIApplication.shared.keyWindowInConnectedScenes {
            return window.safeAreaInsets.right
        }
        return 0
    }
    
    func saveSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeCalculator(size: size))
    }
}

// Reference: https://stackoverflow.com/questions/57577462/get-width-of-a-view-using-in-swiftui
struct SizeCalculator: ViewModifier {
    
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear // we just want the reader to get triggered, so let's use an empty color
                        .onAppear {
                            size = proxy.size
                        }
                }
            )
    }
}


extension View {
    ///Use UIKitAppear To fix onAppear bug
    public func onAppearFix(perform action: (() -> Void)? = nil ) -> some View {
        //self.overlay(UIKitAppear(action: action).disabled(true))
        self.background(UIKitAppear(action: action).disabled(true))
    }
    
    @ViewBuilder
    func compatibleGlassEffect(radius: CGFloat? = nil) -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) {
            if let radius = radius {
                self.glassEffect(in: .rect(cornerRadius: radius ) )
            } else {
                self.glassEffect()
            }
        } else {
            // Fallback on earlier versions
            self
        }
    }
    
    @ViewBuilder
    func compatibleGlassTouchEffect(radius: CGFloat? = nil) -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) {
            //Group {
                if let radius = radius {
                    self.glassEffect( .clear.tint(SettingsUtil.shared.glassBgColor()).interactive(true) ,in: .rect(cornerRadius: radius ) )
                        .overlay {
                            RoundedRectangle(cornerRadius: radius)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.24),
                                            Color.black.opacity(0.18),
                                            Color.white.opacity(0.24)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                } else {
                    self.glassEffect( .clear.tint(SettingsUtil.shared.glassBgColor()).interactive(true) )
                        .overlay {
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.24),
                                            Color.black.opacity(0.18),
                                            Color.white.opacity(0.24)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                }
           // }
        } else {
            // Fallback on earlier versions
            self
        }
    }
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

// MARK: - Settings Navigation Back Button
extension View {
    // BIA-2260,BIA-2265: Adds a custom back button in compact mode for Settings navigation.
    // because native navigation bar has weired transition anaimation(jump, resize) when navigationBarHidden from false to true
    // so we have to use a custom back button to prevent navigationBarHidden glitch on iOS 26 compact mode
    func settingsCompactBackButton(horizontalSizeClass: UserInterfaceSizeClass?, isFromSetting: Bool = true) -> some View {
        self
            .toolbar {
                if isFromSetting {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            let currentComponent = SettingsViewModel.shared.highlightedUIComponent
                            let pathCount = SettingsViewModel.shared.getCurrentNavigationPathCount()
                            Logger.debug("[SettingsNavigation] Back button tapped - currentComponent: \(currentComponent), pathCount: \(pathCount)")
                            
                            // If in pushed pages, just pop without changing highlightedUIComponent
                            if pathCount > 0 {
                                SettingsViewModel.shared.popView()
                                
                            } else {
                                // If at root of detail view, go back to sidebar
                                let parentMenuItem = currentComponent.getParentMenuItem()
                                Logger.debug("[SettingsNavigation] Returning to sidebar - setting highlightedUIComponent to: \(parentMenuItem)")
                                SettingsViewModel.shared.highlightedUIComponent = parentMenuItem
                                SettingsViewModel.shared.popView()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
//                                .bold()
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(isFromSetting)
    }
}
