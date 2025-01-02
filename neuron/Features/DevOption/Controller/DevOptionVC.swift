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

class DevOptionVC: RZBaseVC {
    
    let titleLabSpaceLeft = 40.0
    let titleLabSpaceTop = 40.0
    
    lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView(frame: view.bounds)
        scroll.bounces = false
        
        return scroll
    }()
    
    lazy var contentView : UIView = {
        let view = UIView.init()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    var showSeparateScreenOptionTitleLabel: UILabel? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setupData()
        setupView()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupData() {
        handel.reloadCallBack = { [self] in
            handel.delegate = self
            reloadContentView()
        }
    }
    
    func reloadContentView() {
    }
    
    func setupView() {
        
        view.backgroundColor = .black
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.top.left.bottom.equalTo(0)
            make.width.equalTo(view)
        }
        
        scrollView.addSubview(contentView)
        
        contentView.snp.makeConstraints { make in
            make.top.left.equalTo(0)
            make.width.equalTo(view)
        }
        
        let statsItemView = DevOptionItemView.itemView("Export last session streaming stats".localize())
        contentView.addSubview(statsItemView)
        statsItemView.snp.makeConstraints { make in
            make.top.equalTo(titleLabSpaceTop)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(statsTapAction(_:)))
        statsItemView.addGestureRecognizer(tap)
        statsItemView.isUserInteractionEnabled = true
        
        
        let statusText = statsDesText()
        let statsDesLael = DevOptionItemView.desLab(statusText, 17.0)
        statsDesLael.tag = ItemViewTag.StatsDes.rawValue
        contentView.addSubview(statsDesLael)
        statsDesLael.snp.makeConstraints { make in
            make.top.equalTo(statsItemView.snp.bottom)
            make.left.equalTo(titleLabSpaceLeft + 20)
            make.right.equalTo(-titleLabSpaceLeft)
            
        }
        
        let exportSettingsGesture = UITapGestureRecognizer(target: self, action: #selector(exportSettingsAction(_:)))
        let exportSettingsView = DevOptionItemView.itemView("Export all settings".localize())
        exportSettingsView.addGestureRecognizer(exportSettingsGesture)
        contentView.addSubview(exportSettingsView)
        exportSettingsView.snp.makeConstraints { make in
            make.top.equalTo(statsDesLael.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }
        
        let hideSeparateScreenOptionGesture = UITapGestureRecognizer(target: self, action: #selector(setIsShowSeparateScreenOption(_:)))
        let (hideSeparateScreenOptionView, titleLable) = DevOptionItemView.changeableItemView(isShowSeparateScreenDisplayMode ? "Hide Separate Screen Option" : "Show Separate Screen Option")
        showSeparateScreenOptionTitleLabel = titleLable
        hideSeparateScreenOptionView.addGestureRecognizer(hideSeparateScreenOptionGesture)
        contentView.addSubview(hideSeparateScreenOptionView)
        hideSeparateScreenOptionView.snp.makeConstraints { make in
            make.top.equalTo(exportSettingsView.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
            make.bottom.equalTo(contentView.snp.bottom).offset(-50)
        }
        
    }
    
    
    func statsDesText() -> String {
        let stats: StreamingStats? = DevUtils.shared().lastestStreamingStats()
        let statusText = stats == nil ? "No stats yet".localize() : "\(stats!.lastUpdateTime())\n\(stats!.random_id)"
        return statusText
    }
    
    @objc func statsTapAction(_ sender: UITapGestureRecognizer) {
        Logger.info("statsTapAction")
        guard let stats = DevUtils.shared().lastestStreamingStats(), stats.started_at > 0 else {
            Logger.debug("No stats yet")
            Toast.show(text: "No stats yet")
            return
        }
        
        shareStatsFile()
    }
    
    func shareStatsFile() {
        let fileURL = ShareDataDB.shared().fileUrl(fromGroup: statsPath)
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 100, y: 100, width: 200, height: 200)
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func exportSettingsAction(_ sender: UITapGestureRecognizer) {
        
        let data = ShareDataDB.shared().readData(fromPath: frameSettingsPath)
        ShareDataDB.shared().write(data, toFile: frameSettingsTXTPath)
        let fileURL = ShareDataDB.shared().fileUrl(fromGroup: frameSettingsTXTPath)
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 100, y: 100, width: 200, height: 200)
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func setIsShowSeparateScreenOption(_ sender: UITapGestureRecognizer) {
        // is isShowSeparateScreenDisplayMode current value is
        let newValue = !isShowSeparateScreenDisplayMode
        setShowSeparateScreenDisplayMode(value: newValue)
        
        showSeparateScreenOptionTitleLabel?.text = newValue ? "Hide Separate Screen Option" : "Show Separate Screen Option"
        if newValue == false && NeuronFrameSettingsViewModel.shared().displayMode == .SeparateScreenMode {
            NeuronFrameSettingsViewModel.shared().displayMode = .DuplicatePCDisplayMode
            NeuronFrameSettingsViewModel.shared().frameSettings.displayMode = PCDisplayStreamingMode.DuplicatePCDisplayMode.rawValue
            NeuronFrameSettingsViewModel.shared().saveSettings()
        }
    }
    
}

extension DevOptionVC: RZHandleResponderDelegate {
    func handleClickButton(_ action: GamePadButton) {
        switch action {
        case .B , .left:
            handel.stopTracking()
            lastHandel?.startTracking()
            lastHandel?.reloadCallBack?()
            reloadContentView()
        default:
            break
        }
    }
    
    
}


extension DevOptionVC {
    func setupNotifications() {
        NotificationCenter.default.addObserver(forName: .streamingStatsUpdateNotification, object: nil, queue: .main) { [weak self]  not in
            self?.streamingStatsUpdate()
        }
    }
    
    func streamingStatsUpdate() {
        if let statsDesLabel = contentView.viewWithTag(ItemViewTag.StatsDes.rawValue) as? UILabel {
            let statusText = statsDesText()
            statsDesLabel.text = statusText
        }
    }
}
