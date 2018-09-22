//
//  IMSdkInt.h
//  ImSDK
//
//  Created by bodeng on 10/12/14.
//  Copyright (c) 2014 tencent. All rights reserved.
//

#ifndef ImSDK_IMSdkInt_h
#define ImSDK_IMSdkInt_h

#import <Foundation/Foundation.h>
#import "IMSdkComm.h"
#import "TIMComm.h"


/**
 *  音视频接口
 */
@interface IMSdkInt : NSObject

/**
 *  获取 IMSdkInt 全局对象
 *
 *  @return IMSdkInt 对象
 */
+ (IMSdkInt*)sharedInstance;

/**
 *  获取当前登陆用户 TinyID
 *
 *  @return tinyid
 */
- (unsigned long long)getTinyId;

/**
 *  引入IMBugly.framework时，设置componentId（仅AVSdk使用）
 *
 *  @param componentId 在Buly系统上申请的appid
 *  @param version     版本信息
 */
- (void)setBuglyComponentIdentifier:(NSString*)componentId version:(NSString*)version;

/**
 * 设置音视频版本号
 */
- (void)setAvSDKVersion:(NSString*)ver;

/**
 *  UserId 转 TinyId
 *
 *  @param userIdList userId列表，IMUserId 结构体
 *  @param succ       成功回调
 *  @param err        失败回调
 *
 *  @return 0 成功
 */
- (int)userIdToTinyId:(NSArray*)userIdList okBlock:(OMUserIdSucc)succ errBlock:(OMErr)err;

/**
 *  TinyId 转 UserId
 *
 *  @param tinyIdList tinyId列表，unsigned long long类型
 *  @param succ       成功回调
 *  @param err        失败回调
 *
 *  @return 0 成功
 */
- (int)tinyIdToUserId:(NSArray*)tinyIdList okBlock:(OMUserIdSucc)succ errBlock:(OMErr)err;

/**
 *  发送请求
 *
 *  @param cmd  命令字
 *  @param body 包体
 *  @param succ 成功回调，返回响应数据
 *  @param fail 失败回调，返回错误码
 *
 *  @return 0 发包成功
 */
- (int)request:(NSString*)cmd body:(NSData*)body succ:(OMRequestSucc)succ fail:(OMRequsetFail)fail;

/**
 *  多人音视频请求
 *
 *  @param reqbody 请求二进制数据
 *  @param succ    成功回调
 *  @param err     失败回调
 *
 *  @return 0 成功
 */
- (int)requestMultiVideoApp:(NSData*)reqbody okBlock:(OMCommandSucc)succ errBlock:(OMErr)err;
- (int)requestMultiVideoInfo:(NSData*)reqbody okBlock:(OMCommandSucc)succ errBlock:(OMErr)err;

/**
 *  多人音视频发送请求
 *
 *  @param serviceCmd 命令字
 *  @param reqbody    发送包体
 *  @param succ       成功回调
 *  @param err        失败回调
 *
 *  @return 0 成功
 */
- (int)requestOpenImRelay:(NSString*)serviceCmd req:(NSData*)reqbody okBlock:(OMCommandSucc)succ errBlock:(OMErr)err;

/**
 *  设置超时时间
 *
 *  @param timeout 超时时间（单位:s）
 */
- (void)setReqTimeout:(int)timeout;


/**
 *  双人音视频请求
 *
 *  @param tinyid  接收方 tinyid
 *  @param reqbody 请求包体
 *  @param succ    成功回调
 *  @param err     失败回调
 *
 *  @return 0 成功
 */
- (int)requestSharpSvr:(unsigned long long)tinyid req:(NSData*)reqbody okBlock:(OMCommandSucc)succ errBlock:(OMErr)err;

- (int)responseSharpSvr:(unsigned long long)tinyid req:(NSData*)reqbody okBlock:(OMCommandSucc)succ errBlock:(OMErr)err;


/**
 *  设置双人音视频监听回调
 *
 *  @param succ 成功回调，有在线消息时调用
 *  @param err  失败回调，在线消息解析失败或者包体错误码不为0时调用
 *
 *  @return 0 成功
 */
- (int)setSharpSvrPushListener:(OMCommandSucc)succ errBlock:(OMErr)err;
- (int)setSharpSvrRspListener:(OMCommandSucc)succ errBlock:(OMErr)err;

/**
 *  发送质量上报请求
 *
 *  @param data  上报的数据
 *  @param type  上报数据类型
 *  @param succ  成功回调
 *  @param fail  失败回调，返回错误码
 *
 *  @return 0 发包成功
 */
- (int)requestQualityReport:(NSData*)data type:(unsigned int)type succ:(OMMultiSucc)succ fail:(OMMultiFail)fail;


- (void)doIMPush:(NSData*)body;


/**
 * Crash 日志
 *
 * @param   level    日志级别
 * @param   tag      日志模块分类
 * @param   content  日志内容
 */
- (void)logBugly:(TIMLogLevel)level tag:(NSString*) tag log:(NSString*)content;


/**
 *  事件上报
 *
 *  @param item 事件信息
 *
 *  @return 0 成功
 */
- (int)reportEvent:(TIMEventReportItem*)item;

@end

#endif
