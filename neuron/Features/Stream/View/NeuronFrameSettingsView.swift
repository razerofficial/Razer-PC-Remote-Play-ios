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
import SwiftUI
import CocoaLumberjack
import Introspect

struct NeuronFrameSettingsView: View {

    @ObservedObject var viewModel: NeuronFrameSettingsViewModel
    
    private let spaceBetweenView = CGFloat(16)
    private let topPaddingValue = IsIpad() ? CGFloat(75) : CGFloat(35)
    private let PCDisplayStreamingModeItemDefaultWidth: CGFloat = IsIpad() ? 155 : 145
    @SwiftUI.State var remotePlay: Bool = false
    
    let scrollViewCoordinateSpaceName: String = "NeuronFrameSettingsScrollView"
    
    @SwiftUI.State private var viewPositions: [String: CGRect] = [:]
    @SwiftUI.State private var scrollViewSize: CGSize = .zero
    @SwiftUI.State private var scrollViewContentOffset: CGPoint = .zero
    @SwiftUI.State private var navbarHeight: CGFloat = 44.0
    
    init(viewModel: NeuronFrameSettingsViewModel) {
        self.viewModel = viewModel
        remotePlay = viewModel.remotePlayToggle
    }

    var body: some View {
        
        return ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false, content: {
                    
                    VStack(alignment: .leading, spacing: 0) {
                        
                        Spacer()
                            .frame(minHeight: topPaddingValue + 20)
                        
                        displayModeSelectView
                        
                        bitrateSlider
                        
                        if viewModel.isDeviceSupportHDR() {
                            HDRToggle
                        }
                            
                        if viewModel.displayMode != .DeviceOptimized {
                            MuteHostPCToggle
                        }
                        
                        touchScreenControlPicker
                        
                        advancedSettingsTextView
                        
                        autoQuitPicker
                        
                        limtRefreshRateAndScreenResolutionToggle
                        
                        framePacingPicker
                        
                        videoEncoderPicker
                        
                        Spacer()
                            .frame(height: 30)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .padding(.trailing, 10)
                    
                })
                .introspectScrollView(customize: { scrollView in
                    scrollViewContentOffset = scrollView.contentOffset
                })
                .coordinateSpace(name: scrollViewCoordinateSpaceName)
                .onPreferenceChange(ViewPositionKey.self) { rects in
                    viewPositions.merge(rects) { _, new in new }
                }
                .onDataChange(of: viewModel.highlightedUIComponent, perform: { newValue in
                    scrollToIfNeeded(proxy: proxy, targetID: viewModel.highlightedUIComponent.description)
                })
            }
            .padding(.leading, 20)
            .background(Color.black)
        }
        .onAppear(perform: {
            viewModel.isAtFrontMost = true
            viewModel.reloadSettings()
        })
        .onDisappear(perform: {
            viewModel.isAtFrontMost = false
        })
    }
    
    private func scrollToIfNeeded(proxy: ScrollViewProxy, targetID: String) {
        guard let rect = viewPositions[targetID], let visibleRect = getVisibleRect() else { return }
        
        if isRectMostlyVisible(rect, within: visibleRect) {
            proxy.scrollTo(targetID, anchor: .center)
        }
    }

    private func getVisibleRect() -> CGRect? {
        return CGRect(x: scrollViewContentOffset.x,
                      y: scrollViewContentOffset.y,
                      width: UIScreen.screenSize.width,
                      height: UIScreen.screenSize.height)
    }
    
    private func isRectMostlyVisible(_ rect: CGRect, within visibleRect: CGRect) -> Bool {
        let minY = visibleRect.minY + navbarHeight
        return !(rect.minY > minY && rect.maxY < (minY + UIScreen.screenSize.height - navbarHeight))
    }
    
    var displayModeSelectView: some View {
        let highlighted = viewModel.highlightedUIComponent
        return VStack(alignment: .leading, spacing: 0, content: {
            
            Text("Display mode".localize().uppercased())
                .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
                .foregroundStyle(Color.SettingText)
                .padding(.bottom,4)
                .padding(.leading, spaceBetweenView)
            Spacer()
                .frame(width: 10)
            HStack {
                ForEach(PCDisplayStreamingMode.all, id: \.self) {mode in
                    VStack {
                        Image(highlighted == mode.highlightedUIComponent() ? mode.highlightedImageName() : mode.displayImageName())
                            .frame(width: 62, height: 40)
                            .padding(.top, 10)
                        Text(mode.displayName().localize())
                            .foregroundColor(Color.white)
                            .font(.system(size: 16))
                            .padding(.leading, spaceBetweenView)
                            .padding(.trailing, spaceBetweenView)
                            .padding(.top, 10)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(height: 50)
                        Image(viewModel.frameSettings.displayMode == mode.rawValue ? "active_profile" : "favorite_nm")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .padding(.bottom, 10)
                    }
                        .frame(maxWidth: PCDisplayStreamingMode.all.count>2 ? .infinity : PCDisplayStreamingModeItemDefaultWidth)
                        .frame(alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(highlighted == mode.highlightedUIComponent() ? Color.SettingMenuFocus : Color.SettingMenuBG)
                        .autoScrollingWith(id: mode.highlightedUIComponent().description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
                        .cornerRadius(10, corners: .topLeft)
                        .cornerRadius(10, corners: .topRight)
                        .cornerRadius(10, corners: .bottomLeft)
                        .cornerRadius(10, corners: .bottomRight)
                        .onTapGesture {
                            //select mode
                            viewModel.lastVC?.updateLastVCHandel()
                            viewModel.highlightedUIComponent = mode.highlightedUIComponent()
                            viewModel.updateDisplayMode(mode)
                        }
                    Spacer()
                        .frame(width: 10)
                }
            }
            Text(viewModel.displayMode.descriptionString().localize())
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.SettingText)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(0)
                .lineLimit(.max)
                .multilineTextAlignment(.leading)
                .padding(.vertical,4)
                .padding(.leading, spaceBetweenView)
            
            Spacer()
                .frame(height:20)
        })
    }
    
    var LimitScreenResolutionTtoSafeAreaToggle: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
        return HStack {
            Toggle(isOn: $viewModel.LimitScreenResolutionTtoSafeArea, label: {
                Text("Limit Screen Resolution To Safe Area".localize())
                    .foregroundColor(Color.white)
                    .font(.system(size: 16))
                    .padding(.leading, spaceBetweenView)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
            })
            .padding(.trailing, 10)
            .onDataChange(of: viewModel.LimitScreenResolutionTtoSafeArea) { newValue in
                if newValue == true {
                    viewModel.resolution = .resolutionSafeArea
                    viewModel.frameSettings.width = Int32(Resolution.resolutionSafeArea.resolutionSize().width)
                    viewModel.frameSettings.height = Int32(Resolution.resolutionSafeArea.resolutionSize().height)
                }else {
                    viewModel.resolution = .resolutionFull
                    viewModel.frameSettings.width = Int32(Resolution.resolutionFull.resolutionSize().width)
                    viewModel.frameSettings.height = Int32(Resolution.resolutionFull.resolutionSize().height)
                }
                viewModel.saveSettings()
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded{
                        viewModel.highlightedUIComponent = .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
                    }
            )
        }
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var limitRefreshRateToggle: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsRefreshRateToggle
        return HStack {
            Toggle(isOn: $viewModel.limitRefreshRate, label: {
                Text("Limit Refresh Rate To 60Hz".localize())
                    .foregroundColor(Color.white)
                    .font(.system(size: 16))
                    .padding(.leading, spaceBetweenView)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
            })
            .padding(.trailing, 10)
            .simultaneousGesture(
                TapGesture()
                    .onEnded{
                        viewModel.highlightedUIComponent = .NeuronStreamingSettingsRefreshRateToggle
                    }
            )
            .onDataChange(of: viewModel.limitRefreshRate) { newValue in
                if newValue == false {
                    let refreshRate = UIScreen.main.maximumFramesPerSecond
                    viewModel.frameRate = refreshRate >= 62 ? .frameRate120fps : .frameRate60fps
                    viewModel.frameSettings.framerate = Int32(refreshRate)
                    viewModel.frameSettings.videoRefreshRate = UIScreen.main.maximumFramesPerSecond
                }else {
                    viewModel.frameSettings.framerate = 60
                    viewModel.frameRate = .frameRate60fps
                    viewModel.frameSettings.videoRefreshRate = 60
                    
                }
                viewModel.saveSettings()
            }
        }
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsRefreshRateToggle.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var bitrateSlider: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsBitrateSlider
        return VStack(alignment: .leading, spacing: 0, content: {
            
            HStack(content: {
                Text("Video Bitrate".localize().uppercased())
                    .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
                    .foregroundStyle(Color.SettingText)
                    .padding(.bottom,4)
                    .padding(.leading, spaceBetweenView)
                
                Spacer()
                
                Text("\(String(format: "%.1f", viewModel.bitrate)) Mbps")
                    .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
                    .foregroundStyle(Color.SettingText)
                    .padding(.bottom,4)
                    .padding(.trailing, spaceBetweenView)
            })
            
            
            HStack {
                Spacer().frame(width: spaceBetweenView)
                Slider(value: $viewModel.bitrate, in: 1.0...150.0, step: 0.1) { isChanging in
                    viewModel.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
                }
                    .onDataChange(of: viewModel.bitrate) { newValue in
                        //update menu
                        viewModel.lastVC?.updateLastVCHandel()
                        viewModel.frameSettings.bitrate = Int32(newValue * 1000)
                        viewModel.saveSettings()
                    }
                    .tint(Color(red: 0.27, green: 0.84, blue: 0.17))
                    .foregroundColor(.White)
                Spacer().frame(width: spaceBetweenView)
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
            .frame(alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .background(isHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
            .cornerRadius(10, corners: .topLeft)
            .cornerRadius(10, corners: .topRight)
            .cornerRadius(10, corners: .bottomLeft)
            .cornerRadius(10, corners: .bottomRight)
            .simultaneousGesture(
                TapGesture()
                    .onEnded{
                        //update menu
                        viewModel.lastVC?.updateLastVCHandel()
                        viewModel.highlightedUIComponent = .NeuronStreamingSettingsBitrateSlider
                    }
            )
            Spacer()
                .frame(height:20)
        })
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsBitrateSlider.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var HDRToggle: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsHDRToggle
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Toggle(isOn: $viewModel.frameSettings.enableHdr, label: {
                    Text("Allow HDR".localize())
                        .foregroundColor(Color.white)
                        .font(.system(size: 16))
                        .padding(.leading, spaceBetweenView)
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                })
                .padding(.trailing, 10)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded{
                            viewModel.highlightedUIComponent = .NeuronStreamingSettingsHDRToggle
                        }
                )
                .onDataChange(of: viewModel.frameSettings.enableHdr) { newValue in
                    viewModel.saveSettings()
                }
            }.frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
                .frame(alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .background(isHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
                .cornerRadius(10, corners: .topLeft)
                .cornerRadius(10, corners: .topRight)
                .cornerRadius(10, corners: .bottomLeft)
                .cornerRadius(10, corners: .bottomRight)
            
            Spacer().frame(height:5)
            
            Text("Enhances visuals with better contrast, brightness, and color range.".localize() + "\n" + "Requires your PC’s connected display to have HDR enabled.".localize())
                .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
                .foregroundStyle(Color.SettingText)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(0)
                .lineLimit(.max)
                .multilineTextAlignment(.leading)
                .padding(.bottom,4)
                .padding(.leading, spaceBetweenView)
            
            Spacer()
                .frame(height:20)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsHDRToggle.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var framePacingPicker: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsFramePacingPicker
        return VStack(alignment: .leading, spacing: 0, content: {
            HStack {
                Text("Frame Pacing".localize())
                    .foregroundColor(Color.white)
                    .font(.system(size: 16))
                    .padding(.leading, spaceBetweenView)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                Spacer()
                Picker("", selection: $viewModel.framePacingPreference) {
                    ForEach(FramePacingPreference.all, id: \.self) {type in
                        Text(type.displayName().localize())
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.init(red: 235/255.0, green: 245/255.0, blue: 245/255.0, opacity:0.6))
                .background(.clear)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded{
                            viewModel.highlightedUIComponent = .NeuronStreamingSettingsFramePacingPicker
                        }
                )
                .onDataChange(of: viewModel.framePacingPreference) { newValue in
                    viewModel.frameSettings.useFramePacing = viewModel.framePacingPreference == .lowestLatency ? false : true
                    viewModel.saveSettings()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(isHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
            .cornerRadius(10, corners: .topLeft)
            .cornerRadius(10, corners: .topRight)
            .cornerRadius(10, corners: .bottomLeft)
            .cornerRadius(10, corners: .bottomRight)
            
            Spacer()
                .frame(height:20)
        })
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsFramePacingPicker.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var MuteHostPCToggle: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsMutePCToggle
        return VStack(alignment: .leading, spacing: 0, content: {
            HStack {
                Toggle(isOn: $viewModel.MuteHostPC, label: {
                    Text("Mute host PC's Speakers While Streaming".localize())
                        .foregroundColor(Color.white)
                        .font(.system(size: 16))
                        .padding(.leading, spaceBetweenView)
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                })
                .padding(.trailing, 10)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded{
                            viewModel.highlightedUIComponent = .NeuronStreamingSettingsMutePCToggle
                        }
                )
                .onDataChange(of: viewModel.MuteHostPC) { newValue in
                    viewModel.frameSettings.playAudioOnPC = !newValue
                    viewModel.saveSettings()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(isHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
            .cornerRadius(10, corners: .topLeft)
            .cornerRadius(10, corners: .topRight)
            .cornerRadius(10, corners: .bottomLeft)
            .cornerRadius(10, corners: .bottomRight)
            
            Spacer()
                .frame(height:20)
        })
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsMutePCToggle.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var autoQuitPicker: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsAutoQuitPicker
        return VStack(alignment: .leading, spacing: 0, content: {
            HStack {
                Text("Automatically Quit Games".localize())
                    .foregroundColor(Color.white)
                    .font(.system(size: 16))
                    .padding(.leading, spaceBetweenView)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                Spacer()
                Picker("", selection: $viewModel.autoQuit) {
                    ForEach(AutoQuit.all, id: \.self) {type in
                        Text(type.displayName().localize())
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.init(red: 235/255.0, green: 245/255.0, blue: 245/255.0, opacity:0.6))
                .background(.clear)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded{
                            viewModel.highlightedUIComponent = .NeuronStreamingSettingsAutoQuitPicker
                        }
                )
                .onDataChange(of: viewModel.autoQuit) { newValue in
                    viewModel.frameSettings.timeToTerminateApp = newValue.autoQuitTime()
                    viewModel.saveSettings()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(isHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
            .cornerRadius(10, corners: .topLeft)
            .cornerRadius(10, corners: .topRight)
            .cornerRadius(10, corners: .bottomLeft)
            .cornerRadius(10, corners: .bottomRight)
            
            Spacer().frame(height:5)
            
            Text("Attempt to automatically close games when finished streaming.".localize())
                .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
                .foregroundStyle(Color.SettingText)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(0)
                .lineLimit(.max)
                .multilineTextAlignment(.leading)
                .padding(.bottom,4)
                .padding(.leading, spaceBetweenView)
            
            Spacer()
                .frame(height:20)
        })
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsAutoQuitPicker.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var touchScreenControlPicker: some View {
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsTouchScreenPicker
        return VStack(alignment: .leading, spacing: 0, content: {
            
            HStack {
                Text("Touch Screen Control".localize())
                    .foregroundColor(Color.white)
                    .font(.system(size: 16))
                    .padding(.leading, spaceBetweenView)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                Spacer()
                Picker("", selection: $viewModel.touchModel) {
                    ForEach(TouchMode.all, id: \.self) {type in
                        Text(type.displayName().localize())
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.init(red: 235/255.0, green: 245/255.0, blue: 245/255.0, opacity:0.6))
                .background(.clear)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded{
                            viewModel.highlightedUIComponent = .NeuronStreamingSettingsTouchScreenPicker
                        }
                )
                .onDataChange(of: viewModel.touchModel) { newValue in
                    viewModel.frameSettings.absoluteTouchMode = viewModel.touchModel == .touchpad ? false : true
                    viewModel.saveSettings()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(isHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
            .cornerRadius(10, corners: .topLeft)
            .cornerRadius(10, corners: .topRight)
            .cornerRadius(10, corners: .bottomLeft)
            .cornerRadius(10, corners: .bottomRight)
            
            Spacer()
                .frame(height:20)
        })
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsTouchScreenPicker.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var videoEncoderPicker: some View {
        
        let isHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsVideoEncoderPicker
        return VStack(alignment: .leading, spacing: 0, content: {
            
            HStack {
                Text("Video Codec".localize())
                    .foregroundColor(Color.white)
                    .font(.system(size: 16))
                    .padding(.leading, spaceBetweenView)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                Spacer()
                Picker("", selection: $viewModel.videoEncoder) {
                    ForEach(RZPreferredCodec.all, id: \.self) {type in
                        Text(type.displayName().localize())
                    }
                }
                .pickerStyle(.menu)
                .accentColor(Color.init(red: 235/255.0, green: 245/255.0, blue: 245/255.0, opacity:0.6))
                .background(.clear)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded{
                            viewModel.highlightedUIComponent = .NeuronStreamingSettingsVideoEncoderPicker
                        }
                )
                .onDataChange(of: viewModel.videoEncoder) { newValue in
                    viewModel.frameSettings.preferredCodec = viewModel.videoEncoder.rawValue
                    viewModel.saveSettings()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(isHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
            .cornerRadius(10, corners: .topLeft)
            .cornerRadius(10, corners: .topRight)
            .cornerRadius(10, corners: .bottomLeft)
            .cornerRadius(10, corners: .bottomRight)
            
            Spacer()
                .frame(height:20)
        })
        .autoScrollingWith(id: FrameSettingsUIComponents.FrameSettingsHightlightedComponent.NeuronStreamingSettingsVideoEncoderPicker.description, scrollViewCoordinateSpaceName: scrollViewCoordinateSpaceName, positions: $viewPositions)
    }
    
    var advancedSettingsTextView: some View {
     
        return VStack(alignment: .leading, spacing:0) {
            Text("Advanced Settings".localize().uppercased())
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.SettingText)
                .padding(.bottom,4)
                .padding(.leading, spaceBetweenView)
            Spacer()
                .frame(width: 10)
        }
    }
    
    var limtRefreshRateAndScreenResolutionToggle: some View {
        
        let isRefreshRateHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsRefreshRateToggle
        let isSafeAreaHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
        return VStack(alignment: .leading, spacing: 0) {
            if viewModel.isNeedShowLimitRefreshRateToggle() && viewModel.isNeedShowLimitScreenResolutionToSafeAreaToggle() {
                limitRefreshRateToggle
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
                    .frame(alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(isRefreshRateHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
                    .cornerRadius(10, corners: .topLeft)
                    .cornerRadius(10, corners: .topRight)
                
                Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale)
                
                LimitScreenResolutionTtoSafeAreaToggle
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
                    .frame(alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(isSafeAreaHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
                    .cornerRadius(10, corners: .bottomLeft)
                    .cornerRadius(10, corners: .bottomRight)
                
                Spacer().frame(height:5)
                
                Text("Restricts display size to avoid device's front camera".localize())
                    .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
                    .foregroundStyle(Color.SettingText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(0)
                    .lineLimit(.max)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom,4)
                    .padding(.leading, spaceBetweenView)
                
                Spacer().frame(height: 20)
            }else if viewModel.isNeedShowLimitRefreshRateToggle() {
                limitRefreshRateToggle
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
                    .frame(alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(isRefreshRateHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
                    .cornerRadius(10, corners: .topLeft)
                    .cornerRadius(10, corners: .topRight)
                    .cornerRadius(10, corners: .bottomLeft)
                    .cornerRadius(10, corners: .bottomRight)
                
                Spacer().frame(height: 20)
            }else if viewModel.isNeedShowLimitScreenResolutionToSafeAreaToggle() {
                LimitScreenResolutionTtoSafeAreaToggle
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
                    .frame(alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(isSafeAreaHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
                    .cornerRadius(10, corners: .topLeft)
                    .cornerRadius(10, corners: .topRight)
                    .cornerRadius(10, corners: .bottomLeft)
                    .cornerRadius(10, corners: .bottomRight)
                
                Spacer().frame(height:5)
                
                Text("Restricts display size to avoid device's front camera".localize())
                    .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
                    .foregroundStyle(Color.SettingText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(0)
                    .lineLimit(.max)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom,4)
                    .padding(.leading, spaceBetweenView)
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    
//    var advancedSettingsView: some View {
//        let isRefreshRateHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsRefreshRateToggle
//        let isSafeAreaHighlighted = viewModel.highlightedUIComponent == .NeuronStreamingSettingsLimitScreenResolutionToSafeAreaToggle
//        return VStack(alignment: .leading, spacing: 0, content: {
//            
//            Text("Advanced Settings".localize().uppercased())
//                .font(.system(size: 14, weight: .medium))
//                .foregroundStyle(Color.SettingText)
//                .padding(.bottom,4)
//                .padding(.leading, spaceBetweenView)
//            Spacer()
//                .frame(width: 10)
//            
//            VStack(alignment: .leading, spacing: 0, content: {
//                
//                autoQuitPicker
//                
//                Spacer()
//                    .frame(height: 20)
//                
//                if viewModel.isNeedShowLimitRefreshRateToggle() && viewModel.isNeedShowLimitScreenResolutionToSafeAreaToggle() {
//                    limitRefreshRateToggle
//                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
//                        .frame(alignment: .leading)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .background(isRefreshRateHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
//                        .cornerRadius(10, corners: .topLeft)
//                        .cornerRadius(10, corners: .topRight)
//                    
//                    Color.SettingsLine.frame(maxWidth: .infinity).frame(height: 1 / UIScreen.main.scale)
//                    
//                    LimitScreenResolutionTtoSafeAreaToggle
//                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
//                        .frame(alignment: .leading)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .background(isSafeAreaHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
//                        .cornerRadius(10, corners: .bottomLeft)
//                        .cornerRadius(10, corners: .bottomRight)
//                    
//                    Spacer().frame(height:5)
//        
//                    Text("Restricts display size to avoid device's front camera".localize())
//                        .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
//                        .foregroundStyle(Color.SettingText)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .lineSpacing(0)
//                        .lineLimit(.max)
//                        .multilineTextAlignment(.leading)
//                        .padding(.bottom,4)
//                        .padding(.leading, spaceBetweenView)
//                    
//                    Spacer().frame(height: 10)
//                }else if viewModel.isNeedShowLimitRefreshRateToggle() {
//                    limitRefreshRateToggle
//                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
//                        .frame(alignment: .leading)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .background(isRefreshRateHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
//                        .cornerRadius(10, corners: .topLeft)
//                        .cornerRadius(10, corners: .topRight)
//                        .cornerRadius(10, corners: .bottomLeft)
//                        .cornerRadius(10, corners: .bottomRight)
//                    
//                    Spacer().frame(height: 10)
//                }else if viewModel.isNeedShowLimitScreenResolutionToSafeAreaToggle() {
//                    LimitScreenResolutionTtoSafeAreaToggle
//                        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: .infinity)
//                        .frame(alignment: .leading)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .background(isSafeAreaHighlighted ? Color.SettingMenuFocus : Color.SettingMenuBG)
//                        .cornerRadius(10, corners: .topLeft)
//                        .cornerRadius(10, corners: .topRight)
//                        .cornerRadius(10, corners: .bottomLeft)
//                        .cornerRadius(10, corners: .bottomRight)
//                    
//                    Spacer().frame(height:5)
//        
//                    Text("Restricts display size to avoid device's front camera".localize())
//                        .font(.system(size: IsIpad() ? 16 : 14, weight: .medium))
//                        .foregroundStyle(Color.SettingText)
//                        .fixedSize(horizontal: false, vertical: true)
//                        .lineSpacing(0)
//                        .lineLimit(.max)
//                        .multilineTextAlignment(.leading)
//                        .padding(.bottom,4)
//                        .padding(.leading, spaceBetweenView)
//                    
//                    Spacer().frame(height: 10)
//                }
//            })
//            
//            framePacingPicker
//            
//            Spacer().frame(height: 20)
//            
//            videoEncoderPicker
//            
//        })
//        .frame(
//            maxWidth: .infinity,
//            maxHeight: .infinity,
//            alignment: .topLeading
//        )
//    }
    
    
    private func printLog(_ msg:String){
        BiancaLogger.shared.logInfo("SettingsLauncherView - " + msg)
    }
}

func IsIpad() -> Bool
{
    let deviceType = UIDevice.current.model
    
    if(deviceType == "iPhone") {
        //iPhone
        return false
    }
    else if(deviceType == "iPod touch") {
        //iPod Touch
        return false
    }
    else if(deviceType == "iPad") {
        //iPad
        return true
    }
    return false
    
    //这两个防范判断不准，不要用
    //#define is_iPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    //
    //#define is_iPad (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
}
