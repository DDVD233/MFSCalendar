//
//  firstTimeLaunch.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/4/23.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import SwiftMessages
import NVActivityIndicatorView
import SCLAlertView
import SkyFloatingLabelTextField
import NotificationCenter
#if !targetEnvironment(macCatalyst)
    import FirebaseCrashlytics
    import FirebaseAnalytics
#endif
import SwiftDate
import SwiftyJSON

class LoginView {
    func getProfile() {
        let semaphore = DispatchSemaphore.init(value: 0)
        guard let token = Preferences().token else { return }
        guard let userID = Preferences().userID else { return }
        print(userID)
        
        provider.request(MyService.getProfile(userID: userID, token: token), callbackQueue: DispatchQueue.global(), completion: { result in
            switch result {
            case let .success(response):
                do {
                    guard let resDict = try response.mapJSON() as? Dictionary<String, Any?> else {
                        presentErrorMessage(presentMessage: "Internal error: incorrect file format.", layout: .cardView)
                        semaphore.signal()
                        return
                    }
                    
                    print(resDict)
                    
                    guard resDict["Error"] == nil else {
                        //                        When error occured.
                        print("Login Error!")
                        if (resDict["ErrorType"] as! String) == "UNAUTHORIZED_ACCESS" {
                            DispatchQueue.main.async {
                                presentErrorMessage(presentMessage: NSLocalizedString("The username/password is incorrect. Please check your spelling.", comment: ""), layout: .cardView)
                            }
                        }
                        
                        semaphore.signal()
                        return
                    }
                    
                    if let firstName = resDict["FirstName"] as? String, let lastName = resDict["LastName"] as? String {
                        Preferences().firstName = firstName
                        Preferences().lastName = lastName
                        if firstName == "Wei" && lastName == "Dai" {
                            Preferences().isDev = true
                        } else {
                            Preferences().isDev = false
                        }
                    }
                    
                    if let email = resDict["Email"] as? String {
                        Preferences().email = email
                    }
                    
                    if let photo = resDict["ProfilePhoto"] as? NSDictionary {
                        if let photolink = photo["ThumbFilenameUrl"] as? String {
                            Preferences().photoLink = photolink
                            print(photolink)
                            self.downloadSmallProfilePhoto(photoLink: photolink)
                        }
                        
                        let largePhotoLink = photo["LargeFilenameUrl"] as? String
                        userDefaults.set(largePhotoLink, forKey: "largePhotoLink")
                    }
                    
                    if let lockerNumber = resDict["LockerNbr"] as? String {
                        Preferences().lockerNumber = lockerNumber
                    }
                    if let lockerPassword = resDict["LockerCombo"] as? String {
                        Preferences().lockerCombination = lockerPassword
                    }
                    
                    Preferences().isStudent = false
                    if let studentInfo = resDict["StudentInfo"] as? [String: Any] {
//                        //TODO
                        print(studentInfo)
                        if let graduationYear = studentInfo["GradYear"] as? String {
                            Preferences().isStudent = true
                            print(graduationYear)
                            let gradYearInt = Int(graduationYear)!
                            var year = DateInRegion().year
                            // For example, if I'm a senior who will graduate in 2019.
                            // Then my gradelevel should be 12 - (2019-2019) = 12
                            if DateInRegion().month > 8 {
                                year += 1
                            }
                            Preferences().gradeLevel = 12 - (gradYearInt - year)
                        }
                    }
                    
                    
                    
                } catch {
                    NSLog("Data parsing failed")
                    DispatchQueue.main.async {
                        presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                    }
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
            }
            
            semaphore.signal()
        })
        
        semaphore.wait()
    }
    
    func getPersonaId() {
        guard loginAuthentication().success else { return }
        provider.request(MyService.getSchoolContext, callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case let .success(response):
                do {
                    let json = try JSON(data: response.data)
                    let personaId = json["Personas"][0]["Id"].int ?? 0
                    Preferences().personaId = String(personaId)
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
            }
        }
    }
    
    func downloadSmallProfilePhoto(photoLink: String) {
        let semaphore = DispatchSemaphore(value: 0)
        
        provider.request(.downloadLargeProfilePhoto(link: photoLink), callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case .success(let response):
                print(response.request?.url as Any)
                userDefaults.set(false, forKey: "didDownloadFullSizeImage")
            case let .failure(error):
                NSLog("Failed downloading small profile photo because: \(error)")
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
    }
}

class firstTimeLaunchController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var wrongPassword: UILabel!
    @IBOutlet weak var username: SkyFloatingLabelTextField!
    @IBOutlet weak var password: SkyFloatingLabelTextField!

    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var NVIndicator: NVActivityIndicatorView!
    
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!

    @IBOutlet var logoPhoto: UIImageView!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {

        self.indicatorView.backgroundColor = UIColor.black
        self.NVIndicator.type = .ballClipRotatePulse

        self.loginView.layer.shadowColor = UIColor.black.cgColor
        self.loginView.layer.shadowOpacity = 0.5
        self.loginView.layer.shadowOffset = CGSize.zero
        self.loginView.layer.shadowRadius = 10
        self.wrongPassword.isHidden = true
        self.username.delegate = self
        self.password.delegate = self
        
        if Preferences().schoolName == "MFS" {
            self.logoPhoto.image = UIImage(named: "MFS Logo.jpg")
        } else if Preferences().schoolName == "CMH" {
            self.logoPhoto.image = UIImage(named: "CMH Logo.png ")
        }

        self.username.text = Preferences().username
        self.password.text = Preferences().password

//        self.username.placeholder = "Username"
//        self.username.title = "Username"
//        
//        self.password.placeholder = "Password"
//        self.password.title = "Password"

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.indicatorView.isHidden = true
    }


    override func viewDidAppear(_ animated: Bool) {
        let isFirstTimeLogin = Preferences().isFirstTimeLogin
        if isFirstTimeLogin {
            Preferences().isFirstTimeLogin = false
            let loginNotice = SCLAlertView()
            loginNotice.addButton("Go to mySchool website", action: {
                UIApplication.shared.open(URL(string: Preferences().baseURL + "/app/#login")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            })
            loginNotice.showInfo(NSLocalizedString("Welcome", comment: ""), subTitle: NSLocalizedString("Welcome to Class Master. Please use your mySchool account to log in.", comment: ""), animationStyle: .bottomToTop)
        }
    }

    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.bottomLayoutConstraint?.constant = 0.0
            } else {
                self.bottomLayoutConstraint?.constant = endFrame!.size.height + 15
            }
            UIView.animate(withDuration: duration,
                    delay: TimeInterval(0),
                    options: animationCurve,
                    animations: {
                        self.logoPhoto.isHidden = true
                        self.view.layoutIfNeeded()
                    },
                    completion: nil)
        }
    }

    @objc func keyboardHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            self.bottomLayoutConstraint?.constant = 20
            UIView.animate(withDuration: duration,
                    delay: TimeInterval(0),
                    options: animationCurve,
                    animations: {
                        self.logoPhoto.isHidden = false
                        self.view.layoutIfNeeded()
                    },
                    completion: nil)
        }
    }

    func errorMessage(presentMessage: String) {
        DispatchQueue.main.async {
            let view = MessageView.viewFromNib(layout: .cardView)
            view.configureTheme(.error)
            var icon: String? = nil
            if presentMessage == NSLocalizedString("The username/password is incorrect. Please check your spelling.", comment: "") {
                icon = "🤔"
            } else {
                icon = "😱"
            }
            view.configureContent(title: "Error!", body: presentMessage, iconText: icon!)
            if presentMessage == NSLocalizedString("The username/password is incorrect. Please check your spelling.", comment: "") {
                view.button?.setTitle(NSLocalizedString("Forgot Password", comment: ""), for: .normal)
                view.button?.addTarget(self, action: #selector(self.wrongPassword(button:)), for: .touchUpInside)
            } else {
                view.button?.isHidden = true
            }
            let config = SwiftMessages.Config()
            SwiftMessages.show(config: config, view: view)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

    @objc func wrongPassword(button: UIButton!) {
        print("Password?")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: Preferences().baseURL + "/app/#login/request")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(URL(string: Preferences().baseURL + "/app/#login/request")!)
        }
    }

    //When you click "Log in".
    @IBAction func done(_ sender: Any) {
        guard self.username.text.existsAndNotEmpty() && self.password.text.existsAndNotEmpty() else { return }
        
        DispatchQueue.global().async {
            self.login()
        }
    }
    
    func login() {
        DispatchQueue.main.async {
            self.indicatorView.isHidden = false
            self.NVIndicator.startAnimating()
        }
        
        guard self.authentication() else {
            #if !targetEnvironment(macCatalyst)
            Analytics.logEvent("AnalyticsEventLogin", parameters: [
                AnalyticsParameterSuccess: false
            ])
            #endif
            
            DispatchQueue.main.async {
                self.indicatorView.isHidden = true
            }
            return
        }
        
        Preferences().didLogin = true
        
        let group = DispatchGroup()
        
        DispatchQueue.global().async(group: group) {
            LoginView().getProfile()
        }
        
        DispatchQueue.global().async(group: group) {
            self.initDayData()
        }
        
        DispatchQueue.global().async(group: group) {
            LoginView().getPersonaId()
        }
        
//        DispatchQueue.global().async(group: group) {
//            self.versionCheck()
//        }
        
        group.wait()
        
        DispatchQueue.global().async(group: group) {
            let semaphore = DispatchSemaphore(value: 0)
            NetworkOperations().refreshEvents(completion: {
                semaphore.signal()
            })
            
            semaphore.wait()
        }
        
        Analytics.logEvent("AnalyticsEventLogin", parameters: [
            AnalyticsParameterSuccess: true
        ])
        
        
        DispatchQueue.main.async {
            self.indicatorView.isHidden = true
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension firstTimeLaunchController {

    func authentication() -> Bool {
        var username: String? = nil
        var password: String? = nil
        DispatchQueue.main.sync {
            username = self.username.text
            password = self.password.text
        }
        
        guard username.existsAndNotEmpty() && password.existsAndNotEmpty() else {
            return false
        }
        
        Preferences().username = username
        Preferences().password = password
        Preferences().loginTime = nil
        let (success, token, _) = loginAuthentication()
        if token == "Incorrect password" {
            self.errorMessage(presentMessage: NSLocalizedString("The username/password is incorrect. Please check your spelling.", comment: ""))
        } else if !success {
            self.errorMessage(presentMessage: token)
        } else {
            Preferences().token = token
            return true
        }

        return false
    }

    //Get calendar's day data.
    func initDayData() {
        let semaphore = DispatchSemaphore.init(value: 0)

        //Task 1: Getting day data.

        provider.request(.getCalendarData, completion: { result in
            switch result {
            case let .success(response):
                do {
                    let resDict = try response.mapJSON() as! NSDictionary

                    let path = FileList.day.filePath
                    resDict.write(toFile: path, atomically: true)
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: MessageView.Layout.statusLine)
                    NSLog("Day Data: Data parsing failed")
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    let presentMessage = error.localizedDescription
                    self.errorMessage(presentMessage: presentMessage)
                }
            }

            semaphore.signal()
        })

        semaphore.wait()
    }

    func versionCheck() {
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(MyService.dataVersionCheck, completion: { result in
            switch result {
            case let .success(response):
                guard let version = String(data: response.data, encoding: .utf8) else {
                    return
                }
                let versionNumber = Int(version)
                print("Version: %@", versionNumber ?? 0)
                Preferences().version = versionNumber ?? 0
            case let .failure(error):
                DispatchQueue.main.async {
                    let presentMessage = error.localizedDescription + NSLocalizedString(" Please check your internet connection.", comment: "")
                    self.errorMessage(presentMessage: presentMessage)
                }
            }

            semaphore.signal()
        })

        semaphore.wait()
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
