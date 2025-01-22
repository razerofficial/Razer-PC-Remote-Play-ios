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
import YYModel
import SwiftUI

@objc class NeuronFrameSettings: NSObject, Codable, YYModel, ObservableObject  {
    
    @objc var bitrate: Int32 = 30000
    @objc var framerate: Int32 = Int32(UIScreen.main.maximumFramesPerSecond)
    @objc var height: Int32 = Int32(Resolution.resolutionFull.resolutionSize().height)
    @objc var width: Int32 = Int32(Resolution.resolutionFull.resolutionSize().width)
    @objc var audioConfig: Int32 = 2
    @objc var onscreenControls: RZOnScreenControls = .off
    
    @objc var uniqueId: String = "\(arc4random())"
    @objc var preferredCodec: RZPreferredCodec = .Hevc
    
    @objc var useFramePacing: Bool = false
    @objc var multiController: Bool = false
    @objc var swapABXYButtons: Bool = false
    @objc var playAudioOnPC: Bool = false
    @objc var optimizeGames: Bool = true
    @objc var enableHdr: Bool = false
    @objc var btMouseSupport: Bool = false
    @objc var absoluteTouchMode: Bool = true
    @objc var statsOverlay: Bool = false
    @objc var displayMode: Int = isShowSeparateScreenDisplayMode ? 1 : 2
    @objc var videoRefreshRate: Int = 0
    @objc var automaticallyConfigureGameSettings: Bool = true
    @objc var timeToTerminateApp: Int = 30
    
    override init() {
        super.init()
    }
    
}
