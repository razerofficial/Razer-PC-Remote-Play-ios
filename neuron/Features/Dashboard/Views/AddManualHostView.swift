/*
 * Copyright (C) 2025 Razer Inc.
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
import Combine
import UIKit
import AVFoundation

let AddManualHostViewWidth = IsIOS26() ? 478.0 : 582.0
let AddManualHostViewHeight = IsIOS26() ? 275.0 : 281.0

struct AddManualHostView: View {
    //@ObservedObject var settingsViewModel:SettingsViewModel
    
    @ObservedObject var viewModel: AddManualHostViewModel = AddManualHostViewModel.shared
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @SwiftUI.State var address:String = ""
    @SwiftUI.State var port:String = ""
    @SwiftUI.State var loading:Bool = false
    @SwiftUI.State var success:Bool = true
    @SwiftUI.State var addEnable:Bool = false
    @SwiftUI.FocusState private var isAddressFieldFocused: Bool
    @SwiftUI.FocusState private var isPortFieldFocused: Bool
    
    @SwiftUI.State var viewWidth = AddManualHostViewWidth
    @SwiftUI.State var viewHeight = AddManualHostViewHeight
    
    
    @SwiftUI.State private var scale: CGFloat = 1.0 //DashboardViewModel.shared.portraitBaseScale
    
    var body: some View {
        
        ZStack() {
            
            GeometryReader { geo in
                
                ZStack() {
                    
                    Color.black.opacity(0.5)
                        .onTapGesture {
                            DDLogInfo("click button to End search text editing")
                            if viewModel.isAddressEditing == true || viewModel.isPortEditing == true {
                                EmptyView().resignFirstResponder()
                            }
                        }
                    
                    ZStack(){
                        
                        if #available(iOS 26.0, *) {
                            Color.clear
                                .frame(width: viewWidth, height: viewHeight)
                                .backgroundExtensionEffect()
                                .glassEffect(in: .rect(cornerRadius: 34.0))
                        }else{
                            Color.hex(0x222222)
                                .frame(width: viewWidth, height: viewHeight)
                        }
                        
                        VStack(alignment:.leading) {
                            
                            if #available(iOS 26.0, *) {
                                
                                Spacer().frame(height: 22.0)
                                
                                Text("Add PC manually".localize())
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .padding(EdgeInsets.init(top: 0 , leading: 22, bottom: 0, trailing: 22))
                                
                                Spacer().frame(height: 34.0)
                                
                                newTextFiles
                                
                                Spacer().frame(height: 8.0)
                                newWaringView.opacity(success ? 0.0 : 1.0)
                                Spacer().frame(height: 8.0)
                                
                                bottomPath
                                
                                Spacer().frame(height: 14.0)
                                
                            }else {
                                
                                VStack(alignment:.leading) {
                                    topPath
                                    Spacer().frame(height:20)
                                    textFiles
                                }
                                
                                waringView.opacity(success ? 0.0 : 1.0)
                                Spacer()
                            }
                            
                        }
                        
                    }
                    .frame(width: viewWidth, height: viewHeight)
                    .onAppear() {
                        if IsIpad() {
                            viewWidth = min(AddManualHostViewWidth,geo.size.width)
                            //let ratio = geo.size.width / SettingsRouter.shared.wWidth
                            //scale = ratio
                        }
                    }
                    .valueChanged(value: geo.size.width, onChange: { width in
                        if IsIpad() {
                            viewWidth = min(AddManualHostViewWidth,width)
                            //let ratio = width / SettingsRouter.shared.wWidth
                            //scale = ratio
                        }
                    })
                    .clipped()
                    .cornerRadius(10)
                    .blur(radius: loading ? 3.0 : 0.0)
                    .scaleEffect(scale)
                    
                    if loading {
                        
                        Color.Black.opacity(0.5)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                DDLogInfo("Tap:Wating add host manually result ...")
                            }
                        
                        VStack(){
                            Spacer()
                            Text("Connecting…".localize())
                                .foregroundColor(.white)
                                .font(.system(size:18))
                            Spacer().frame(height: 10)
                            Text("Please ensure Razer Cortex is running.".localize())
                                .foregroundColor(.hex(0x999999))
                                .font(.system(size:14))
                            Spacer().frame(height: 10)
                            ActivityIndicator(isAnimating: $loading, style: UIActivityIndicatorView.Style.medium)
                                .frame(width:60,height: 60)
                            Spacer()
                        }
                        
                    }
                }
                //.background(Color.Black)
                .onAppear {
                    DDLogInfo("AddManualHostView:onAppear")
                    viewModel.startTracking()
                    viewModel.delegate = viewModel
                    
                    isAddressFieldFocused = true
                    viewModel.isFocusCancel = false
                    
                    viewModel.clickA = {
                        
                        let str = address + ":" + port
                        
                        if checkAddEnable() == false {
                            return
                        }
                        
                        if viewModel.isAddressEditing == true || viewModel.isPortEditing == true {
                            EmptyView().resignFirstResponder()
                        }
                        
                        onManualIpEnter(address: str)
                    }
                    viewModel.addNotification()
                }
                //        .onReceive(DashboardViewModel.shared.$portraitBaseScale) { newScale in
                //            self.scale = newScale
                //        }
                .onAppearFix{
                    DDLogInfo("AddManualHostView:onAppear")
                    viewModel.startTracking()
                    viewModel.delegate = viewModel
                }
                .onDisappear() {
                    viewModel.removeNotification()
                }
                .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
                    if shouldDismiss {
                        self.presentationMode.wrappedValue.dismiss()
                        //settingsViewModel.isShowManualHostView = false
                        NotificationCenter.default.post(name: NTCloseManualHostView, object: nil)
                    }
                }
                .valueChanged(value: address) { address in
                    addEnable = checkAddEnable()
                }
                .valueChanged(value: port) { port in
                    addEnable = checkAddEnable()
                }
                .valueChanged(value: loading) { isLoading in
                    viewModel.loading = loading
                }
                .valueChanged(value: viewModel.isFocusAddress) { isFocusAddress in
                    isAddressFieldFocused = isFocusAddress
                }
                .valueChanged(value: viewModel.isFocusPort) { isFocusPort in
                    isPortFieldFocused = isFocusPort
                }
                
            }
            
        }
    }
    //MARK: - views
    var topPath : some View {
        
        return HStack(){
            
            Button.init {
                //viewModel.clickA?()
                self.viewModel.viewDismissalModePublisher.send(true)
            } label: {
                Text("Cancel".localize())
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                    .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
            .frame(height: 44)
            .opacity( loading ? 0.5 : 1.0)
            
            Spacer()
            
            Text("Add PC manually".localize())
                .foregroundColor(.white)
                .font(.system(size: 16))
            
            Spacer()
            
            Button.init {
                viewModel.clickA?()
            } label: {
                Text("Add".localize())
                    .foregroundColor( addEnable ? .blue :.hex(0x999999))
                    .font(.system(size: 16))
                    .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
            .frame(height: 44)
            .opacity(addEnable ? 1.0 : 0.5)
            
        }
        
    }
    
    var textFiles : some View {
        return HStack(){
            
            Spacer().frame(width:15)
            
            VStack(spacing:0.1){
                
                HStack(){
                    
                    Spacer().frame(width:15)
                    
                    Text("IP address".localize())
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    
                    Spacer().frame(width:15)
                    
                    RZTextField(placeholder: Text("Enter the IP address of your computer.".localize())
                        .foregroundColor(.hex(0x999999))
                        .font(.system(size: 16)), text: $address) { editing in
                            viewModel.isAddressEditing = editing
                        } commit: {
                            if addEnable {
                                viewModel.clickA?()
                            }
                        }
                        .frame(height: 40)
                    //.frame(maxWidth: IsIpad() ? .infinity : 350)
                        .padding(EdgeInsets.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                    //.background(Color.White)
                        .focused($isAddressFieldFocused)
                        .introspectTextField { textField in
                            // force disable keyboard's Shortcut Bar
                            textField.inputAssistantItem.leadingBarButtonGroups = []
                            textField.inputAssistantItem.trailingBarButtonGroups = []
                            textField.inputAccessoryView = UIView()
                        }
                    
                    
                }
                
                HStack(){
                    Spacer().frame(width:15)
                    Color.gray.frame(height: 1.0 / UIScreen.screenScale)
                }
                
                
                HStack(){
                    
                    Spacer().frame(width:15)
                    
                    ZStack(alignment:.leading){
                        Text("IP address".localize())
                            .foregroundColor(.hex(0x999999))
                            .font(.system(size: 16))
                            .opacity(0.0)
                        
                        Text("Port".localize())
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    
                    Spacer().frame(width:15)
                    
                    RZTextField(placeholder: Text("e.g.51337".localize())
                        .foregroundColor(.hex(0x999999))
                        .font(.system(size: 16)), text: $port) { editing in
                            viewModel.isPortEditing = editing
                        } commit: {
                            if addEnable {
                                viewModel.clickA?()
                            }
                        }
                        .frame(height: 40)
                    //.frame(maxWidth: IsIpad() ? .infinity : 350)
                        .padding(EdgeInsets.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                    //.background(Color.White)
                        .focused($isPortFieldFocused)
                        .introspectTextField { textField in
                            // force disable keyboard's Shortcut Bar
                            textField.inputAssistantItem.leadingBarButtonGroups = []
                            textField.inputAssistantItem.trailingBarButtonGroups = []
                            textField.inputAccessoryView = UIView()
                        }
                    
                    
                }
                
            }.background {
                Color.hex(0x303032)
            }
            .cornerRadius(10.0)
            
            Spacer().frame(width:15)
            
        }
    }
    
    var waringView : some View {
        return HStack(){
            Spacer().frame(width:15)
            Spacer().frame(width:15)
            Text("Could not connect to host".localize())
                .foregroundColor(.hex(0xff0000))
                .font(.system(size: 14))
            Image("settings_host_warning")
        }
        //.frame(height:40.0)
    }
    
    var newWaringView : some View {
        return HStack(){
            Spacer().frame(width:15)
            Text("Could not connect to host".localize())
                .foregroundColor(.hex(0xff0000))
                .font(.system(size: 14))
            Image("new_settings_host_warning")
        }
        //.frame(height:40.0)
    }
    
    var newTextFiles : some View {
        return HStack(){
            
            Spacer().frame(width:15)
            
            VStack(spacing:0.1){
                
                HStack(){
                    
                    Spacer().frame(width:15)
                    
                    RZTextField(placeholder: Text("Enter the IP address of your computer.".localize())
                        .foregroundColor(.hex(0xEBEBF5,alpha: 0.3))
                        .font(.system(size: 16)), text: $address) { editing in
                            viewModel.isAddressEditing = editing
                        } commit: {
                            if addEnable {
                                viewModel.clickA?()
                            }
                        }
                        .frame(height: 52)
                        .focused($isAddressFieldFocused)
                        .introspectTextField { textField in
                            // force disable keyboard's Shortcut Bar
                            textField.inputAssistantItem.leadingBarButtonGroups = []
                            textField.inputAssistantItem.trailingBarButtonGroups = []
                            textField.inputAccessoryView = UIView()
                        }
                    
                    
                    Spacer().frame(width:15)
                    
                }
                
                HStack(){
                    Spacer().frame(width:15)
                    Color.hex(0x1a1a1a).frame(height: 1.0 / UIScreen.screenScale)
                    Spacer().frame(width:15)
                }
                
                
                HStack(){
                    
                    Spacer().frame(width:15)
                    
                    RZTextField(placeholder: Text("Port".localize())
                        .foregroundColor(.hex(0xEBEBF5,alpha: 0.3))
                        .font(.system(size: 16)), text: $port) { editing in
                            viewModel.isPortEditing = editing
                        } commit: {
                            if addEnable {
                                viewModel.clickA?()
                            }
                        }
                        .frame(height: 52)
                        .focused($isPortFieldFocused)
                        .introspectTextField { textField in
                            // force disable keyboard's Shortcut Bar
                            textField.inputAssistantItem.leadingBarButtonGroups = []
                            textField.inputAssistantItem.trailingBarButtonGroups = []
                            textField.inputAccessoryView = UIView()
                        }
                    
                    
                    Spacer().frame(width:15)
                    
                }
                
            }.background {
                Color.hex(0x767680,alpha: 0.24)
            }
            .cornerRadius(34.0)
            
            Spacer().frame(width:15)
            
        }
    }
    
    var bottomPath : some View {
        
        let bottonHeight = 48.0
        let leftSpace = 14.0
        let midSpace = 16.0
        let bottonWidth = ( viewWidth - leftSpace * 2 - midSpace ) / 2.0
        
        return HStack(){
            Spacer().frame(width:leftSpace)
            
            Button.init {
                //viewModel.clickA?()
                self.viewModel.viewDismissalModePublisher.send(true)
            } label: {
                Text("Cancel".localize())
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
            .frame(width: bottonWidth ,height: bottonHeight )
            .background(content: {
                if viewModel.isFocusCancel {
                    Color.hex(0xffffff,alpha: 0.32)
                        .cornerRadius( bottonHeight / 2)
                }else{
                    Color.hex(0x787880,alpha: 0.32)
                        .cornerRadius( bottonHeight / 2)
                }
            })
            .opacity( loading ? 0.5 : 1.0)
            
            Spacer().frame(width:midSpace)
            
            Button.init {
                viewModel.clickA?()
            } label: {
                Text("Add".localize())
                    .foregroundColor( addEnable ? .white :.hex(0x999999))
                    .font(.system(size: 16))
                    .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
            .frame(width: bottonWidth ,height: bottonHeight )
            .background(content: {
                if viewModel.isFocusAdd && addEnable {
                    Color.hex(0xffffff,alpha: 0.32)
                        .cornerRadius( bottonHeight / 2)
                }else{
                    Color.hex(0x787880,alpha: 0.32)
                        .cornerRadius( bottonHeight / 2)
                }
            })
            .opacity(addEnable ? 1.0 : 0.5)
            
            Spacer().frame(width:leftSpace)
        }
        
    }
    
    //MARK: - func
    func checkAddEnable()->Bool {
        
        if address.isEmpty || port.isEmpty {
            addEnable = false
            viewModel.addEnable = addEnable
            return false
        }
        
        let strArray = address.components(separatedBy: ":")
        if strArray.count > 1 {
            addEnable = false
            viewModel.addEnable = addEnable
            return false
        }
        
        let strArray2 = address.components(separatedBy: "：")
        if strArray2.count > 1 {
            addEnable = false
            viewModel.addEnable = addEnable
            return false
        }
        
        let str = address + ":" + port
        addEnable = viewModel.checkIPWithPort(str)
        viewModel.addEnable = addEnable
        return addEnable
        
    }
    
    func onManualIpEnter(address: String) {
        
        self.loading = true
        self.success = true
        //HostListManger.shared.showHostConnetingView()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) { [self] in
            //let discoveryManager = DiscoveryManager.init()
            HostListManger.shared.discoveryManager.discoverHost(address) { [self] host, message in
                //loadingView.isHidden = true
                self.loading = false
                //HostListManger.shared.removeHostConnectingView()
                //成功
                if host != nil {
                    self.viewModel.viewDismissalModePublisher.send(true)
                    
                    var isPair : Bool = false
                    for pairedHost in HostListManger.shared.pairedHosts {
                        if pairedHost.uuid == host?.uuid {
                            isPair = true
                        }
                    }
                    if !isPair {
                        HostListManger.shared.pairNetHost(host!)
                    }
                    
                    //errorTips.isHidden = true
                }else{
                    
                    var found:Bool = false
                    //errorTips.isHidden = false
                    if message == "Host information updated" {
                        for netHost in HostListManger.shared.netHosts {
                            if netHost.address == address || netHost.activeAddress == address || netHost.localAddress == address{
                                self.viewModel.viewDismissalModePublisher.send(true)
                                
                                var isPair : Bool = false
                                for pairedHost in HostListManger.shared.pairedHosts {
                                    if pairedHost.uuid == netHost.uuid {
                                        isPair = true
                                    }
                                }
                                if !isPair {
                                    HostListManger.shared.pairNetHost(netHost)
                                }
                                
                                found = true
                                break
                            }
                        }
                    }
                    if found == false {
                        self.success = false
                        self.isAddressFieldFocused = true
                    }
                }
            }
        }
    }
}

class AddManualHostViewModel : RZHandleResponder , RZHandleResponderDelegate {
    
    static let shared = AddManualHostViewModel()
    
    var loading:Bool = false
    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    @Published var isAddressEditing: Bool = false
    @Published var isPortEditing: Bool = false
    @Published var isFocusAddress: Bool = true
    @Published var isFocusPort: Bool = false
    @Published var isFocusCancel: Bool = false
    @Published var isFocusAdd: Bool = false
    @Published var addEnable:Bool = false
    var clickA:(()->Void)? = nil
    
    func addNotification(){
        //NotificationCenter.default.addObserver(self, selector: #selector(sunshinePairSuccess), name: .SUNSHINE_PAIR_SUCCESS, object: nil)
    }
    
    func removeNotification(){
        //NotificationCenter.default.removeObserver(self, name: .SUNSHINE_PAIR_SUCCESS, object: nil)
    }
    
    func checkIPWithPort(_ ip: String) -> Bool {
        let pattern = "(\\d{1,3}\\.){3}\\d{1,3}(:\\d{1,5})?\\b"//"\\b(?:\\d{1,3}\\.){3}\\d{1,3}(:\\d{1,5})?\\b"
        
        do {
            
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            
            if let match = regex.firstMatch(in: ip, options: [], range: NSRange(location: 0, length: ip.utf16.count)) {
                let swiftString = NSString(string: ip)
                let portRange = match.range(at: 1)
                
                if portRange.location != NSNotFound {
                    print("")
                    //IP address with port found.
                    return true
                } else {
                    //IP address without port found
                    return false
                }
            } else {
                //No valid IP address found.
                return false
            }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    
    
    @objc func sunshinePairSuccess(){
        DispatchQueue.main.async {
            self.shouldDismissView = true
        }
    }
    
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }
    
    func handleClickButton(_ action: GamePadButton) {
        
        if loading {
            return
        }
        
        switch action {
        case .A:
            if IsIOS26() {
                if isFocusCancel {
                    self.shouldDismissView = true
                } else if isFocusAdd {
                    clickA?()
                }
            } else{
                clickA?()
            }
            
        case .B:
            self.shouldDismissView = true
        case .left:
            if isFocusAdd {
                isFocusCancel = true
                isFocusAdd = false
            }
        case .right:
            if isFocusAdd == false && isFocusCancel == false {
                isFocusCancel = true
                isFocusAdd = false
            }else if isFocusCancel && addEnable {
                isFocusCancel = false
                isFocusAdd = true
            }
        case .up:
            if isFocusPort {
                isFocusAddress = true
                isFocusPort = false
            }
        case .down:
            if isFocusAddress {
                isFocusAddress = false
                isFocusPort = true
            }
        default: break
        }
        
    }
}


extension View {
    func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - ESC Key Handling UIHostingController for AddManualHostView
public class AddManualHostHostingController<Content: View>: UIHostingController<Content> {
    
    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            if key.keyCode == .keyboardEscape {
                Logger.debug("AddManualHostView: ESC key dismiss")
                dismiss(animated: true) { [weak self] in
                    NotificationCenter.default.post(name: NTCloseManualHostView, object: nil)
                }
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }
}
