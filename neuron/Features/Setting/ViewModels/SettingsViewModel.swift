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
import Combine

enum SettingsViewControllersCount: Int {
    case regular = 0
    case compactSidebar = 1
    case compactDetail = 2
    case compactPushPage = 3
    case regularPushPage = 4
}

class SettingsViewModel: RZHandleResponder {
    
    static let shared = SettingsViewModel()
    var hostScrollView:UIScrollView? = nil
    
    @Published var dismissScreen : Bool = false{
        willSet {
            self.objectWillChange.send()
        }
    }
    
    @Published private var detailPath = NavigationPath() {
        didSet {
            detailPathCount = detailPath.count
        }
    }
    @Published private(set) var detailPathCount: Int = 0
    
    var selectedMenuItem = SettingsUIComponents.defaultHighlightedMenuType
    @Published var menuItemList = MenuItemList() {
        willSet {
            self.objectWillChange.send()
        }
    }
    @Published var highlightedUIComponent = SettingsUIComponents.defaultHighlightedMenuType {
        willSet {
            self.objectWillChange.send()
        }
        didSet {
            if highlightedUIComponent.isMenuItem() == false {
              detailVisibilitySubject.send(true)
            }else {
              detailVisibilitySubject.send(false)
            }
        }
    }
    
    private let detailVisibilitySubject = PassthroughSubject<Bool, Never>()
    var detailVisibilityPublisher: AnyPublisher<Bool, Never> {
        detailVisibilitySubject.eraseToAnyPublisher()
    }
    
    var pushPageReturnHighlight: SettingsUIComponents.ComponentType? = nil  // Set by push page to indicate which item to highlight when returning to detail
    
    @Published private(set) var viewControllersCountState: SettingsViewControllersCount = .regular
    
