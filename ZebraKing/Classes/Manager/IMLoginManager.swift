//
//  IMLoginManager.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/7/12.
//

import Foundation
import ImSDK
import IMMessageExt

public final class IMLoginManager: NSObject {
    
    public private(set) var identifier: String?
    public private(set) var userSig: String?
    public private(set) var appidAt3rd: String?
    public private(set) var accountType: String?
    
    public static var isLoginSuccessed: Bool {
        return TIMManager.sharedInstance().getLoginStatus() == .STATUS_LOGINED
    }
    
    private var loginCompletion: ((IMResult<Bool>) -> Void)!
    private var timer: Timer?
    //是否正在登录中
    private var isBusy: Bool = false
    //重试次数
    private let retryNum: Int = 5
    private var currentIndex: Int = 0
    
    /// 注册sdk
    ///
    /// - Parameters:
    ///   - appidAt3rd: 平台分配给开发者使用的appid
    ///   - accountType: 平台分配给开发者使用的type
    /// - Returns: 返回true, 表示注册成功
    @discardableResult
    public func register(appidAt3rd: String, accountType: String?) -> Bool {
        
        var status: Bool = false
        
        if let appid = Int32(appidAt3rd) {
            let sdkConfig = TIMSdkConfig()
            sdkConfig.sdkAppId = appid
            sdkConfig.accountType = accountType
            sdkConfig.disableLogPrint = true //禁止在控制台打印
            let initStatus = TIMManager.sharedInstance().initSdk(sdkConfig)
            status = (initStatus == 0)
        }
        
        let userConfig = TIMUserConfig()
        userConfig.enableReadReceipt = true //开启已读回执
        userConfig.disableRecnetContact = true //不开启最近联系人
        let userStatus = TIMManager.sharedInstance().setUserConfig(userConfig)
        status = (userStatus == 0)
        
        self.appidAt3rd = appidAt3rd
        self.accountType = accountType
        
        return status
    }
    
    
    /// 重新登录
    ///
    /// - Parameter result: 结果 .success 登录成功  .failure 登录失败
    public func relogin(result: @escaping (IMResult<Bool>) -> Void) {
        login(identifier: identifier, userSig: userSig, result: result)
    }
    
    /// 登录
    ///
    /// - Parameters:
    ///   - identifier: 用户唯一id
    ///   - userSig: 用户签名sign
    ///   - result: 结果 .success 登录成功 true  .failure 登录失败
    public func login(identifier: String?, userSig: String?, result: @escaping (IMResult<Bool>) -> Void) {
        
        self.identifier = identifier
        self.userSig = userSig
        loginCompletion = result
        
        let status = TIMManager.sharedInstance().getLoginStatus()
        
        switch status {
        case .STATUS_LOGINED:
            //已登录
            
            loginCompletion(.success(true))
            
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
                self.loginCompletion(.success(true))
            }) { _, _ in
                self.isBusy = true
            }
            
            self.isBusy = true
            
            //添加一个定时器
            addTimer(duration: 5)
            
        }
        
    }
    
    
    /// 登出
    ///
    /// - Parameters:
    ///   - success: 登出成功
    ///   - fail: 登出失败
    public func logout(success: @escaping TIMSucc, fail: @escaping TIMFail) {
        TIMManager.sharedInstance().logout(success, fail: fail)
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
