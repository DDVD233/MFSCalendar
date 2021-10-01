project 'MFSMobile.xcodeproj'
platform :ios, '11.0'
use_frameworks!
# Main 


target 'MFSMobile' do
  pod 'AFNetworking'
  pod 'SwiftMessages'
  pod 'NVActivityIndicatorView'
  pod 'UICircularProgressRing'
  pod 'SCLAlertView'
  pod 'SkyFloatingLabelTextField'
  pod 'DZNEmptyDataSet'
  pod 'FSCalendar'
  pod 'LTMorphingLabel'
  pod 'SwiftyJSON'
  pod 'DGElasticPullToRefresh', :git => 'https://github.com/Lateblumer88/DGElasticPullToRefresh.git', :branch => 'Feature/Swift5Support'
  pod 'M13Checkbox'
  pod 'SwiftDate'
  pod 'CRRefresh'
  pod 'XLPagerTabStrip'
  pod 'Firebase/Analytics'  
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Performance'
  pod 'Alamofire'
  pod 'SDWebImage'
  pod 'Moya'
  pod 'M13ProgressSuite'
  pod 'SnapKit'
  pod 'Down'
  pod 'Kanna'
  pod 'SVProgressHUD'
  pod 'Charts'
  pod 'SwiftyJSON'
  pod 'SwipeCellKit'
  # pod 'GSKStretchyHeaderView'
end

target 'Class Schedule' do
  pod 'SwiftDate'
end

target 'Next ClassExtension' do
  pod 'SwiftDate'
end

post_install do |installer|
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-MFSMobile/Pods-MFSMobile-acknowledgements.markdown', 'MFSCalender/Acknowledgements.markdown', :remove_destination => true)
  # installer.pods_project.targets.each do |target|
  #   if target.name == "Pods-MFSMobile"
  #     puts "Updating #{target.name} to exclude Crashlytics/Fabric"
  #     target.build_configurations.each do |config|
  #       xcconfig_path = config.base_configuration_reference.real_path
  #       xcconfig = File.read(xcconfig_path)
  #       xcconfig.sub!('-framework "FirebaseAnalytics"', '')
  #       new_xcconfig = xcconfig + 'OTHER_LDFLAGS[sdk=iphone*] = -framework "FirebaseAnalytics"'
  #       File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
  #     end
  #   end
  # end
end