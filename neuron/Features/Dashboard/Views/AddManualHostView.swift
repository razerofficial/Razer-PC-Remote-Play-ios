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

struct AddManualHostView: View {
    //@ObservedObject var settingsViewModel:SettingsViewModel
    
    @ObservedObject var viewModel: AddManualHostViewModel = AddManualHostViewModel.shared
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @SwiftUI.State var address:String = ""
    @SwiftUI.State var port:String = ""
    @SwiftUI.State var loading:Bool = false
    @SwiftUI.State var success:Bool = true
    @SwiftUI.State var addEnable:Bool = false
    
    var body : some View {
        
        ZStack() {
            
            Color.black.opacity(0.5)
                .onTapGesture {
                    DDLogInfo("click button to End search text editing")
                    if viewModel.isAddressEditing == true || viewModel.isPortEditing == true {
                        EmptyView().resignFirstResponder()
                    }
                }
            
            ZStack(){
                
                Color.hex(0x222222)
                
                VStack(alignment:.leading) {
                    
                    
                    VStack(alignment:.leading) {
                        
                        HStack(){
                            
                            Button.init {
                                viewModel.viewDismissalModePublisher.send(true)
                            } label: {
                                Text("Cancel".localize())
                                    .foregroundColor(.blue)
                                    .font(Font.system(size:16))
                                    .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 20))
                            }
                            .frame(height: 44)
                            .opacity( loading ? 0.5 : 1.0)
                            
                            Spacer()
                            
                            Text("Add PC manually".localize())
                                .foregroundColor(.white)
                                .font(Font.system(size:16))
                            
                            Spacer()
                            
                            Button.init {
                                viewModel.clickA?()
                            } label: {
                                Text("Add".localize())
                                    .foregroundColor( addEnable ? .blue : .hex(0x999999))
                                    .font(Font.system(size:16))
                                    .padding(EdgeInsets.init(top: 0, leading: 20, bottom: 0, trailing: 20))
                            }
                            .frame(height: 44)
                            .opacity( addEnable ? 1.0 : 0.5 )
                            
                            
                        }
                        
                        Spacer().frame(height:20)
                        
                        HStack(){
                            
                            Spacer().frame(width:15)
                            
                            VStack(spacing:0.1){
                                
                                HStack(alignment: .center){
                                    
                                    Spacer().frame(width:15)
                                    
                                    Text("IP address".localize())
                                        .foregroundColor(.white)
                                        .font(Font.system(size:16))
                                    
                                    Spacer().frame(width:15)
                                    
                                    RZTextField(placeholder: Text("Enter the IP address of your computer.".localize())
                                        .foregroundColor(.hex(0x999999))
                                        .font(Font.system(size: 16)), text: $address) { editing in
                                            viewModel.isAddressEditing = editing
                                        } commit: {
                                            
                                        }
                                        .frame(height: 40)
                                        .padding(EdgeInsets.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    
                                }
                                
                                HStack(){
                                    Spacer().frame(width:15)
                                    Color.gray.frame(height: 1.0 / UIScreen.screenScale)
                                }
                                
                                HStack(alignment: .center){
                                    
                                    Spacer().frame(width:15)
                                    
                                    ZStack(alignment:.leading){
                                        Text("IP address".localize())
                                            .foregroundColor(.hex(0x999999))
                                            .font(Font.system(size:16))
                                            .opacity(0.0)
                                        
                                        Text("Port".localize())
                                            .foregroundColor(.white)
                                            .font(Font.system(size:16))
                                    }
                                    
                                    Spacer().frame(width:15)
                                    
                                    RZTextField(placeholder: Text("e.g.51337".localize())
                                        .foregroundColor(.hex(0x999999))
                                        .font(Font.system(size: 16)), text: $port) { editing in
                                            viewModel.isPortEditing = editing
                                        } commit: {
                                            
                                        }
                                        .frame(height: 40)
                                        .padding(EdgeInsets.init(top: 0, leading: 10, bottom: 0, trailing: 10))
                                    
                                }
                                
                            }.background {
                                Color.hex(0x303032)
                            }
                            .cornerRadius(10.0)
                            
                            Spacer().frame(width:15)
                            
                        }
                        
                    }
                    
                    if success == false {
                        HStack(){
                            Spacer().frame(width:15)
                            Spacer().frame(width:15)
                            Text("Could not connect to host".localize())
                                .foregroundColor(.hex(0xff0000))
                                .font(Font.system(size:14))
                            Image("settings_devices_warning")
                        }
                    }
                    
                    Spacer()
                }
                
                
            }
            .frame(width: 582, height: 281)
            .clipped()
            .cornerRadius(10)
            .blur(radius: loading ? 3.0 : 0.0)
            
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
                        .font(Font.system(size:18))
                    Spacer().frame(height: 10)
                    Text("Please ensure Razer Cortex is running.".localize())
                        .foregroundColor(.hex(0x999999))
                        .font(Font.system(size:14))
                    Spacer().frame(height: 10)
                    ActivityIndicator(isAnimating: $loading, style: UIActivityIndicatorView.Style.medium)
                        .frame(width:60,height: 60)
                    Spacer()
                }
                
            }
            
        }
        .onAppear {
            DDLogInfo("AddManualHostView:onAppear")
            viewModel.startTracking()
            viewModel.delegate = viewModel
            
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
        .edgesIgnoringSafeArea(.all)
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
        .introspectViewController { vc in
            vc.view.backgroundColor = .clear
        }
    }
    
    func checkAddEnable()->Bool {
        
        if address.isEmpty || port.isEmpty {
            addEnable = false
            return false
        }
        
        let strArray = address.components(separatedBy: ":")
        if strArray.count > 1 {
            addEnable = false
            return false
        }
        
        let strArray2 = address.components(separatedBy: "：")
        if strArray2.count > 1 {
            addEnable = false
            return false
        }
        
        let str = address + ":" + port
        return viewModel.checkIPWithPort(str)
        
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
                    if message == "Host information updated".localize() {
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
            clickA?()
        case .B:
            self.shouldDismissView = true
        default: break
        }
        
    }
}


extension View {
    func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
