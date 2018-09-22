//
//  PathUtility.swift
//  IMDemo
//
//  Created by 武飞跃 on 2017/7/18.
//  Copyright © 2017年 ZebraKing. All rights reserved.
//

import Foundation

public struct PathUtility {
    public static func getCachePath() -> String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }
    
    public static func isExistFile(path:String) -> Bool {
        guard !path.isEmpty else{ return false }
        return FileManager.default.fileExists(atPath: path)
    }
    
    public static func createDirectory(atCache dirName: String) -> Bool{
        let dirPath = getFileCachePath(fileName: dirName)
        if FileManager.default.fileExists(atPath: dirPath) {
            return true
        }
        do {
         try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        }catch {
            return false
        }
        return true
    }
    
    private static func getFileCachePath(fileName: String) -> String{
        let path = getCachePath()
        return NSString(string: path).appendingPathComponent(fileName)
    }
    
}


