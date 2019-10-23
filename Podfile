project 'MFSMobile.xcodeproj'
platform :ios, '11.0'
use_frameworks!
# Main 


target 'MFSMobile' do
  pod 'AFNetworking', :git => 'https://github.com/blissapps/AFNetworking.git', :branch => 'feature/WKWebView'
  pod 'SwiftMessages'
  pod 'NVActivityIndicatorView'
  pod 'UICircularProgressRing'
  pod 'SCLAlertView'
  pod 'SkyFloatingLabelTextField'
  pod 'DZNEmptyDataSet'
  pod 'FSCalendar'
  pod 'LTMorphingLabel'
  pod 'SwiftyJSON'
  pod 'M13Checkbox'
  pod 'SwiftDate'
  pod 'DGElasticPullToRefresh', :git => 'https://github.com/KennethTsang/DGElasticPullToRefresh.git'
  pod 'XLPagerTabStrip'
#   pod 'Firebase/Core'
#   pod 'Firebase/Performance'
#   pod 'Fabric'
  pod 'Alamofire'
  pod 'SDWebImage'
  pod 'Moya'
  pod 'M13ProgressSuite', "= 1.2.5"
  pod 'SnapKit'
  pod 'Down'
  pod 'Kanna'
  pod 'SVProgressHUD'
  pod 'Charts'
#   pod 'p2.OAuth2'
  pod 'SwiftyJSON'
  pod "ChatSDK"
#   pod "ChatSDKFirebase/Adapter"
#   pod "ChatSDKFirebase/FileStorage"
#   pod "ChatSDKFirebase/Push"
  pod 'SwipeCellKit'
  # pod 'GSKStretchyHeaderView'
end

target 'Class Schedule' do
  pod 'SwiftDate'
end

post_install do |installer|
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-MFSMobile/Pods-MFSMobile-acknowledgements.markdown', 'MFSCalender/Acknowledgements.markdown', :remove_destination => true)
end