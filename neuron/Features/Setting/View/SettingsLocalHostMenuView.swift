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
import StoreKit

let LocalHostMenuHeight = 52.0
let LocalHostMenuCornerRadius = (LocalHostMenuHeight / 2.0)

enum SettingsLocalHostMenuButtonType {
    case unpair
    case remotePlay
}

struct SettingsLocalHostMenuView : View {
    
    @ObservedObject var viewModel: SettingsLocalHostMenuViewModel = SettingsLocalHostMenuViewModel.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @SwiftUI.State private var navTitle = ""
    @SwiftUI.State private var firstInPage : Bool = true
    
    var host: TemporaryHost
    
    var body: some View {
        
        let letspace = (horizontalSizeClass == .compact) ? 20.0 : 70.0
        
        return GeometryReader { geometry in
            
            ZStack(alignment: .center) {
                
                VStack(alignment: .leading, spacing: 0) {
                    
                    Spacer()
                        .frame(height: (horizontalSizeClass == .compact) ? 16.0 : 32.0)
                    
                    HStack {
                        Spacer().frame(width: letspace)
                        
                        VStack (alignment:.leading, spacing: 0) {
                            
                            hostMenu(
                                title: "Remote Play",
                                selected: (viewModel.selectedButton == .remotePlay),
                                geometry:geometry
                            ) {
                                self.onRemotePlayClicked()
                            }
                            
                            HStack(){
                                Spacer().frame(width:8)
                                Color.hex(0x999999)
                                Spacer().frame(width:8)
                            }
                            .background(content: {
                                Color.SettingMenuBG
                            })
                            .frame(height: (1.0 / UIScreen.screenScale))
                            
                            
                            hostMenu(
                                title: "Unpair",
                                selected: (viewModel.selectedButton == .unpair),
                                geometry:geometry
                            ) {
                                self.onUnpairClicked()
                            }
                            
                            
                        }
                        .cornerRadius(LocalHostMenuCornerRadius)
                        
                        Spacer().frame(width: letspace)
                    }
                    
                    Spacer()
                }
                .introspectNavigationController { nav in
                    SettingsRouter.shared.navigationController = nav
                }
                
                if viewModel.isShowProgressView {
                    progressView
                        .zIndex(99)
                }
                
            }
            .frame(width: geometry.size.width ,height: geometry.size.height)
            .background(Color.Black)
            .navigationBarTitle( host.name , displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.dismissProgressView()
                        SettingsViewModel.shared.popView()
                    } label: {
                        Image(systemName: "chevron.left")
                            .bold()
                    }
                    .accessibilityLabel("Back".localize())
                }
                
                ToolbarItem(placement: .title) {
                    Text.init(host.name)
                        .foregroundColor(Color.white)
                        .font(.system(size:17))
                }
            })
            .onAppearFix(){
                //DDLogInfo("\(APP_LOG_VC) SettingsAddManualHostView:onAppear")
                viewModel.startTracking()
                if firstInPage {
                    viewModel.selectedButton = .remotePlay
                    firstInPage = false
                }
                viewModel.clickA = {
                    if viewModel.selectedButton == .unpair {
                        self.onUnpairClicked()
                    } else if viewModel.selectedButton == .remotePlay {
                        self.onRemotePlayClicked()
                    }
                }
                DispatchQueue.main.async {
                    self.navTitle = host.name
                }
            }
            .onDisappear {
                viewModel.dismissProgressView()
            }
            
        }
    }
    
    var progressView: some View {
        
        ZStack {
            Color.black.opacity(0.5)
            VStack {
                ActivityIndicator(isAnimating: $viewModel.isShowProgressView, style: .large)
            }
        }
    }
    
    func onUnpairClicked() {
        if viewModel.isShowProgressView == true {
            return
        }
        viewModel.showProgressView()
        viewModel.selectedButton = .unpair
        DispatchQueue.main.async {
            DashboardViewModel.shared.unpairHost(self.host)
            //viewModel.stopTracking()
            if DashboardViewModel.shared.pairedHosts.count > 0 {
                SettingsViewModel.shared.highlightedUIComponent = .NeuronStreamingLocalHost
                SettingsViewModel.shared.selectedHostIndex = 0
            }else if DashboardViewModel.shared.netHosts.count > 0 {
                SettingsViewModel.shared.highlightedUIComponent = .NeuronStreamingNetHost
                SettingsViewModel.shared.selectedHostIndex = 0
            }else {
                SettingsViewModel.shared.highlightedUIComponent = .NeuronStreamingAddHost
            }
            //SettingsViewModel.shared.updateHostScrollViewOffset()
            SettingsViewModel.shared.popView()
        }
    }
    
    func onRemotePlayClicked() {
        if viewModel.isShowProgressView == true {
            return
        }
        viewModel.showProgressView()
        viewModel.selectedButton = .remotePlay
        DispatchQueue.main.async {
            viewModel.launchDesktop(host)
        }
    }
    
    func hostMenu(title: String , selected: Bool , geometry : GeometryProxy ,action: @escaping () -> Void ) -> some View {
        
        let letspace = (horizontalSizeClass == .compact) ? 20.0 : 70.0
        
        return HStack(){
            Spacer().frame(width:15)
            Text(title.localize().uppercased())
                .font(.system(size: 17))
            Spacer()
        }
        .foregroundColor(Color.white)
        .frame(width:geometry.size.width - letspace * 2 , height:LocalHostMenuHeight)
        .background {
            if (viewModel.isConnected()) && selected {
                Color.SettingMenuFocus
            }else{
                Color.SettingMenuBG
            }
        }
        .onTapGesture {
            action()
        }
    }
}

