//
//  IMConst.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/10/28.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public let kUserPicMarginLeading: CGFloat = 8    // 头像的leading距离
public let kUserPicMarginTralling: CGFloat = 0   // 头像的tralling的距离
public let kUserPicWidth: CGFloat = 40           // 头像的长宽
////////////////////////////////////////////////////////////////////////////////////
public let kChatVoiceMaxWidth: CGFloat = 200
/////////////////////////////////////////////////////////////////////////////////////
public let kChatTextLeft: CGFloat = 67 //消息在左边时文字距离屏幕的距离
public let kChatTextMaxWidth: CGFloat = UIScreen.main.bounds.size.width - kChatTextLeft * 2
public let kChatTextMarginLeft: CGFloat = 15 //文字左边距气泡左边的距离  气泡三角距离5
public let kChatTextMarginTop: CGFloat = 12 //文字顶部距离气泡的距离
public let kChatTextMarginBottom: CGFloat = 0 //文字底部距气泡的距离
public let kChatBGImgMaginLeft: CGFloat = 5 //气泡背景和头像的gap值
public let kChatBGViewWidth: CGFloat = 55 //气泡最小的宽度
public let kChatBGViewHeight: CGFloat = 40 //气泡最小高度
public let kChatBGWidthBuffer: CGFloat = kChatTextMarginLeft * 2 //气泡背景比文字的宽度多出的值
public let kChatBGHeightBuffer: CGFloat = kChatTextMarginTop * 2 //气泡背景比文字的高度多出的值
public let kChatBGViewLeft: CGFloat = kUserPicMarginLeading + kUserPicWidth + kChatBGImgMaginLeft //气泡距离屏幕左边的距离
extension CGFloat {
    static let chatActionBarOriginalHeight: CGFloat = 48
    static let kChatTimeLabelPaddingLeft: CGFloat = 10   //左右分别留出 6 像素的留白
    static let kChatTimeLabelPaddingTop: CGFloat = 3     //上下分别留出 3 像素的留白
}

extension UIColor {
    static let themeColor = UIColor(hexString:"#FF7801")
}
