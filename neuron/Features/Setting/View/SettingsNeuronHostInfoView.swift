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
import Introspect
//import DeviceKit

let SettingHostMenuButtonWidth = 152.0
let SettingHostMenuButtonHeight = 52.0
let SettingHostMenuButtonCornerRadius = (SettingHostMenuButtonHeight / 2.0)
struct SettingsNeuronHostInfoView: View {
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var viewModel : DashboardViewModel = DashboardViewModel.shared
    @SwiftUI.State var menuShowing:Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @SwiftUI.State var appear:Bool = false
    //var host: NeuronHost
    
    var body: some View {
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
//        if viewModel.isNeedShowNoNetworkPermissonAlert {
//            viewModel.initAndShowNoLocalNetworkPermissionAlert(colorScheme: colorScheme)
//        }
        
        return GeometryReader { geometry in
            
            ZStack{
                ScrollView(showsIndicators: false){
                    VStack (alignment: .leading){
                        
                        //navigationbar的高度
                        Color.clear.frame(height:(10 + SettingsUtil.shared.getNavBarHeight()))
                        
                        Text("All Computers".localize())
                            .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                            .settingsSectionHeaderStyle()
                        
                        Spacer().frame(height: 5)
                        
                        Text(String(format: "To pair a PC, it must be on the same network as your %@. Ensure your PC has Razer Cortex v11.0.+ installed and signed in with your Razer ID.".localize(), deviceType))
                            .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                            .foregroundColor(.hex(0x999999))
                            .font(.system(size: 13))
                        
                        Spacer().frame(height: 20)
                        
                        //已经保存的host
                        if viewModel.pairedHosts.count > 0 {
                            
                            Text("Paired PC".localize())
                                .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                                .settingsSectionHeaderStyle()
                            
                            VStack(spacing: 0.0, content: {
                                ForEach(0...viewModel.pairedHosts.count-1, id: \.self) { index in
                                    
                                    if let host = viewModel.pairedHosts[safe:index] {
                                        SettingDevicesHostCell.init(settingsViewModel: settingsViewModel, host: host, local: true , online: (host.state == .online) )
                                            .background {
                                                let selected = settingsViewModel.highlightedUIComponent == .NeuronStreamingLocalHost && index == settingsViewModel.selectedHostIndex && (settingsViewModel.isConnected())
                                                selected ? Color.SettingMenuFocus : Color.SettingMenuBG
                                            }
                                        
                                        if viewModel.pairedHosts.count > 1 && index != viewModel.pairedHosts.count-1 {
                                            separator
                                        }
                                    }
                                }
                            })
                            .background {
                                Color.SettingMenuBG
                                    .cornerRadius(SettingHostMenuButtonCornerRadius)
                            }
                            .cornerRadius(SettingHostMenuButtonCornerRadius)
                            .clipped()
                            
                            Spacer().frame(height: 20)
                        }
                        
                        HStack(){
                            
                            Text("Unpaired PC".localize())
                                .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 0))
                                .settingsSectionHeaderStyle()
                            if viewModel.netHosts.count == 0 {
                                ActivityIndicator.init(isAnimating: .constant(true), style: UIActivityIndicatorView.Style.medium)
                                    .frame(width: 24,height: 24)
                            }
                        }
                        
                        
                        //搜索到的host
                        VStack(spacing: 0.0, content: {
                            
                            if viewModel.netHosts.count > 0 {
                                ForEach(0...viewModel.netHosts.count-1, id: \.self) { index in
                                    if let host = viewModel.netHosts[safe:index] {
                                        SettingDevicesHostCell.init(settingsViewModel: settingsViewModel , host: host, local: false)
                                            .background {
                                                let selected = settingsViewModel.highlightedUIComponent == .NeuronStreamingNetHost && index == settingsViewModel.selectedHostIndex && (settingsViewModel.isConnected())
                                                selected ? Color.SettingMenuFocus : Color.SettingMenuBG
                                            }
                                        //if viewModel.netHostArray.count > 1 && index != viewModel.netHostArray.count-1 {
                                        separator
                                        //}
                                    }
                                }
                            }
                            
                            HStack(){
                                Spacer().frame(width:20)
                                
                                Text("Add PC manually".localize())
                                    .foregroundColor(.white)
                                    .font(.system(size:17))
                                
                                Spacer()
                                
                                Image("settings_item_backward_white")
                                
                                Spacer().frame(width:20)
                                
                            }
                            .frame(height:SettingHostMenuButtonHeight)
                            .contentShape(Rectangle())
                            .background {
                                
                                if settingsViewModel.highlightedUIComponent == .NeuronStreamingAddHost && (settingsViewModel.isConnected()) {
                                    Color.SettingMenuFocus
                                    //.cornerRadius(10.0)
                                }else{
                                    Color.SettingMenuBG
                                    //.cornerRadius(10.0)
                                }
                                
                            }
                            .onTapGesture {
                                viewModel.settingsManuallyAddPC()
                            }
                        })
                        .background {
                            Color.SettingMenuBG
                                .cornerRadius(SettingHostMenuButtonCornerRadius)
                        }
                        .cornerRadius(SettingHostMenuButtonCornerRadius)
                        .clipped()
                        
                        
                        Text("Enter the IP address of your computer.".localize())
                            .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 10))
                            .foregroundColor(.hex(0x999999))
                            .font(.system(size: 13))
                        
                        Spacer().frame(height: 20)
                        
                    }
                    .padding(EdgeInsets.init(top: 0, leading: 0, bottom: 50, trailing: 0))
                }
                .frame(width:geometry.size.width , height: geometry.size.height , alignment: .topLeading)
