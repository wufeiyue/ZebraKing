//
//  MessageInputBar.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/1.
//  底部工具栏

import UIKit

open class MessageInputBar: UIView {

    open var inputTextView = InputTextView()
    
    open var padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
    
    open var contentView = UIView()
    
    ///给textView赋值
    open var inputTextViewText: String? {
        didSet {
            guard let unwrappedText = inputTextViewText else { return }
            inputTextView.text = unwrappedText
            inputTextView.becomeFirstResponder()
        }
    }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setup() {
        
        autoresizingMask = [.flexibleHeight]
        setupSubviews()
        setupConstraints()
        setupObservers()
    }
    
    open func setupSubviews() {
        addSubview(contentView)
        contentView.addSubview(inputTextView)
    }
    
    open func setupConstraints() {
        inputTextView.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview()
            m.top.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { (m) in
            m.top.equalToSuperview().offset(padding.top)
            m.left.equalTo(padding.left)
            m.right.equalTo(-padding.right)
            m.bottom.equalTo(-padding.bottom)
        }
    }
    
    open func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: .UITextViewTextDidChange, object: inputTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidBeginEditing), name: .UITextViewTextDidBeginEditing, object: inputTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidEndEditing), name: .UITextViewTextDidEndEditing, object: inputTextView)
    }

    open override var intrinsicContentSize: CGSize {
        return calculateIntrinsicContentSize()
    }
    
    //计算bar的高度, 只在这一个方法里
    open func calculateIntrinsicContentSize() -> CGSize {
        let inputTextViewHeight = inputTextView.intrinsicContentSize.height
        return CGSize(width: bounds.size.width, height: inputTextViewHeight + padding.top + padding.bottom)
    }
    
    @objc
    private func textViewDidChange() {
        let trimmedText = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        //隐藏inputTextView.placeholder
        inputTextView.placeholdLabel.isHidden = !trimmedText.isEmpty
        
        //更新self和inputTextView的高度
        if inputTextView.canUpdateIntrinsicContentHeight() {
            invalidateIntrinsicContentSize()
        }
    }
    
    @objc
    private func textViewDidBeginEditing() {
        if inputTextViewText != nil {
            defer {
                inputTextViewText = nil
            }
            textViewDidChange()
        }
    }
    
    @objc
    private func textViewDidEndEditing() {
        
    }
}

