#BMKP_Chat设计文档

分两大模块
- 聊天UI (IMChatViewController)
- 会话管理 (IMConversationManager)

目录:
1. 了解BMKP_Chat的使用
2. 

### 了解BMKP_Chat的使用
通过cocoaPods集成,在podfile中完成配置:
```ruby
pod 'BMKP_Chat'
```

如果顺利的话,集成完成可以看到在**Build Setting**中的**Other Linker Flags项**已经添加了**-ObjC**,在




# BMKP_Chat

[![CI Status](http://img.shields.io/travis/eppeo/BMChat.svg?style=flat)](https://travis-ci.org/eppeo/BMChat)
[![Version](https://img.shields.io/cocoapods/v/BMChat.svg?style=flat)](http://cocoapods.org/pods/BMChat)
[![License](https://img.shields.io/cocoapods/l/BMChat.svg?style=flat)](http://cocoapods.org/pods/BMChat)
[![Platform](https://img.shields.io/cocoapods/p/BMChat.svg?style=flat)](http://cocoapods.org/pods/BMChat)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
1.引入Framework
```
ImSDK
QALSDK
TLSSDK
IMMessageExt
```
2.引入系统依赖库
```
CoreTelephony.framework
SystemConfiguration.framework
libstdc++.6.dylib
libc++.dylib
libz.dylib
libsqlite3.dylib
```
3.xcode设置



4.加入 cocoaPods

```
pod 'BMKP_Package'
pod 'YYText', '~> 1.0.7'
pod 'HandyJSON', '~> 4.0.0-beta.1'
pod 'TSVoiceConverter', '~> 0.1.6'
```

5.增加资源文件

有关的图片资源全部放在Asses/BMChat目录下

## Installation

BMChat is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

## 随便写,随笔
- 2017.12.19
1.新增IMMessageList类,对IMChatViewController中的消息数据源进行管理,

## License

BMChat is available under the MIT license. See the LICENSE file for more info.
