//
//  IMChatAudioFileManager.swift
//  BMKP
//
//  Created by gongjie on 2017/7/19.
//  Copyright © 2017年 bmkp. All rights reserved.
//

import UIKit

//MARK:   录音文件文件管理类
private let audioFileTypeWav = "wav"
private let kAmrRecordFolder = "ChatAudioAmrRecord"   //存 amr 的文件目录名
private let kWavRecordFolder = "ChatAudioWavRecord"  //存 wav 的文件目录名

class IMChatAudioFileManager: IMChatAudioManager {
    
    /**
     创建录音的文件夹
     */
    @discardableResult
    class fileprivate func createAudioFolder(_ folderName :String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(folderName)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: folder.absoluteString) {
            try? fileManager.createDirectory(atPath: folder.path, withIntermediateDirectories: true, attributes: nil)
            return folder
        }
        return folder
    }
    
    
    /**
     创建录音的文件夹, amr 格式
     */
    fileprivate class var amrFilesFolder: URL {
        get { return self.createAudioFolder(kAmrRecordFolder)}
    }
    
    
    /**
     创建录音的文件夹, wav 格式
     */
    fileprivate class var wavFilesFolder: URL {
        get { return self.createAudioFolder(kWavRecordFolder)}
    }
    
    
    /**
     删除目标文件
     */
    fileprivate class func deleteFilesWithPath(_ path: String) {
        let fileManager = FileManager.default
        let files = try? fileManager.contentsOfDirectory(atPath: path)
        guard let recordings = files?.filter( { name in return name.hasSuffix(audioFileTypeWav) }) else { return }
        
        for i in 0 ..< recordings.count {
            let path = path + "/" + recordings[i]
            try? fileManager.removeItem(atPath: path)
        }
    }
    
    /**
     删除所有录音文件
     */
    class func deleteAllRecordingFiles() {
        self.deleteFilesWithPath(self.amrFilesFolder.path)
        self.deleteFilesWithPath(self.wavFilesFolder.path)
    }
}
