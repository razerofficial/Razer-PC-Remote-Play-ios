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

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI
import WebKit

class WebVC : RZBaseVC {
    var isLoadFileURL:Bool = false
    @objc var url:URL!
    @objc var webViewTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        //set back ground color
        view.backgroundColor = .black
        
        //add contents
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        reloadContentView()
    }
    
    func reloadContentView() {
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
        
        let webView = WKWebView.init()
        contentView.addSubview(webView)
        view.addSubview(customNavBar)

        customNavBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(60.0)
        }
        
        webView.snp.makeConstraints{ make in
            make.leading.equalTo(view.safeAreaLayoutGuide.snp.leading)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing)
            make.top.equalTo(customNavBar.snp.bottom)
            make.bottom.equalTo(contentView.snp.bottom)
        }
        
        if isLoadFileURL {
            webView.loadFileURL(url!, allowingReadAccessTo: url!)
        } else {
            let request = URLRequest(url: url!)
            webView.load(request)
        }
        
        contentView.layoutIfNeeded()
    }
    //MARK: - Lazy - UI
    
    lazy var customNavBar:CustomNavigationBar = {
        let nav = CustomNavigationBar(title: webViewTitle, leftButtonTitle: "Settings".localize(), rightButtonTitle: nil, delegate: self)
        return nav
    }()
    
    lazy var contentView : UIView = {
        let view = UIView.init()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    func onBackButtonClicked() {
        if self.navigationController == nil {
            dismiss(animated: true)
        } else {
            SettingsRouter.shared.navigationController?.popViewController(animated: true)
        }
    }
}

//MARK: - RZHandleResponderDelegate
extension WebVC : RZHandleResponderDelegate {
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .B:
            handel.stopTracking()
            lastHandel?.startTracking()
            lastHandel?.reloadCallBack?()
            onBackButtonClicked()
        default:
            break
        }
    }
}

extension WebVC: CustomNavigationBarDelegate {
    func backButtonTapped() {
        self.onBackButtonClicked()
    }
    
    func rightButtonTapped() {
        //do nothing
    }
}