class SettingsLocalHostMenuViewModel : RZHandleResponder { //InputTrackerViewModel {
    
    static let shared = SettingsLocalHostMenuViewModel()
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    var clickA:(()->Void)? = nil
    
    @Published var selectedButton: SettingsLocalHostMenuButtonType = .remotePlay
    
    @Published var isShowProgressView: Bool = false {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    @Published var isShowInstallNeuronAlert: Bool = false
    var installNeuronAlert: SwiftAlertView? = nil
    
    @Published var isShowDownloadOverlay = false {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    private var cancellableBag = Set<AnyCancellable>()
    
    override init() {
        super.init()
    }
    
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    func showProgressView() {
        isShowProgressView = true
    }
    
    func dismissProgressView() {
        isShowProgressView = false
    }
    
    override func analyzeControllerInputs(_ value:ControllerInputDelegate.ActionTriggered){
        //DDLogInfo("\(APP_LOG_VC) SettingsLocalHostMenuView:analyzeControllerInputs")
        self.analyze(value)
    }
    
    func handleClickButton(_ button: GamePadButton) {
        
        
    }
    
    func analyze(_ value:ControllerInputDelegate.ActionTriggered){
        
        switch value {
        case .control(button: let button, counter: let counter, state: _):
            //DDLogInfo("\(APP_LOG_VC) SettingsLocalHostMenuView:analyzeControllerInputs button:\(button.description) counter:\(counter)")
            switch button{
            case .A:
                if isShowProgressView { return }
                clickA?()
            case .B:
                //self.shouldDismissView = true
                //                stopTracking()
                dismissProgressView()
                SettingsViewModel.shared.popView()
            case .up:
                if isShowProgressView { return }
                if selectedButton == .unpair {
                    selectedButton = .remotePlay
                }
            case .down:
                if isShowProgressView { return }
                if selectedButton == .remotePlay {
                    selectedButton = .unpair
                }
            default: break
            }
        default: break
        }
    }
    
    func launchDesktop(_ host: TemporaryHost) {
        DashboardViewModel.shared.startPlayHost(host)
    }
    
}
