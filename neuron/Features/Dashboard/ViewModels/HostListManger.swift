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
import Combine
import RxSwift
import RxCocoa
import SnapKit
import CocoaLumberjack
import SwiftUI
import SwiftBridging
import YYModel

let External_IP = "External_IP"
let DifferentCountMax:Int = 3
let checkTimeInterval:TimeInterval = 2

class HostListManger: NSObject {
    
    @objc static let shared = HostListManger()
    
    var pairManager:PairManager = PairManager()
    var discoveryManager = DiscoveryManager()
    let queue = OperationQueue.init()
    
    //
    let pairHostListSubject = CurrentValueSubject<[TemporaryHost], Never>([])
    let netHostListSubject = CurrentValueSubject<[TemporaryHost], Never>([])
    //
    var allHosts:NSMutableArray = NSMutableArray()
    var pairedHosts:[TemporaryHost] = [TemporaryHost]()
    var netHosts:[TemporaryHost] = [TemporaryHost]()
    //Reflashing
    var isReflashing:Bool = false
    
    var selectedHost:TemporaryHost?
    var selectedIndex:Int = 0
    var hasNetwork:Bool = true
    var timer:Timer?
    
    //Should snow a loading circle like Moonlight does for the first 10 seconds
    var showFirstLoading:Bool = true
    
    //first check network
    private var firstCheckNetwork:Bool = true
    
    //if check differentCount == 3 , update share db
    private var differentCount:Int = 0
    
    @objc var dismissLoadingViewCallBack : (()->Void)?
    @objc var showLoadingViewCallBack : (()->Void)?
    //if is unpairing , wait
    private var isUnpairing:Bool = false
    
    fileprivate var bag = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        NetworkMonitor.shared.startMonitoring()
        
