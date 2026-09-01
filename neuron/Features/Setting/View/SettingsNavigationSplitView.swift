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
import Introspect

// 定義專屬的 EnvironmentKey
private struct SplitColumnVisibilityKey: EnvironmentKey {
    // 預設值使用 .constant，避免沒有注入時 crash
    static let defaultValue: Binding<NavigationSplitViewVisibility> =
        .constant(.all)
}

extension EnvironmentValues {
    var splitColumnVisibility: Binding<NavigationSplitViewVisibility> {
        get { self[SplitColumnVisibilityKey.self] }
        set { self[SplitColumnVisibilityKey.self] = newValue }
    }
}

public struct SettingsNavigationSplitView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var viewModel: SettingsViewModel = SettingsViewModel.shared
    
    @SwiftUI.State var visibility: NavigationSplitViewColumn = .sidebar
    @SwiftUI.State var columnVisibility: NavigationSplitViewVisibility = .all
    @SwiftUI.State var isInDetailView: Bool = false                  // isInDetailView to make sure the back btn can pop to sidebar
    @SwiftUI.State private var uikitNavigationStackDepth: Int = 0    // Raw UIKit navigation controller stack depth (updated by NavigationPopObserver)
    @SwiftUI.State private var navigationPopObserverUUID = UUID()    // Force rebuild when split view reconfigures (e.g., rotation)
    @SwiftUI.State private var splitViewRefreshID = UUID()           // Force rebuild the whole split view when needed (iOS 17 sidebar refresh issue) BIA-2304
    @SwiftUI.State var detailNavigationController: UINavigationController?
    @SwiftUI.State var backButtonTarget = NavigationBarButtonTarget()
    @SwiftUI.State private var isSyncScheduled = false               // prevent multiple scheduled syncs
    @SwiftUI.State private var lastSyncKey = ""                      // last sync key to prevent redundant syncs
    @SwiftUI.State private var previousDetailPathCount: Int = 0      // Track detail path count before latest change
    @SwiftUI.State private var currentDetailPathCount: Int = 0       // Track latest detail path count
    @SwiftUI.State private var didInitializeViewControllersState = false // for initializing viewControllersState based on current UI conditino
    @SwiftUI.State private var isDetailOpening = false               // track detail opening to avoid skipping sync on close
    @SwiftUI.State private var pendingRotationSync = false           // wait for depth update after rotation
    @SwiftUI.State private var pendingRotationSyncToken = UUID()     // cancel stale fallback syncs
    
    let TermOfServiceUrl = "https://www.razer.com/legal/services-and-software-terms-of-use-mobile"
    let PrivacyPolicyUrl = "https://www.razer.com/legal/customer-privacy-policy-mobile"
    
    @GestureState private var settingsDragOffset: CGFloat = 0                                           //change from SwiftUI.State to GestureState to avoid view shift (won't return to 0 when dragging ended)
    @SwiftUI.State private var settingsDragViewControllersState: SettingsViewControllersCount? = nil    //make sure state consistent during to dragging
    @SwiftUI.State private var settingsDragStartPathCount: Int? = nil                                  //capture initial path count to avoid mid-gesture state flips
    @GestureState private var isSettingsDragging: Bool = false//track dragging state for reset view offset when drag ended
    
    let onDismiss: DismissCallback
    
    private var navigationPopObserverId: String {
        "\(isInDetailView)-\(navigationPopObserverUUID.uuidString)"
    }
    
    private var currentNavStackDepth: Int {
        detailNavigationController?.viewControllers.count ?? uikitNavigationStackDepth
    }
    
    private var shouldUseCustomBackButton: Bool {
        !isHorizontalSizeClassRegular() && currentNavStackDepth <= 1
    }
    
    public var body: some View {
        
        return NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: $visibility) {
            SettingsMenuView(leftPadding: leftPadding)
                .navigationTitle(horizontalSizeClass == .compact ? "Settings".localize() : "")
                #if !os(tvOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        let size = SettingsUtil.shared.getNativeNavBarHeight()
                        Button {
                            dismiss()
                        } label: {
                            if #available(iOS 26.0, *), isHorizontalSizeClassRegular() {
                                Image(systemName: "chevron.left")
//                                    .bold()
                                    .frame(width: size, height: size)
                                    .compatibleGlassTouchEffect()
                            } else {
                                Image(systemName: "chevron.left")
//                                    .bold()
                            }
                        }
                    }
                }
        } detail: {
            NavigationStack(path: viewModel.bindingForDetailPath()) {
             
                SettingsSubContentView(content: getRightContentView())
                    .navigationTitle(viewModel.highlightedUIComponent.getParentMenuItem().getTitle())
                    #if !os(tvOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .background {
                        //register NavigationPopObserver to retrieve navigation stack depth
                        NavigationPopObserver(
                            navigationController: $detailNavigationController,
                            viewControllersCount: $uikitNavigationStackDepth,
                            onNavigationPop: { popDelta in
                                Logger.debug("[SettingsSplitView]NavigationPopObserver detected popDelta: \(popDelta), uikitNavigationStackDepth: \(uikitNavigationStackDepth)")
                                handleNavigationPop(popDelta: popDelta)
                            }
                        )
                            .id(navigationPopObserverId)
                    }
                    .toolbar {
                        if shouldUseCustomBackButton && viewModel.getCurrentNavigationPathCount() == 0 {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    handleSplitViewBackButtonTap()
                                } label: {
                                    Image(systemName: "chevron.left")
//                                        .bold()
                                }
                            }
                        }
                    }
                    .navigationBarBackButtonHidden(shouldUseCustomBackButton)
                    .navigationDestination(for: SettingsRoute.self) { route in
                        
                        switch route {
                        case .TermsOfService:
                            SettingWebView(title: "Terms of Service".localize(), url: URL(string: TermOfServiceUrl))
                        case .PrivacyPolicy:
                            SettingWebView(title: "Privacy Policy".localize(), url: URL(string: PrivacyPolicyUrl))
                        case .OpenSource:
                            SettingWebView(title: "Open Source Software Notice".localize(), url: Bundle.main.url(forResource: "licenses", withExtension: "html"), isLoadFileURL:true)
                        case .DevPage:
                            DevView()
                        case .PairedComputer(host:let host):
                            //EmptyView()
                            SettingsLocalHostMenuView(host:host)
                        }
                        
                    }
            }
            .introspectNavigationController(customize: { nav in
                if detailNavigationController !== nav {
                    detailNavigationController = nav
                    // updateBackButtonState()
                }
            })
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .accentColor(.primary)
        .environment(\.splitColumnVisibility, $columnVisibility)
        // NavigationLink("", destination: viewModel.destinationView, isActive: $viewModel.showNewScreen)
        .id(splitViewRefreshID)
        .navigationSplitViewStyle(.balanced)
        .onReceive(viewModel.detailVisibilityPublisher) { shouldShowDetailView in
            let wasInDetailView = isInDetailView
            Logger.debug("[SettingsSplitView] detailVisibilityPublisher received: \(shouldShowDetailView), highlightedUIComponent: \(viewModel.highlightedUIComponent), wasInDetailView: \(wasInDetailView)")
            isInDetailView = shouldShowDetailView
            // Only mark opening on a true transition; avoids ignore sync on push -> detail returns.
            if shouldShowDetailView && !wasInDetailView {
                isDetailOpening = true
                Logger.debug("[SettingsSplitView] isDetailOpening set true (detail opening transition)")
            } else if !shouldShowDetailView {
                if isDetailOpening {
                    Logger.debug("[SettingsSplitView] isDetailOpening set false (detail closed)")
                }
                isDetailOpening = false
            }
        }
        .onChange(of: isInDetailView) { newValue in
            visibility = newValue ? .detail : .sidebar
            if !isHorizontalSizeClassRegular(),
                newValue == false,
                viewModel.getCurrentNavigationPathCount() > 0 {
                viewModel.popToRoot()
            }
            Logger.debug("[SettingsSplitView]Set visibility to: \(newValue ? "detail" : "sidebar")")
            scheduleSync(reason: "isInDetailView")//to prevent the case of uikitNavigationStackDepth may not be triggered
            if #unavailable(iOS 18) {
                if newValue == false {
                    // for BIA-2304, ios 17 will ignore sidebar UI update in some cases of close detail in compact screen
                    forceSidebarVisibilityRefreshIfNeeded()
                }
            }
        }
        .onChange(of: visibility) { newValue in
            Logger.debug("[SettingsSplitView]onChange visibility: \(newValue), highlightedUIComponent: \(viewModel.highlightedUIComponent), isInDetailView: \(isInDetailView), pathCount: \(viewModel.getCurrentNavigationPathCount()), viewControllersCount: \(uikitNavigationStackDepth)")
            //move condition to restoreHighlightAfterPopIfNeeded after NavigationPop to avoid sometime swiftui crash duo to push the same view controller
        }
        .onChange(of: columnVisibility) { newValue in
            Logger.debug("[SettingsSplitView]onChange columnVisibility: \(newValue)")
            // navigationPopObserverUUID = UUID()  // Removed: only rebuild on rotation
        }
        .onChange(of: horizontalSizeClass) { newValue in
            Logger.debug("[SettingsSplitView]onChange horizontalSizeClass: \(String(describing: newValue))")
            navigationPopObserverUUID = UUID()
            pendingRotationSync = true
            let token = UUID()
            pendingRotationSyncToken = token
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard pendingRotationSync, pendingRotationSyncToken == token else { return }
                pendingRotationSync = false
                scheduleSync(reason: "horizontalSizeClass(fallback)")
            }
            //for ios 18, sometime back btn won't show after rotation in detail view
            updateBackButtonState()
        }
        .onChange(of: uikitNavigationStackDepth) { _ in
            Logger.debug("[SettingsSplitView]onChange uikitNavigationStackDepth: \(uikitNavigationStackDepth)")
            if isDetailOpening && uikitNavigationStackDepth >= 2 {
                isDetailOpening = false
            }
            if pendingRotationSync {
                pendingRotationSync = false
                scheduleSync(reason: "uikitNavigationStackDepth(pendingRotation)")
            } else {
                scheduleSync(reason: "uikitNavigationStackDepth")
            }
        }
        .onChange(of: viewModel.detailPathCount) { newValue in
            Logger.debug("[SettingsSplitView]onChange detailPathCount: \(newValue), previousDetailPathCount: \(previousDetailPathCount)")
            previousDetailPathCount = currentDetailPathCount
            currentDetailPathCount = newValue
            scheduleSync(reason: "detailPathCount")
        }
        .onAppear {
            Logger.debug("[SettingsSplitView]onAppear")
            // syncViewControllersState()
            currentDetailPathCount = viewModel.detailPathCount
            previousDetailPathCount = viewModel.detailPathCount
            initializeViewControllersStateIfNeeded()
        }
        .background {
            Color.black
        }
        .navigationTitle("Settings".localize())
        .onReceive(viewModel.$dismissScreen) { dismissScreen in
            if dismissScreen {
                printLog("dismissScreen == true")
                //TODO:  stop controller Track
//                self.viewModel.stopTracking()
                // close page
                dismiss()
            }
        }
        .onAppear{
            // get firmware version from controller in onAppear() to avoid sending redundant commands
            printLog("onAppear")
            
            //TODO: controller input
//            self.startTrackingControllerInput()
            self.viewModel.dismissScreen = false
        }
        .onDisappear(perform: {
            viewModel.dismissScreen = false
        })
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .updating($isSettingsDragging) { _, state, _ in
                    state = true
                }
                .updating($settingsDragOffset) { value, state, _ in
                    state = dragTranslation(for: value)
                }
                .onChanged(onSettingsDragChanged)
                .onEnded(onSettingsDragEnded)
        )
        .edgesIgnoringSafeArea(.all)
        .eraseToAnyView()
    }
    
    func handleSplitViewBackButtonTap() {
        let currentComponent = viewModel.highlightedUIComponent
        let pathCount = viewModel.getCurrentNavigationPathCount()
        Logger.debug("[SettingsNavigation] Back button tapped - currentComponent: \(currentComponent), pathCount: \(pathCount)")
        
        // If in pushed pages, just pop without changing highlightedUIComponent
        if pathCount > 0 {
            Logger.debug("[SettingsNavigation] Popping from navigation stack")
            
            viewModel.popView()
            
        } else {
            // If at root of detail view, go back to sidebar
            let parentMenuItem = currentComponent.getParentMenuItem()
            Logger.debug("[SettingsNavigation] Returning to sidebar - setting highlightedUIComponent to: \(parentMenuItem)")
            viewModel.highlightedUIComponent = parentMenuItem
            viewModel.popView()
        }
    }
    
    fileprivate func getRightContentView() -> some View {
        VStack(alignment: .leading) {
            getSubView()
        }
        .background(Color.clear)
    }
    
    private func getSubView() -> some View {
     
        switch viewModel.highlightedUIComponent.getParentMenuItem() {
        case .NeuronStreamingMenu :
            return AnyView(NeuronFrameSettingsView(viewModel: NeuronFrameSettingsViewModel.shared()))
        case .NeuronStreamingHostMenu:
            return AnyView (SettingsNeuronHostInfoView(settingsViewModel: SettingsViewModel.shared))
        case .AboutMenu:
            return AnyView (AboutView())
        default:
            return AnyView (EmptyView())
        }
    }

    private var leftPadding : CGFloat {

        if (horizontalSizeClass == .compact) || IsIpad() {
            return SettingsUtil.shared.getSubViewSpaceBetweenView()
        }else {
            return 70
        }
    }
    
    //to avoid detailPath won't be popped when user gesture back from push page in compact screen
    //compact screen 1.settings -> help -> about -> gesture back to help -> about -> gesture back to help....
    private func handleNavigationPop(popDelta: Int) {
        //restoreHighlightAfterPopIfNeeded to avoid this case: compact screen 1.settings -> controller menu -> controller options ->gesture back to controller menu
        // -> (A) to contorller option -> (B) will go back to sidebar  in commit id of 01c4ccff92ac0a7cdfb6e530f5d03617223be177
        viewModel.restoreHighlightAfterPopIfNeeded(
            currentState: viewModel.getViewControllersCountState(),
            popDelta: popDelta
        )

        guard #available(iOS 18, *) else {      //BIA-2321 only occurs in iOS 18 or later
            Logger.debug("[SettingsSplitView] iOS 17 skip pop sync")
            return
        }
        guard popDelta > 0 else { return }
        let pathDelta = max(0, previousDetailPathCount - currentDetailPathCount)
        if pathDelta >= popDelta {
            return
        }
        guard isInDetailView else { return }
        let pathCount = currentDetailPathCount
        guard pathCount > 0 else { return }
        let popCount = min(popDelta - pathDelta, pathCount)
        Logger.debug("[SettingsSplitView] navigation pop detected - delta: \(popDelta), pathCount: \(pathCount), pathDelta: \(pathDelta), popping: \(popCount)")
        for _ in 0..<popCount {
            viewModel.popView()
        }
    }
    
    // Since sometime the struct NavigationPopObserver's viewControllersCount won't be updated when user close detail view,
    // so we need to schedule sync to make sure the state is correct UIViewControllerRepresentable {
    private func scheduleSync(reason: String) {
        if !isHorizontalSizeClassRegular()
            && isDetailOpening
            && visibility == .detail {
            Logger.debug("[SettingsSplitView] scheduleSync skipped (detail opening), reason: \(reason), depth: \(uikitNavigationStackDepth), visibility: \(visibility)")
            return
        }
        let key = currentSyncKey()
        guard key != lastSyncKey else { return }
        guard !isSyncScheduled else { return }
        isSyncScheduled = true
        DispatchQueue.main.async {
            isSyncScheduled = false
            let latestKey = currentSyncKey()
            guard latestKey != lastSyncKey else { return }
            lastSyncKey = latestKey
            Logger.debug("[SettingsSplitView] scheduleSync call syncViewControllersState reason: \(reason), key: \(latestKey)")
            syncViewControllersState()
        }
    }

    private func currentSyncKey() -> String {
        "\(isHorizontalSizeClassRegular())|\(isInDetailView)|\(uikitNavigationStackDepth)|\(viewModel.getCurrentNavigationPathCount())"
    }
    
    private func syncViewControllersState() {
        Logger.debug("[SettingsSplitView] syncViewControllersState called uikitNavigationStackDepth \(uikitNavigationStackDepth)")
        let previousState = viewModel.getViewControllersCountState()
        let newState: SettingsViewControllersCount

        // Since horizontalSizeClass may not correct in fullscreencovery, we use our utility function to get the correct size class
        if isHorizontalSizeClassRegular() {
            //in regular mode, use uikitNavigationStackDepth to resolve stale pathCount after rotations
            //ios 26: 1 = regular , 2 = push
            //ios 18: 1 = regular , 2 = push
            //ios 17: 1 = regular , 2 = push
            let pathCount = viewModel.getCurrentNavigationPathCount()
            if uikitNavigationStackDepth == 0 {  //ios 26 sometime pathcount will keep 1 even after rotation, so we use uikitNavigationStackDepth to determine state, but not accurect so need combine pathcount
                newState = pathCount > 0 ? .regularPushPage : .regular  //in this case, use pathcount to determine state
            } else if uikitNavigationStackDepth <= 1 {
                newState = .regular
            } else {
                newState = .regularPushPage
            }
            // if newState == .regularPushPage && previousState == .compactPushPage { // rotate in push page from compact to regular
            //     navigationPopObserverUUID = UUID()
            // }
        } else {
            //in compact mode ,
            // ios 26: 1 = sidebar , 2 = detail , 3 = push , 4 = push more
            // ios 18: 1 = sidebar , 2 = detail , 3 = push , 4 = push more
            // ios 17: 1 = sidebar , 2 = sidebar+detail , 3 = push , 4 = push more
            //Notice: uikitNavigationStackDepth doesn't accurate in some case like change UI from compact detail to compact sidebar(keep value 2)
            if uikitNavigationStackDepth > 2 {
                newState = .compactPushPage
                // if previousState == .regularPushPage { // rotate in push page from regular to compact
                //     navigationPopObserverUUID = UUID()
                // }
            } else if uikitNavigationStackDepth <= 1 {
                newState = .compactSidebar
                if isInDetailView {
                    viewModel.syncHighlightToParentMenuIfNeeded()
                    isInDetailView = false
                }
            } else if isInDetailView {
                newState = .compactDetail
            } else {
                newState = .compactSidebar
            }
        }

        Logger.debug("[SettingsSplitView] syncViewControllersState - previous: \(previousState), new: \(newState), isInDetailView: \(isInDetailView), uikitNavigationStackDepth: \(uikitNavigationStackDepth)")
        viewModel.updateViewControllersCountState(newState)
        let pathCount = viewModel.getCurrentNavigationPathCount()
        if !isHorizontalSizeClassRegular(),     //sometime back from push back but visibility will be changed to sidebar, we need to correct it back to detail
           isInDetailView,
           uikitNavigationStackDepth >= 2,
           visibility == .sidebar,
           pathCount > 0 {
            Logger.debug("[SettingsSplitView] correcting visibility back to detail after navigation sync")
            DispatchQueue.main.async {
                if isInDetailView && uikitNavigationStackDepth >= 2 && visibility == .sidebar {
                    visibility = .detail
                }
            }
        }
    }
    
    private func initializeViewControllersStateIfNeeded() {
        let currentState = viewModel.getViewControllersCountState()
        guard !didInitializeViewControllersState || currentState == .regular else { return }
        didInitializeViewControllersState = true
        initializeViewControllersState()
    }
    
    private func initializeViewControllersState() {
        let pathCount = viewModel.getCurrentNavigationPathCount()
        let isDetailVisible = !viewModel.highlightedUIComponent.isMenuItem()
        let initialState: SettingsViewControllersCount

        if isHorizontalSizeClassRegular() {
            initialState = pathCount > 0 ? .regularPushPage : .regular
        } else if pathCount > 0 {
            initialState = .compactPushPage
        } else if isDetailVisible {
            initialState = .compactDetail
        } else {
            initialState = .compactSidebar
        }

        Logger.debug("[SettingsSplitView] init viewControllersState: \(initialState), pathCount: \(pathCount), isDetailVisible: \(isDetailVisible)")
        viewModel.updateViewControllersCountState(initialState)
    }
    
    private func forceSidebarVisibilityRefreshIfNeeded() {
        guard #unavailable(iOS 18) else { return }
        guard !isHorizontalSizeClassRegular() else { return }
        guard visibility == .sidebar else { return }
        Logger.debug("[SettingsSplitView] forceSidebarVisibilityRefreshIfNeeded Execute")
        splitViewRefreshID = UUID()
    }
    
    
    private func printLog(_ msg:String) {
        BiancaLogger.shared.logInfo("SettingsView - " + msg)
    }
}

