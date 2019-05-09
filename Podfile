project 'MFSMobile.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!
# Main 


target 'MFSMobile' do
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
  pod 'DGElasticPullToRefresh'
  pod 'ReachabilitySwift'
  pod 'XLPagerTabStrip'
  pod 'Firebase/Core'
  pod 'Firebase/Performance'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Alamofire'
  pod 'SDWebImage'
  pod 'Moya'
  pod 'M13ProgressSuite'
  pod 'SnapKit'
  pod 'JSQWebViewController'
  pod 'Down'
  pod 'Spring'
  pod 'Kanna'
  pod 'SVProgressHUD'
  pod 'UrbanAirship-iOS-SDK'
  pod 'Charts'
  pod 'p2.OAuth2'
  pod 'SwiftyJSON'
  pod "ChatSDK"
  pod "ChatSDKFirebase/Adapter"
  pod "ChatSDKFirebase/FileStorage"
  pod "ChatSDKFirebase/Push"
  # pod 'GSKStretchyHeaderView'
end

target 'Class Schedule' do
  pod 'SwiftDate'
end

post_install do |installer|
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-MFSMobile/Pods-MFSMobile-acknowledgements.markdown', 'MFSCalender/Acknowledgements.markdown', :remove_destination => true)
end