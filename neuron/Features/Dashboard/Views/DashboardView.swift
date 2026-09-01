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
import Introspect
import Kingfisher
import AVFoundation

let MenuButtonRightSpace = 32.0//(IsIpad() ? 27.0 : 16.0)

struct DashboardView: View {
    
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.colorScheme) var colorScheme
    #if os(tvOS)
    @FocusState private var focusedButton: FocusTarget?
    #endif
    
    var body: some View {
        GeometryReader { geo in
            // Dynamic layout calculations using actual screen size
            let dynamicConfig = DynamicGridConfig.hostCells
            let currentViewWidth = geo.size.width
            let dynamicRowLimit = dynamicConfig.rowLimit(for: currentViewWidth)
            let dynamicCellSize = dynamicConfig.cellSize(for: currentViewWidth)
            let dynamicSpacing = DynamicGridLayoutHelper.shouldScaleCells(
                viewWidth: currentViewWidth,
                cellBaseWidth: dynamicConfig.cellBaseWidth,
                spacing: dynamicConfig.spacing,
                margin: dynamicConfig.margin,
                minCells: dynamicConfig.minCells
            ) ? dynamicConfig.spacing * DynamicGridLayoutHelper.currentHScale(viewWidth: currentViewWidth) : dynamicConfig.spacing
            
            let hasHost = viewModel.pairedHosts.count > 0 || viewModel.netHosts.count > 0
            let spaceTop = IsIpad() ? (hasHost ? 265.0 : 114.0 ): 100.0
            let leftSpace = dashBoardDeviceLeftSpace() //DeviceLeftSpace
            
            // Dynamic position calculations based on actual geometry
            let settingsTop = IsIpad() ? 59.0 : 50
            let settingsWidth = IsIpad() ? 54.0 : 48.0
            let settingsLeft = geo.size.width - settingsWidth - MenuButtonRightSpace
            let settingFocusWidth = IsIOS26() ? 50.0 : 40.0
            
            ZStack {
                
                Color.black
                
                ScrollView(.vertical,showsIndicators: false) {
                    
                    LazyVStack (alignment: .leading){
                        
                        Spacer().frame(height: spaceTop)
                        
                        if viewModel.pairedHosts.count > 0 {
                            
                            Text("Paired PC".localize().uppercased())
                                .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                                .foregroundColor(.white)
                                .font(Font.dynamic(size: 20))
                            
                            
                            LazyVStack(spacing: VHostCellSpace) {
                                
                                ForEach(0...viewModel.pairedHosts.count-1, id: \.self) { index in
                                    
                                    if (index % dynamicRowLimit == 0) {
                                        
                                        let maxIndex:Int = index + dynamicRowLimit
                                        
                                        HStack(alignment: .top , spacing: dynamicSpacing) {
                                            
                                            Spacer().frame(width:leftSpace)
                                            
                                            ForEach( index..<maxIndex , id:\.self ){ rowIndex in
                                                
                                                getHostCell(rowIndex: rowIndex, isPairedHost: true, cellSize: dynamicCellSize)
                                                
                                            }
                                            
                                            Spacer()
                                            
                                        }
                                        .frame(width: geo.size.width)  // Use actual geometry width
                                        
                                    }
                                }
                                
                            }
                            
                            Spacer().frame(height: 10)
                        }
                        
                        HStack(){
                            
                            Text("Unpaired PC".localize().uppercased())
                                .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 0))
                                .foregroundColor(.white)
                                .font(Font.dynamic(size: 20))
                            
                            if viewModel.netHosts.count == 0 {
                                ActivityIndicator.init(isAnimating: .constant(true), style: UIActivityIndicatorView.Style.medium, color: Color.hex(0x999999).uiColor())
                                    .frame(width: 24,height: 24)
                            }
                        }
                        
                        if viewModel.netHosts.count > 0 {
                            
                            LazyVStack(spacing: VHostCellSpace) {
                                
                                
                                ForEach(0...viewModel.netHosts.count-1, id: \.self) { index in
                                    
                                    if (index % dynamicRowLimit == 0) {
                                        
                                        let maxIndex:Int = index + dynamicRowLimit
                                        
                                        HStack(alignment: .top , spacing: dynamicSpacing) {
                                            
                                            Spacer().frame(width:leftSpace)
                                            
                                            ForEach( index..<maxIndex , id:\.self ){ rowIndex in
                                                
                                                getHostCell(rowIndex: rowIndex, isPairedHost: false, cellSize: dynamicCellSize)
                                                
                                            }
                                            
                                            Spacer()
                                            
                                        }
                                        .frame(width: geo.size.width)  // Use actual geometry width
                                        
                                    }
                                }
                                
                            }
                            
                        }
                        
                        Button.init {
                            
                            viewModel.selectedIndex = 0
                            viewModel.deviceSection = .AddSection
                            viewModel.updateBottoMenu()
                            viewModel.manuallyAddPC()
                            
                        } label: {
                            
                            HStack(){
                                Spacer().frame(width:20)
                                
                                Text("Add PC manually".localize())
                                    .foregroundColor(.white)
                                    .font(Font.dynamic(size: 18))
                                
                                Spacer()
                                
                                Image("settings_item_backward_white")
                                
                                Spacer().frame(width:20)
                                
                            }
                            .frame(height:50)
                            //.contentShape(Rectangle())
                            .background {
                                
                                if viewModel.deviceSection == .AddSection && viewModel.connected {
                                    Color.hex(0x4c4c4c)
                                        .frame(height:50)
                                        .cornerRadius(10.0)
                                }else{
                                    Color.hex(0x222222)
                                        .frame(height:50)
                                        .cornerRadius(10.0)
                                }
                                
                            }
                            .accessibilityElement()
                            .accessibilityHidden(true)
                        }
                        .frame(height:50)
                        .clipped()
                        .accessibilityLabel("Add PC manually".localize())
                        //                    .onTapGesture {
                        //                        viewModel.selectedIndex = 0
                        //                        viewModel.deviceSection = .AddSection
                        //                        viewModel.updateBottoMenu()
                        //                        viewModel.manuallyAddPC()
                        //                    }
                        
                        Text("Enter the IP address of your computer.".localize())
                            .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                            .foregroundColor(.hex(0x999999))
                            .font(Font.dynamic(size: 14))
                        
                        Spacer().frame(height: 50)
                        
                    }
                    
                }
                .padding(EdgeInsets.init(top: 0, leading: leftSpace , bottom: 0 , trailing: leftSpace))
                .background(Color.black)
                .introspectScrollView { scroll in
                    viewModel.scroll = scroll
                    scroll.delegate = viewModel
                }
                
                
                VStack {
                    Spacer().frame(height:settingsTop)
                    HStack {
                        Spacer()
                        
                        Button.init {
                            viewModel.goToSettingVC()
                        } label: {
                            ZStack {
                                
                                if viewModel.deviceSection == .NavSection && viewModel.connected {
                                    Color.clear
                                        .frame(width: settingFocusWidth , height: settingFocusWidth )
                                        .overlay(content: {
                                            RoundedRectangle(cornerRadius: IsIOS26() ? settingFocusWidth / 2 : 8.0)
                                                .stroke(.white.opacity(0.8), lineWidth: 3.0)
                                        })
                                }
                                
                                Image.init(IsIOS26() ? "icon_Settings_glass" : "icon_Settings")
                                    .background(content: {
                                        if IsIOS26() {
                                            SettingsUtil.shared.glassBgColor()
                                        }else{
                                            Color.clear
                                        }
                                    })
                                    .cornerRadius(IsIOS26() ? settingsWidth / 2 : 8.0)
                                    .compatibleGlassTouchEffect(radius: IsIOS26() ? settingsWidth / 2 : 8.0)
                            }
                        }
                        .frame(width: settingsWidth,height: settingsWidth)
                        //.position(x: settingsLeft , y:settingsTop)
                        .accessibilitySortPriority(999.0)
                        .accessibilityLabel("Settings".localize())
                        #if os(tvOS)
                        .focused($focusedButton, equals: .settings)
                        #endif
                        
                        Spacer().frame(width:MenuButtonRightSpace)
                    }
                    
                    Spacer()
                }
                
                
                // bottom overlay button with dynamic positioning
                if viewModel.connected {
                    getBottomMenu
                        .position(
                            x: geo.size.width / 2,
                            y: geo.size.height - (IsIpad() ? 30 : 16.0) - ((IsIpad() ? 80.0 : 60.0) / 2)
                        )
                        .zIndex(999)
                        .allowsHitTesting(true)
                }
                
                if viewModel.isShowWakeOnLanLoading {
                    ActivityIndicator.init(isAnimating: .constant(true), style: UIActivityIndicatorView.Style.medium, color: Color.hex(0x999999).uiColor())
                        .frame(width: 24,height: 24)
                }
                
            }
            .frame(width: geo.size.width, height: geo.size.height)  // Use actual geometry size
            .edgesIgnoringSafeArea(.all)
            #if os(tvOS)
            .onMoveCommand { direction in
                switch direction {
                case .up:
                    focusedButton = .settings
                case .down:
                    if focusedButton == .settings {
                        focusedButton = nil
                    }
                default:
                    break
                }
            }
            #endif
            .fullScreenCover(isPresented: $viewModel.isShowAddManualHostView) {
                ZStack {                                //keep out of VStack to avoid vertical layout issues
                    ClearFullScreenBackgroundView()     // Keep background transparent
                    AddManualHostView()
                        .background(Color.clear) // 确保整个模态视图的背景是透明的
                }
                .ignoresSafeArea()
            }
            .valueChanged(value: geo.size.height) { height in
                if viewModel.currentWindowHeight != height {
                    viewModel.currentWindowHeight = height
                }
            }
            .valueChanged(value: geo.size.width) { width in
                if viewModel.dynamicRowLimit != dynamicRowLimit {
                    viewModel.dynamicRowLimit = dynamicRowLimit
                }
                
                if viewModel.currentWindowHeight != geo.size.height {
                    viewModel.currentWindowHeight = geo.size.height
                }
            }
            .valueChanged(value: viewModel.isShowAddManualHostView) { show in
                if show == false {
                    viewModel.startTracking()
                }
            }
            .onAppearFix{
                viewModel.startTracking()
                
                // Check and show no network permission alert if needed
                if viewModel.isNeedShowNoNetworkPermissonAlert && viewModel.isDashboardAppear == true {
                    viewModel.initAndShowNoLocalNetworkPermissionAlert(colorScheme: .dark)
                }
                
                if viewModel.dynamicRowLimit != dynamicRowLimit {
                    viewModel.dynamicRowLimit = dynamicRowLimit
                }
                
                if viewModel.currentWindowHeight != geo.size.height {
                    viewModel.currentWindowHeight = geo.size.height
                }
            }
        } // End of GeometryReader
        .ignoresSafeArea(.all)
        .background(Color.black)
    }
    
    
    private func getHostCell(rowIndex: Int , isPairedHost: Bool, cellSize: CGSize) -> some View {
        
        if (rowIndex < viewModel.pairedHosts.count && isPairedHost ) || ( rowIndex < viewModel.netHosts.count && isPairedHost == false) {
            
            let host : TemporaryHost = isPairedHost ? viewModel.pairedHosts[rowIndex] : viewModel.netHosts[rowIndex]
            var press:Bool = false
            var index:Int = rowIndex
            
            return Button.init {
                
                if press {
                    return
                }
                press = true
                
                if isPairedHost {
                    //viewModel.startPlayHost(host)
                    viewModel.selectedIndex = index
                    viewModel.deviceSection = .PairedSection
                    viewModel.updateBottoMenu()
                    viewModel.clickA()
                }else {
                    viewModel.selectedIndex = index
                    viewModel.deviceSection = .NetSection
                    viewModel.updateBottoMenu()
                    viewModel.clickA()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    press = false
                }
                
            } label: {
                
                VStack {
                    
                    ZStack{
                        
                        if viewModel.connected {
                            if index == viewModel.selectedIndex  {
                                if (isPairedHost && viewModel.deviceSection == .PairedSection) || (isPairedHost == false && viewModel.deviceSection == .NetSection) {
                                    Color.hex(0xffffff, alpha: 0.3).cornerRadius(10.0)
                                }
                            }
                        }
                        
                        VStack {
                            
                            if HostListManger.shared.showFirstLoading {
                                ZStack{
                                    Image("host_online")
                                    ActivityIndicator.init(isAnimating: .constant(true), style: UIActivityIndicatorView.Style.medium, color: Color.hex(0x999999).uiColor())
                                        .frame(width: 24,height: 24)
                                        .offset(y:-8)
                                }
                            }else if host.state != .online {
                                Image("host_offline")
                            }else if (host.currentGame?.count ?? 0 > 0 ) && isPairedHost {
                                Image("host_streaming")
                            }else{
                                Image("host_online")
                            }
                            
                            Text(host.name)
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .font(Font.dynamic(size: 20))
                                .frame(width: cellSize.width, height: 75, alignment: .top)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 5)
                            
                            //                        Spacer().frame(height: 5)
                            
                        }
                    }
                    .clipped()
                    .accessibilityHidden(true)
                    
                }
            }
            .frame(width: cellSize.width, height: cellSize.height)
            .accessibilityLabel(host.name)
            //.contentShape(Rectangle()) //没有颜色区域无法响应点击，//没有颜色的情况用contentShape扩大点击响应区域
            //            .onTapGesture {
            //
            //                if press {
            //                    return
            //                }
            //                press = true
            //
            //                if isPairedHost {
            //                    //viewModel.startPlayHost(host)
            //                    viewModel.selectedIndex = index
            //                    viewModel.deviceSection = .PairedSection
            //                    viewModel.updateBottoMenu()
            //                    viewModel.clickA()
            //                }else {
            //                    viewModel.selectedIndex = index
            //                    viewModel.deviceSection = .NetSection
            //                    viewModel.updateBottoMenu()
            //                    viewModel.clickA()
            //                }
            //
            //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            //                    press = false
            //                }
            //            }
            .eraseToAnyView()
            
        }else{
            
            return Color.black.opacity(0)
                .frame(width: cellSize.width, height: cellSize.height)
                .accessibilityHidden(true)
                .eraseToAnyView()
        }
        
    }
    
    var getBottomMenu : some View {
        BottomMenuView(
            viewModel: viewModel.bottomMenuViewModel) { buttonType in
                switch buttonType {
                case .favorite(let isFavorite): break
                case .play: break
                case .detail: break
                case .appStore: break
                case .fullScreen: break
                case .xBox:break
                case .hide: break
                case .view: break
                case .delete: break
                case .setup: break
                case .pair: viewModel.clickA()
                case .unpair: viewModel.clickY()
                case .start_play: viewModel.clickA()
                case .retry: viewModel.clickA()
                case .settings: viewModel.clickA()
                }
            }
    }
    
}

#if os(tvOS)
private extension DashboardView {
    enum FocusTarget {
        case settings
    }
}
#endif

struct ClearFullScreenBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        DispatchQueue.main.async {
            // clean superview's background to avoid black background
            v.superview?.superview?.backgroundColor = .clear
            v.superview?.backgroundColor = .clear
        }
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
