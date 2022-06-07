
Pod::Spec.new do |s|
  s.name             = 'FFSoundProcess'
  s.version          = '0.5.5'
  s.summary          = 'A short description of FFSoundProcess.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://gitlab.yinyuebao.com/xxyy/client/ios/ArtPods/FFSoundProcess'
     # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jinyuyoulong' => 'fan.jinlong@qq.com' }
  s.source           = { :git => 'http://gitlab.yinyuebao.com/xxyy/client/ios/ArtPods/FFSoundProcess.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.swift_versions = ['5.0']
  
  s.source_files = 'FFSoundProcess/Classes/**/*'
#  s.public_header_files = ""
  s.private_header_files = 'FFSoundProcess/Classes/XBAudioUnitRecorder.h'

  s.ios.vendored_frameworks = 'FFSoundProcess/Frameworks/*.framework'
  s.resource = 'FFARService/Assets/*.tflite'
  s.libraries = 'c++'
  
  s.dependency 'PFAudioLib'
  s.dependency 'OSAbility'
  
  # s.frameworks = 'CoreMIDI'
  s.static_framework = true
  
  #// 配置当前库的 bitcode
  s.pod_target_xcconfig  = {
    'ENABLE_BITCODE' => 'NO',
    'EXCLUDED_ARCHS[sdk=*]' => 'armv7'
   }
  #// 配置宿主工程的 bitcode
  # s.user_target_xcconfig = {
  #   'ENABLE_BITCODE' => 'NO' ,
  #   'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  # }
#  s.xcconfig = {
#      'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
#      'CLANG_CXX_LIBRARY' => 'libc++'
#  }
end
