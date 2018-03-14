project 'MFSMobile.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!
# Main 


target 'MFSMobile' do
  pod 'SwiftMessages'
  pod 'NVActivityIndicatorView'
  pod 'UICircularProgressRing'
  pod 'SCLAlertView'
  pod 'SkyFloatingLabelTextField', :git => 'https://github.com/Skyscanner/SkyFloatingLabelTextField.git', :branch => 'master'
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

  pod 'Spring', :git => 'https://github.com/MengTo/Spring.git', :branch => 'swift4'
  pod 'Kanna', :git => 'https://github.com/tid-kijyun/Kanna.git', :branch => 'feature/v4.0.0'
  pod 'SVProgressHUD'
  pod 'UrbanAirship-iOS-SDK'
  pod 'Charts'
  pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
  # pod 'GSKStretchyHeaderView'
end

target 'Class Schedule' do
  pod 'SwiftDate'
end

post_install do |installer|
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-MFSMobile/Pods-MFSMobile-acknowledgements.markdown', 'MFSCalender/Acknowledgements.markdown', :remove_destination => true)
end