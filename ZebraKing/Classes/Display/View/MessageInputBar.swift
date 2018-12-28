//
//  MessageInputBar.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/1.
//  底部工具栏

import UIKit

public class NSLayoutConstraintSet {
    
    public var top: NSLayoutConstraint?
    public var bottom: NSLayoutConstraint?
    public var left: NSLayoutConstraint?
    public var right: NSLayoutConstraint?
    
    public var height: NSLayoutConstraint?
    public var width: NSLayoutConstraint?
    
    public init(top: NSLayoutConstraint? = nil, bottom: NSLayoutConstraint? = nil,
                left: NSLayoutConstraint? = nil, right: NSLayoutConstraint? = nil,
                height: NSLayoutConstraint? = nil, width: NSLayoutConstraint? = nil) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
        self.height = height
        self.width = width
    }
    
    //可用的约束
    private var availableConstraints: [NSLayoutConstraint] {
        return [top, bottom, left, right, width, height].compactMap{ $0 }
    }
    
    /// 激活
    public func activate() {
        NSLayoutConstraint.activate(availableConstraints)
    }
    
    /// 金庸
    public func deactivate() {
        NSLayoutConstraint.deactivate(availableConstraints)
    }
    
}


open class MessageInputBar: UIView {

    open var padding: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) {
        didSet {
            updatePadding()
        }
    }
    
    open var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
        return view
    }()
    
    open var inputTextView = InputTextView()
    
    open var contentView = UIView()
    
    //MARK: - 为内部属性设置约束
    
    private var contentViewLayoutSet: NSLayoutConstraintSet?
    
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
        setupSubConstraints()
    }
    
    open func setupSubviews() {
        addSubview(backgroundView)
        addSubview(contentView)
        contentView.addSubview(inputTextView)
    }
    
    open func setupSubConstraints() {
        
        contentView.addConstraints([
            
            NSLayoutConstraint(item: inputTextView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: inputTextView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: inputTextView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: inputTextView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
        
    }
    
    private func setupConstraints() {

        contentView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundView.edgesToSuperView()
        
        if #available(iOS 11, *) {
            
            contentViewLayoutSet = NSLayoutConstraintSet(
                top:    contentView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding.bottom),
                bottom: contentView.topAnchor.constraint(equalTo: topAnchor, constant: padding.top),
                left:   contentView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: padding.left),
                right:  contentView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -padding.right)
            )
        }
        else {
            
            contentViewLayoutSet = NSLayoutConstraintSet(
                top:    NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: padding.top),
                bottom: NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: -padding.right),
                left:   NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: padding.left),
                right:  NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -padding.bottom)
            )
            
        }
        
        activateConstraints()
    }
    
    private func activateConstraints() {
        contentViewLayoutSet?.activate()
    }
    
    private func deactivateConstraints() {
        contentViewLayoutSet?.deactivate()
    }
    
    private func updatePadding() {
        contentViewLayoutSet?.top?.constant = padding.top
        contentViewLayoutSet?.left?.constant = padding.left
        contentViewLayoutSet?.right?.constant = -padding.right
        contentViewLayoutSet?.bottom?.constant = -padding.bottom
    }
    
    open func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidBeginEditing), name: UITextView.textDidBeginEditingNotification, object: inputTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidEndEditing), name: UITextView.textDidEndEditingNotification, object: inputTextView)
    }
    
    internal func performLayout(_ animated: Bool, _ animations: @escaping () -> Void) {
        deactivateConstraints()
        if animated {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: animations)
            }
        } else {
            UIView.performWithoutAnimation { animations() }
        }
        activateConstraints()
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
    open func textViewDidBeginEditing() {
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

extension UIView {
    
    func edgesToSuperView() {
        
        guard let superview = self.superview else {
            return
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 9.0, *) {
            let constraints: [NSLayoutConstraint] = [
                leftAnchor.constraint(equalTo: superview.leftAnchor),
                rightAnchor.constraint(equalTo: superview.rightAnchor),
                topAnchor.constraint(equalTo: superview.topAnchor),
                bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
        }
        else {
            
            superview.addConstraints([
                
                NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: superview, attribute: .trailing, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: superview, attribute: .leading, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: superview, attribute: .bottom, multiplier: 1.0, constant: 0)
                
                ])
        }
        
    }
    
    
}