//                .frame(
//                    maxWidth: .infinity,
//                    maxHeight: .infinity,
//                    alignment: .topLeading
//                )
                .introspectScrollView(customize: { scrollView in
                    settingsViewModel.hostScrollView = scrollView
                })
                
                if viewModel.isWaitForHostResponse {
                    waitForHostResponseLoadingView
                }
            }
            .onAppearFix(perform: {
                //check local network permission
//                viewModel.isHostInfoViewAppear = true
//                viewModel.stopDiscovery()
//                viewModel.requestLocalNetworkPermission()
//                viewModel.updateCacheLocalHostData()
//                viewModel.resetAll()
//                viewModel.startDiscovery()
                Logger.info("SettingsDevicesHostView onAppear")
                //AnalyticsManager.shared.logScreen(screenName: AnalyticsManager.SCREEN_SETTINGS_HOST)
                
                //settingsViewModel.navTitle = "Computer".localize()
                settingsViewModel.startTracking()
                appear = true
            })
            .onDisappear(perform: {
//                viewModel.isHostInfoViewAppear = false
//                viewModel.isWaitForHostResponse = false
//                viewModel.cancelAllRequest()
                if settingsViewModel.getCurrentNavigationPathCount() < 1 && appear {
                    if horizontalSizeClass == .compact {
                        settingsViewModel.highlightedUIComponent = .NeuronStreamingHostMenu
                    }
                }
                appear = false
            })
            .onAppear(){
//                settingsViewModel.sidebarVisibilitySubject.send(true)
            }
            .fullScreenCover(isPresented: $viewModel.isShowAddManualHostViewInSettings) {
                ZStack {                                //keep out of VStack to avoid vertical layout issues
                    ClearFullScreenBackgroundView()     // Keep background transparent
                    AddManualHostView()
                        .background(Color.clear) // 确保整个模态视图的背景是透明的
                }
                .ignoresSafeArea()
            }
            .valueChanged(value: viewModel.isShowAddManualHostViewInSettings) { show in
                if show == false {
                    settingsViewModel.startTracking()
                }
            }
            
        }
        .ignoresSafeArea(.all)
    }
    
    var waitForHostResponseLoadingView: some View {
        ZStack {
            Color.black.opacity(0.3)
            ActivityIndicator(isAnimating: $viewModel.isWaitForHostResponse, style: .large)
        }
    }
    
    var separator: some View {
        return HStack(){
            Spacer().frame(width:20)
            Color.hex(0xe6e6e6)
            Spacer().frame(width:20)
        }
        .frame(height: (1.0 / UIScreen.screenScale))
    }
}