extension SettingsNavigationSplitView {
    private func onSettingsDragChanged(_ value: DragGesture.Value) {
        // to avoid state change during drag causing view shift incorreectly
        // case ios26: regular landscape settings -> help ->about -> rotate to portrait -> rotate to landscape -> gesture back
        let currentPathCount = viewModel.getCurrentNavigationPathCount()
        let currentState = viewModel.getViewControllersCountState()
        Logger.debug("[DashboardView]Gesture changed  \(viewModel.highlightedUIComponent), path: \(currentPathCount), currentState: \(currentState)")

        if settingsDragViewControllersState == nil {
            settingsDragViewControllersState = currentState
            settingsDragStartPathCount = currentPathCount
            Logger.debug("[Gesture] drag start state=\(currentState) path=\(currentPathCount)")
        }

        let startPathCount = settingsDragStartPathCount ?? currentPathCount
        if startPathCount > 0 {
            Logger.debug("[Gesture] drag ignored: startPathCount=\(startPathCount)")
            return
        }

        // if State is not regular or compactSidebar, reset offset and return to avoid view shift
        let startState = settingsDragViewControllersState ?? currentState
        if startState != .regular && startState != .compactSidebar {
            Logger.debug("[Gesture] drag ignored: startState=\(startState)")
            return
        }

        let viewControllersState = startState
        switch viewControllersState {
        case .regular, .compactSidebar:
            let startLocation = value.startLocation.x
            guard startLocation < 50 else {
                Logger.debug("[Gesture] drag ignored: startLocation=\(startLocation)")
                return
            }

            let translation = value.translation.width
            if translation > 0, settingsDragOffset != translation {
                Logger.debug("[Gesture] drag translation=\(translation) currentOffset=\(settingsDragOffset)")
            }
        case .compactDetail, .compactPushPage, .regularPushPage:
            return
        }
    }
    
