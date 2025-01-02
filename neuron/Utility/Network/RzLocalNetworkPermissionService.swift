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
import Network
import Combine

//typealias PermissionBlock = () -> Void
//@objc class RzLocalNetworkPermissionService: NSObject {
//    
//    private var port: UInt16 = 1
//    private var interfaces: [String] = []
//    private var connections: [NWConnection] = []
//    private var grant: PermissionBlock?
//    private var failed: PermissionBlock?
//    private var monitor = NetworkMonitor()
//    
//    override init() {
//        super.init()
//        self.interfaces = RzLocalNetworkPermissionService.ipv4AddressesOfEthernetLikeInterfaces()
//    }
//    
//    deinit {
//        stop()
//    }
//    
//    func stop() {
//        connections.forEach { $0.cancel() }
//        monitor.stopMonitoring()
//    }
//    
//    @objc func requestPermissions(grant:PermissionBlock?,failed:PermissionBlock?) {
//        self.grant = grant
//        self.failed = failed
//        self.port = 12345
//        
//        self.monitor.stopMonitoring()
//        self.monitor.startMonitoring { [weak self] status in
//            if status {
//                self?.stop()
//                self?.grant?()
//            }
//        }
//        
//        for interface in interfaces {
//            let host = NWEndpoint.Host(interface)
//            let port = NWEndpoint.Port(integerLiteral: self.port)
//            let connection = NWConnection(host: host, port: port, using: .tcp)
//            connection.stateUpdateHandler = { [weak self, weak connection] state in
//                self?.stateUpdateHandler(state, connection: connection)
//            }
//            connection.start(queue: .main)
//            connections.append(connection)
//        }
//    }
//    
//    // MARK: Private API
//    
//    private func stateUpdateHandler(_ state: NWConnection.State, connection: NWConnection?) {
//        print("state:\(state)")
//        switch state {
//        case .waiting:
//            let content = "H".data(using: .utf8)
//            connection?.send(content: content, completion: .idempotent)
//        default:
//            break
//        }
//    }
//    
//    private static func namesOfEthernetLikeInterfaces() -> [String] {
//        var addrList: UnsafeMutablePointer<ifaddrs>? = nil
//        let err = getifaddrs(&addrList)
//        guard err == 0, let start = addrList else { return [] }
//        defer { freeifaddrs(start) }
//        return sequence(first: start, next: { $0.pointee.ifa_next })
//            .compactMap { i -> String? in
//                guard
//                    let sa = i.pointee.ifa_addr,
//                    sa.pointee.sa_family == AF_LINK,
//                    let data = i.pointee.ifa_data?.assumingMemoryBound(to: if_data.self),
//                    data.pointee.ifi_type == IFT_ETHER
//                else {
//                    return nil
//                }
//                return String(cString: i.pointee.ifa_name)
//            }
//    }
//    
//    private static func ipv4AddressesOfEthernetLikeInterfaces() -> [String] {
//        let interfaces = Set(namesOfEthernetLikeInterfaces())
//        
//        print("Interfaces: \(interfaces)")
//        var addrList: UnsafeMutablePointer<ifaddrs>? = nil
//        let err = getifaddrs(&addrList)
//        guard err == 0, let start = addrList else { return [] }
//        defer { freeifaddrs(start) }
//        return sequence(first: start, next: { $0.pointee.ifa_next })
//            .compactMap { i -> String? in
//                guard
//                    let sa = i.pointee.ifa_addr,
//                    sa.pointee.sa_family == AF_INET
//                else {
//                    return nil
//                }
//                let name = String(cString: i.pointee.ifa_name)
//                guard interfaces.contains(name) else { return nil }
//                var addr = [CChar](repeating: 0, count: Int(NI_MAXHOST))
//                let err = getnameinfo(sa, socklen_t(sa.pointee.sa_len), &addr, socklen_t(addr.count), nil, 0, NI_NUMERICHOST | NI_NUMERICSERV)
//                guard err == 0 else { return nil }
//                let address = String(cString: addr)
//                print("Address: \(address)")
//                return address
//            }
//    }
//    
//    func randomPort() -> UInt16 {
//        return UInt16(Int.random(in: 1...65535))
//    }
//    
//}

@available(iOS 14.0, *)
public class LocalNetworkAuthorization: NSObject {
    private var browser: NWBrowser?
    private var netService: NetService?
    private var completion: ((Bool) -> Void)?
    //private var monitor = NetworkMonitor()
    private var networkPermission: Bool = false
    private var localNetworkPermission: Bool = false
    private var done: Bool = false
    private var lock: NSLock = NSLock()
    fileprivate var bag = Set<AnyCancellable>()
    
    @objc public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        self.networkPermission = false
        self.localNetworkPermission = false
        self.done = false
        
        self.completion = completion
        
        NetworkMonitor.shared.hasNetSubject.debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { status in
                print("network status:\(status)")
                self.networkPermission = status
                self.updateNetworkState()
            }
            .store(in: &bag)
        
//        self.monitor.stopMonitoring()
//        self.monitor.startMonitoring { [weak self] status in
//            print("network status:\(status)")
//            self?.networkPermission = status
//            self?.updateNetworkState()
//        }
        
        // Create parameters, and allow browsing over peer-to-peer link.
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        // Browse for a custom service type.
        let browser = NWBrowser(for: .bonjour(type: "_rzstream._tcp", domain: nil), using: parameters)
        self.browser = browser
        browser.stateUpdateHandler = { newState in
            print("state:\(newState)")
            switch newState {
            case .failed(let error):
                print(error.localizedDescription)
            case .ready:
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5){
                    if self.browser != nil {
                        print("Local network permission has been granted")
                        self.completion?(true)
                    }
                }
                break
            case let .waiting(error):
                print("Local network permission has been denied: \(error)")
                self.reset()
                self.completion?(false)
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { results, changes in
            if !results.isEmpty {
                print("Local network services found or access granted.")
                self.localNetworkPermission = true
                self.updateNetworkState()
            }
        }
        
        self.browser?.start(queue: .main)
    }
    
    deinit {
        reset()
    }
    
    private func updateNetworkState() {
        self.lock.lock()
        print("[updateNetworkState] local:\(localNetworkPermission) network:\(networkPermission) done:\(done)")
        let status = self.networkPermission && self.localNetworkPermission
        if status && !done {
            self.done = true
            self.completion?(status)
            self.reset()
        }
        self.lock.unlock()
    }
    
    private func reset() {
        self.browser?.cancel()
        self.browser = nil
        self.netService?.stop()
        self.netService = nil
    }
}

