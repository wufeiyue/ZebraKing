# ![](https://raw.githubusercontent.com/wufeiyue/ZebraKing/master/zebraking.png)
> 基于腾讯云通信,在swift中优雅的使用即时通讯

[![CI Status](https://img.shields.io/travis/eppeo/ZebraKing.svg?style=flat)](https://travis-ci.org/eppeo/ZebraKing)
[![Version](https://img.shields.io/cocoapods/v/ZebraKing.svg?style=flat)](https://cocoapods.org/pods/ZebraKing)
[![License](https://img.shields.io/cocoapods/l/ZebraKing.svg?style=flat)](https://cocoapods.org/pods/ZebraKing)
[![Platform](https://img.shields.io/cocoapods/p/ZebraKing.svg?style=flat)](https://cocoapods.org/pods/ZebraKing)

## 产品特色

- [x] 高度可定制会话页面, 会话页面分3层结构,依次负责UI、IM、Business
- [x] 支持富文本、语音、图片、视频、地理位置等消息,并可根据需求添加自定义消息类型
- [x] 文本消息支持手机号,地址,日期,URL识别
- [x] 支持根据chatId在未获取会话对象时,先监听未读消息数,降低耦合性,也不会造成内存泄漏
- [x] 没有过多依赖第三方库
- [x] 发送消息时, 根据上下文判断自动添加时间戳

## 要求

- iOS 8.2
- Xcode 9.4.1
- Swift 4.1

## 配置

### 使用CocoaPods工具进行安装

不出意外你现在使用的应该是swift项目, 但还是想提醒一下在Podfile别忘记加`use_frameworks!`然后就是在 Podfile中配置:

```ruby
pod 'ZebraKing', '~> 2.0.5'
```

### 手动安装

1. 在`Build Phases` >> `Link binary With Libraries` 中添加系统依赖库:
- CoreTelephony
- SystemConfiguration
- libc++.tbd
- libsqlite3.tbd
- libz.tbd

2. 然后在`Build Settings`中 搜索`Other Linker Flags` 添加 `-ObjC` 注意大小写拼写. 因为云通信SDK本身不支持Bitcode编码,所以还需要将`Enable Bitcode` 的值修改为`No`

---

IM聊天支持语音输入,苹果在iOS8.0以后的版本中做了限制, 所以还需要在info.plist中添加使用系统麦克风的权限:
**Privacy - Microphone Usage Description**

顺便你可能还需要其他的访问权限, 关于IM常用到的有这么几个:

- 访问照片权限
  **Privacy - Photo Library Usage Description**
- 访问相机权限
  **Privacy - Camera Usage Description**
- 访问定位权限
  **Privacy - Location Always Usage Description**
- 访问保存照片权限
  **Privacy - Photo Library Additions Usage Description**



## 开始使用



### 基础配置并处理消息通知的回调

在AppDelegate中完成初始化, 找到` didFinishLaunchingWithOptions` 方法:

```swift
// 开发者申请key时可以拿到, 是固定值
let accountType: String = 12345
let appidAt3rd: String = 1234512345

ZebraKing.register(accountType: accountType, appidAt3rd: appid) { notification in
    self.onResponseNotification(notification)
}       
```
ZebraKing将消息通知的回调暴露接口供外部使用, 开发者可以利用回调方法处理消息在前台或后台的展示逻辑, 如果消息是在App切到后台发过来的,这个时候还添加本地通知的逻辑,当收到消息需要打开会话页面时, SDK有提供一个专门的接口可实现操作, 这里需要遵守`ZebraKingDelegate`协议:



### 登录

```swift
let sign = xxxxxxx
let id = 123456
ZebraKing.login(sign: sign, userId: id, appidAt3rd: appid, result: { 
    switch $0 {
    case .success:
    //TODO:登录成功
    case .failure(let error):
    //TODO:登录失败
    }
})
```



### 发起会话

```swift
ZebraKing.chat(id: receiveId) { result in
                switch result {
                case .success(let conversation):
                    let chattingViewController = ChattingViewController(conversation: conversation)
                    let nav = UINavigationController(rootViewController: chattingViewController)
                    self.present(nav, animated: true, completion: nil)
                case .failure(_):
                    break
                }
            }
```



### 接收会话通知

```swift
func onResponseNotification(_ notification: ChatNotification) {
        
    //消息发送人的资料
    //let sender = notification.receiver

    //推送的内容
    let content = notification.content

    if case .background = UIApplication.shared.applicationState {
        //处理本地系统推送(只会在后台推送)
        UIApplication.localNotification(title: "推送消息", 
                                        body: content ?? "您收到一条新消息", 
                                        userInfo: ["chatNotification": notification])
    } else {
        openChattingViewController(with: notification)
    }
        
}

private func openChattingViewController(with notification: ChatNotification) {
     ZebraKing.chat(id: notification.receiver.id) { result in
           switch result {
           case .success(let conversation):
                let vc = ChattingViewController(conversation: conversation)
                let nav = UINavigationController(rootViewController: vc)
                self.present(nav, animated: true, completion: nil)
           case .failure(_): 
               //TODO:
               break
           }
     }
} 
```



### 下个版本需要优化的内容

1. 需要给MessageStatus一个(prepare)状态, 现在语音录制时, 使用的是发送中状态,导致真正到发送中时, 没有loading加载效果不好
2. 取消消息未发出去时,使用sdk消息替换, 这样就不需要主动判断sender是我还是对方, 并且还不用在拉取资料给它赋值了
3. 发消息出去, 个人资料不显示
4. 点击时间戳没有触发响应导致不能收回键盘
5. 新增插件的功能, 方便做日志埋点

## License

ZebraKing is available under the MIT license. See the LICENSE file for more info.