    private func onSettingsDragEnded(_ value: DragGesture.Value) {
        defer {
            resetSettingsDragState(reason: "drag ended")
        }
        Logger.debug("[DashboardView] Gesture ended - offset: \(settingsDragOffset), comp: \(viewModel.highlightedUIComponent), path: \(viewModel.getCurrentNavigationPathCount())")
        // to avoid state change during drag causing view shift incorreectly settings has been closed unexpectedly
        // case ios26: regular landscape settings -> help ->about -> rotate to portrait -> rotate to landscape -> gesture back
        let startPathCount = settingsDragStartPathCount ?? viewModel.getCurrentNavigationPathCount()
        if startPathCount != 0 {
            Logger.debug("[Gesture] drag ended ignored: startPathCount=\(startPathCount)")
            return
        }

        let currentState = viewModel.getViewControllersCountState()
        guard currentState == .regular || currentState == .compactSidebar else {
            Logger.debug("[Gesture] drag ended ignored: currentState=\(currentState)")
            return
        }
        let viewControllersState = settingsDragViewControllersState ?? currentState
        Logger.debug("[Gesture] drag ended state=\(viewControllersState) startLocation=\(value.startLocation.x) translation=\(value.translation.width)")

        switch viewControllersState {
        case .regular, .compactSidebar:
            let startLocation = value.startLocation.x
            guard startLocation < 50 else {
                Logger.debug("[Gesture] drag ended ignored: startLocation=\(startLocation)")
                return
            }

            if value.translation.width > 80 {
                Logger.debug("[DashboardView] Gesture ended regular - close settings")
                //sent to SettingsHostingController
                onDismiss()
            }
        case .compactDetail, .compactPushPage, .regularPushPage:
            Logger.debug("[DashboardView] Gesture ended regular viewControllersState = \(viewControllersState) - do nothing")
            return
        }
    }
    
