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

public final class UserManager: NSObject {
    
    private var receiverPlaceholder: UIImage?
    private var hostPlaceholder: UIImage?
    
    /// 好友列表
    public private(set) var friendsList = Dictionary<String, Sender>()
    
    /// 个人资料
    public fileprivate(set) var host: Sender?
    
    func config(hostPlaceholder: UIImage?, receiverPlaceholder: UIImage?) {
        self.hostPlaceholder = hostPlaceholder
        self.receiverPlaceholder = receiverPlaceholder
    }
    
    /// 获取好友资料
    ///
    /// - Parameters:
    ///   - id: 唯一id
    ///   - result: 结果
    public func queryFriendProfile(id: String, placeholder: UIImage? = nil, result: @escaping (IMResult<Sender>) -> Void) {
        
        if let cacheUser = friendsList[id], cacheUser.isLossNecessary == false {
            result(.success(cacheUser))
        }
        else {
            
            TIMFriendshipManager.sharedInstance()?.getUsersProfile([id], succ: { profile in
                
                if let unwrappedProfile = profile?.first as? TIMUserProfile {
                    
                    var sender = Sender(id: unwrappedProfile.identifier)
                    sender.displayName = unwrappedProfile.nickname
                    sender.facePath = unwrappedProfile.faceURL
                    sender.placeholder = placeholder ?? self.receiverPlaceholder
                    
                    self.friendsList[id] = sender
                    result(.success(sender))
                }
                else {
                    result(.failure(.unwrappedUsersProfileFailure))
                }
                
            }, fail: { (code , str) in
                result(.failure(.getUsersProfileFailure))
            })
        }
    }
    
    public func fetchSender(id: String) -> Sender? {
        var sender = friendsList[id]
        if sender?.placeholder == nil {
            sender?.placeholder = receiverPlaceholder
        }
        return sender
    }
    
    //释放资源
    public func free() {
        host = nil
        friendsList.removeAll(keepingCapacity: false)
    }
}

extension UserManager {
    
    /// 修改自己的昵称
    public func modifySelfNickname(_ nick : String) {
        guard nick.count > 0 && nick.count < 64 else { return }
        updateMyUserModel(nickName: nick)
    }
    
    /// 修改自己的头像
    public func modifySelfFacePath(_ path : String) {
        updateMyUserModel(facePath: path)
    }
    
    public func createAccountIfNotFound(id: String) {
        
        if host == nil {
            host = Sender(id: id)
            host?.placeholder = hostPlaceholder
        }
        
        //FIXME: - 同步我的个人信息, 如果外面不传facePath过来, 这里同步结果比较慢, 就会造成chatViewController个人信息显示成默认头像
        updateHostProfile { sender in
            
        }
        
    }
    
    /// 获取自己的资料, (猜测selfProfile只是离线在本地, )
    public func updateHostProfile(result: @escaping (IMResult<Sender?>) -> Void) {
        TIMFriendshipManager.sharedInstance().getSelfProfile({ (profile) in
            
            guard let unwrappedProfile = profile else { return }
            
            if let unwrappedFaceURL = unwrappedProfile.faceURL, unwrappedFaceURL.isEmpty == false {
                self.host?.facePath = unwrappedFaceURL
            }
            
            if let unwrappedNickName = unwrappedProfile.nickname, unwrappedNickName.isEmpty == false {
                self.host?.displayName = unwrappedNickName
            }
            
            result(.success(self.host))
            
        }, fail: { (code , str) in
            //同步资料失败
            result(.failure(.unknown))
        })
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

