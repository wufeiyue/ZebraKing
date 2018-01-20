//
//  IMTextView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/12/12.
//

import UIKit

public protocol IMTextViewDelegate: class {
    func textViewDidChange(_ textView: UITextView)
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    func textViewDidEndEditing(_ textView: UITextView)
    func textView(_ textView: IMTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
}

public struct TextViewHeightRange {
    static var `default` = TextViewHeightRange(min: 40, max: 100)
    var min: CGFloat
    var max: CGFloat
}

public final class IMTextView: UIView {

    public var placeholder: String? {
        set {
            titleLabel.text = newValue
        }
        get { return nil }
    }
    
    public var text: String! {
        set {
            textView.text = newValue
        }
        get {
            return textView.text
        }
    }
    
    public weak var delegate: IMTextViewDelegate?
    
    private var recordTextViewHeight:RecordTextViewHeight!
    private var textView: UITextView!
    private var titleLabel: UILabel!
    
    let heightRange: TextViewHeightRange
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - heightRange: textView的高度随着文本换行增长范围 默认是 40 ~ 100
    ///   - textViewHeight: 文本框的高度, 如果参数为nil, 默认取 40
    init(heightRange: TextViewHeightRange = .default, textViewHeight: CGFloat? = nil) {
        self.heightRange = heightRange
        super.init(frame: .zero)
        
        if let unwrappedTextViewHeight = textViewHeight {
            recordTextViewHeight = RecordTextViewHeight(initValue: unwrappedTextViewHeight)
        }
        else {
            recordTextViewHeight = RecordTextViewHeight(initValue: heightRange.min)
        }
        
        setupViews()
    }
    
    private func setupViews() {
        textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.textColor = UIColor(hexString: "#4D4D4D")
        textView.scrollsToTop = false
        textView.textContainerInset = UIEdgeInsetsMake(10, 3, 3, 5)
        textView.returnKeyType = .send
        textView.isHidden = false
        textView.enablesReturnKeyAutomatically = true
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.delegate = self
        addSubview(textView)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(hexString: "#999999")
        addSubview(titleLabel)
        
        textView.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview()
            m.height.equalTo(recordTextViewHeight.value)
            m.top.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { (m) in
            m.right.centerY.equalTo(textView)
            m.left.equalTo(textView).offset(8)
        }
    }
    
    public override func updateConstraints() {
        
        textView.snp.updateConstraints { (m) in
            m.height.equalTo(recordTextViewHeight.value)
        }
        
        super.updateConstraints()
    }
    
    //更新TextView的高度, textView可不传
    public func updateTextView(_ textView: UITextView? = nil) {
        
        var tempTextView: UITextView {
            if let unwrappedTextView = textView {
                return unwrappedTextView
            }
            else {
                return self.textView
            }
        }
        
        let originHeight = tempTextView.sizeThatFits(CGSize(width: bounds.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        
        recordTextViewHeight.value = min(max(originHeight, heightRange.min), heightRange.max)
        
        if recordTextViewHeight.isDidChanged {
            setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
        
        titleLabel.isHidden = !tempTextView.text.isEmpty
    }
    
    public func resignResponder() {
        textView.resignFirstResponder()
    }
    
    public func becomeResponder(){
        textView.becomeFirstResponder()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension IMTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        updateTextView(textView)
        delegate?.textViewDidChange(textView)
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let unwrappedDelegate = delegate {
            return unwrappedDelegate.textViewShouldBeginEditing(textView)
        }
        return false
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        updateTextView(textView)
        delegate?.textViewDidEndEditing(textView)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let unwrappedDelegate = delegate {
            return unwrappedDelegate.textView(self, shouldChangeTextIn: range, replacementText: text)
        }
        return false
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
