//
//  SeparatorLine.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import UIKit

open class SeparatorLine: UIView {
    
    // MARK: - Properties
    
    /// The height of the line
    open var height: CGFloat = 0.5 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width, height: height)
    }
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    /// Sets up the default properties
    open func setup() {
        backgroundColor = .lightGray
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
}
