//
//  String+Extension.swift
//  Zebra_Example
//
//  Created by 武飞跃 on 2017/11/7.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

extension String {
    
    func height(considering width: CGFloat, and font: UIFont) -> CGFloat {
        
        let constraintBox = CGSize(width: width, height: .greatestFiniteMagnitude)
        let rect = self.boundingRect(with: constraintBox, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return rect.height
        
    }
    
    func width(considering height: CGFloat, and font: UIFont) -> CGFloat {
        
        let constraintBox = CGSize(width: .greatestFiniteMagnitude, height: height)
        let rect = self.boundingRect(with: constraintBox, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return rect.width
        
    }
}