    private func resetSettingsDragState(reason: String) {
        guard settingsDragViewControllersState != nil || settingsDragStartPathCount != nil else { return }
        Logger.debug("[Gesture] resetSettingsDragState reason=\(reason) offset=\(settingsDragOffset)")
        settingsDragViewControllersState = nil
        settingsDragStartPathCount = nil
    }
    
    //condition for drag gesture to avoid view move incorrectly
    private func dragTranslation(for value: DragGesture.Value) -> CGFloat {
        let currentPathCount = viewModel.getCurrentNavigationPathCount()
        let currentState = viewModel.getViewControllersCountState()
        let startPathCount = settingsDragStartPathCount ?? currentPathCount
        if startPathCount > 0 {
            return 0
        }
        let startState = settingsDragViewControllersState ?? currentState
        if startState != .regular && startState != .compactSidebar {
            return 0
        }
        guard value.startLocation.x < 50 else { return 0 }
        let translation = value.translation.width
        return translation > 0 ? translation : 0
    }
}

public final class DismissCallback {
    var callback: (() -> Void)?
    
    func callAsFunction() {
        callback?()
    }
}

// UIKit observer that detects when NavigationController pops back to root
struct NavigationPopObserver: UIViewControllerRepresentable {
    @Binding var navigationController: UINavigationController?
    @Binding var viewControllersCount: Int
    let onNavigationPop: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(viewControllersCount: $viewControllersCount, onNavigationPop: onNavigationPop)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        vc.view.isUserInteractionEnabled = false
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.viewControllersCount = viewControllersCount
        context.coordinator.onNavigationPop = onNavigationPop
        context.coordinator.attach(to: navigationController)
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        coordinator.detachIfNeeded()
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate {
        @Binding var viewControllersCount: Int
        var onNavigationPop: (Int) -> Void
        private var lastCount: Int?
        private var isCountRefreshScheduled = false
        private var zeroCountRetryCount = 0
        private let zeroCountRetryLimit = 3

        private weak var navigationController: UINavigationController?
        private weak var previousDelegate: UINavigationControllerDelegate?

        init(viewControllersCount: Binding<Int>, onNavigationPop: @escaping (Int) -> Void) {
            self._viewControllersCount = viewControllersCount
            self.onNavigationPop = onNavigationPop
        }

        func attach(to navController: UINavigationController?) {
            guard let navController else {
                detachIfNeeded()
                return
            }
            if navigationController !== navController {
                detachIfNeeded()
                navigationController = navController
                zeroCountRetryCount = 0
            }

            if navController.delegate !== self {
                previousDelegate = navController.delegate
                navController.delegate = self
            }

            refreshViewControllersCountIfNeeded()
        }

        func detachIfNeeded() {
            guard let navController = navigationController else { return }
            if navController.delegate === self {
                navController.delegate = previousDelegate
            }
            navigationController = nil
            previousDelegate = nil
        }

        func navigationController(
            _ navigationController: UINavigationController,
            willShow viewController: UIViewController,
            animated: Bool
        ) {
            previousDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
        }

        func navigationController(
            _ navigationController: UINavigationController,
            didShow viewController: UIViewController,
            animated: Bool
        ) {
            previousDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)

            let count = navigationController.viewControllers.count
            Logger.debug("[SettingsSplitView][NavigationPopObserver] didShow - viewControllers.count: \(count)")
            if handleZeroCountIfNeeded(count, reason: "didShow") { return }

            let previousCount = lastCount ?? count
            if let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
               !navigationController.viewControllers.contains(fromVC) {
                let popDelta = previousCount - count
                if popDelta > 0 {
                    Logger.debug("[SettingsSplitView][NavigationPopObserver] pop detected - delta: \(popDelta)")
                    onNavigationPop(popDelta)
                }
            }
            lastCount = count

            DispatchQueue.main.async {
                self.viewControllersCount = count
            }
        }

