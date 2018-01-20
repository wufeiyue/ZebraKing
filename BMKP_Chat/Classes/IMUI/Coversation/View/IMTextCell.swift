//
//  IMTextCell.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation
import UIKit
import YYText
import ImSDK
import IMMessageExt

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
private let kChatTextFont: UIFont = UIFont.systemFont(ofSize: 15) //cell的文字大小
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class IMTextCell: IMBaseCell  {
    
    lazy var contentLab: YYLabel = { [unowned self] in
        let label = YYLabel()
        label.font = kChatTextFont
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.textVerticalAlignment = .top
        label.displaysAsynchronously = false
        label.ignoreCommonProperties = true
        label.highlightTapAction = ({[weak self] containerView, text, range, rect in
            self?.didTapRichLabelText((self?.contentLab)!, textRange: range)
        })
        return label
    }()
    
    
    lazy var bgImg: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func createView() {
        super.createView()
        [bgImg, contentLab].forEach{ contentView.addSubview($0) }
    }
    
    /**
      重写父类设置content方法
     */
    
    override func configContentView(_ model: IMMessage, receiver: IMUserUnit) {
        super.configContentView(model, receiver: receiver)
        if model.isMineMsg {
            if model.status == .create {
                self.retryButton.isHidden = true
                self.activityView.isHidden = true
                self.readStatusLab.isHidden = true
//                printLogDebug("message=======>>>>>init")
            } else if model.status == .sending {
                self.retryButton.isHidden = true
                self.activityView.isHidden = false
                self.readStatusLab.isHidden = true
                self.activityView.startAnimating()
//                printLogDebug("message=======>>>>>sending")
                
            } else if model.status == .sendFail {
                self.retryButton.isHidden = false
                self.activityView.isHidden = true
                self.readStatusLab.isHidden = true
                self.activityView.stopAnimating()
//                printLogDebug("message=======>>>>>failed")
            } else if model.status == .sendSucc {
                self.retryButton.isHidden = true
                self.activityView.isHidden = true
                if receiver.role == .server {
                    self.readStatusLab.isHidden = true
                }
                else {
                    self.readStatusLab.isHidden = false
                }
                self.activityView.stopAnimating()
//                printLogDebug("message=======>>>>>success")
            }
        } else {
            self.retryButton.isHidden = true
            self.activityView.isHidden = true
            self.readStatusLab.isHidden = true
        }
        if let richTextLinePositionModifier = model.richTextLinePositionModifier,
           let richTextLayout = model.richTextLayout,
            let richTextAttributedString = model.richTextAttributedString {
            self.contentLab.linePositionModifier = richTextLinePositionModifier
            self.contentLab.textLayout = richTextLayout
            self.contentLab.attributedText = richTextAttributedString
        }
        let strechImg = model.isMineMsg ? UIImage.init(named: "chat_text-area-blue") : UIImage.init(named: "chat_text-area-white")
        let BGimg = strechImg?.resizableImage(withCapInsets: UIEdgeInsetsMake((strechImg?.size.height)! * 0.7, (strechImg?.size.width)! * 0.5, (strechImg?.size.height)! * 0.3  , (strechImg?.size.width)! * 0.5 )  , resizingMode: .stretch)
        self.bgImg.image = BGimg
        self.msgModel = model
        self.setNeedsLayout()
    }
    
    
    /**
      布局cell样式
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let model = self.msgModel else {
            return
        }
        if let layout = model.richTextLayout {
            self.contentLab.frame.size = layout.textBoundingSize
        }
        if model.isMineMsg {
            self.bgImg.frame.origin.x = UIScreen.main.bounds.size.width - kUserPicMarginLeading - kUserPicWidth - kChatBGImgMaginLeft - max(self.contentLab.frame.size.width + kChatBGWidthBuffer, kChatBGViewWidth)
        }else {
            self.bgImg.frame.origin.x = kChatBGViewLeft
        }
        self.bgImg.frame.origin.y = 0
        self.bgImg.frame.size = CGSize.init(width: max(contentLab.frame.width + kChatBGWidthBuffer,  kChatBGViewWidth), height: max(contentLab.frame.height + kChatBGHeightBuffer, kChatBGViewHeight))
        contentLab.frame.origin.y = self.bgImg.frame.origin.y + kChatTextMarginTop
        contentLab.frame.origin.x = self.bgImg.frame.origin.x + kChatTextMarginLeft
        activityView.center = CGPoint(x: self.bgImg.frame.origin.x - 20, y: self.bgImg.center.y)
        retryButton.center = CGPoint(x: self.bgImg.frame.origin.x - 20, y: self.bgImg.center.y)
        readStatusLab.center = CGPoint(x: self.bgImg.frame.origin.x - 20, y: self.bgImg.center.y)
    }
    
    /**
     解析富文本，计算cell的高度
     */
    class func layoutHeight(_ model: IMMessage) -> CGFloat {
        if model.cellHeight != 0 {
            return model.cellHeight
        }
        //解析富文本
       guard  let elem: TIMTextElem = model.msg.getElem(0) as? TIMTextElem,
        let atrrStr = IMTextParser.parseText(elem.text, font: kChatTextFont, color: (model.isMineMsg ? .white : UIColor(hexString: "#666666")))
       else {
            return 0
        }
        model.richTextAttributedString = atrrStr
        //初始化排版布局对象
        let modifier = IMTextLinePosition(font: kChatTextFont)
        model.richTextLinePositionModifier = modifier
        //初始化YYTextContainer
        let textContainer: YYTextContainer = YYTextContainer()
        textContainer.size = CGSize(width: kChatTextMaxWidth, height: CGFloat.greatestFiniteMagnitude)
        textContainer.linePositionModifier = modifier
        textContainer.maximumNumberOfRows = 0
        //设置layout
        let textLayout = YYTextLayout(container: textContainer, text: atrrStr)
        model.richTextLayout = textLayout
        //计算高度
        var height: CGFloat = kChatTextMarginTop + kChatTextMarginBottom
        let strHeight = modifier.heightForLineCount(Int(textLayout!.rowCount))
        height += max(strHeight + kChatBGHeightBuffer, kChatBGViewHeight)
        model.cellHeight = height
        return model.cellHeight
    }
    
    
    
    /**
     解析点击文字
     
     - parameter label:     YYLabel
     - parameter textRange: 高亮文字的 NSRange，不是 range
     */
    fileprivate func didTapRichLabelText(_ label: YYLabel, textRange: NSRange) {
        //解析 userinfo 的文字
        
        
        
       
    }

    
}
