//
//  IMTimeTipCell.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import UIKit
import ImSDK
import IMMessageExt

final class IMTimeTipCell: IMBaseCell {
    
    var timeLab: EdgeLabel = {
        let timeLab = EdgeLabel(frame: CGRect.zero)
        timeLab.inset = CGSize(width: .kChatTimeLabelPaddingLeft, height: .kChatTimeLabelPaddingTop)
        timeLab.textColor = .white
        timeLab.backgroundColor = UIColor(hexString: "#D6D6D6")
        timeLab.font = UIFont.systemFont(ofSize: 11)
        timeLab.layer.cornerRadius = 2
        timeLab.layer.masksToBounds = true
        return timeLab
    }()
  
    override func createView() {
        addSubview(timeLab)
        timeLab.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
    }
    
    override func configContentView(_ model: IMMessage, receiver: IMUserUnit) {
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        if let element = model.msg.getElem(0) as? TIMCustomElem,
            let data = element.data,
            let date = NSKeyedUnarchiver.unarchiveObject(with: data) as? Date {
            self.timeLab.text = date.chatTimeToString
        }
    }
    
    class func layoutHeight(_ model: IMMessage) -> CGFloat {
        return 40
    }
    
}

class EdgeLabel: UILabel {
    
    var inset: CGSize = .zero
    
    override var text: String? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let originaSize = super.intrinsicContentSize
        let size = CGSize(width: originaSize.width + inset.width, height: originaSize.height + inset.height)
        return size
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textAlignment = .center
    }
    
    init() {
        super.init(frame: .zero)
        textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) { return nil }
}

