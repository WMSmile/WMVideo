//
//  FileTools.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/26.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit

class WMCameraFileTools: NSObject {
    
    /// get temp Directory
    ///
    /// - Returns: String  Directory Path
    class func wm_getDirectory() -> String {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        let resourceDir = path! + "/Resource/"
        return resourceDir
    }

    /// get save File Url
    ///
    /// - Parameter type: file type eg: mov jpg
    /// - Returns: String
    class func wm_createFileUrl(_ type: String) -> String {
        let formate = DateFormatter()
        formate.dateFormat = "yyyyMMddHHmmss"
        let fileName = formate.string(from: Date()) + "." + type
        let resourceDir = wm_getDirectory()
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: resourceDir){
            do {
                try fileManager.createDirectory(atPath: resourceDir, withIntermediateDirectories: true, attributes: [:])
            } catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        }
        let filePath = resourceDir + fileName
        return filePath
       
    }
    
    /// clear all cache
    class func wm_clearAllFiles() -> Void {
        let resourceDir = wm_getDirectory()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: resourceDir){
            do {
                try fileManager.removeItem(atPath: resourceDir)
            }
            catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        }
    }
    
    /// get all files
    ///
    /// - Returns: [String]
    class func wm_getAllfiles() -> [String] {
        var list:[String] = []
        let resourceDir = wm_getDirectory()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: resourceDir){
            do {
                try list = fileManager.contentsOfDirectory(atPath: resourceDir)
            } catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        }
        return list
    }
    
    
   


    

}
