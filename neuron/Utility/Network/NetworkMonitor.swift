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

import Network
import Combine
import UIKit
import SystemConfiguration

typealias StateChangeBlock = (Bool) -> Void

func getWiFiAddress() -> String? {
    var address: String?
    
    // Get list of all interfaces on the local machine:
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }
    
    // For each interface ...
    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let flags = Int32(ptr.pointee.ifa_flags)
        let addr = ptr.pointee.ifa_addr.pointee
        
        // Check for IPv4 or IPv6 interface:
        let isIPv4 = addr.sa_family == UInt8(AF_INET)
        if isIPv4 {
            // Check if interface is en0 which is the Wi-Fi connection on the iPhone
            let name: String = String(cString: ptr.pointee.ifa_name)
            if name == "en0" {
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                    address = String(cString: hostname)
                }
            }
        }
    }
    freeifaddrs(ifaddr)
    
    return address
}

func isWifiAndSameLocalAddress(_ address:String) -> Bool {
    if NetworkMonitor.shared.isWifi == false {
        return false
    }
    var same:Bool = true
    let localAddress = getWiFiAddress()
    let localStrArray = localAddress?.components(separatedBy: ".")
    //NSLog("local ip: \(localAddress) , manualy address: \(address)")
    let addresdStrArray = address.components(separatedBy: ".")
    if localStrArray?.count ?? 0 < 4 || addresdStrArray.count < 4 {
        return false
    }
    
    for index in 0...2 {
        if localStrArray?[safe:index] != addresdStrArray[safe:index] {
            same = false
            break
        }
    }
    return same
}

@objc class NetworkMonitor : NSObject {
    @objc static let shared:NetworkMonitor = NetworkMonitor()
    private var monitor: NWPathMonitor?
    private var isMonitoring = false
    
    
    let netSubject = CurrentValueSubject<(Bool , Bool), Never>((true,true))
    var hasNet:Bool = true
    //use for externalIP update
    @objc var isWifi:Bool = true
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        monitor = NWPathMonitor()
        //self.onStateChange = onStateChange
 
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor?.start(queue: queue)
 
        monitor?.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                print("Connected to the internet")
                
                if path.usesInterfaceType(.wifi) {
                    print("Reachable via WiFi")
                    self?.isWifi = true
                }else{
                    self?.isWifi = false
                }
                
                self?.hasNet = true
                let netState = (true, self?.isWifi ?? false)
                self?.netSubject.send(netState)
                
            } else {
                print("No internet connection")
                self?.isWifi = false
                self?.hasNet = false
                let netState = (false, false)
                self?.netSubject.send(netState)
            }
 
            print("Is Expensive: \(path.isExpensive)") // True if the path is using an expensive connection
        }
 
        isMonitoring = true
    }
 
    func stopMonitoring() {
        guard isMonitoring, let monitor = monitor else { return }
        monitor.cancel()
        self.monitor = nil
        isMonitoring = false
    }
}
