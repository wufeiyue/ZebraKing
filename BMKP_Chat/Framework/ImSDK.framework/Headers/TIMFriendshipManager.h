//
//  TIMFriendshipManager.h
//  ImSDK
//
//  Created by bodeng on 21/5/15.
//  Copyright (c) 2015 tencent. All rights reserved.
//

#ifndef ImSDK_TIMFriendshipManager_h
#define ImSDK_TIMFriendshipManager_h

#import "TIMComm.h"


/**
 * 好友管理
 */
@interface TIMFriendshipManager : NSObject

/**
 *  获取好友管理器实例
 *
 *  @return 管理器实例
 */
+ (TIMFriendshipManager*)sharedInstance;

/**
 *  设置自己的资料
 *
 *  @param option    需要更新的属性
 *  @param profile   新的资料
 *  @param succ 成功回调
 *  @param fail 失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)modifySelfProfile:(TIMFriendProfileOption*)option profile:(TIMUserProfile*)profile succ:(TIMSucc)succ fail:(TIMFail)fail;

/**
 *  获取自己的资料
 *
 *  @param succ  成功回调，返回 TIMUserProfile
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getSelfProfile:(TIMGetProfileSucc)succ fail:(TIMFail)fail;

/**
 *  获取指定用户资料
 *
 *  @param users 要获取的用户列表 NSString* 列表
 *  @param succ  成功回调，返回 TIMUserProfile* 列表
 *  @param fail  失败回调
 *
 *  @return 0 发送请求成功
 */
- (int)getUsersProfile:(NSArray*)users succ:(TIMFriendSucc)succ fail:(TIMFail)fail;


@end

#endif