        private func refreshViewControllersCountIfNeeded() {
            guard let navController = navigationController else { return }
            let count = navController.viewControllers.count
            if handleZeroCountIfNeeded(count, reason: "refresh") { return }
            guard count != viewControllersCount else { return }
            Logger.debug("[SettingsSplitView][NavigationPopObserver] refresh - viewControllers.count: \(count)")
            DispatchQueue.main.async {
                self.viewControllersCount = count
            }
        }

        private func scheduleCountRefresh() {
            guard !isCountRefreshScheduled else { return }
            isCountRefreshScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self else { return }
                self.isCountRefreshScheduled = false
                self.refreshViewControllersCountIfNeeded()
            }
        }

        //during rotation, the viewControllers.count may be 0 temporarily, we need retry to get correct count
        private func handleZeroCountIfNeeded(_ count: Int, reason: String) -> Bool {
            guard count == 0, viewControllersCount > 0 else {
                zeroCountRetryCount = 0
                return false
            }
            guard zeroCountRetryCount < zeroCountRetryLimit else { return true }
            zeroCountRetryCount += 1
            Logger.debug("[SettingsSplitView][NavigationPopObserver] \(reason) saw zero count; scheduling retry \(zeroCountRetryCount)")
            scheduleCountRefresh()
            return true
        }
    }
}

final class NavigationBarButtonTarget: NSObject {
    var action: (() -> Void)?

    @objc func handleTap() {
        action?()
    }
}