struct SettingDevicesHostCell: View {
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    var host: TemporaryHost
    var local:Bool
    var online:Bool = false
    @SwiftUI.State private var clicking:Bool = false
    
    var body: some View {
        
        HStack(){
            Spacer().frame(width:20)
            
            if local {
                if online {
                    Image("new_pc_available")
                }else{
                    Image("new_pc_unavailable")
                }
            }else{
                Image("new_pc_unpaired")
            }
            
            
            Text(host.name).font(.system(size: 17))
            
            Spacer()
            
            if local {
                if online {
                    Text("Available".localize()).font(.system(size:17)).foregroundColor(Color.hex(0x999999))
                }else{
                    Text("Unavailable".localize()).font(.system(size:17)).foregroundColor(Color.hex(0x999999))
                }
            }else{
                Text("Unpaired".localize()).font(.system(size:17)).foregroundColor(Color.hex(0x999999))
            }
            
            Image("settings_host_more")
                .frame(width:30,height: 50)
                .contentShape(Rectangle())
                .onTapGesture {
                    DispatchQueue.main.async {
                        if self.local {
                            //settingsViewModel.goToLocalHostMenuView(host: self.host)
                            settingsViewModel.pushToNewPageWith(path: SettingsRoute.PairedComputer(host: host))
                        }else{
                            
                            if self.clicking {
                                return
                            }
                            
                            self.clicking = true
                            
                            if ControllerInputTracker.shared.isConnected {
                                settingsViewModel.highlightedUIComponent = .NeuronStreamingNetHost
                                let index = DashboardViewModel.shared.netHosts.firstIndex(where: {$0.uuid == host.uuid}) ?? 0
                                settingsViewModel.selectedHostIndex = index
                            }
                            print("host = \(host.name) PairViewModel.shared.netHostArray.count = \(DashboardViewModel.shared.netHosts.count)  selectIndex = \(index)")
                            //PairViewModel.shared.startPairHost(host, showAlert: true)
                            DashboardViewModel.shared.pairHost(host)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.clicking = false
                            }
                        }
                    }
                }
            
            Spacer().frame(width:20)
        }
        .contentShape(Rectangle())
        .frame(height: SettingHostMenuButtonHeight)
        .onTapGesture {
            if local {
                //settingsViewModel.goToLocalHostMenuView(host: self.host)
                settingsViewModel.pushToNewPageWith(path: SettingsRoute.PairedComputer(host: host))
            }else{
                
                if clicking {
                    return
                }
                
                clicking = true
                
                if ControllerInputTracker.shared.isConnected {
                    settingsViewModel.highlightedUIComponent = .NeuronStreamingNetHost
                    let index = DashboardViewModel.shared.netHosts.firstIndex(where: {$0.uuid == host.uuid}) ?? 0
                    settingsViewModel.selectedHostIndex = index
                }
                print("host = \(host.name) PairViewModel.shared.netHostArray.count = \(DashboardViewModel.shared.netHosts.count)  selectIndex = \(String(describing: index))")
                //PairViewModel.shared.startPairHost(host, showAlert: true)
                DashboardViewModel.shared.pairHost(host)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.clicking = false
                }
            }
        }
    }
    
}



struct SettingHostMeneButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(content: {
                configuration.isPressed ? Color.white : Color.gray
            })
            .foregroundColor(configuration.isPressed ? Color.black : Color.white)
            .animation(.default)
    }
}
