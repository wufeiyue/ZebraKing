//
//  String+Extension.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/11/7.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

extension String {
    /// 转换老的七牛 http 图片地址到 https 地址
    public var qiNiuHttpsUrl: String {
        if hasPrefix("https://") { return self }
        
        // 老的图片地址可能是两个空间的其中一个
        let isBusSpace = contains("7xt8hn.com")
        let isBmkpSpace = contains("7xk6m8.com")
        
        if !isBusSpace && !isBmkpSpace { return self }
        
        guard let endRange = range(of: ".com/") else { return self }
        
        let endString = substring(from: endRange.upperBound)
        var httpsUrl = self
        
        // 一个空间有一个匹配的 https 地址,这里判断替换为哪个空间的 https 地址
        if isBusSpace {
            httpsUrl = "https://oid6vc2bb.qnssl.com/" + endString
        } else {
            httpsUrl = "https://oi7i2zxtu.qnssl.com/" + endString
        }
        return httpsUrl
    }
}
