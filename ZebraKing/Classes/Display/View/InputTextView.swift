//
//  InputTextView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/5.
//

import Foundation

open class InputTextView: UITextView {
    
    open var calculateMaxTextViewHeight: CGFloat = 100.0
    
    open override var text: String! {
        didSet {
            placeholdLabel.isHidden = !text.isEmpty
        }
    }
    
    open var placeholder: String? {
        didSet {
            placeholdLabel.text = placeholder
        }
    }
    
    public let placeholdLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.gray
        label.backgroundColor = .clear
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var recordTextViewHeight = RecordTextViewHeight(initValue: 40)
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        
        font = UIFont.preferredFont(forTextStyle: .body)
        textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 4, right: 4)
        scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                             left: .leastNonzeroMagnitude,
                                             bottom: .leastNonzeroMagnitude,
                                             right: .leastNonzeroMagnitude)
        
        layer.cornerRadius = 4.0
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0).cgColor
        allowsEditingTextAttributes = false
        isScrollEnabled = false
        
        addSubview(placeholdLabel)

        addConstraints([

            NSLayoutConstraint(item: placeholdLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: -1),
            NSLayoutConstraint(item: placeholdLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 8),

            ])
        
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.size.width, height: recordTextViewHeight.value)
    }
    
    //根据输入内容更新自身高度, 返回true表示有改变
    @discardableResult
    public func canUpdateIntrinsicContentHeight() -> Bool {
        
        let originHeight = sizeThatFits(CGSize(width: bounds.size.width, height: CGFloat.greatestFiniteMagnitude)).height.rounded(.up)
        
        if originHeight < 40 {
            textContainerInset.top = 8
        }
        else {
            textContainerInset.top = 4
        }
        
        var originValue = max(originHeight, 40)
        
        if originValue > (calculateMaxTextViewHeight - 10) && originValue < calculateMaxTextViewHeight {
            originValue = calculateMaxTextViewHeight
        }
        else {
            originValue = min(originValue, calculateMaxTextViewHeight)
        }
        
        if originHeight > calculateMaxTextViewHeight {
            isScrollEnabled = true
        }
        else {
            isScrollEnabled = false
        }
        
        recordTextViewHeight.value = originValue
        
        if recordTextViewHeight.isDidChanged {
            invalidateIntrinsicContentSize()
            return true
        }
        else {
            return false
        }
        
    }
    
}


fileprivate struct RecordTextViewHeight {
    
    var value: CGFloat = 0 {
        didSet {
            preValue = oldValue
        }
    }
    
    var isDidChanged:Bool {
        return preValue != value
    }
    
    private var preValue: CGFloat = 0
    
    init(initValue: CGFloat) {
        self.value = initValue
        self.preValue = initValue
    }
}

extension UIFont {
    //根据宽度，获取文本计算高度
    func sizeOfString(string:String , width:Double) -> CGFloat {
        let size = string.boundingRect(with: CGSize(width: width , height: Double.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: self], context: nil)
        return size.height
    }
}
