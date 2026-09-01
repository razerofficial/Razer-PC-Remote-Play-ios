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

struct SettingsMenuView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: SettingsViewModel = SettingsViewModel.shared
    
    private var leftPadding : CGFloat
    private var rightPadding : CGFloat = SettingsUtil.shared.getMenuButtonRightPadding()
    
    @SwiftUI.State private var shouldScrollToHighlighted = false
    
    init(leftPadding: CGFloat) {
        self.leftPadding = leftPadding
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer().frame(width: leftPadding)
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack (alignment: .leading, spacing: 0) {
                        
                        ForEach(getMenuItems(), id: \.self) { menuItem in
                            self.getMenuButton(menuItem: menuItem)//.scaleEffect(VScale, anchor: .leading)
                            self.getMenuSpace(menuItem:menuItem)
                        }
                        
                    }
                    //.scaleEffect(SettingMenuScale)//SE需要缩放适应屏幕
                }
                #if !os(tvOS)
                .scrollContentBackground(.hidden)
                #endif
                .frame(maxHeight: .infinity)
                .onAppear {
                    //for BIA-2304, ios 17 will reset whole NavigationSplitView, so we need to re-scroll to highlighted item again
                    if #unavailable(iOS 18) {
                        shouldScrollToHighlighted = true
                    }
                }
            }
            Spacer().frame(width: rightPadding)
        }
        .background(
            Color.black
        )
    }
    
    private func getMenuItems() -> [SettingsUIComponents.ComponentType]{
        return viewModel.menuItemList.list
    }
    
    private func getMenuButton(menuItem:SettingsUIComponents.ComponentType) -> some View {
        let title = menuItem.getTitle()
        let isSelected = isMenuSelected(menuItem)
        
        if (menuItem == .NeuronStreamingHostMenu) {
            return SettingsMenuItemButton(description:title,isSelected:isSelected, style:.bottomHalfRoundedRectangle, isNeedBottomLine:false, settingsVM: viewModel) {
                viewModel.setSelectedMenuItem(menuItem: menuItem, doBookmarking: true)
                
                viewModel.popToRoot()
                
                if shouldShowDetailView() {
                    if HostListManger.shared.pairedHosts.count > 0 {
                        viewModel.highlightedUIComponent = .NeuronStreamingLocalHost
                        viewModel.selectedHostIndex = 0
                    }else if HostListManger.shared.netHosts.count > 0 {
                        viewModel.highlightedUIComponent = .NeuronStreamingNetHost
                        viewModel.selectedHostIndex = 0
                    }else {
                        viewModel.highlightedUIComponent = .NeuronStreamingAddHost
                    }
                }
            }
        }
        else if (menuItem == .NeuronStreamingMenu) {
            let style:SettingsMenuItemStyle = NeuronFrameSettingsViewModel.shared().remotePlayToggle ? .topHalfRoundedRectangle : .roundedRectangle
            let needBottomLine = NeuronFrameSettingsViewModel.shared().remotePlayToggle
            return SettingsMenuItemButton(description:title,isSelected:isSelected, style:style , isNeedBottomLine:needBottomLine, settingsVM: viewModel) {
                
                viewModel.popToRoot()
                viewModel.setSelectedMenuItem(menuItem: menuItem, doBookmarking: true)
                
                if shouldShowDetailView() {
                    viewModel.highlightedUIComponent = .NeuronStreamingSettingsDisplayModeDeviceOptimized
                }
            }
        }
        
        else if (menuItem == .AboutMenu) {
            return SettingsMenuItemButton(description:title,isSelected:isSelected, settingsVM: viewModel){
                
                viewModel.popToRoot()
                viewModel.setSelectedMenuItem(menuItem: menuItem, doBookmarking: true)
                
                if shouldShowDetailView() {
                    viewModel.highlightedUIComponent = .AboutButtonTermsOfService
                }
            }
        }
        else {
            return SettingsMenuItemButton(description:title,isSelected:isSelected, settingsVM: viewModel){
                viewModel.setSelectedMenuItem(menuItem: menuItem, doBookmarking: true)
            }
        }
    }
    
    private func isMenuSelected(_ menuItem:SettingsUIComponents.ComponentType) -> Bool{
        if menuItem == viewModel.highlightedUIComponent.getParentMenuItem() {
            return true
        }
        return false
    }
    
    private func getMenuSpace(menuItem:SettingsUIComponents.ComponentType) -> AnyView {
        
        if (menuItem == .NeuronStreamingHostMenu || menuItem == .AboutMenu) {
            return  AnyView(Spacer().frame(height: 20))
        }
        
        return AnyView(EmptyView())
    }
    
    func shouldShowDetailView() -> Bool {
        if IsIPhone() {
            return true
        }else {
            if horizontalSizeClass == .compact {
                return true
            }else {
                return false
            }
        }
    }
}

