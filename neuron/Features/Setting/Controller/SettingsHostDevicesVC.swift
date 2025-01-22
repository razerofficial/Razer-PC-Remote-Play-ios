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
import SwiftBridging

enum HostDevicesSection : Int  {
    case Unknow
    case PairedSection
    case NetSection
    case AddSection
}

class SettingsHostDevicesVC : RZBaseVC { // DiscoveryCallback, PairCallback
    
//    var pairManager:PairManager = PairManager()
//    var discoveryManager = DiscoveryManager()
//    let queue = OperationQueue.init()
    
//    var allHosts:NSMutableArray = NSMutableArray()
//    var pairedHosts:NSMutableArray = NSMutableArray()
//    var netHosts:NSMutableArray = NSMutableArray()
    
    var pairedHosts:[TemporaryHost] = HostListManger.shared.pairedHosts//[TemporaryHost]()
    {
        didSet {
            if let hostuuid = selectedHost?.uuid {
                for host in pairedHosts {
                    if host.uuid == hostuuid {
                        //dismiss loading view
                        self.dismissLoadingView()
                    }
                }
            }
        }
    }
    var netHosts:[TemporaryHost] = HostListManger.shared.netHosts//[TemporaryHost]()

    
    //Reflashing
    var isReflashing:Bool = false
    
    var lastView:UIView?
    let titleLabSpaceLeft = 40.0
    let deviceCellSpaceLeft = 20.0
    var selectedHost:TemporaryHost?
    var deviceSection:HostDevicesSection = .Unknow
    var selectedIndex:Int = 0
    
    var viewShoudResponsHandel:Bool = true
    
