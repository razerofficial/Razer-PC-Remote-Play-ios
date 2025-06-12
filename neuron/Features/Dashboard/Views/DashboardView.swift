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

struct DashboardView: View {
    
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        
        if viewModel.isNeedShowNoNetworkPermissonAlert && viewModel.isDashboardAppear == true {
            viewModel.initAndShowNoLocalNetworkPermissionAlert(colorScheme: .dark)
        }
        
        let hasHost = viewModel.pairedHosts.count > 0 || viewModel.netHosts.count > 0
        let spaceTop = IsIpad() ? (hasHost ? 265.0 : 114.0 ): 100.0
        let settingsTop = IsIpad() ? 59.0 : 50
        let left_iphone = UIScreen.screenWidth - 48 - 32
        let left_ipad = UIScreen.screenWidth - 27 - 54
        let settingsWidth = IsIpad() ? 54.0 : 48.0
        let settingsLeft = IsIpad() ? left_ipad : left_iphone
        
        return ZStack {
            
            Color.black
            
            ScrollView(.vertical,showsIndicators: false) {
                
                LazyVStack (alignment: .leading){
                    
                    Spacer().frame(height: spaceTop)
                    
                    if viewModel.pairedHosts.count > 0 {
                        
                        Text("Paired PC".localize().uppercased())
                            .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                            .foregroundColor(.white)
                            .font(Font.system(size: 20 ))
                        
                        
                        LazyVStack(spacing: VHostCellSpace) {
                            
                            ForEach(0...viewModel.pairedHosts.count-1, id: \.self) { index in
                                
                                if (index % HostRowLimit == 0) {
                                    
                                    let maxIndex:Int = index + HostRowLimit
                                    
                                    HStack(alignment: .top , spacing: HHostCellSpace) {
                                        
                                        Spacer().frame(width:DeviceLeftSpace)
                                        
                                        ForEach( index..<maxIndex , id:\.self ){ rowIndex in
                                            
                                            getHostCell(rowIndex: rowIndex, isPairedHost: true)
                                            
                                        }
                                        
                                        Spacer()
                                        
                                    }
                                    .frame(width: UIScreen.screenWidth)
                                    
                                }
                            }
                            
                        }
                        
                        Spacer().frame(height: 10)
                    }
                    
                    HStack(){
                        
                        Text("Unpaired PC".localize().uppercased())
                            .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 0))
                            .foregroundColor(.white)
                            .font(Font.system(size: 20))
                        
                        if viewModel.netHosts.count == 0 {
                            ActivityIndicator.init(isAnimating: .constant(true), style: UIActivityIndicatorView.Style.medium, color: Color.hex(0x999999).uiColor())
                                .frame(width: 24,height: 24)
                        }
                    }
                    
                    if viewModel.netHosts.count > 0 {
                        
                        LazyVStack(spacing: VHostCellSpace) {
                            
                            
                            ForEach(0...viewModel.netHosts.count-1, id: \.self) { index in
                                
                                if (index % HostRowLimit == 0) {
                                    
                                    let maxIndex:Int = index + HostRowLimit
                                    
                                    HStack(alignment: .top , spacing: HHostCellSpace) {
                                        
                                        Spacer().frame(width:DeviceLeftSpace)
                                        
                                        ForEach( index..<maxIndex , id:\.self ){ rowIndex in
                                            
                                            getHostCell(rowIndex: rowIndex, isPairedHost: false)
                                            
                                        }
                                        
                                        Spacer()
                                        
                                    }
                                    .frame(width: UIScreen.screenWidth)
                                    
                                }
                            }
                            
                        }
                        
                    }
                    
                    
                    HStack(){
                        Spacer().frame(width:20)
                        
                        Text("Add PC manually".localize())
                            .foregroundColor(.white)
                            .font(Font.system(size: 18))
                        
                        Spacer()
                        
                        Image("settings_item_backward_white")
                        
                        Spacer().frame(width:20)
                        
                    }
                    .frame(height:50)
                    .contentShape(Rectangle())
                    .background {
                        
                        if viewModel.deviceSection == .AddSection && viewModel.connected {
                            Color.hex(0x4c4c4c)
                                .cornerRadius(10.0)
                        }else{
                            Color.hex(0x222222)
                                .cornerRadius(10.0)
                        }
                        
                    }
                    .onTapGesture {
                        viewModel.selectedIndex = 0
                        viewModel.deviceSection = .AddSection
                        viewModel.updateBottoMenu()
                        viewModel.manuallyAddPC()
                    }
                    
                    Text("Enter the IP address of your computer.".localize())
                        .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                        .foregroundColor(.hex(0x999999))
                        .font(Font.system(size: 14))
                    
                    Spacer().frame(height: 50)
                    
                }
                
            }
            .padding(EdgeInsets.init(top: 0, leading: DeviceLeftSpace , bottom: 0 , trailing: DeviceLeftSpace))
            .introspectScrollView { scroll in
                viewModel.scroll = scroll
                scroll.delegate = viewModel
            }
            
            Button.init {
                viewModel.goToSettingVC()
            } label: {
                Image.init("icon_Settings")
            }
            .frame(width: settingsWidth,height: settingsWidth)
            .position(x: settingsLeft , y:settingsTop)
            
            
            // bottom overlay button
            if viewModel.connected {
                VStack {
                    Spacer()
                    getBottomMenu
                    Spacer().frame(height: IsIpad() ? 30 : 16.0)
                }.padding(.trailing, IsIpad() ? 30 : 0)
            }
            
            if viewModel.isShowWakeOnLanLoading {
                ActivityIndicator.init(isAnimating: .constant(true), style: UIActivityIndicatorView.Style.medium, color: Color.hex(0x999999).uiColor())
                    .frame(width: 24,height: 24)
            }
            
        }
        .edgesIgnoringSafeArea(.all)
        .fullScreenCover(isPresented: $viewModel.isShowAddManualHostView) {
            AddManualHostView()
            .background(Color.clear) // 确保整个模态视图的背景是透明的
        }
        .valueChanged(value: viewModel.isShowAddManualHostView) { show in
            if show == false {
                viewModel.startTracking()
            }
        }
        .onAppearFix{
            viewModel.startTracking()
        }
    }
    
    
    private func getHostCell(rowIndex: Int , isPairedHost: Bool) -> some View {
        
        if (rowIndex < viewModel.pairedHosts.count && isPairedHost ) || ( rowIndex < viewModel.netHosts.count && isPairedHost == false) {
            
            let host : TemporaryHost = isPairedHost ? viewModel.pairedHosts[rowIndex] : viewModel.netHosts[rowIndex]
            var press:Bool = false
            var index:Int = rowIndex
            
            return VStack {
                
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
                            .font(Font.system(size: 20))
                            .frame(width: HostCellWidth, height: 75, alignment: .top)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 5)
                        
//                        Spacer().frame(height: 5)
                        
                    }
                }
                .clipped()
                
            }
            .frame(width: HostCellWidth, height: HostCellHeight)
            .contentShape(Rectangle()) //没有颜色区域无法响应点击，//没有颜色的情况用contentShape扩大点击响应区域
            .onTapGesture {
                
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
            }
            .eraseToAnyView()
            
        }else{
            
            return Color.black.opacity(0)
                .frame(width: HostCellWidth, height: HostCellHeight)
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
                }
            }
    }
    
}

