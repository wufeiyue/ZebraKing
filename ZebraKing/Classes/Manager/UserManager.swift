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
    public private(set) var friendsList: Dictionary<String, Sender>?
    
    /// 个人资料
    public private(set) var host: Sender?
    
    /// 创建本地账户
    ///
    /// - Parameter id: 用户Id
    public func createAccount(id: String) {
        
        //本地账户为nil
        if host == nil {
            
            host = Sender(id: id)
            
            updateHostProfile {
                if case .success(let facePath, let displayName) = $0 {
                    self.host?.facePath = facePath
                    self.host?.displayName = displayName
                }
            }
        }
        
        //好友列表为nil
        if friendsList == nil {
            friendsList = Dictionary<String, Sender>()
        }
        
    }
    
    //释放资源
    public func free() {
        host = nil
        friendsList?.removeAll(keepingCapacity: false)
        friendsList = nil
    }
    
}

extension UserManager {
    
    /// 获取好友资料
    ///
    /// - Parameters:
    ///   - id: 唯一id
    ///   - result: 结果
    public func queryFriendProfile(id: String, result: @escaping (IMResult<Sender>) -> Void) {
        
        if let cacheUser = friendsList?[id], cacheUser.isLossNecessary == false {
            result(.success(cacheUser))
        }
        else {
            
            TIMFriendshipManager.sharedInstance()?.getUsersProfile([id], succ: { profile in
                
                if let unwrappedProfile = profile?.first as? TIMUserProfile {
                    
                    var sender = Sender(id: unwrappedProfile.identifier)
                    sender.displayName = unwrappedProfile.nickname
                    sender.facePath = unwrappedProfile.faceURL
                    
                    result(.success(sender))
                    self.friendsList?[id] = sender
                }
                else {
                    result(.failure(.unwrappedUsersProfileFailure))
                }
                
            }, fail: { (code , str) in
                result(.failure(.getUsersProfileFailure))
            })
        }
    }
    
    /// 获取自己的资料, (猜测selfProfile只是离线在本地, )
    public func updateHostProfile(result: @escaping (IMResult<(facePath: String?, displayName: String)>) -> Void) {
        TIMFriendshipManager.sharedInstance().getSelfProfile({
            
            var profile: (facePath: String?, displayName: String) = (nil, "")
            
            if let unwrappedFaceURL = $0?.faceURL, unwrappedFaceURL.isEmpty == false {
                profile.facePath = unwrappedFaceURL
            }
            
            if let unwrappedNickName = $0?.nickname, unwrappedNickName.isEmpty == false {
                profile.displayName = unwrappedNickName
            }
            
            result(.success(profile))
            
        }, fail: { (code , str) in
            //同步资料失败
            result(.failure(.unknown))
        })
    }
    
    
    /// 获取缓存的好友资料
    ///
    /// - Parameter id: 用户id
    /// - Returns: 结果
    public func getSender(id: String) -> Sender? {
        return friendsList?[id]
    }
    
    /// 修改自己的昵称
    public func modifySelfNickname(_ nick : String) {
        guard nick.count > 0 && nick.count < 64 else { return }
        updateMyUserModel(nickName: nick)
    }
    
    /// 修改自己的头像
    public func modifySelfFacePath(_ path : String) {
        updateMyUserModel(facePath: path)
    }
    
    
    /// 设置自己的资料
    ///
    /// - Parameters:
    ///   - facePath: 头像
    ///   - nickName: 昵称
    private func updateMyUserModel(facePath: String? = nil, nickName: String? = nil) {
        
        let option = TIMFriendProfileOption()
        let profile = TIMUserProfile()
        
        if let unwrappedFacePath = facePath {
            
            option.friendFlags = UInt64(TIMProfileFlag.PROFILE_FLAG_FACE_URL.rawValue)  //表示头像
            profile.faceURL = unwrappedFacePath
            self.host?.facePath = unwrappedFacePath
        }
        
        if let unwrappedNickName = nickName {
            option.friendFlags = UInt64(TIMProfileFlag.PROFILE_FLAG_NICK.rawValue)  //表示昵称
            profile.nickname = unwrappedNickName
            self.host?.displayName = unwrappedNickName
        }
        
        TIMFriendshipManager.sharedInstance().modifySelfProfile(option, profile: profile, succ: {
            
        }) { (code, str) in
            //TODO: 设置个人信息失败
        }
    }
}

