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

struct TutorialView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @ObservedObject var viewModel: TutorialViewModel
    
    @SwiftUI.State var streamingModeDescriptionHeight: CGFloat = 0
    
    var windowHeight: CGFloat {
        UIApplication.shared.windows.first?.bounds.height ?? 0
    }
    
    var windowWidth: CGFloat {
        UIApplication.shared.windows.first?.bounds.width ?? 0
    }
    
    var horizontalPadding: CGFloat {
        if viewModel.tutorialStep == .permission {
            return 0 // for iPhone And iPad permissionView
        } else if IsIpad() {
            return horizontalSizeClass == .compact ? 20 : 80 // for iPad
        } else {
            //for iPhone
            let padding = max(self.safeAreaLeft, self.safeAreaRight)
            if padding == 0 {
                return 20
            } else {
                return padding
            }
        }
    }
    
    var appIconSize: CGFloat {
        if IsIpad() {
            return horizontalSizeClass == .compact ? 30 : 54
        } else {
            return 35
        }
    }
    
    var isIpadCompactScreen: Bool {
        return IsIpad() && horizontalSizeClass == .compact
    }
    
    var descriptiontSize: CGFloat {
        if IsIpad() {
            if horizontalSizeClass == .regular && windowHeight > 510 {
                return 16
            } else {
                return 12
            }
        } else {
            return 14
        }
    }
    
    var titleSize: CGFloat {
        return IsIpad() && horizontalSizeClass == .regular ? 24 : 20
    }
    
    var streamingModelWidthRatio: CGFloat{
        return max(windowWidth/UIScreen.main.bounds.width, 0.6)
    }
    var body: some View {
        
        GeometryReader { geometry in
            let scale = geometry.size.width/UIScreen.main.bounds.width
            return contentView
        }
        
    }
    
    var contentView: some View {
        return ZStack {
            //background
            LinearGradient(
                gradient: Gradient(colors: [Color.hex(0x555555), Color.Black]),
                startPoint: .leading,
                endPoint: .trailing
            ).frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)

            //content view
            Group {
                switch viewModel.tutorialStep {
                case .tos: tosView
                case .permission: permissionView
                case .downloadNexus: downloadNexusView
                case .displayMode: streamingModeView
                default: EmptyView()
                }
            }.padding(.horizontal, horizontalPadding)
            
            //bottom button
            ZStack(alignment: .bottomTrailing) {
                HStack(spacing: 20){
                    ForEach($viewModel.bottomButtons, id: \.self) { button in
                        switch button.wrappedValue {
                        case .done:
                            BlurLetterGuideButton(buttonType: .Button_A, title: "Done".localize() ,backgroundColor: SettingsUtil.shared.lgBtnBgColor()) {
                                viewModel.onDoneButtonClicked()
                            }
                            
                        case .continue:
                            BlurLetterGuideButton(buttonType: .Button_A, title: "Continue".localize(), backgroundColor: SettingsUtil.shared.lgBtnBgColor()) {
                                viewModel.onPermissionContinueButtonClicked()
                            }
                        case .accept:
                            BlurLetterGuideButton(buttonType: .Button_A, title: "Accept".localize(), backgroundColor: SettingsUtil.shared.lgBtnBgColor()) {
                                viewModel.onTOSAcceptButtonClicked()
                            }
                        case .skip:
                            BlurLetterGuideButton(buttonType: .Button_Y, title: "Skip".localize() ,backgroundColor: SettingsUtil.shared.lgBtnBgColor()) {
                                viewModel.onDownloadPageSkipButtonClicked()
                            }
                        case .allow:
                            BlurLetterGuideButton(buttonType: .Button_A, title: "Allow".localize() ,backgroundColor: SettingsUtil.shared.lgBtnBgColor()) {
                                viewModel.onPermissionAllowButtonClicked()
                            }
                        case .download:
                            BlurLetterGuideButton(buttonType: .Button_A, title: "Download".localize() ,backgroundColor: SettingsUtil.shared.lgBtnBgColor()) {
                                viewModel.onDownloadButtonClicked()
                            }
                        }
                        
                    }
                }
            }.padding(.trailing, 30)
                .padding(.bottom, IsIpad() ? 30 : 15)
                .frame(width: windowWidth, height: windowHeight, alignment: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

        }
        .edgesIgnoringSafeArea(.all)

    }
    
    var tosView: some View {
        HStack(spacing: isIpadCompactScreen ? 10 : 60) {
            Image(IsIpad() ? "streaming_ipad" : "streaming")
                .resizable()
                .aspectRatio(297/167, contentMode: .fit)
                .frame(maxWidth: .infinity)
            
            
            HStack(spacing: IsIpad() ? 30 : 15) {
                Image("neuron_icon")
                    .resizable()
                    .frame(width: appIconSize, height: appIconSize)
                    .offset(CGSize(width: 0, height: -10))
                VStack(alignment: .leading) {
                    Text("Welcome to &applabel;".localize().kStringByReplaceString(replaceStr:"&applabel;",willReplaceStr:"Razer PC Remote Play"))
                        .font(Font.dynamic(size: titleSize, weight:.bold))
                        .foregroundColor(Color.white)
                    Spacer().frame(height: 5)
                    Text("To continue using Razer software and services you must first accept the Terms of Service and Privacy Policy agreement".localize())
                        .font(Font.dynamic(size: descriptiontSize))
                        .foregroundColor(Color.hex(0x999999))
                    Spacer().frame(height: 20)
                    HStack(alignment: .center) {
                        
                        Button(action: {
                            viewModel.onTermsOfServiceClicked()
                        }) {
                            Text("Terms of Service".localize())
                                .font(Font.dynamic(size: descriptiontSize))
                                .foregroundColor(Color.razerGreen)
                        }
                        
                        Rectangle()
                            .fill(Color.White)
                            .frame(width: 1, height: 10)
                            .padding(.horizontal, 1)
                        
                        Button(action: {
                            viewModel.onPrivacyPolicyClicked()
                        }) {
                            Text("Privacy Policy".localize())
                                .font(Font.dynamic(size: descriptiontSize))
                                .foregroundColor(Color.razerGreen)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var permissionView: some View {
        let imageWidth = windowWidth * 0.34
        return HStack(spacing: IsIpad() ? windowWidth*0.11 : windowWidth*0.06)  {
            HStack {
                Spacer()
                VStack(alignment: .leading) {
                    Image("request_permission")
                        .resizable()
                        .scaledToFit()
                        .frame(width:  imageWidth, height: imageWidth*0.53)
                        .accessibilityHidden(true)
                    Text("Allow Remote Play to access this device’s network.".localize())
                        .font(Font.dynamic(size: descriptiontSize))
                        .foregroundColor(Color.white)
                        .frame(minWidth: imageWidth, maxWidth: imageWidth, alignment: .leading)
                }
            }.frame(maxWidth: .infinity)
            
            VStack(alignment: .leading) {
                Text("To unlock additional functionality, Razer PC Remote Play requires the following permissions:")
                    .font(Font.dynamic(size: (IsIpad() && horizontalSizeClass == .regular) ? 22 : 18, weight: .bold))
                    .foregroundColor(Color.white)
                    .padding(.trailing, isIpadCompactScreen ? 10 : 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 0) {
                    Image("local_network_black")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: isIpadCompactScreen ? 33 : 44).padding(.all,isIpadCompactScreen ? 8 : 11)
                        .accessibilityHidden(true)
                    HStack {
                        VStack(alignment: .leading) {
                            Spacer().frame(height: 12)
                            Text("Local Network".localize())
                                .fixedSize(horizontal: false, vertical: true)
                                .font(Font.dynamic(size: IsIpad() && horizontalSizeClass == .regular ? 20 : 18, weight: .bold))
                                .foregroundColor(Color.black)
                            Text("Enable seamless streaming between your PC and Nexus.".localize())
                                .fixedSize(horizontal: false, vertical: true)
                                .font(Font.dynamic(size: descriptiontSize, weight: .bold))
                                .foregroundColor(Color.black)
                            Spacer().frame(height: 12)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Image("tick_green")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .opacity(viewModel.isGrantedLocalNetworkPermission ? 1 : 0)
                    
                    Spacer().frame(width: isIpadCompactScreen ? 10 : 40)
                }
                .background(Color.White)
                .cornerRadius(10, corners: .topLeft)
                .cornerRadius(10, corners: .bottomLeft)
                .edgesIgnoringSafeArea(.trailing)
            }.padding(.bottom, 20)
                .frame(maxWidth: .infinity)
        }.edgesIgnoringSafeArea(.horizontal)
    }
    
    var downloadNexusView: some View {
        HStack(spacing: IsIpad() ? (horizontalSizeClass == .compact ? 10 : windowWidth*0.11) : 0) {
            HStack {
                Image(IsIpad() ? "nexus_screenshot_ipad" : "nexus_screenshot")
                    .resizable()
                    .aspectRatio(IsIpad() ? 989/549 : 297/167, contentMode: .fit)
                    .frame(width: windowWidth*0.3)
            }.frame(maxWidth: .infinity)
            
            HStack(spacing: IsIpad() ? (horizontalSizeClass == .compact ? 10 : 30) : 15) {
                Image("nexus_icon")
                    .resizable()
                    .frame(width: appIconSize, height: appIconSize)
                    .offset(CGSize(width: 0, height: -20))
                VStack(alignment: .leading) {
                    Text("Download &nexus;".localize().kStringByReplaceString(replaceStr: "&nexus;", willReplaceStr: "Razer Nexus"))
                        .font(Font.dynamic(size: titleSize, weight:.bold))
                        .foregroundColor(Color.white)
                    Spacer().frame(height: 5)
                    Text("Remote Play is designed to enhance PC gaming on your mobile device through seamless integration with Razer Nexus.".localize())
                        .font(Font.dynamic(size: descriptiontSize))
                        .foregroundColor(Color.hex(0x999999))
                    Spacer().frame(height: 20)
                    Image("appstore")
                        .resizable()
                        .aspectRatio(118/40, contentMode: .fit)
                        .frame(width: isIpadCompactScreen ? 80 : 118)
                        
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var streamingModeView: some View {
        HStack(spacing: IsIpad() ? (horizontalSizeClass == .compact ? 20 : windowWidth*0.11) : 0) {
            
            HStack {
                Image(IsIpad() ? "streaming_ipad" : "streaming")
                    .resizable()
                    .aspectRatio(297/167, contentMode: .fit)
                    .frame(width: windowWidth*0.33)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                VStack(alignment: .leading) {

                    Text("Streaming Display Mode".localize())
                        .font(Font.dynamic(size: IsIpad() && horizontalSizeClass == .regular ? 22 : 20, weight:.bold))
                        .foregroundColor(Color.white)

                    Spacer().frame(height: 11)
                    HStack(spacing: 10) {
                        VStack {
                            Image(viewModel.currentDisplayMode == .phoneOnly ? "tutorial_pc_phone_only_dark" : "tutorial_pc_phone_only")
                                .resizable()
                                .aspectRatio(74/65, contentMode: .fit)
                                .frame(width: 74 * streamingModelWidthRatio)
                                .layoutPriority(2)
                            Text("[iPhone/iPad] Optimized".localize().replacingOccurrences(of: "[iPhone/iPad]", with: IsIpad() ? "iPad" : "iPhone"))
                                .font(Font.dynamic(size: descriptiontSize))
                                .foregroundColor(Color.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(3)
                                .multilineTextAlignment(.center)
                                .layoutPriority(1)
                            Spacer().frame(minHeight: 10)
                            Image(viewModel.currentDisplayMode == .phoneOnly ? "tutorial_pc_model_selected" : "tutorial_pc_model_unselected")
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: 22 * streamingModelWidthRatio)
                                .layoutPriority(2)
                            Spacer().frame(height: 10 * streamingModelWidthRatio)
                        }.padding(.horizontal, 10)
                            .frame(width: 137*streamingModelWidthRatio, height: 168*streamingModelWidthRatio)
                            .background(viewModel.currentDisplayMode == .phoneOnly ? Color.white.opacity(0.25) : Color.hex(0x222222))
                            .cornerRadius(10, corners: .allCorners)
                            .onTapGesture {
                                viewModel.currentDisplayMode = .phoneOnly
                            }
                        
                        VStack {
                            Image("tutorial_pc_duplicate")
                                .resizable()
                                .aspectRatio(74/65, contentMode: .fit)
                                .frame(width: 74 * streamingModelWidthRatio)
                                .layoutPriority(2)
                            Text("Duplicate PC Display".localize())
                                .font(Font.dynamic(size: descriptiontSize))
                                .foregroundColor(Color.white)
                                .minimumScaleFactor(0.5)
                                .lineLimit(3)
                                .multilineTextAlignment(.center)
                                .layoutPriority(1)
                            Spacer().frame(minHeight: 10)
                            Image(viewModel.currentDisplayMode == .duplicate ? "tutorial_pc_model_selected" : "tutorial_pc_model_unselected")
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .frame(width: 22 * streamingModelWidthRatio)
                                .layoutPriority(2)
                            Spacer().frame(height: 10 * streamingModelWidthRatio)
                        }.padding(.horizontal, 10)
                            .frame(width: 137*streamingModelWidthRatio, height: 168*streamingModelWidthRatio)
                            .background(viewModel.currentDisplayMode == .duplicate ? Color.white.opacity(0.25) : Color.hex(0x222222))
                            .cornerRadius(10, corners: .allCorners)
                            .onTapGesture {
                                viewModel.currentDisplayMode = .duplicate
                            }
                        
                    }
                    ZStack(alignment: .topLeading) {
                        Text(viewModel.displayModelDescription)
                            .font(Font.dynamic(size: descriptiontSize))
                            .foregroundColor(Color.white)
                            .minimumScaleFactor(0.5)
                            .frame(width: .infinity, height: streamingModeDescriptionHeight, alignment: .topLeading)
                        
                        //just for layout, no need show
                        Text(IsIpad() && horizontalSizeClass == .regular ?
                             "Your PC will create a virtual display matching your [iPhone/iPad]’s resolution and refresh rate of %1$s at %2$sHz and stream it to your [iPhone/iPad].\n\nAny screen connected to your PC will be temporarily disabled while streaming.".localize() :
                                "Your PC will create a virtual display matching your [iPhone/iPad]’s resolution and refresh rate of %1$s at %2$sHz and stream it to your [iPhone/iPad].\n\nAny screen connected to your PC will be temporarily disabled while streaming.")
                            .font(.system(size: descriptiontSize))
                            .padding(.trailing)
                            .foregroundColor(Color.red)
                            .fixedSize(horizontal: false, vertical: false)
                            .hidden()
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: HeightPreferenceKey.self,
                                                                  value: geo.size.height)
                                }
                            )
                            .onPreferenceChange(HeightPreferenceKey.self) { newHeight in
                                streamingModeDescriptionHeight = newHeight
                            }
 
                    }
                    
                    if !IsIpad() {
                        Spacer().frame(height: 30)
                    }
                    
                }//VStack
                .frame(maxHeight: .infinity)
                
                
                Spacer()
            }//HStack
            .frame(maxHeight: .infinity)
            
        }
        .frame(height: windowHeight)
    }
    
    ///StreamingModeDescription Height
    private struct HeightPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
}
