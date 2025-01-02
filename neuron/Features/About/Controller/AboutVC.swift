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

enum AboutItem : Int  {
    case TermsOfService
    case PrivacyPolicy
    case OpenSourceNotice
}

let debugModeCount = 8
let RazerPCRemotePlayName = "Razer PC Remote Play"
class AboutVC : RZBaseVC {
    var selectedItem:AboutItem = .TermsOfService
    private var tapCount = 0
    private var tapWorkItem: DispatchWorkItem?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        handel.reloadCallBack = { [self] in
            handel.delegate = self
            reloadContentView()
        }
        
        setupView()
    }
    
    func setupView() {
        //set back ground color
        view.backgroundColor = .black
        
        //add contents
        view.addSubview(contentView)
        
//        scroll.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        
//        scroll.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
//        contentView.backgroundColor = .yellow
        
        reloadContentView()
    }
    
    private func getAppName() -> String {
//        if let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
//            return displayName
//        }
        return RazerPCRemotePlayName
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
        return "Copyright © 2022 Razer Inc.".localize().replacingOccurrences(of: oldText, with: newText) + "\n" + "All rights reserved.".localize()
    }
    
    private func clickA() {
        switch selectedItem {
        case .TermsOfService:
            onTermsOfServiceClicked()
        case .PrivacyPolicy:
            onPrivacyPolicyClicked()
        case .OpenSourceNotice:
            onOpenSourceNoticeClicked()
        default:
            break
        }
    }
    
    func reloadContentView() {
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
        
        let iconImg = UIImageView(image: UIImage(named: "neuron_icon"))
        iconImg.contentMode = .scaleAspectFill
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(logoTapped(_:)))
        iconImg.addGestureRecognizer(tapGesture)
        iconImg.isUserInteractionEnabled = true
        
        contentView.addSubview(iconImg)
        
        let appNameLabel = UILabel.init()
        appNameLabel.text = getAppName()
        appNameLabel.textColor = .white
        appNameLabel.textAlignment = .center
        appNameLabel.font = UIFont.boldSystemFont(ofSize: IsIpad() ? 20 : 18)
        
        contentView.addSubview(appNameLabel)
        
        let appVersionLabel = UILabel.init()
        appVersionLabel.text = getAppVersion()
        appVersionLabel.textColor = Color.hex(0x999999).uiColor()
        appVersionLabel.textAlignment = .center
        appVersionLabel.font = UIFont.systemFont(ofSize: IsIpad() ? 16 : 14, weight:.medium)
        
        contentView.addSubview(appVersionLabel)
        
        let appCopyrightLabel = UILabel.init()
        appCopyrightLabel.text = getCopyRight()
        appCopyrightLabel.textColor = .white
        appCopyrightLabel.textAlignment = .center
        appCopyrightLabel.font = UIFont.systemFont(ofSize: IsIpad() ? 16 : 14)
        
        contentView.addSubview(appCopyrightLabel)
        
        let allRightsLabel = UILabel.init()
        allRightsLabel.text = "All rights reserved.".localize()
        allRightsLabel.textColor = .white
        allRightsLabel.textAlignment = .center
        allRightsLabel.font = UIFont.systemFont(ofSize: IsIpad() ? 16 : 14)
        
        contentView.addSubview(allRightsLabel)
        
        let appICPLabel = UILabel.init()
        appICPLabel.text = "ICP备案号:沪ICP备12035791号-16A"
        if !isCNRegion {
            appICPLabel.text = ""
        }
        appICPLabel.textColor = .white
        appICPLabel.textAlignment = .center
        appICPLabel.font = UIFont.systemFont(ofSize: IsIpad() ? 16 : 14)

        contentView.addSubview(appICPLabel)
        
        let centerLineLabel = UILabel.init()
        centerLineLabel.text = ""
        centerLineLabel.textColor = .white
        centerLineLabel.textAlignment = .center
        centerLineLabel.font = UIFont.systemFont(ofSize: 14)

        contentView.addSubview(centerLineLabel)
        
        let textColor = Color.hex(0x999999).uiColor()
        let textHighlightColor:UIColor = .white
        let termsOfServiceButton = UIButton(type: .custom)
        termsOfServiceButton.setTitle("Terms of Service".localize(), for: .normal)
        termsOfServiceButton.titleLabel?.textAlignment = .right
        termsOfServiceButton.titleLabel?.font = UIFont.systemFont(ofSize: IsIpad() ? 16 : 14)
        termsOfServiceButton.setTitleColor(isTermsOfServiceHighlighted() ? textHighlightColor : textColor, for: .normal)
        termsOfServiceButton.contentHorizontalAlignment = .right
        termsOfServiceButton.addTarget(self, action: #selector(onTermsOfServiceClicked), for: .touchUpInside)
        
        contentView.addSubview(termsOfServiceButton)
        
        let divider = UILabel.init()
        divider.text = "|"
        divider.textColor = .white
        divider.textAlignment = .center
        divider.font = UIFont.systemFont(ofSize: 14)

        contentView.addSubview(divider)

        let privacyPolicyButton = UIButton(type: .custom)
        privacyPolicyButton.setTitle("Privacy Policy".localize(), for: .normal)
        privacyPolicyButton.titleLabel?.textAlignment = .left
        privacyPolicyButton.contentHorizontalAlignment = .left
        privacyPolicyButton.titleLabel?.font = UIFont.systemFont(ofSize: IsIpad() ? 16 : 14)
        privacyPolicyButton.setTitleColor(isPrivacyPolicyHighlighted() ? textHighlightColor : textColor, for: .normal)
        privacyPolicyButton.addTarget(self, action: #selector(onPrivacyPolicyClicked), for: .touchUpInside)
        
        contentView.addSubview(privacyPolicyButton)
        
        let openSourceNoticeButton = UIButton(type: .custom)
        openSourceNoticeButton.setTitle("Open Source Software Notice".localize(), for: .normal)
        openSourceNoticeButton.titleLabel?.textAlignment = .center
        openSourceNoticeButton.titleLabel?.font = UIFont.systemFont(ofSize: IsIpad() ? 16 : 14)
        openSourceNoticeButton.setTitleColor(isOpenSourceNoticeHighlighted() ? textHighlightColor : textColor, for: .normal)
        openSourceNoticeButton.addTarget(self, action: #selector(onOpenSourceNoticeClicked), for: .touchUpInside)
        
        contentView.addSubview(openSourceNoticeButton)

        
        centerLineLabel.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.centerX)
            make.centerY.equalTo(contentView.snp.centerY)
            make.width.equalTo(contentView)
            make.height.equalTo(1)
        }
        
        appVersionLabel.snp.makeConstraints { make in
            make.centerX.equalTo(contentView.snp.centerX)
            make.bottom.equalTo(centerLineLabel.snp.top).offset(-20)
        }
        
        appNameLabel.snp.makeConstraints { make in
            make.centerX.equalTo(appVersionLabel.snp.centerX)
            make.bottom.equalTo(appVersionLabel.snp.top).offset(-5)
        }
        
        iconImg.snp.makeConstraints { make in
            make.centerX.equalTo(appNameLabel.snp.centerX)
            make.bottom.equalTo(appNameLabel.snp.top).offset(-20)
            make.height.width.equalTo(58)
        }
        
        appCopyrightLabel.snp.makeConstraints { make in
            make.centerX.equalTo(centerLineLabel.snp.centerX)
            make.top.equalTo(centerLineLabel.snp.bottom).offset(5)
        }
        
        allRightsLabel.snp.makeConstraints { make in
            make.centerX.equalTo(appCopyrightLabel.snp.centerX)
            make.top.equalTo(appCopyrightLabel.snp.bottom).offset(0)
        }
        
        appICPLabel.snp.makeConstraints { make in
            make.centerX.equalTo(allRightsLabel.snp.centerX)
            make.top.equalTo(allRightsLabel.snp.bottom).offset(20)
        }
        
        divider.snp.makeConstraints { make in
            make.centerX.equalTo(appICPLabel.snp.centerX)
            make.top.equalTo(appICPLabel.snp.bottom).offset(20)
        }
        
        termsOfServiceButton.snp.makeConstraints { make in
            make.centerY.equalTo(divider)
            make.left.equalTo(contentView).offset(5)
            make.right.equalTo(divider.snp.left).offset(-10)
        }
        
        privacyPolicyButton.snp.makeConstraints{ make in
            make.left.equalTo(divider.snp.right).offset(10)
            make.right.equalTo(contentView).offset(-5)
            make.centerY.equalTo(divider)
        }
        
        openSourceNoticeButton.snp.makeConstraints { make in
            make.centerX.equalTo(divider.snp.centerX).offset(-10)
            make.top.equalTo(divider.snp.bottom).offset(5)
        }
        
        contentView.layoutIfNeeded()
    }
    
    private func isTermsOfServiceHighlighted() -> Bool {
        if selectedItem == .TermsOfService && handel.shouleTracking() {
            return true
        }
        return false
    }
    
    private func isPrivacyPolicyHighlighted() -> Bool {
        if selectedItem == .PrivacyPolicy && handel.shouleTracking() {
            return true
        }
        return false
    }
    
    private func isOpenSourceNoticeHighlighted() -> Bool {
        if selectedItem == .OpenSourceNotice && handel.shouleTracking() {
            return true
        }
        return false
    }
    
    @objc func onTermsOfServiceClicked() {
        print("onTermsOfServiceClicked")
        moveToItem(item:.TermsOfService)
        
        let webVC = WebVC()
        webVC.url = URL(string: TermOfServiceUrl)
        webVC.lastHandel = self.handel
        webVC.webViewTitle = "Terms of Service".localize()
        SettingsRouter.shared.navigationController?.pushViewController(webVC, animated: true)
    }
    
    @objc func onPrivacyPolicyClicked() {
        print("onPrivacyPolicyClicked")
        moveToItem(item:.PrivacyPolicy)

        let webVC = WebVC()
        webVC.url = URL(string: PrivacyPolicyUrl)
        webVC.lastHandel = self.handel
        webVC.webViewTitle = "Privacy Policy".localize()
        SettingsRouter.shared.navigationController?.pushViewController(webVC, animated: true)
    }
    
    @objc func onOpenSourceNoticeClicked() {
        print("onOpenSourceNoticeClicked")
        moveToItem(item:.OpenSourceNotice)

        let webVC = WebVC()
        let url = Bundle.main.url(forResource: "licenses", withExtension: "html")
        webVC.url = url!
        webVC.isLoadFileURL = true
        webVC.lastHandel = self.handel
        webVC.webViewTitle = "Open Source Software Notice".localize()
        SettingsRouter.shared.navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func moveToItem(item:AboutItem) {
        selectedItem = item
        reloadContentView()
    }
    
    //MARK: - Lazy - UI
    lazy var contentView : UIView = {
        let view = UIView.init()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    @objc func logoTapped(_ sender: UITapGestureRecognizer) {
        tapWorkItem?.cancel()

        tapWorkItem = DispatchWorkItem {
            self.tapCount = 0
        }

        tapCount += 1

        if tapCount >= debugModeCount {
            toggleDebugMode()
            tapCount = 0
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: tapWorkItem!)
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

//MARK: - RZHandleResponderDelegate
extension AboutVC : RZHandleResponderDelegate {
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .B , .left:
            if selectedItem == .PrivacyPolicy {
                selectedItem = .TermsOfService
                reloadContentView()
                return
            }
            
            handel.stopTracking()
            lastHandel?.startTracking()
            lastHandel?.reloadCallBack?()
            reloadContentView()
        case .A:
            clickA()
        case .up:
            if selectedItem == .OpenSourceNotice {
                moveToItem(item:.TermsOfService)
            }
        case .down:
            if selectedItem == .TermsOfService || selectedItem == .PrivacyPolicy {
                moveToItem(item:.OpenSourceNotice)
            }
        case .right:
            if selectedItem == .TermsOfService {
                moveToItem(item:.PrivacyPolicy)
            }
        default:
            break
        }
    }
}
