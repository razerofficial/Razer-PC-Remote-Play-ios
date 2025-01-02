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
import UIKit
import CocoaLumberjack
import FirebaseCrashlytics

class BiancaLogger{
    
    public static var shared = BiancaLogger()
    
    private init(){
        
    }
    
    public func logInfo(_ msg:String){
        DDLogInfo(msg)
    }
}

#if DEBUG
    let Log_Level: DDLogLevel = DDLogLevel.verbose;
#else
    let Log_Level: DDLogLevel = DDLogLevel.info;
#endif
/// Output logs for each level
final class Logger {
    ///Verbose level log
    static func verbose(_ msg:String) {
        DDLogVerbose("Verbose: "+msg)
    }
    
    ///Debug level log
    static func debug(_ msg:String) {
        DDLogDebug("Debug: "+msg)
    }
    
    ///Info level log
    static func info(_ msg:String) {
        DDLogInfo("Info: "+msg)
        Crashlytics.crashlytics().log("Info: "+msg)
    }
    
    ///warning level log
    static func warning(_ msg:String) {
        DDLogWarn("⚠️ Warning: "+msg)
        Crashlytics.crashlytics().log("⚠️ Warning: "+msg)
    }
    
    ///error level log
    static func error(_ msg:String) {
        DDLogError("🛑 Error: "+msg)
        Crashlytics.crashlytics().log("🛑 Error: "+msg)
    }
}

extension FileManager {
    class func allFiles(folder:String, filter: String) -> [URL]? {
        let url = URL(fileURLWithPath: folder)
        var files = [URL]()
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        files.append(fileURL)
                    }
                } catch {
                    print(error, fileURL)
                    return nil
                }
            }
        }
        return files.filter{ $0.pathExtension == filter || $0.lastPathComponent == filter}
    }
    
    //Screenshot used
    func documentDirectory() -> URL {
        return self.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getScreenShotFolderURL() -> URL {
        let path = documentDirectory().appendingPathComponent("ScreenshotFolder")

        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            try! FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return path
    }
    
    func saveScreenshotImage(photoData:Data?, fileName:String) {
        let fileURL = getScreenShotFolderURL().appendingPathComponent(fileName)
        if let data = photoData,!FileManager.default.fileExists(atPath: fileURL.path){
            saveFileToPath(data: data, path: fileURL)
        }
    }
    
    func loadScreenshotImage(fileName:String) -> UIImage? {
        let fileURL = getScreenShotFolderURL().appendingPathComponent(fileName)
        Logger.info("FileManager loadScreenshotImage, fileURL = \(fileURL)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            guard let image = UIImage(contentsOfFile: fileURL.path) else {
                Logger.error("FileManager loadScreenshotImage, fileName = \(fileName), fail")
                return nil
            }
            Logger.info("FileManager loadScreenshotImage, fileName = \(fileName), success")
            return image
        }
        Logger.error("FileManager loadScreenshotImage, fileName = \(fileName), file is not exist")
        return nil
    }
    
    func deleteScreenshotImage(fileName:String) {
        let fileURL = getScreenShotFolderURL().appendingPathComponent(fileName)
        Logger.info("FileManager deleteScreenshotImage, fileURL = \(fileURL)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                Logger.info("FileManager deleteScreenshotImage, fileName = \(fileName), success")
                return
            } catch let error {
                Logger.error("FileManager deleteScreenshotImage, fileName = \(fileName), fail:\(error.localizedDescription)")
            }
        }
    }
    
    func saveFileToPath(data:Data, path:URL) {
        let fileURL = path
        Logger.info("FileManager saveScreenshotImage, fileURL = \(fileURL)")
        do {
            try data.write(to: fileURL)
            Logger.info("FileManager saveFileToPath, file saved")
        } catch {
            Logger.error("FileManager saveFileToPath, error saving file")
        }
    }
    
    ////Record used
    func getRecordingFolderURL() -> URL {
        let groupURL = self.containerURL(forSecurityApplicationGroupIdentifier: ScreencastConfig.AppGroupkey)
        let path = groupURL!.appendingPathComponent("Recording")
        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            Logger.error("ScreenCastExtension Unable to create directory: \(error.localizedDescription)")
        }
        return path
    }
    
    func deleteRecording(fileName:String) {
        let fileURL = getRecordingFolderURL().appendingPathComponent(fileName)
        Logger.info("FileManager deleteRecording, fileURL = \(fileURL)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                Logger.info("FileManager deleteRecording, fileName = \(fileName), success")
                return
            } catch let error {
                Logger.error("FileManager deleteRecording, fileName = \(fileName), fail:\(error.localizedDescription)")
            }
        }
    }
    
    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            Logger.error("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }
}
