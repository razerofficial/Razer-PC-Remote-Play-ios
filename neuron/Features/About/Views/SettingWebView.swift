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
import CocoaLumberjack
import Combine
import WebKit

struct SettingWebView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @ObservedObject var settingsVM: SettingsViewModel = SettingsViewModel.shared

    @SwiftUI.State var title:String = ""
    let url:URL?
    var isLoadFileURL:Bool = false
    var htmlString = ""
    
    init(title: String, url: URL?, isLoadFileURL: Bool = false, htmlString: String = "") {
        self.title = title
        self.url = url
        self.isLoadFileURL = isLoadFileURL
        self.htmlString = htmlString
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                SimpleWebView(url: url!, isLoadFileURL: isLoadFileURL, htmlString: htmlString)
                    .background(Color.Black)
                    .padding(.leading, safeAreaLeft)
            }
        
        }
        .background(Color.Black)
        .navigationBarTitle(title, displayMode: .inline)
        .settingsCompactBackButton(horizontalSizeClass: horizontalSizeClass)
    }
}

struct SimpleWebView: UIViewRepresentable {
    var url: URL
    var isLoadFileURL:Bool = false
    var htmlString:String = ""
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.applicationNameForUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/124.0.6367.68 Mobile/15E148 Safari/604.1"
        configuration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.isOpaque = false
        //make the content fullscreen
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        ///make the webView can control by controller
        webView.becomeFirstResponder()
        return webView
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        if isLoadFileURL {
            if htmlString.isEmpty {
                webView.loadFileURL(url, allowingReadAccessTo: url)
            } else {
                webView.loadHTMLString(htmlString, baseURL: Bundle.main.bundleURL)
            }
        } else {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
