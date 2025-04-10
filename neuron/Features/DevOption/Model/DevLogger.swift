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

class DevLogger : NSObject {
    
    @objc static let shared = DevLogger()
    private let writeLogQueue:OperationQueue = OperationQueue.init()
    private let fileManager = FileManager.default
    private var logPath:String = ""
    private var fileHandle:FileHandle?
    private var queueLock = os_unfair_lock()
  
    override init() {
        writeLogQueue.maxConcurrentOperationCount = 1
//        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//            logPath = documentsDirectory.appendingPathComponent(shareLogPath).path
//        }
        logPath = ShareDataDB.shared().fileUrl(fromGroup: shareLogPath).path
    }
    
    func lock(){
        os_unfair_lock_lock(&queueLock)
    }
    
    func unLock(){
        os_unfair_lock_unlock(&queueLock)
    }
    
    func appendLog(text: String) {
        writeLogQueue.addOperation {
            //加锁
            self.lock()
            self.appendTextToFile(text: text , filePath: self.logPath)
            //解锁
            self.unLock()
        }
    }
    
    func cleanLog(){
        
        writeLogQueue.addOperation {
//            self.fileHandle?.truncateFile(atOffset: 0)
            do {
                // 打开文件以进行写入
                let fileHandle = try FileHandle(forWritingAtPath: self.logPath)
                
                //加锁
                self.lock()
                // 将文件大小截断为 0 字节
                fileHandle?.truncateFile(atOffset: 0)
                
                // 关闭文件句柄
                fileHandle?.closeFile()
                
                //解锁
                self.unLock()
                
                //print("文件内容已清空")
            } catch {
                print("清空文件内容时发生错误: \(error)")
            }
        }
        
    }
    
    func appendTextToFile(text: String, filePath: String) {
        
        if text.isEmpty {
            print("文本为空")
            return
        }
        
        // 将字符串转换为 Data 对象
        guard let data = (Date.now.toString(withFormat: "yyyy-MM-dd HH:mm:ss") + " " + text + "\n").data(using: .utf8) else {
            print("无法将文本转换为数据")
            return
        }
        
        if !fileManager.fileExists(atPath: filePath) {
            // 如果文件不存在，则创建一个空文件
            fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
        }
                
        // 打开文件以追加模式写入
        if let fileHandle = FileHandle(forWritingAtPath: filePath) {
            // 移动到文件末尾
            fileHandle.seekToEndOfFile()
            // 写入数据
            fileHandle.write(data)
            
            // 关闭文件句柄
            fileHandle.closeFile()
            
            //print("成功追加写入内容！")
        } else {
            print("无法打开文件进行写入")
        }
        
    }
    
    func path() ->String {
        return logPath
    }
    
}
