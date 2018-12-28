//
//  InputTextView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/5.
//

import UIKit

open class RefreshView: UIView {
    
    let indicator = UIActivityIndicatorView(style: .gray)
    
    public let height: CGFloat
    private let action: () -> Void
    
    public init(height: CGFloat, action: @escaping () -> Void) {
        self.height = height
        self.action = action
        super.init(frame: .zero)
        addSubview(indicator)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isRefreshing = false {
        didSet {
            isRefreshing ? indicator.startAnimating() : indicator.stopAnimating()
        }
    }
    
    private var isBusy = false
    
    private var scrollView: UIScrollView? {
        return superview as? UIScrollView
    }
    
    private var offsetToken: NSKeyValueObservation?
    private var stateToken: NSKeyValueObservation?
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil {
            offsetToken?.invalidate()
            stateToken?.invalidate()
        } else {
            guard let scrollView = scrollView else { return }
            offsetToken = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
                self?.scrollViewDidScroll(scrollView)
            }
            stateToken = scrollView.observe(\.panGestureRecognizer.state) { [weak self] scrollView, _ in
                guard scrollView.panGestureRecognizer.state == .began else { return }
                self?.scrollViewWillBeginDragging(scrollView)
            }
            
            frame = CGRect(x: 0, y: -height, width: UIScreen.main.bounds.width, height: height)
            
        }
    }
    
    private func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard isRefreshing else { return }
        
        if scrollView.contentSize.height <= scrollView.bounds.height { return }
        
        if scrollView.isDragging {
            return
        }
        
        //当前值 < height时, 还在滚动判断表示 contentInset.top == -height 此时已进入待刷新
        if scrollView.contentOffset.y + scrollView.contentInset.top < height {
            if isBusy == false {
                isBusy = true
                action()
            }
        }
        
    }
    
    private func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if scrollView.contentSize.height <= scrollView.bounds.height { return }
        
        if isRefreshing == false {
            scrollView.contentInset.top += self.height
            isRefreshing = true
        }
        
    }
    
    func endRefreshing(completion: (() -> Void)? = nil) {
        
        guard let scrollView = scrollView else { return }
        
        guard isRefreshing else { completion?(); return }
        
        scrollView.contentInset.top -= self.height
        
        isRefreshing = false
        isBusy = false
        completion?()
        
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        indicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

private var headerKey: UInt8 = 0

extension UIScrollView {
    
    private var refresh_header: RefreshView? {
        
        get { return objc_getAssociatedObject(self, &headerKey) as? RefreshView }
        
        set {
            refresh_header?.removeFromSuperview()
            objc_setAssociatedObject(self, &headerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            newValue.map{ insertSubview($0, at: 0) }
        }
    }
    
    public func setIndicatorHeader(height: CGFloat = 35, action: @escaping () -> Void) {
        refresh_header = RefreshView(height: height, action: action)
    }
    
    public func endRefreshing() {
        refresh_header?.endRefreshing()
    }
    
    public func endRefreshingAndNoMoreData() {
        refresh_header?.endRefreshing(completion: {
            self.refresh_header = nil
        })
    }
}
