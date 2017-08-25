project 'MFSCalendar.xcodeproj'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!




target 'MFSCalendar' do
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
    pod 'SwiftDate', '~> 4.0'
    pod 'DGElasticPullToRefresh'
    pod 'ReachabilitySwift'
    pod 'XLPagerTabStrip', '~> 7.0'
    pod 'Firebase/Core'
    pod 'Firebase/Performance'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Alamofire', '~> 4.4'
    pod 'SDWebImage', '~>3.8'
    pod 'Moya'
    # pod 'IGListKit'
    pod 'M13ProgressSuite'
    pod 'SnapKit'
    pod 'RAMAnimatedTabBarController'
    pod 'JSQWebViewController'
    pod 'Down'
end

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-MFSCalendar/Pods-MFSCalendar-acknowledgements.markdown', 'MFSCalender/Acknowledgements.markdown', :remove_destination => true)
end