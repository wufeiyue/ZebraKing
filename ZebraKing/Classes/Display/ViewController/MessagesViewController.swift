//
//  MessagesViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/1/24.
//

import UIKit

open class MessagesViewController: UIViewController {

    open var messagesCollection = MessagesCollectionView()
    
    //当输入框inputTextView开始编辑的时候, 是否需要将collectionView滚动到底部, 默认是false
    public var scrollsToBottomOnKeybordBeginsEditing: Bool = false
    
    internal var messageCollectionViewBottomInset: CGFloat = 0 {
        didSet {
            messagesCollection.contentInset.bottom = messageCollectionViewBottomInset
            messagesCollection.scrollIndicatorInsets.bottom = messageCollectionViewBottomInset
        }
    }
    
    open var maintainPositionOnKeyboardFrameChanged: Bool = false
    
    open var messageInputBar: MessageInputBar! {
        return inputBar
    }
    
    private lazy var inputBar = MessageInputBar()
    
    private var isFirstLayout: Bool = true
    
    //选中的菜单indexPath
    open var selectedIndexPath: IndexPath?
    
    internal var selectedIndexPathForMenu: IndexPath?
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // 是否支付屏幕旋转 默认不支持
    open override var shouldAutorotate: Bool {
        return false
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupDefaults()
        setupSubviews()
        setupConstraints()
        addMenuControllerObservers()
        
        messagesCollection.delegate = self
        messagesCollection.dataSource = self
        messagesCollection.register(TextMessageCell.self, forCellWithReuseIdentifier: "TextMessageCellKey")
        messagesCollection.register(MediaMessageCell.self, forCellWithReuseIdentifier: "MediaMessageCellKey")
        messagesCollection.register(LocationMessageCell.self, forCellWithReuseIdentifier: "LocationMessageCellKey")
        messagesCollection.register(AudioMessageCell.self, forCellWithReuseIdentifier: "AudioMessageCellKey")
        messagesCollection.register(TimestampCell.self, forCellWithReuseIdentifier: "TimestampCellKey")
        messagesCollection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCellKey")
        messagesCollection.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1.0)
        
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    deinit {
        removeKeyboardObservers()
        removeMenuControllerObservers()
    }
    
    private func setupDefaults() {
        //设置布局是从左上角开始, 必须注释, 否则在iPhone X上布局会错乱
        if #available(iOS 11.0, *) {
            messagesCollection.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        extendedLayoutIncludesOpaqueBars = true
        //FIXME: - 设置成onDrag, 会造成inputAccessoryView位置发生改变
        messagesCollection.keyboardDismissMode = .interactive
        //设置如果collection的内容没有占满整个collectionView，
        //这个就不能下拉滑动，没法实现下拉；但是设置下面这个就可以实现下拉了
        messagesCollection.alwaysBounceVertical = true
    }
    
    
    
    private func setupSubviews() {
        view.addSubview(messagesCollection)
    }
    
    private func setupConstraints() {
        
        messagesCollection.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            let top = messagesCollection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topLayoutGuide.length)
            let bottom = messagesCollection.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            let leading = messagesCollection.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
            let trailing = messagesCollection.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            NSLayoutConstraint.activate([top, bottom, trailing, leading])
        }
        else {
            let top = NSLayoutConstraint(item: messagesCollection, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0)
            let bottom = NSLayoutConstraint(item: messagesCollection, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
            let leading = NSLayoutConstraint(item: messagesCollection, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0)
            let trailing = NSLayoutConstraint(item: messagesCollection, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0)
            view.addConstraints([top, bottom, trailing, leading])
        }
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    final override public func viewDidLayoutSubviews() {
        if isFirstLayout {
            defer {
                isFirstLayout = false
            }
            addKeyboardObservers()
            messageCollectionViewBottomInset = keyboardOffsetFrame.size.height
        }
        adjustScrollViewInset()
    }
    
    final override public var inputAccessoryView: UIView? {
        return messageInputBar
    }
}

