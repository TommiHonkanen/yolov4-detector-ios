platform :ios, '15.0'
use_frameworks!

project 'yolov4-detector.xcodeproj'

target 'yolov4-detector' do
  # Use the local OpenCV 4.11 podspec
  pod 'OpenCV', :podspec => './OpenCV.podspec.json'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end