        NetworkMonitor.shared.hasNetSubject.debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { conneted in
                
                //update ExternalIP
                self.updateExternalIP()
                
                self.hasNetwork = conneted
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    if conneted == false {
                        self.allHosts = NSMutableArray.init()
                        self.pairedHosts = [TemporaryHost]()
                        self.netHosts = [TemporaryHost]()
                    }
                    
                    //Not first check network
                    if self.firstCheckNetwork != true {
                        self.restartDiscovery()
                    }
                    
                    self.firstCheckNetwork = false
                    
                })

            }
            .store(in: &bag)
        
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] noti in
            //进入后台停止搜索host
            self?.stopDiscovery()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] noti in
            //已经restart discovery 时候调用过，所以不需要再单独调用start timer
        }
        
        loadSharedDBUI()
    }
    
    deinit {
        NetworkMonitor.shared.stopMonitoring()
        timer?.invalidate()
        timer = nil
    }
    
    lazy var hostConnetingView : UIView = {
        let view = UIView.init()
        view.isHidden = false
        view.backgroundColor = Color.hex(0x000000, alpha: 0.5).uiColor()
        let title = SettingsRouter.titleLab("Connecting…".localize())
        title.font = UIFont.systemFont(ofSize: 18)
        
        let des = SettingsRouter.desLab("Please ensure Razer Cortex is running on the same network.".localize(), 14)
        
        let indicator = UIActivityIndicatorView.init(style: .large)
        indicator.color = .gray
        indicator.startAnimating()
        
        view.addSubview(title)
        view.addSubview(des)
        view.addSubview(indicator)
        
        title.snp.makeConstraints { make in
            make.bottom.equalTo(des.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
        
        des.snp.makeConstraints { make in
            make.width.equalTo(400.0)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
        
        indicator.snp.makeConstraints { make in
            make.top.equalTo(des.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.width.equalTo(60.0)
        }
        return view
    }()
    
    func showHostConnetingView(){
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(self.hostConnetingView)
            self.hostConnetingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    func removeHostConnectingView(){
        self.hostConnetingView.removeFromSuperview()
    }
    
}

//MARK: - Pair / Unpair
extension HostListManger {
    
    @objc func pairNetHost(_ host:TemporaryHost) {
        
        DDLogInfo("=====pair host ======")
        let httpManger = HttpManager.init(host: host)
//        let uuid:String = UIDevice.current.identifierForVendor?.uuidString ?? "" + "\(Date.timeIntervalSinceReferenceDate)"
//        httpManger?.setuniqueId(uuid)
        selectedHost = host
        pairManager = PairManager.init(manager: httpManger, clientCert: CryptoManager.readCertFromFile(), callback: self)
        queue.addOperation(pairManager)
        
    }
    
    
    @objc func unpairNetHost(_ host:TemporaryHost) {
        
        if isUnpairing == true {
            return
        }
        isUnpairing = true
        
        DDLogInfo("=====unpair host ======")
        print("=====unpair host:\(host.name) ======")
        ShareDataDB.shared().writeManuallyUnpairedHostDataToshareDB(host.uuid)
        host.pairState = .unpaired
        host.serverCert = Data()
        let httpManger = HttpManager.init(host:host)
//        let uuid:String = UIDevice.current.identifierForVendor?.uuidString ?? "" + "\(Date.timeIntervalSinceReferenceDate)"
//        httpManger?.setuniqueId(uuid)
        httpManger?.executeRequestSynchronously(HttpRequest(urlRequest: httpManger?.newUnpairRequest()))
        discoveryManager.removeHost(fromDiscovery: host)
        SettingsRouter.shared.dataManager.remove(host)
        //ShareDataDB.shared().wirteHostListDataToShare()
        ShareDataDB.shared().removePairedHostFromeShare(host)
        restartDiscovery()
        
        isUnpairing = false
    }
    
}


//MARK: - start // stop
extension HostListManger {

    //MARK: - start
    @objc func startDiscovery() {
        
        if !RzUtils.isGrantedLocalNetworkPermission() {
            //用于禁止在引导页时候，系统本地网络权限弹窗
            Logger.warning("Nexus local network permission is not granted. Disable mdns...")
            return
        }
        
        Logger.info("start mdns...")
        ShareDataDB.shared().readHostListDataFromeShare()
        let pairedHosts = NSMutableArray.init(array: SettingsRouter.shared.dataManager.getHosts().filter( { (host) -> Bool in
            var result = false
            if let localHost = host as? TemporaryHost {
                result = localHost.pairState == .paired
            }
            return result
        }))
        
        discoveryManager = DiscoveryManager(hosts: pairedHosts as? [Any], andCallback: self)
        discoveryManager.startDiscovery()
        startTimer()
    }
    
    //MARK: - stop
    @objc func stopDiscovery() {
        stopTimer()
        discoveryManager.stopDiscovery()
    }
    
    //MARK: - restart
    @objc func restartDiscovery() {
        stopDiscovery()
        startDiscovery()
    }
    
    func startTimer(){
        
        print("===== start timer ======")
        
        timer = Timer(timeInterval: checkTimeInterval, repeats: true, block: { t in
            self.updateUI()
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + checkTimeInterval ) {
            if let checkTimer = self.timer {
                RunLoop.current.add(checkTimer, forMode: .default)
            }
            //set fisrt loading false
            if self.showFirstLoading {
                self.showFirstLoading = false
            }
        }
    }
    
    func stopTimer(){
        print("===== stop timer ======")
        self.isReflashing = false
        self.differentCount = 0
        self.timer?.invalidate()
    }
    
    func updateUI(){
        if self.isReflashing {
            return
        }
        self.isReflashing = true
        
        let pairedHostsCopy = self.pairedHosts
        
        self.pairedHosts = [TemporaryHost]()
        self.netHosts = [TemporaryHost]()
        
        for host in self.allHosts {
            if let tmpHost = host as? TemporaryHost {
                if tmpHost.pairState == .paired {
                    self.pairedHosts.append(tmpHost)
                }else if tmpHost.state != .offline  &&  tmpHost.pairState != .paired {
                    self.netHosts.append(tmpHost)
                }
            }
        }
        
        for host in pairedHostsCopy {
            if self.netHosts.contains(where: {$0.uuid == host.uuid}) {
                print("unpair share hosts count :\(pairedHostsCopy.count) writeManuallyUnpairedHostDataToshareDB")
                ShareDataDB.shared().writeManuallyUnpairedHostDataToshareDB(host.uuid)
            }
        }
        

        let sortedPairHostList = self.pairedHosts.sorted{ $0.name < $1.name}
        self.pairedHosts = sortedPairHostList
        
        let sortedNetHostList = self.netHosts.sorted{ $0.name < $1.name}
        self.netHosts = sortedNetHostList
        
        //check pair hosts if changed  YES:save data to sharedb
        let shareHostList = ShareDataDB.shared().getShareHostList()
        if shareHostList.count != self.pairedHosts.count {
            if self.differentCount < DifferentCountMax {
                self.differentCount = self.differentCount + 1
            }else{
                self.differentCount = 0
                print("different share hosts count :\(shareHostList.count) , paired host count :\(self.pairedHosts.count)")
                ShareDataDB.shared().wirteHostListDataToShare()
            }
        }else{
            self.differentCount = 0
        }
        
        //self.reloadContentView()
        DispatchQueue.main.async {
            self.pairHostListSubject.send(self.pairedHosts)
            self.netHostListSubject.send(self.netHosts)
        }
        self.isReflashing = false
    }
    
    func loadSharedDBUI(){
        ShareDataDB.shared().readHostListDataFromeShare()
        let pairedHosts = NSMutableArray.init(array: SettingsRouter.shared.dataManager.getHosts().filter( { (host) -> Bool in
            var result = false
            if let localHost = host as? TemporaryHost {
                result = localHost.pairState == .paired
            }
            return result
        }))
        
        DispatchQueue.main.async {
            if (pairedHosts.count > 0){
                self.updateAllHosts(pairedHosts as? [Any])
            }
        }
    }
}

//MARK: - DiscoveryCallback
extension HostListManger : DiscoveryCallback {
    
    func updateAllHosts(_ hosts: [Any]!) {
        
        allHosts = NSMutableArray.init(array: hosts)
        pairedHosts = [TemporaryHost]()
        netHosts = [TemporaryHost]()
        
        for host in allHosts {
            if let tmpHost = host as? TemporaryHost {
                if tmpHost.pairState == .paired {
                    pairedHosts.append(tmpHost)
                }else if  (tmpHost.state == .online  || tmpHost.state == .unknown )  &&  tmpHost.pairState != .paired {
                    netHosts.append(tmpHost)
                }
            }
        }
        
        let sortedPairHostList = self.pairedHosts.sorted{ $0.name < $1.name}
        self.pairedHosts = sortedPairHostList
        
        let sortedNetHostList = self.netHosts.sorted{ $0.name < $1.name}
        self.netHosts = sortedNetHostList
        
        DispatchQueue.main.async {
            //self.reloadContentView()
            self.pairHostListSubject.send(self.pairedHosts)
            self.netHostListSubject.send(self.netHosts)
        }
    }
}

//MARK: - PairCallback
extension HostListManger : PairCallback {
    
    func startPairing(_ PIN: String!) {
        DispatchQueue.main.async { [self] in
            SettingsRouter.shared.showHostPairAlert(pin: PIN, hostName: selectedHost?.name ?? "")
        }
    }
    
    func pairSuccessful(_ serverCert: Data!) {
        
        selectedHost?.serverCert = serverCert
        selectedHost?.pairState = .paired
        SettingsRouter.shared.dataManager.update(selectedHost)
        ShareDataDB.shared().wirteHostListDataToShare()
        
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [self] in
            SettingsRouter.shared.closePairAlertView()
            showLoadingViewCallBack?()
            restartDiscovery()
        })
    }
    
    func pairFailed(_ message: String!) {
        DispatchQueue.main.async {
            SettingsRouter.shared.closePairAlertView()
            let alertVC = UIAlertController(title: "Pairing Failed".localize(), message: message, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction.init(title: "OK".localize(), style: .cancel))
            UIApplication.shared.keyWindow?.rootViewController?.present(alertVC, animated: true)
        }
    }
    
    func alreadyPaired() {
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [self] in
            SettingsRouter.shared.closePairAlertView()
            restartDiscovery()
        })
    }
}


extension HostListManger {
    
    func getExternalIp() -> String? {
        if (NetworkMonitor.shared.isWifi) {
            var url = URL(string: "https://razerid.razer.com/api/geoip/geoip/city")
            do {
                if let url = url {
                  let data = try Data.init(contentsOf: url)
                    if let addressModel:PublicAddressModel = PublicAddressModel.yy_model(withJSON: data) {
                        return addressModel.ip_address
                    }
                }
            } catch let error {
                print(error)
            }
            
            url = URL(string: "https://ipinfo.io/ip")//https://myexternalip.com/raw
            do {
                if let url = url {
                    return try String(contentsOf: url)
                }
            } catch let error {
                print(error)
            }
            
            return nil
        } else {
            Logger.error("Device is not in a local network")
            return nil
        }
    }
    
    func updateExternalIP(){
        DispatchQueue.global().async {
            if let externalIp = self.getExternalIp() {
                DDLogInfo("==== Latest ExternalIp:\(externalIp) ==== ")
                UserDefaults.standard.set(externalIp, forKey: External_IP)
            }
        }
    }
    
    func externalIP()->String{
        if let ip = UserDefaults.standard.value(forKey: External_IP) as? String {
            return ip
        }
        return ""
    }

}


//use for get public ip
@objc class PublicAddressModel: NSObject, YYModel {
    @objc var ip_address: String = ""
    @objc var city_name: String = ""
    @objc var country_name: String = ""
    @objc var latitude: Double = 0.0
    @objc var longitude: Double = 0.0
    @objc var accuracy_radius: Double = 0.0
    @objc var time_zone: String = ""
    @objc var postal_code: String = ""
}
