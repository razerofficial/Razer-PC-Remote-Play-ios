/*
* Copyright (C) 2025 Razer Inc.
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
import YYModel

@objc class NeuronEvent: NSObject, YYModel {
    @objc var eventId: String = ""
    @objc var timestamp: Int64 = 0
    @objc var eventAction: String = ""
    @objc var eventLabel: String = ""
    @objc var dimension: [String: Any] = [:]
    
    @objc static func createEvent(eventAction: String, eventLabel: String, dimension: [String: Any]) -> NeuronEvent {
        let event = NeuronEvent()
        event.eventId = UUID().uuidString
        event.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        event.eventLabel = eventLabel
        event.eventAction = eventAction
        event.dimension = dimension
        return event
    }
}
