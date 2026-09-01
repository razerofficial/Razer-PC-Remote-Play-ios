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

struct AboutView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: SettingsViewModel = SettingsViewModel.shared
    
    //MARK: -x
    
    var body: some View {
        
        Group {
            ZStack(alignment: .top) {
                
                VStack(alignment: .leading, spacing: 0) {

                    Spacer()
                    
                    HStack(alignment: .center) {
                        let appName = getAppName()
                        let appVersion = getAppVersion()
                        Spacer()
                        VStack{
                            Spacer()
                            appIcon
                            Spacer().frame(height:IsIpad() ? 20:10)
                            Text(appName)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            Spacer().frame(height:IsIpad() ? 5:10)
                            Text(appVersion)
                                .font(.system(size: 14))
                                .foregroundColor(Color.TaupeGray)
                            Spacer().frame(height: 23)
                            VStack{
                                Text(getCopyRight())
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                Text("All rights reserved.".localize())
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                Spacer().frame(height: 17)
                                if isCNRegion {
                                    //ICP license only show in CN region for now, so the string of 备案号xxx should not be translated
                                    Text("ICP备案号:沪ICP备12035791号-16A".localize())
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Spacer().frame(height: 31)
                                }
                                HStack{
                                    getTermsOfServiceButton()
                                    Text("|")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.TaupeGray)
                                    getPrivacyPolicyButton()
                                }
                                Spacer().frame(height: 23)
                                getOpenSourceButton().offset(y: -5)
                                    .padding(.bottom, 10)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    
                    Spacer()
                }
//                .scaleEffect(scale)
            }
            .navigationBarTitle("About".localize(), displayMode: .inline)
//            .settingsCompactBackButton(horizontalSizeClass: horizontalSizeClass)
            .background(Color.Black)
            .onAppearFix(){
                printLog("onAppear")
                viewModel.iconTapCount = 0
            }
            .eraseToAnyView()
        }
    }
    
    
    var isCNRegion: Bool {
        let regionCode = Locale.current.regionCode?.uppercased() ?? ""
        return regionCode == "CN"
    }
    
    private var appIcon : some View {
        Image("neuron_icon").resizable()
            .scaledToFit()
            .frame(width: 58.0, height: 58.0)
            .clipShape(Circle())
            .onTapGesture {
                viewModel.aboutPageIconImageTapped()
            }
    }
    
    private func getAppName() -> String {
        if let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName
        }
        return "No AppName"
    }
    
    private func getAppVersion() -> String {
        if let versionno = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            var description : String = "Version %1$s".localize()
            description = description.replacingOccurrences(of: "%1$s", with: "")
            
            var buildNumber = ""
            let isDebugMode = DevUtils.shared().isDebugMode
            if isDebugMode {
                
                if let version:String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String{
                    buildNumber = version
                }
                return description + "\(versionno)" + " (\(buildNumber))"
            }
            return description + "\(versionno)"
        }
        return "No App Version"
    }
    
    private func getCopyRight() -> String {
        let oldText = "2022"
        let newText = "\(Date().year())"
        return "Copyright © 2022 Razer Inc.".localize().replacingOccurrences(of: oldText, with: newText)
    }
    
    private func getTermsOfServiceButton() -> some View {
        return Button(action: {
            
            viewModel.goToTermsOfService()
            
        }) {
            Text("Terms of Service".localize())
                .font(.system(size: 14))
                .foregroundColor(isTermsOfServiceButtonHighlighted() ? Color.White:Color.TaupeGray)
                .padding(.all, 2)
        }
    }
    private func getPrivacyPolicyButton() -> some View {
        return Button(action: {
            
            viewModel.goToPrivacyPolicy()
            
        }) {
            Text("Privacy Policy".localize())
                .font(.system(size: 14))
                .foregroundColor(isPrivacyPolicyButtonHighlighted() ? Color.White:Color.TaupeGray)
                .padding(.all, 2)
        }
    }
    
    private func getOpenSourceButton() -> some View {
        return Button(action: {
            
            viewModel.goToOpenSource()
            
        }) {
            Text("Open Source Software Notice".localize())
                .font(.system(size: 14))
                .foregroundColor(isOpenSourceButtonHighlighted() ? Color.White:Color.TaupeGray)
        }

    }
    
    private func isOpenSourceButtonHighlighted() -> Bool {

        if viewModel.highlightedUIComponent == .AboutButtonOpenSource {
            return true
        }
        return false
    }

    private func isTermsOfServiceButtonHighlighted() -> Bool {

        if viewModel.highlightedUIComponent == .AboutButtonTermsOfService {
            return true
        }
        return false
    }

    private func isPrivacyPolicyButtonHighlighted() -> Bool {

        if viewModel.highlightedUIComponent == .AboutButtonPrivacyPolicy {
            return true
        }
        return false
    }
    
    private func printLog(_ msg:String) {
        BiancaLogger.shared.logInfo("AboutView - " + msg)
    }
}
