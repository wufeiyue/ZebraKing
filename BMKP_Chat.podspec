#
# Be sure to run `pod lib lint BMChat.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BMKP_Chat'
  s.version          = '1.0.1'
  s.summary          = 'BMChat这是基于腾讯云通信IM封装而来,简单可依赖,定期依据官网更新版本, 欢迎使用'
  s.description      = <<-DESC
BMChat是基于腾讯云通信V3.0版本更新而来,此版本较v2.0变化不大,移除一些多余的API,整体逻辑更清晰
                       DESC

  s.homepage         = 'https://github.com/wufeiyue/BMChat'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eppeo' => 'ieppeo@163.com' }
  s.source           = { :git => 'git@github.com/wufeiyue/BMChat.git', :tag => "#{s.version}" }
  s.requires_arc = true
  s.ios.deployment_target = '8.2'
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS'            => '-ObjC',
                            'ENABLE_BITCODE'           => 'NO'
                          }

  s.source_files = 'BMKP_Chat/Classes/**/*'
  s.ios.vendored_frameworks = "BMKP_Chat/Framework/*.framework"
  s.preserve_paths = 'BMKP_Chat/Framework/module.modulemap'

  # 'BMKP_Chat' => ['BMKP_Chat/Assets/**/*.png',
  s.resource_bundles = {
     'BMKP_Chat' => ['BMKP_Chat/Assets/**/**.gif']
  }

  s.frameworks = 'CoreTelephony', 'SystemConfiguration'
  s.libraries ='stdc++.6', 'c++', 'z', 'sqlite3'
  s.dependency 'YYText', '~> 1.0.7'
  s.dependency 'TSVoiceConverter', '~> 0.1.6'
  s.dependency 'SnapKit'
  s.dependency 'Kingfisher'
  s.dependency 'BMKP_Network'
  s.dependency 'DynamicColor'
  s.dependency 'MJRefresh'
  s.dependency 'SwiftDate'

end
