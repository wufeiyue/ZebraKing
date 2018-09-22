#
# Be sure to run `pod lib lint ZebraKing.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZebraKing'
  s.version          = '2.0.0'
  s.summary          = 'ZebraKing这是基于腾讯云通信IM封装而来,简单可依赖,定期依据官网更新版本, 欢迎使用'
  s.description      = <<-DESC
ZebraKing是基于腾讯云通信V3.0版本更新而来,此版本较v2.0变化不大,移除一些多余的API,整体逻辑更清晰, 使用swift4.0编写
                       DESC

  s.homepage         = 'https://github.com/wufeiyue/ZebraKing'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eppeo' => 'ieppeo@163.com' }
  s.source           = { :git => 'git@github.com/wufeiyue/zebraking.git', :tag => "#{s.version}" }
  s.requires_arc = true
  s.ios.deployment_target = '8.2'
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS'            => '-ObjC',
                            'ENABLE_BITCODE'           => 'NO'
                          }

  s.source_files = 'ZebraKing/Classes/**/*'
  s.ios.vendored_frameworks = "ZebraKing/Framework/*.framework"
  s.preserve_paths = 'ZebraKing/Framework/module.modulemap'

  s.ios.resource_bundle = { 'ZebraKingAssets' => 'ZebraKing/Assets/ZebraKingAssets.bundle/Images' }

  s.frameworks = 'CoreTelephony', 'SystemConfiguration'
  s.libraries = 'c++', 'z', 'sqlite3'
  #s.dependency 'TSVoiceConverter', '~> 0.1.6'
  s.dependency 'SnapKit'
  s.dependency 'Kingfisher'

end
