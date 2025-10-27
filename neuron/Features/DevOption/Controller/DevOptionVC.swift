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
    var enableSaveLogOptionTitleLabel: UILabel? = nil
    var enableSaveAudioOptionTitleLabel: UILabel? = nil
    
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
        }
        
        
        let enableSaveLogGesture = UITapGestureRecognizer(target: self, action: #selector(enableSaveLogOption(_:)))
        let (enableSaveLogView, enableSaveLogLable) = DevOptionItemView.changeableItemView("Enable Log File Saving" + (isEnableSaveLogDisplayMode ? " (ON)" : " (OFF)"))
        enableSaveLogOptionTitleLabel = enableSaveLogLable
        enableSaveLogView.addGestureRecognizer(enableSaveLogGesture)
        contentView.addSubview(enableSaveLogView)
        enableSaveLogView.snp.makeConstraints { make in
            make.top.equalTo(hideSeparateScreenOptionView.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }
        
        let exportLogGesture = UITapGestureRecognizer(target: self, action: #selector(exportLogAction(_:)))
        let exportLogView = DevOptionItemView.itemView("Export Log File".localize())
        exportLogView.addGestureRecognizer(exportLogGesture)
        contentView.addSubview(exportLogView)
        exportLogView.snp.makeConstraints { make in
            make.top.equalTo(enableSaveLogView.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }

        let cleanLogGesture = UITapGestureRecognizer(target: self, action: #selector(cleanLogAction(_:)))
        let cleanLogView = DevOptionItemView.itemView("Clean Log".localize())
        cleanLogView.addGestureRecognizer(cleanLogGesture)
        contentView.addSubview(cleanLogView)
        cleanLogView.snp.makeConstraints { make in
            make.top.equalTo(exportLogView.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }
        
        let enableSaveAudioGesture = UITapGestureRecognizer(target: self, action: #selector(enableSaveAudioOption(_:)))
        let (enableSaveAudioView, enableSaveAudioLable) = DevOptionItemView.changeableItemView("Save Streaming Audio" + (isEnableSaveAudioDisplayMode ? " (ON)" : " (OFF)"))
        enableSaveAudioOptionTitleLabel = enableSaveAudioLable
        enableSaveAudioView.addGestureRecognizer(enableSaveAudioGesture)
        contentView.addSubview(enableSaveAudioView)
        enableSaveAudioView.snp.makeConstraints { make in
            make.top.equalTo(cleanLogView.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }

        let exportAudioGesture = UITapGestureRecognizer(target: self, action: #selector(exportAudioAction(_:)))
        let exportAudioView = DevOptionItemView.itemView("Export Streaming Audio")
        exportAudioView.addGestureRecognizer(exportAudioGesture)
        contentView.addSubview(exportAudioView)
        exportAudioView.snp.makeConstraints { make in
            make.top.equalTo(enableSaveAudioView.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }
        
        let cleanAudioGesture = UITapGestureRecognizer(target: self, action: #selector(cleanAudioAction(_:)))
        let cleanAudioView = DevOptionItemView.itemView("Delete Streaming Audio")
        cleanAudioView.addGestureRecognizer(cleanAudioGesture)
        contentView.addSubview(cleanAudioView)
        cleanAudioView.snp.makeConstraints { make in
            make.top.equalTo(exportAudioView.snp.bottom).offset(30)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
            make.bottom.equalTo(contentView.snp.bottom).offset(-50)
        }
                
        contentView.layoutIfNeeded()
        scrollView.contentSize = CGSize(width: 0 , height: contentView.frame.height)
        
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
    
    @objc func enableSaveLogOption(_ sender: UITapGestureRecognizer) {
        // is enableSaveLogDisplayMode current value is
        let newValue = !isEnableSaveLogDisplayMode
        setEnableSaveLogDisplayMode(value: newValue)
        enableSaveLogOptionTitleLabel?.text = "Enable Log File Saving" + (newValue ? " (ON)" : " (OFF)")
        SettingsRouter.shared.shareLogEnableSave = newValue
    }
    
    @objc func enableSaveAudioOption(_ sender: UITapGestureRecognizer) {
        let newValue = !isEnableSaveAudioDisplayMode
        setEnableSaveAudioDisplayMode(value: newValue)
        enableSaveAudioOptionTitleLabel?.text = "Save Streaming Audio" + (newValue ? " (ON)" : " (OFF)")
        
        // Note: Audio recording will be automatically controlled by streaming state
        // We just save the preference here
    }
    
    @objc func exportLogAction(_ sender: UITapGestureRecognizer) {

        if SettingsRouter.shared.shareLogExcportIng {
            return
        }else {
            
            SettingsRouter.shared.shareLogExcportIng = true
            //加锁
            DevLogger.shared.lock()
            
//            let data:Data = DevLogger.shared.getLogData() ?? Data()
//            ShareDataDB.shared().write(data, toFile: shareLogPath)
            let fileURL = ShareDataDB.shared().fileUrl(fromGroup: shareLogPath)
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = self.view
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 100, y: 100, width: 200, height: 200)
            }
            self.present(activityViewController, animated: true) {}
            
            activityViewController.completionHandler = { a , b in
                //解锁
                DevLogger.shared.unLock()
                SettingsRouter.shared.shareLogExcportIng = false
            }

        }
        
    }
    
    @objc func cleanLogAction(_ sender: UITapGestureRecognizer) {
        DevLogger.shared.cleanLog()
    }
    
    @objc func exportAudioAction(_ sender: UITapGestureRecognizer) {
        // Get documents directory path
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let pcmPath = "\(documentsPath)/audio_streaming_pcm.wav"
        
        // Check if PCM WAV file exists
        if !FileManager.default.fileExists(atPath: pcmPath) {
            Toast.show(text: "No audio files found")
            return
        }
        
        let fileURL = URL(fileURLWithPath: pcmPath)
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 100, y: 100, width: 200, height: 200)
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func cleanAudioAction(_ sender: UITapGestureRecognizer) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let pcmPath = "\(documentsPath)/audio_streaming_pcm.wav"
        
        do {
            // Delete PCM WAV file if it exists
            if FileManager.default.fileExists(atPath: pcmPath) {
                try FileManager.default.removeItem(atPath: pcmPath)
                Toast.show(text: "Audio file deleted")
            } else {
                Toast.show(text: "No audio file found to delete")
            }
        } catch {
            Toast.show(text: "Failed to delete audio file")
        }
    }
    
    @objc class func log(_ msg:String) {
        //使用单例，避免重复读写数据库
        if SettingsRouter.shared.shareLogEnableSave {
            
            if msg.isEmpty {
                return
            }
            DevLogger.shared.appendLog(text: msg)
        }
    }
}

public func DevOptionLog(_ items: Any..., separator: String = " ", terminator: String = "\n"){
    //使用单例，避免重复读写数据库
    if SettingsRouter.shared.shareLogEnableSave {
        DevLogger.shared.appendLog(text: items.description)
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
