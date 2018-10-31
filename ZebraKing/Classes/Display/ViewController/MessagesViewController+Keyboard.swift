//
//  MessagesViewController+Keyboard.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/1/25.
//

import Foundation

extension MessagesViewController {
    
    func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.handleKeyboardDidChangeState(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.handleTextViewDidBeginEditing(_:)), name: .UITextViewTextDidBeginEditing, object: nil)
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UITextViewTextDidBeginEditing, object: nil)
    }
    
    @objc
    private func handleKeyboardDidChangeState(_ notification: Notification) {
        //键盘的高度
        guard let keyboardEndFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        if (keyboardEndFrame.origin.y + keyboardEndFrame.size.height) > UIScreen.main.bounds.size.height {
            messageCollectionViewBottomInset = view.frame.size.height - keyboardEndFrame.origin.y - iPhoneXBottomInset
        }
        else {
            let afterBottomInset = keyboardEndFrame.size.height > keyboardOffsetFrame.size.height ? (keyboardEndFrame.size.height - iPhoneXBottomInset) : keyboardOffsetFrame.size.height
            let differenceOfBottomInset = afterBottomInset - messageCollectionViewBottomInset
            let contentOffset = CGPoint(x: messagesCollection.contentOffset.x, y: messagesCollection.contentOffset.y + differenceOfBottomInset)
            
            if maintainPositionOnKeyboardFrameChanged {
                messagesCollection.setContentOffset(contentOffset, animated: false)
            }
            
            messageCollectionViewBottomInset = afterBottomInset
        }
        
    }
    
    @objc
    private func handleTextViewDidBeginEditing(_ notification: Notification) {
        if scrollsToBottomOnKeybordBeginsEditing {
            guard let inputTextView = notification.object as? InputTextView, inputTextView === messageInputBar.inputTextView else { return }
            //延迟0.1秒是为了避免两个监听方法一块执行, 对messagesCollection.setContentOffset操作有影响, 导致键盘弹出时, scrollview没有移到最底部
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.messagesCollection.scrollToBottom(animated: true)
//            }
        }
    }
    
    func adjustScrollViewInset() {
        if #available(iOS 11.0, *) {
            
        } else {
            let navigationBarInset = navigationController?.navigationBar.frame.height ?? 0
            let statusBarInset: CGFloat = UIApplication.shared.isStatusBarHidden ? 0 : 20
            let topInset = navigationBarInset + statusBarInset
            messagesCollection.contentInset.top = topInset
            messagesCollection.scrollIndicatorInsets.top = topInset
        }
    }
    
    var keyboardOffsetFrame: CGRect {
        guard let inputFrame = inputAccessoryView?.frame else { return .zero }
        return CGRect(origin: inputFrame.origin, size: CGSize(width: inputFrame.size.width, height: inputFrame.size.height - iPhoneXBottomInset))
    }
    
    private var iPhoneXBottomInset: CGFloat {
        if #available(iOS 11, *) {
            guard UIScreen.main.nativeBounds.height == 2436 else { return 0 }
            return view.safeAreaInsets.bottom
        }
        return 0
    }
}
