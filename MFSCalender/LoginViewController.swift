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
import Crashlytics

class LoginView {
    func getProfile() {
        
        let semaphore = DispatchSemaphore.init(value: 0)
        let token = Preferences().token
        let userID = Preferences().userID
        
        provider.request(MyService.getProfile(userID: userID!, token: token!), callbackQueue: DispatchQueue.global(), completion: { result in
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
                                presentErrorMessage(presentMessage: "The username/password is incorrect. Please check your spelling.", layout: .cardView)
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
                        }
                    }
                    
                    if let email = resDict["Email"] as? String {
                        Preferences().email = email
                    }
                    
                    if let photo = resDict["ProfilePhoto"] as? NSDictionary {
                        if let photolink = photo["ThumbFilenameUrl"] as? String {
                            userDefaults.set(photolink, forKey: "photoLink")
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
                        print(studentInfo)
                        if (studentInfo["GradYear"] as? String).existsAndNotEmpty() {
                            Preferences().isStudent = true
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
    
    func downloadSmallProfilePhoto(photoLink: String) {
        let semaphore = DispatchSemaphore(value: 0)
        
        provider.request(.downloadLargeProfilePhoto(link: photoLink), callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case .success(let response):
                print(response.request?.url)
                userDefaults.set(false, forKey: "didDownloadFullSizeImage")
            case let .failure(error):
                NSLog("Failed downloading small profile photo because: \(error)")
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
//        let urlString = "https://mfriends.myschoolapp.com" + photoLink
//        let url = URL(string: urlString)
//        //create request.
//        var request3 = URLRequest(url: url!)
//        request3.timeoutInterval = 5
//        let downloadTask = URLSession.shared.downloadTask(with: request3, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
//            if error == nil {
//                //Temp location:
//                print("location:\(String(describing: location))")
//                let locationPath = location!.path
//                //Copy to User Directory
//                let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
//                let path = photoPath.appending("/ProfilePhoto.png")
//                //Init FileManager
//                let fileManager = FileManager.default
//                if fileManager.fileExists(atPath: path) {
//                    do {
//                        try fileManager.removeItem(atPath: path)
//                    } catch {
//                        NSLog("File does not exist! (Which is impossible)")
//                    }
//                }
//                try! fileManager.moveItem(atPath: locationPath, toPath: path)
//                print("new location:\(path)")
//                userDefaults.set(false, forKey: "didDownloadFullSizeImage")
//            } else {
//                DispatchQueue.main.async {
//                    let presentMessage = error!.localizedDescription + " Please check your internet connection."
//                    presentErrorMessage(presentMessage: presentMessage, layout: .statusLine)
//                }
//            }
//            // semaphore.signal()
//        })
//
//        //使用resume方法启动任务
//        downloadTask.resume()
        // semaphore.wait()
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

        self.username.text = Preferences().username
        self.password.text = Preferences().password

//        self.username.placeholder = "Username"
//        self.username.title = "Username"
//        
//        self.password.placeholder = "Password"
//        self.password.title = "Password"

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
            let loginNotice = SCLAlertView()
            loginNotice.addButton("Go to myMFS website", action: {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL(string: "https://mfriends.myschoolapp.com/app/#login")!, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(URL(string: "https://mfriends.myschoolapp.com/app/#login")!)
                    // Fallback on earlier versions
                }
            })
            loginNotice.showInfo("Welcome", subTitle: "Welcome to MFS Mobile. Please use your myMFS account to log in.", animationStyle: .bottomToTop)
            
            Preferences().isFirstTimeLogin = false
        }
    }

    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
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
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
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
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.error)
        var icon: String? = nil
        if presentMessage == "The username/password is incorrect. Please check your spelling." {
            icon = "🤔"
        } else {
            icon = "😱"
        }
        view.configureContent(title: "Error!", body: presentMessage, iconText: icon!)
        if presentMessage == "The username/password is incorrect. Please check your spelling." {
            view.button?.setTitle("Forgot Password", for: .normal)
            view.button?.addTarget(self, action: #selector(wrongPassword(button:)), for: .touchUpInside)
        } else {
            view.button?.isHidden = true
        }
        let config = SwiftMessages.Config()
        SwiftMessages.show(config: config, view: view)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

    @objc func wrongPassword(button: UIButton!) {
        print("Password?")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: "https://mfriends.myschoolapp.com/app/#login/request")!, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(URL(string: "https://mfriends.myschoolapp.com/app/#login/request")!)
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
            Answers.logLogin(withMethod: "Default", success: false, customAttributes: [:])
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
            self.getEvent()
        }
        
        DispatchQueue.global().async(group: group) {
            self.versionCheck()
        }
        
        group.wait()
        
        Answers.logLogin(withMethod: "Default", success: true, customAttributes: [:])
        
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
        let (success, token, _) = loginAuthentication()
        if token == "Incorrect password" {
            self.errorMessage(presentMessage: "The username/password is incorrect. Please check your spelling.")
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

                    let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                    let path = plistPath.appending("/Day.plist")
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

    func getEvent() {
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(.getCalendarEvent, completion: { result in
            switch result {
            case .success(_):
                break
            case let .failure(error):
                DispatchQueue.main.async {
                    let presentMessage = error.localizedDescription + " Please check your internet connection."
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
                    let presentMessage = error.localizedDescription + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }

            semaphore.signal()
        })

        semaphore.wait()
    }
}

