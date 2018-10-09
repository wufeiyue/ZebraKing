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

        contentView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addConstraints([
            
            NSLayoutConstraint(item: inputTextView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: inputTextView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: inputTextView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0)
            
        ])
        
        addConstraints([

            NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: padding.top),
            NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: -padding.right),
            NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: padding.left),
            NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -padding.bottom)

        ])
        
    }
    
    open func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidBeginEditing), name: UITextView.textDidBeginEditingNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidEndEditing), name: UITextView.textDidEndEditingNotification, object: inputTextView)
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

