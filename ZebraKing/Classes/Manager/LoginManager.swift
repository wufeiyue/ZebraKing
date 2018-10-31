//
//  IMLoginManager.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/7/12.
//

import Foundation
import ImSDK
import IMMessageExt

public final class LoginManager: NSObject {
    
    public var identifier: String?
    public var userSig: String?
    public var appidAt3rd: String?
    
    public static var isSuccessed: Bool {
        return TIMManager.sharedInstance().getLoginStatus() == .STATUS_LOGINED
    }
    
    private var loginCompletion: ((Result<Bool>) -> Void)!
    private var timer: Timer?
    //是否正在登录中
    private var isBusy: Bool = false
    //重试次数
    private let retryNum: Int = 5
    private var currentIndex: Int = 0
    
    
    /// 登出
    ///
    /// - Parameters:
    ///   - success: 登出成功
    ///   - fail: 登出失败
    public func logout(success: @escaping TIMSucc, fail: @escaping TIMFail) {
        TIMManager.sharedInstance().logout(success, fail: fail)
    }
    
    /// 登录
    ///
    /// - Parameters:
    ///   - result: 结果 .success 登录成功 true  .failure 登录失败
    public func login(result: @escaping (Result<Bool>) -> Void) {
        
        loginCompletion = result
        
        let status = TIMManager.sharedInstance().getLoginStatus()
        
        switch status {
        case .STATUS_LOGINED:
            //已登录
            
            result(.success(true))
            
        case .STATUS_LOGINING:
            //登陆中
            
            self.isBusy = true
            
            //添加一个定时器
            addTimer(duration: 5)
            
            break
        case .STATUS_LOGOUT:
            
            //无登陆
            start(success: {
                self.isBusy = false
                self.stop(isDidLoginSuccessed: true)
                result(.success(true))
            }) { _, _ in
                self.isBusy = true
            }
            
            self.isBusy = true
            
            //添加一个定时器
            addTimer(duration: 5)
            
        }
        
    }
    
    private func addTimer(duration: TimeInterval) {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(timerElapsed), userInfo: nil, repeats: true)
    }
    
    private func stop(isDidLoginSuccessed: Bool) {
        timer?.invalidate()
        timer = nil
        currentIndex = 0
        
        if isDidLoginSuccessed == false && isBusy {
            loginCompletion(.failure(.loginFailure))
        }
        
        isBusy = false
    }
    
    /// 定时执行方法
    @objc
    private func timerElapsed() {
        
        defer {
            currentIndex += 1
        }
        
        if currentIndex == retryNum || currentIndex < 0 {
            //停止定时器
            stop(isDidLoginSuccessed: false)
        }
        
        if isBusy {
            relogin()
        }
        
    }
    
    private func start(success: @escaping TIMSucc, fail: @escaping TIMFail) {
        
        let param = TIMLoginParam()
        param.identifier = identifier
        param.userSig = userSig
        param.appidAt3rd = appidAt3rd
        
        TIMManager.sharedInstance().login(param, succ: success, fail: fail)
    }
    
    private func relogin() {
        
        guard TIMManager.sharedInstance().getLoginStatus() == .STATUS_LOGOUT else {
            return
        }
        
        start(success: {
            if self.isBusy {
                self.isBusy = false
                self.loginCompletion(.success(true))
                self.stop(isDidLoginSuccessed: true)
            }
        }) { (code, string) in
            self.isBusy = true
        }
    }
    
}