    let loaddingViewTimeout = 5

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        handel.reloadCallBack = { [self] in
            deviceSection = .Unknow
            handel.delegate = self
            reloadContentView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.viewShoudResponsHandel = true
            }
        }
        
        //setupData()
        setupView()
        
        SettingsRouter.shared.hostDevicesRemoveHostCallBack = { [weak self] host in
            HostListManger.shared.unpairNetHost(host)
            //网络无权限的时候，setupData()无法执行刷新逻辑，所以这里执行
            if !RzUtils.isGrantedLocalNetworkPermission() {
                self?.reloadContentView()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.viewShoudResponsHandel = true
            }
        }
        
        SettingsRouter.shared.hostDevicesPairedHostCallBack = { [weak self] host in
            host.pairState = .paired
            //self?.discoveryManager.update(host)
            HostListManger.shared.discoveryManager.update(host)
            SettingsRouter.shared.dataManager.update(host)
            ShareDataDB.shared().wirteHostListDataToShare()
            self?.setupData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.viewShoudResponsHandel = true
            }
        }
        
        SettingsRouter.shared.hostDevicesReadShareDataCallBack = { [weak self] in
            //self?.discoveryManager.stopDiscovery()
            HostListManger.shared.discoveryManager.stopDiscovery()
            self?.setupData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.viewShoudResponsHandel = true
            }
        }
        
        HostListManger.shared.showLoadingViewCallBack = { [weak self] in
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self?.showLoadingView()
            }
        }
        
        HostListManger.shared.dismissLoadingViewCallBack = { [weak self] in
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self?.dismissLoadingView()
            }
        }
                
        registerObservers()
        
    }
    
    deinit {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewShoudResponsHandel = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewShoudResponsHandel = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        dismissLoadingView()
    }
    
    //
    private func registerObservers() {
        
        HostListManger
            .shared
            .pairHostListSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { hostList in
                self.pairedHosts = hostList
                self.reloadContentView()
            }
            .store(in: &bag)
        
        HostListManger
            .shared
            .netHostListSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { hostList in
                self.netHosts = hostList
                self.reloadContentView()
            }
            .store(in: &bag)
        
    }
    
    //MARK: - setup
    func setupData() {
        HostListManger.shared.restartDiscovery()
    }
    
    func setupView() {
        //set back ground color
        view.backgroundColor = .black
        
        //add contents
        view.addSubview(scroll)
        
        scroll.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scroll.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.left.right.equalTo(0)
            make.width.equalTo(view)
        }
        
        reloadContentView()
        
    }
    
    func reloadContentView(){
        
        if viewShoudResponsHandel == false {
            return
        }
        
        if isReflashing {
            return
        }
        
        isReflashing = true
        
        for subview in contentView.subviews {
            subview.removeFromSuperview()
        }
                
        if deviceSection == .Unknow {
            selectedIndex = 0
            if pairedHosts.count > 0 {
                deviceSection = .PairedSection
            }else if netHosts.count > 0 {
                deviceSection = .NetSection
            }else {
                deviceSection = .AddSection
            }
        }
        
        let labAllDevice = SettingsRouter.titleLab("All Computers".localize().uppercased())
        contentView.addSubview(labAllDevice)
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let labAllDeviceDec = SettingsRouter.desLab(String(format: "To pair a PC, it must be on the same network as your %@. Ensure your PC has Razer Cortex v11.0.+ installed and signed in with your Razer ID.".localize(), deviceType),IsIpad() ? 16.0 : 14.0)
        contentView.addSubview(labAllDeviceDec)
        
        labAllDevice.snp.makeConstraints { make in
            make.top.equalTo(55.0)
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
        }
        
        labAllDeviceDec.snp.makeConstraints { make in
            make.left.equalTo(titleLabSpaceLeft)
            make.right.equalTo(-titleLabSpaceLeft)
            make.top.equalTo(labAllDevice.snp.bottom).offset(10)
        }
        
        lastView = labAllDeviceDec
        
        addPairedDevicesUI()
        addAvailableDevicesUI()
        //addHostManullyUI()
        
        contentView.layoutIfNeeded()
        contentView.snp.remakeConstraints { make in
            make.top.left.right.equalTo(0)
            make.width.equalTo(view)
            make.height.equalTo((lastView ?? contentView).frame.maxY + 50)
        }
        scroll.contentSize = CGSize.init(width: contentView.bounds.width, height: (lastView ?? contentView).frame.maxY + 50)
        
        isReflashing = false
    }
    
    func addPairedDevicesUI() {
        
        if pairedHosts.count > 0 {
            let labPairedDevices = SettingsRouter.desLab("Paired computers".localize().uppercased(), IsIpad() ? 16.0 : 14.0)
            contentView.addSubview(labPairedDevices)
            
            labPairedDevices.snp.makeConstraints { make in
                make.left.equalTo(titleLabSpaceLeft)
                make.right.equalTo(-titleLabSpaceLeft)
                make.top.equalTo((lastView ?? contentView).snp.bottom).offset(20)
            }
            
            let devicesCellBg = UIView.init()
            devicesCellBg.backgroundColor = Color.hex(0x222222).uiColor()
            devicesCellBg.layer.cornerRadius = 10.0
            devicesCellBg.layer.masksToBounds = true
            devicesCellBg.isUserInteractionEnabled = true
            
            contentView.addSubview(devicesCellBg)
            devicesCellBg.snp.makeConstraints { make in
                make.left.equalTo(deviceCellSpaceLeft)
                make.right.equalTo(-deviceCellSpaceLeft)
                make.top.equalTo(labPairedDevices.snp.bottom).offset(10)
            }
            
            var lastCellTop = 0.0
            var index = 0
            for host in pairedHosts {
                
                if let tmpHost = host as? TemporaryHost {
                    let cell = localHostCell(host: tmpHost)
                    // color
                    let heighted = (deviceSection == .PairedSection && selectedIndex == index) && handel.shouleTracking()
                    let heihgtedColor = heighted ? Color.hex(0xffffff, alpha: 0.3).uiColor() : devicesCellBg.backgroundColor
                    cell.backgroundColor = heihgtedColor
                    cell.tag = index
                    cell.addTarget(self, action: #selector(clickLocalHost), for: .touchUpInside)
                    var tempCellHeight = 40.0
                    
                    devicesCellBg.addSubview(cell)
                    cell.snp.makeConstraints { make in
                        make.left.right.equalTo(0)
                        make.top.equalTo(lastCellTop)
                        make.height.equalTo(tempCellHeight)
                    }
                    lastCellTop = lastCellTop + tempCellHeight
                    
                    if pairedHosts.count > 1 && index != pairedHosts.count - 1 {
                        let line = UIView.init()
                        line.backgroundColor = Color.hex(0x999999).uiColor()
                        cell.addSubview(line)
                        line.snp.makeConstraints { make in
                            make.bottom.right.equalTo(0)
                            make.left.equalTo(20)
                            make.height.equalTo(1.0 / ScreenScale)
                        }
                    }
                    index = index + 1
                }
            }
            
            devicesCellBg.snp.remakeConstraints { make in
                make.left.equalTo(deviceCellSpaceLeft)
                make.right.equalTo(-deviceCellSpaceLeft)
                make.top.equalTo(labPairedDevices.snp.bottom).offset(10)
                make.height.equalTo(lastCellTop)
            }
            lastView = devicesCellBg
        }
    }
    
    func addAvailableDevicesUI() {
        
        let labAvailableDevices = SettingsRouter.desLab("Unpaired computers".localize().uppercased(), IsIpad() ? 16.0 : 14.0)

        contentView.addSubview(labAvailableDevices)
        contentView.addSubview(loading)
        
        labAvailableDevices.snp.makeConstraints { make in
            make.left.equalTo(titleLabSpaceLeft)
            make.top.equalTo((lastView ?? contentView).snp.bottom).offset(20)
        }
        
        loading.snp.makeConstraints { make in
            make.left.equalTo(labAvailableDevices.snp.right).offset(10)
            make.centerY.equalTo(labAvailableDevices)
        }
        
        loading.isHidden = (netHosts.count > 0)
        if netHosts.count > 0 {
            loading.stopAnimating()
        }else{
            loading.startAnimating()
        }
        
        lastView = labAvailableDevices
        
        let devicesCellBg = UIView.init()
        devicesCellBg.backgroundColor = Color.hex(0x222222).uiColor()
        devicesCellBg.layer.cornerRadius = 10.0
        devicesCellBg.layer.masksToBounds = true
        devicesCellBg.isUserInteractionEnabled = true
        
        contentView.addSubview(devicesCellBg)
        devicesCellBg.snp.makeConstraints { make in
            make.left.equalTo(deviceCellSpaceLeft)
            make.right.equalTo(-deviceCellSpaceLeft)
            make.top.equalTo(labAvailableDevices.snp.bottom).offset(10)
        }
        var lastCellTop = 0.0
        let tempCellHeight = 40.0
        
        if netHosts.count > 0 {
            
            var index = 0
            for host in netHosts {
                
                if let tmpHost = host as? TemporaryHost {
                    let cell = netHostCell(host: tmpHost)
                    // color
                    let heighted = (deviceSection == .NetSection && selectedIndex == index) && handel.shouleTracking()
                    let heihgtedColor = heighted ? Color.hex(0xffffff, alpha: 0.3).uiColor() : devicesCellBg.backgroundColor
                    cell.backgroundColor = heihgtedColor
                    cell.tag = index
                    cell.addTarget(self, action: #selector(pairNetHost), for: .touchUpInside)
                    devicesCellBg.addSubview(cell)
                    cell.snp.makeConstraints { make in
                        make.left.right.equalTo(0)
                        make.top.equalTo(lastCellTop)
                        make.height.equalTo(tempCellHeight)
                    }
                    lastCellTop = lastCellTop + tempCellHeight
                    
                    //if netHosts.count > 1 && index != netHosts.count - 1 {
                        let line = UIView.init()
                        line.backgroundColor = Color.hex(0x999999).uiColor()
                        cell.addSubview(line)
                        line.snp.makeConstraints { make in
                            make.bottom.right.equalTo(0)
                            make.left.equalTo(20)
                            make.height.equalTo(1.0 / ScreenScale)
                        }
                    //}
                    index = index + 1
                    
                }
            }
            
        }
        
        
        let addHostCell = addHostCell()
        var section = 2
        if pairedHosts.count < 1 {
            section = section - 1
        }
        
        if netHosts.count < 1 {
            section = section - 1
        }
        
        // color
        let heighted = (deviceSection == .AddSection) && handel.shouleTracking()
        let heihgtedColor = heighted ? Color.hex(0xffffff, alpha: 0.3).uiColor() : Color.hex(0x222222).uiColor()
        addHostCell.backgroundColor = heihgtedColor
        //addHostCell.layer.cornerRadius = 10.0
        addHostCell.layer.masksToBounds = true
        
        devicesCellBg.addSubview(addHostCell)
        addHostCell.addTarget(self, action: #selector(gotoAddHost), for: .touchUpInside)
        addHostCell.snp.makeConstraints { make in
            make.left.right.equalTo(0)
            make.top.equalTo(lastCellTop)
            make.height.equalTo(tempCellHeight)
        }
        lastCellTop = lastCellTop + tempCellHeight
        
        
        devicesCellBg.snp.remakeConstraints { make in
            make.left.equalTo(deviceCellSpaceLeft)
            make.right.equalTo(-deviceCellSpaceLeft)
            make.top.equalTo(labAvailableDevices.snp.bottom).offset(10)
            make.height.equalTo(lastCellTop)
        }
        
        lastView = devicesCellBg
        
        let addHostLab = SettingsRouter.desLab("Enter the IP address of your computer.".localize(), IsIpad() ? 16.0 : 14.0)
        contentView.addSubview(addHostLab)
        
        addHostLab.snp.makeConstraints { make in
            make.left.equalTo(titleLabSpaceLeft)
            make.top.equalTo(devicesCellBg.snp.bottom).offset(10)
        }
        
        lastView = addHostLab
        
    }
    
//    func addHostManullyUI(){
//        
//        let addHostCell = addHostCell()
//        var section = 2
//        if pairedHosts.count < 1 {
//            section = section - 1
//        }
//        
//        if netHosts.count < 1 {
//            section = section - 1
//        }
//        
//        
//        let otherDevices = SettingsRouter.desLab("Other computers".localize().uppercased(), 14)
//        contentView.addSubview(otherDevices)
//        
//        otherDevices.snp.makeConstraints { make in
//            make.left.equalTo(titleLabSpaceLeft)
//            make.right.equalTo(-titleLabSpaceLeft)
//            make.top.equalTo((lastView ?? contentView).snp.bottom).offset(20)
//        }
//        
//        // color
//        let heighted = (deviceSection == .AddSection) && handel.shouleTracking()
//        let heihgtedColor = heighted ? Color.hex(0xffffff, alpha: 0.3).uiColor() : Color.hex(0x222222).uiColor()
//        addHostCell.backgroundColor = heihgtedColor
//        addHostCell.layer.cornerRadius = 10.0
//        addHostCell.layer.masksToBounds = true
//        
//        contentView.addSubview(addHostCell)
//        addHostCell.addTarget(self, action: #selector(gotoAddHost), for: .touchUpInside)
//        addHostCell.snp.makeConstraints { make in
//            make.left.equalTo(deviceCellSpaceLeft)
//            make.right.equalTo(-deviceCellSpaceLeft)
//            make.top.equalTo(otherDevices.snp.bottom).offset(10)
//            //make.top.equalTo((lastView ?? contentView).snp.bottom).offset(20)
//            make.height.equalTo(40)
//        }
//        
//        let addHostLab = SettingsRouter.desLab("Enter the IP address of the host computer.".localize(), IsIpad() ? 16.0 : 14.0)
//        contentView.addSubview(addHostLab)
//        
//        addHostLab.snp.makeConstraints { make in
//            make.left.equalTo(titleLabSpaceLeft)
//            make.top.equalTo(addHostCell.snp.bottom).offset(10)
//        }
//        
//        lastView = addHostLab
//        
//    }
        
    //MARK: - cell click
    @objc func clickLocalHost(_ sender:UIButton){
        DDLogInfo("=====enter to host menuvc (forget host) ======")
        lastVC?.updateNextHandel(handel)
        selectedIndex = sender.tag
        deviceSection = .PairedSection
        reloadContentView()
        
        if let host = pairedHosts[safe:sender.tag] {
            let vc = SettingsHostMenuVC(host: host)
            vc.lastHandel = handel
            SettingsRouter.shared.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func pairNetHost(_ sender:UIButton) {
        
        DDLogInfo("=====pair host ======")
        
        lastVC?.updateNextHandel(handel)
        selectedIndex = sender.tag
        deviceSection = .NetSection
        reloadContentView()
        
        if let host = netHosts[safe:sender.tag] {
            showLoadingView()
            //let httpManger = HttpManager.init(host: host)
            selectedHost = host
            //pairManager = PairManager.init(manager: httpManger, clientCert: CryptoManager.readCertFromFile(), callback: self)
            //queue.addOperation(pairManager)
            HostListManger.shared.pairNetHost(host)
        }
        
    }
    
    @objc func gotoAddHost(){
        lastVC?.updateNextHandel(handel)
        selectedIndex = 0
        deviceSection = .AddSection
        reloadContentView()
        
        let vc = SettingsAdddHostVC()
        vc.lastHandel = handel
        SettingsRouter.shared.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showLoadingView() {
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismissLoadingView), object: nil)
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        loadingView.isHidden = false
        perform(#selector(dismissLoadingView), with: nil, afterDelay: TimeInterval(loaddingViewTimeout))
    }
    
    @objc
    func dismissLoadingView() {
        
        loadingView.isHidden = true
        loadingView.removeFromSuperview()
    }
    
    //MARK: - Lazy - UI
    
    lazy var loadingView: UIView = {
        let view = UIView.init()
        view.isHidden = true
        view.backgroundColor = Color.hex(0x000000, alpha: 0.5).uiColor()
        
        let indicator = UIActivityIndicatorView.init(style: .large)
        indicator.color = .gray
        indicator.startAnimating()
        
        view.addSubview(indicator)
        
        indicator.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.height.width.equalTo(60.0)
        }
        
        return view
    }()
    
    lazy var scroll : UIScrollView = {
        let scroll = UIScrollView.init(frame: view.bounds)
        scroll.showsHorizontalScrollIndicator = false
        scroll.delaysContentTouches = true
        return scroll
    }()
    
    lazy var contentView : UIView = {
        let view = UIView.init()
        view.isUserInteractionEnabled = true
        return view
    }()
    
    lazy var loading : UIActivityIndicatorView = {
        let view = UIActivityIndicatorView.init(style: .medium)
        view.color = .gray
        return view
    }()
    
    //MARK: - create - UI    
    func localHostCell(host:TemporaryHost) -> UIButton {
        
        let imageView = UIImageView.init()
        
        if host.state == State.online {
            imageView.image = UIImage(named: "computer_available")
        }else{
            imageView.image = UIImage(named: "computer_unavailable")
        }
        
        let button = UIButton.init(type: .custom)
        let infoButton = UIButton.init(type: .infoLight)
        infoButton.isUserInteractionEnabled = false
        let title = SettingsRouter.titleLab(host.name)
        let state = SettingsRouter.desLab("Available".localize(), 14)
        if host.state != State.online {
            state.text = "Unavailable".localize()
        }
        
        button.addSubview(imageView)
        button.addSubview(title)
        button.addSubview(state)
        button.addSubview(infoButton)
        
        imageView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        title.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(1)
            make.right.lessThanOrEqualTo(state.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        
        state.snp.makeConstraints { make in
            make.right.equalTo(infoButton.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        
        
        return button
    }
    
    func netHostCell(host:TemporaryHost) -> UIButton {
        
        let imageView = UIImageView.init(image: UIImage(named: "computer_unpaired"))
        let button = UIButton.init(type: .custom)
        let infoButton = UIButton.init(type: .infoLight)
        infoButton.isUserInteractionEnabled = false
        let title = SettingsRouter.titleLab(host.name)
        let state = SettingsRouter.desLab("Unpaired".localize(), 14)

        button.addSubview(imageView)
        button.addSubview(title)
        button.addSubview(state)
        button.addSubview(infoButton)
        
        imageView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        title.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(1)
            make.right.lessThanOrEqualTo(state.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        
        state.snp.makeConstraints { make in
            make.right.equalTo(infoButton.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        
        
        return button
    }

    func addHostCell() -> UIButton {
        
        let button = UIButton.init(type: .custom)
        let title = SettingsRouter.titleLab("Add PC manually".localize())
        let rightImg = UIImageView(image: UIImage(named: "settings_devices_right"))
        button.addSubview(title)
        button.addSubview(rightImg)
        
        title.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(10)
        }
        
        rightImg.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.width.height.equalTo(40)
        }
        return button
    }
    
}

//MARK: - RZHandleResponderDelegate
extension SettingsHostDevicesVC : RZHandleResponderDelegate {
    
    func handleClickButton(_ action: GamePadButton) {
        
        if self.viewShoudResponsHandel == false {
            return
        }
        
        //pin code alertview showing
        if SettingsRouter.shared.pairAlertView != nil {
            switch action {
            case.A :
                SettingsRouter.shared.closePairAlertView()
            default:
                break
            }
            return
        }
        
        if loadingView.isHidden == false {
            return
        }
        
        switch action {
        case .B , .left:
            handel.stopTracking()
            lastHandel?.startTracking()
            lastHandel?.reloadCallBack?()
            reloadContentView()
        case .A:
            clickA()
        case .up:
            lastMenu()
        case .down:
            nextMenu()
        default:
            break
        }
    }
}

//MARK: - RZHandleResponderDelegate - handels actions
extension SettingsHostDevicesVC {
    
    func nextMenu() {
        
        if deviceSection == .PairedSection {
                if selectedIndex + 1 < pairedHosts.count {
                    selectedIndex = selectedIndex + 1
                }else if netHosts.count > 0 {
                    deviceSection = .NetSection
                    selectedIndex = 0
                }else{
                    deviceSection = .AddSection
                    selectedIndex = 0
                }
        }else if deviceSection == .NetSection {
            
            if selectedIndex + 1 < netHosts.count {
                selectedIndex = selectedIndex + 1
            }else{
                deviceSection = .AddSection
                selectedIndex = 0
            }
        }
    
        reloadContentView()
        scrollToSelectedMenu()
    }
    
    func lastMenu() {
        if deviceSection == .PairedSection {
                if selectedIndex - 1 >= 0 {
                    selectedIndex = selectedIndex - 1
                }
        }else if deviceSection == .NetSection {
            if selectedIndex - 1 >= 0 {
                selectedIndex = selectedIndex - 1
            }else if pairedHosts.count > 0{
                deviceSection = .PairedSection
                selectedIndex = pairedHosts.count - 1
            }
        }else if deviceSection == .AddSection {
            if netHosts.count > 0 {
                deviceSection = .NetSection
                selectedIndex = netHosts.count - 1
            }else if pairedHosts.count > 0{
                deviceSection = .PairedSection
                selectedIndex = pairedHosts.count - 1
            }
        }
        reloadContentView()
        scrollToSelectedMenu()
    }
    
    func scrollToSelectedMenu(){
        
        let conentHeihgt = scroll.contentSize.height
        var topY = 0
        
        if deviceSection == .PairedSection {
            topY = 45 * selectedIndex
        }else if deviceSection == .NetSection {
            topY = 40 * selectedIndex + 45 * (pairedHosts.count + 1)
        }else if deviceSection == .AddSection {
            topY = Int(conentHeihgt - UIScreen.screenHeight)
        }
        
        topY = min(topY, Int(conentHeihgt - UIScreen.screenHeight) > 0  ? Int(conentHeihgt - UIScreen.screenHeight) : 0)
        topY = topY < 0 ? 0 : topY
        scroll.contentOffset = CGPoint(x: 0, y: topY)
    }
    
    func clickA() {
                
        switch deviceSection {
        case .PairedSection:
            let button = UIButton.init()
            button.tag = selectedIndex
            clickLocalHost(button)
            
        case .NetSection:
            let button = UIButton.init()
            button.tag = selectedIndex
            pairNetHost(button)
            
        case .AddSection:
            gotoAddHost()
            
        default:
            break
        }
    }
}
