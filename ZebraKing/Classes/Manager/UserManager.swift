//
//  UserManager.swift
//  ZebraKing
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 武飞跃. All rights reserved.
//
import Foundation
import ImSDK
import IMMessageExt

public final class UserManager {
    
    /// 好友列表
    private var friendsList: Dictionary<String, Sender>?
    /// 个人资料
    private var host: Sender?
    
    /// 创建本地账户
    ///
    /// - Parameter id: 用户Id
    public func getHost(result: @escaping (Result<Sender>) -> Void) {
        
        if let unwrappedHost = host {
            result(.success(unwrappedHost))
        }
        else {
            updateHostProfile { (r) in
                if case let .success(sender) = r {
                    self.host = sender
                    DispatchQueue.main.async {
                        result(.success(sender))
                    }
                }
                else {
                    DispatchQueue.main.async {
                        result(.failure(.getHostProfileFailure))
                    }
                }
            }
        }
        
    }
    
    /// 获取好友资料
    ///
    /// - Parameters:
    ///   - id: 唯一id
    ///   - result: 结果
    public func queryFriendProfile(id: String, result: @escaping (Result<Sender>) -> Void) {
        
        if let cacheUser = friendsList?[id], cacheUser.isLossNecessary == false {
            result(.success(cacheUser))
        }
        else {
            
            queryFriendsProfile(identifiers: [id]) { (r) in
                switch r {
                case .success(let list):
                    
                    if self.friendsList == nil {
                        self.friendsList = Dictionary<String, Sender>()
                    }
                    
                    if let profile = list.first {
                        self.friendsList?[profile.id] = profile
                        DispatchQueue.main.async {
                            result(.success(profile))
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            result(.failure(.getUsersProfileFailure))
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        result(.failure(error))
                    }
                }
            }
            
        }
    }
    
    /// 获取自己的资料
    public func updateHostProfile(result: @escaping (Result<Sender>) -> Void) {
        TIMFriendshipManager.sharedInstance().getSelfProfile({ profile in
            
            guard let unwrappedProfile = profile else {
                result(.failure(.getHostProfileFailure))
                return
            }
            
            //用户id
            let id: String = unwrappedProfile.identifier
            //用户头像
            let avatar: String? = unwrappedProfile.faceURL
            //用户昵称
            let nickname: String = unwrappedProfile.nickname
            
            var host = Sender(id: id, displayName: nickname)
            host.facePath = avatar
            
            result(.success(host))
            
        }, fail: { (code , str) in
            //同步资料失败
            result(.failure(.getHostProfileFailure))
        })
    }
  
    /// 修改自己的昵称
    public func modifySelfNickname(_ nick : String,
                                   result: @escaping (Swift.Result<String, ZebraKingError>) -> Void) {
        updateMyUserModel(nickName: nick, result: result)
    }
    
    /// 修改自己的头像
    public func modifySelfFacePath(_ path : String,
                                   result: @escaping (Swift.Result<String, ZebraKingError>) -> Void) {
        updateMyUserModel(facePath: path, result: result)
    }
    
    /// 释放资源
    public func free() {
        host = nil
        friendsList?.removeAll(keepingCapacity: false)
        friendsList = nil
    }
    
    
}

extension UserManager {
    
    /// 设置自己的资料
    ///
    /// - Parameters:
    ///   - facePath: 头像
    ///   - nickName: 昵称
    private func updateMyUserModel(facePath: String? = nil,
                                   nickName: String? = nil,
                                   result: @escaping (Swift.Result<String, ZebraKingError>) -> Void) {
        
        let option = TIMFriendProfileOption()
        let profile = TIMUserProfile()
        var resultString = ""
        
        if self.host == nil, let currendUsername = TIMManager.sharedInstance()?.getLoginUser() {
            self.host = Sender(id: currendUsername)
        }
        
        if let unwrappedFacePath = facePath {
            
            option.friendFlags = UInt64(TIMProfileFlag.PROFILE_FLAG_FACE_URL.rawValue)  //表示头像
            profile.faceURL = unwrappedFacePath
            resultString = unwrappedFacePath
            self.host?.facePath = unwrappedFacePath
        }
        
        if let unwrappedNickName = nickName {
            option.friendFlags = UInt64(TIMProfileFlag.PROFILE_FLAG_NICK.rawValue)  //表示昵称
            profile.nickname = unwrappedNickName
            resultString = unwrappedNickName
            self.host?.displayName = unwrappedNickName
        }
        
        if resultString.isEmpty {
            result(.failure(.updateUserProfileFailure))
        }
        
        TIMFriendshipManager.sharedInstance().modifySelfProfile(option, profile: profile, succ: {
            DispatchQueue.main.async {
                result(.success(resultString))
            }
        }) { (code, str) in
            DispatchQueue.main.async {
                result(.failure(.updateUserProfileFailure))
            }
        }
    }
    
    
    /// 查询好友的资料
    ///
    /// - Parameters:
    ///   - list: 等待查询的好友id的列表
    ///   - result: 查询结果
    private func queryFriendsProfile(identifiers list: Array<String>, result: @escaping (Result<Array<Sender>>) -> Void) {
        TIMFriendshipManager.sharedInstance()?.getUsersProfile(list, succ: { profiles in
            
            guard let unwrappedProfiles = profiles as? [TIMUserProfile] else {
                result(.failure(.unwrappedUsersProfileFailure))
                return
            }
                
            let senders: Array<Sender> = unwrappedProfiles.map{
                var sender = Sender(id: $0.identifier)
                sender.displayName = $0.nickname
                sender.facePath = $0.faceURL
                return sender
            }
            
            result(.success(senders))
            
        }, fail: { (code , str) in
            result(.failure(.getUsersProfileFailure))
        })
    }
}

