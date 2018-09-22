//
//  Bundle+Extension.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/8.
//

import Foundation

extension Bundle {
    
    public static var chatAssetBundle: Bundle {
        let podBundle = Bundle(for: MessagesViewController.self)
        
        guard let resourceBundleUrl = podBundle.url(forResource: "ZebraKingAssets", withExtension: "bundle") else {
            fatalError("资源Bundle的路径不对")
        }
        
        guard let resourceBundle = Bundle(url: resourceBundleUrl) else {
            fatalError("资源Bundle没有找到")
        }
        
        return resourceBundle
    }
    
    public static var displayName: String {
        if let infoDictionary = Bundle.main.infoDictionary {
            CFShow(infoDictionary as CFTypeRef)
            if let appName = infoDictionary["CFBundleDisplayName"] {
                return appName as! String
            }
        }
        return "此App"
    }
}
