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
import StoreKit
import SwiftUI
import CocoaLumberjack
import UIKit

class AppStoreReviewHandler: NSObject {
    private struct UserDefaultsKeys {
        static let gameStreamingCountKey = "gameStreamingCountKey"
        static let isPromptedForReviewKey = "isPromptedForReviewKey"
        static let isNormalFinishStreamingLastTime = "isNormalFinishStreamingLastTime"
        static let isLuanchFromStreaming = "isLuanchFromStreaming"
    }
    
    @objc static let shared = AppStoreReviewHandler()
    
    private override init() {}
    
    private func requestReview() {
        printLog("requestReview")
        
        //Double check
        if !isAppReviewShowBefore() {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                if #available(iOS 14.0, *) {
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                        self.setAppReviewShowBefore()
                    }
                } else {
                    SKStoreReviewController.requestReview()
                    self.setAppReviewShowBefore()
               }
            }
        }
    }
    
    private func requestReviewManually() {
      let url = "https://apps.apple.com/app/id1565916457?action=write-review"
      guard let writeReviewURL = URL(string: url)
          else { fatalError("Expected a valid URL") }
      UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
    
    private func printLog(_ msg:String) {
        print("AppStoreReviewHandler - " + msg)
    }
    
    private func getAppVersion() -> String {
        if let versionno = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return versionno
        }
        return "No App Version"
    }
    /**
            These value should be download from Firebase remote config
            "is_request_app_review": false,
            "request_app_review_mode": foreground_count_and_usage
            "max_session_gap_ms": 15000,
            "min_session_duration_ms": 3000,
            "min_session_count_before_app_review": 2,
            "idle_timer_ms": 5000
            "min_foregrounds_before_app_review":4
            "min_game_launch_before_app_review":2
            "min_days_after_first_launch_before_app_review":1
     */

    //good_session_min_duration = 10min
    private let good_session_min_duration:Double = 60*10 //sec
//    private let good_session_min_duration:Double = 30 //for testing
    private var appStartStreamingDate: Date?
    
    @objc func checkIsStartAppReiew() {
        printLog("checkIsStartAppReiew")
        if isShowAppReview() {
            requestReview()
        }
    }

    private func isAppReviewShowBefore() -> Bool {
        let isAppReviewShowBefore = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isPromptedForReviewKey)
        printLog("isAppReviewShowBefore():\(isAppReviewShowBefore)")
        return isAppReviewShowBefore
    }
    
    private func setAppReviewShowBefore() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isPromptedForReviewKey)
        UserDefaults.standard.synchronize()
    }
    
    private func getGameLaunchCount() -> Int {
        let count = UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameStreamingCountKey)
        printLog("getGameLaunchCount:\(count)")
        return count
    }
    
    @objc func startGameStreaming() {
        printLog("startGameStreaming()")
        appStartStreamingDate = Date()
    }
    
    @objc func endGameStreaming() {
        printLog("endGameStreaming()")

        if let date = appStartStreamingDate {
            let interval: Double = Date().timeIntervalSince(date) //Second
            printLog("endGameStreaming, interval:\(interval)")
            if interval > good_session_min_duration {
                increaseGameLaunchCount()
            }
        }
    }
    
    @objc func markNormalFinishStreaming(normal:Bool) {
        printLog("isNormalFinishStreamingLastTime, value:\(normal ? "true" : "false")")
        UserDefaults.standard.set(normal, forKey: UserDefaultsKeys.isNormalFinishStreamingLastTime)
        UserDefaults.standard.synchronize()
    }
    
    @objc func markLuanchFromStreaming(launch:Bool) {
        printLog("isLuanchFromStreaming, value:\(launch ? "true" : "false")")
        UserDefaults.standard.set(launch, forKey: UserDefaultsKeys.isLuanchFromStreaming)
        UserDefaults.standard.synchronize()
    }
    
    private func isLuanchFromStreaming() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.isLuanchFromStreaming)
    }
    
    private func increaseGameLaunchCount() {
        let count = UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameStreamingCountKey)
        printLog("increaseForegroundsCount:\(count) to \(count+1)")
        UserDefaults.standard.set(count+1, forKey: UserDefaultsKeys.gameStreamingCountKey)
        UserDefaults.standard.synchronize()
    }
    
    private func checkGameLaunchCount() -> Bool {
        let count = UserDefaults.standard.integer(forKey: UserDefaultsKeys.gameStreamingCountKey)
        printLog("checkGameLaunchCount:count:\(count)")
        if count > 0 {
            return true
        }
        return false
    }
    
    private func isNormalFinishStreamingLastTime() -> Bool {
        if UserDefaults.standard.value(forKey: UserDefaultsKeys.isNormalFinishStreamingLastTime) == nil {
            return true
        }else{
            return UserDefaults.standard.bool(forKey: UserDefaultsKeys.isNormalFinishStreamingLastTime)
        }
    }
    
    private func isShowAppReview() -> Bool {
        printLog("func isShowAppReview ")
        
        if isLuanchFromStreaming() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.markLuanchFromStreaming(launch: false)
            }
            return false
        }
        
        if isNormalFinishStreamingLastTime() == false {
            return false
        }
        
        if isAppReviewShowBefore() {
            return false
        }
        
        if checkGameLaunchCount() {
            return true
        }
        
        return false
    }
}