    @Published var selectedHostIndex: Int = -1 {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    @Published var selectedHostAddress: String? = nil {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    @Published var hosts: [TemporaryHost] = [] {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    var iconTapCount = 0
    
    private override init() {
        super.init()
    }
    
    func bindingForDetailPath() -> Binding<NavigationPath> {
        Binding(get: {self.detailPath}, set: {self.detailPath = $0})
    }
    
    func setSelectedMenuItem(menuItem: SettingsUIComponents.ComponentType, doBookmarking: Bool) {
        self.printLog("setSelectedMenuItem to: " + menuItem.description)
        
        if menuItem.isMenuItem() {
            self.selectedMenuItem = menuItem
            self.highlightedUIComponent = menuItem
        }else{
            self.printLog("component is not a menu item")
        }
    }
    
    func printLog(_ msg:String){
        BiancaLogger.shared.logInfo("SettingsViewModel - " + msg)
    }
    
    func NeuronSettingsMenuselectHost(index: Int) {
        highlightedUIComponent = .NeuronStreamingHostMenu
        if index >= 0 && index < hosts.count {
            selectedHostIndex = index
        }
    }
    
    //to avoid this case:Fixed: compact screen 1.settings -> controller menu -> controller options ->gesture back to controller menu
    // -> (A) to contorller option -> (B) will go back to sidebar  in commit id of 01c4ccff92ac0a7cdfb6e530f5d03617223be177
    func restoreHighlightAfterPopIfNeeded(currentState: SettingsViewControllersCount, popDelta: Int) {
        guard popDelta == 1 else { return } // if we won't consider multi-level pop back, we can skip the check for now
        Logger.debug("[SettingsSplitView] Gesture back check - currentState: \(currentState), pushPageReturnHighlight: \(String(describing: pushPageReturnHighlight))")
        guard currentState == .compactDetail,// || currentState == .compactPushPage,
              let returnHighlight = pushPageReturnHighlight else { return }
        if highlightedUIComponent != returnHighlight {
            Logger.debug("[SettingsSplitView] restore highlightedUIComponent after push page return target: \(highlightedUIComponent) -> \(returnHighlight)")
            highlightedUIComponent = returnHighlight
            pushPageReturnHighlight = nil  // Clear after use
        } else {
            Logger.debug("[SettingsSplitView] highlightedUIComponent already at target, clearing cache")
            pushPageReturnHighlight = nil  // Clear even if already correct
        }
    }
    
    func getViewControllersCountState() -> SettingsViewControllersCount {
        // Logger.debug("[SettingsSplitView][SettingsViewModel] getViewControllersCountState: \(viewControllersCountState)")
        return viewControllersCountState
    }
    
    func updateViewControllersCountState(_ state: SettingsViewControllersCount) {
        guard viewControllersCountState != state else { return }
        viewControllersCountState = state
        Logger.debug("[SettingsViewModel] viewControllersCountState updated to: \(state)")
    }
    
    func syncHighlightToParentMenuIfNeeded() {
        let parentMenuItem = highlightedUIComponent.getParentMenuItem()
        if highlightedUIComponent != parentMenuItem {
            highlightedUIComponent = parentMenuItem
        }
    }
    
}


extension SettingsViewModel {
    
    func goToTermsOfService() {
        //TODO https://www.razer.com/legal/services-and-software-terms-of-use-mobile
        SettingsViewModel.shared.highlightedUIComponent = .AboutTermsOfServiceWebView
        SettingsViewModel.shared.pushToNewPageWith(path: SettingsRoute.TermsOfService)
    }
    
    func goToPrivacyPolicy() {
        //TODO https://www.razer.com/legal/customer-privacy-policy-mobile
        SettingsViewModel.shared.highlightedUIComponent = .AboutPrivacyWebView
        SettingsViewModel.shared.pushToNewPageWith(path: SettingsRoute.PrivacyPolicy)
    }
    
    func goToOpenSource() {
        // go to OpenSourceView
        SettingsViewModel.shared.highlightedUIComponent = .AboutOpenSourceWebView
        SettingsViewModel.shared.pushToNewPageWith(path: SettingsRoute.OpenSource)
    }
    
    func aboutPageIconImageTapped() {
        printLog("onImageTapped")
        
        if( iconTapCount > 8 ){
            //show dev page
            pushToNewPageWith(path: .DevPage)
            iconTapCount = 0
        }else{
            iconTapCount += 1
        }
    }
    
    func toggleDebugMode() {
        DevUtils.shared().isDebugMode = !(DevUtils.shared().isDebugMode)
        print("toggleDebugMode:\(DevUtils.shared().isDebugMode)")
        let msg = DevUtils.shared().isDebugMode ? "Enable Debug Mode" : "Disable Debug Mode"
        NotificationCenter.default.post(name: .debugModeUpdateNotification, object: nil)
        Toast.show(text: msg)
    }
}

//NavigationPath
extension SettingsViewModel {
    
    func pushToNewPageWith(path: SettingsRoute) {

        detailPath.append(path)
        // Logger.debug("[SettingsViewModel] pushToNewPageWith: \(path)")
        // let newState: SettingsViewControllersCount = isHorizontalSizeClassRegular() ? .regularPushPage : .compactPushPage
        // updateViewControllersCountState(newState)
    }
    
    func popView() {
        if !detailPath.isEmpty {
            detailPath.removeLast()
        }
    }
    
    func popToRoot() {
        if !detailPath.isEmpty {
            detailPath.removeLast(detailPath.count)
        }
    }
    
    func getCurrentNavigationPathCount() -> Int {
        return detailPath.count
    }

}

//computers page update offset
extension SettingsViewModel {
    
    func updateHostScrollViewOffset(){
        let contentHeight = hostScrollView?.contentSize.height ?? UIScreen.screenHeight
        let scrollHeight = hostScrollView?.bounds.height ?? UIScreen.screenHeight
        var contentY = 0.0
        if highlightedUIComponent == .NeuronStreamingLocalHost {
            contentY = 40.0 * Double(selectedHostIndex)
        }else if highlightedUIComponent == .NeuronStreamingNetHost {
            let count = DashboardViewModel.shared.pairedHosts.count + selectedHostIndex
            contentY = 40.0 * Double(count)
        }else if highlightedUIComponent == .NeuronStreamingAddHost {
            let count = DashboardViewModel.shared.pairedHosts.count + DashboardViewModel.shared.netHosts.count + 1
            contentY = 40.0 * Double(count)
        }
        
        contentY = min(contentY, Double(Int(contentHeight - scrollHeight) > 0  ? Double(contentHeight - scrollHeight) : 0))
        contentY = contentY < 0 ? 0 : contentY
        hostScrollView?.contentOffset = CGPoint(x: 0, y: contentY)
        selectedHostAddress = nil
    }
    
}
