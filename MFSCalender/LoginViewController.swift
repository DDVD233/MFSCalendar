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

class firstTimeLaunchController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var wrongPassword: UILabel!
    @IBOutlet weak var username: SkyFloatingLabelTextField!
    @IBOutlet weak var password: SkyFloatingLabelTextField!

    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var NVIndicator: NVActivityIndicatorView!

    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!


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

        self.username.text = userDefaults?.string(forKey: "username")
        self.password.text = userDefaults?.string(forKey: "password")

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
        let loginNotice = SCLAlertView()
        loginNotice.addButton("Go to myMFS website", action: {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: "https://mfriends.myschoolapp.com/app/#login")!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(URL(string: "https://mfriends.myschoolapp.com/app/#login")!)
                // Fallback on earlier versions
            }
        })
        loginNotice.showInfo("Welcome", subTitle: "Welcome to MFS Calendar. Please use your myMFS account to log in.", animationStyle: .bottomToTop)
    }

    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.bottomLayoutConstraint?.constant = 0.0
            } else {
                self.bottomLayoutConstraint?.constant = (endFrame?.size.height)! + 60
            }
            UIView.animate(withDuration: duration,
                    delay: TimeInterval(0),
                    options: animationCurve,
                    animations: { self.view.layoutIfNeeded() },
                    completion: nil)
        }
    }

    func keyboardHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            self.bottomLayoutConstraint?.constant = 220
            UIView.animate(withDuration: duration,
                    delay: TimeInterval(0),
                    options: animationCurve,
                    animations: { self.view.layoutIfNeeded() },
                    completion: nil)
        }
    }

    func errorMessage(presentMessage: String) {
        let view = MessageView.viewFromNib(layout: .CardView)
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

    func wrongPassword(button: UIButton!) {
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

        self.wrongPassword.isHidden = true
        if (self.username.text?.isEmpty)! || (self.password.text?.isEmpty)! {

        } else if self.username.text == "testaccount" && self.password.text == "test" {
            userDefaults?.set(self.username.text, forKey: "username")
            userDefaults?.set(self.password.text, forKey: "password")
            userDefaults?.set("David", forKey: "firstName")
            userDefaults?.set("Dai", forKey: "lastName")
            userDefaults?.set("77", forKey: "lockerNumber")
            userDefaults?.set("233", forKey: "lockerPassword")
            DispatchQueue.global().async(execute: {
                DispatchQueue.main.sync {
                    self.indicatorView.isHidden = false
                    self.NVIndicator.startAnimating()
                }
                if self.initDayData() && self.getEvent() && self.versionCheck() {
                    userDefaults?.set(true, forKey: "didLogin")
                    self.dismiss(animated: true, completion: nil)
                }
                self.indicatorView.isHidden = true
            })
        } else {
//Global Async Begins................
            DispatchQueue.global().async(execute: {
                DispatchQueue.main.sync {
                    self.indicatorView.isHidden = false
                    self.NVIndicator.startAnimating()
                }
                if self.authentication() {
                    if self.getProfile() && self.initDayData() && self.getEvent() && self.versionCheck() {
                        userDefaults?.set(self.username.text, forKey: "username")
                        userDefaults?.set(self.password.text, forKey: "password")
                        userDefaults?.set(true, forKey: "didLogin")
                        DispatchQueue.main.sync {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
                DispatchQueue.main.sync {
                    self.indicatorView.isHidden = true
                }

            })
//Global Async Ends...........
        }
    }
}

extension firstTimeLaunchController {

    func authentication() -> Bool {
        guard let username = self.username.text else {
            return false
        }
        guard let password = self.password.text else {
            return false
        }
        userDefaults?.set(username, forKey: "username")
        userDefaults?.set(password, forKey: "password")
        let (success, token, _) = loginAuthentication()
        if token == "Incorrect password" {
            self.errorMessage(presentMessage: "The username/password is incorrect. Please check your spelling.")
        } else if !success {
            self.errorMessage(presentMessage: token)
        } else {
            userDefaults?.set(token, forKey: "token")
            return true
        }

        return false
    }

    func getProfile() -> Bool {

        let semaphore = DispatchSemaphore.init(value: 0)
        let token = userDefaults?.string(forKey: "token")
        let userID = userDefaults?.string(forKey: "userID")
        var success: Bool = false

        provider.request(MyService.getProfile(userID: userID!, token: token!), completion: { result in
            switch result {
            case let .success(response):
                do {
                    guard let resDict = try response.mapJSON() as? Dictionary<String, Any?> else {
                        presentErrorMessage(presentMessage: "Internal error: incorrect file format.", layout: .CardView)

                        return
                    }

                    guard resDict["Error"] == nil else {
                        //                        When error occured.
                        print("Login Error!")
                        if (resDict["ErrorType"] as! String) == "UNAUTHORIZED_ACCESS" {
                            DispatchQueue.main.async {
                                presentErrorMessage(presentMessage: "The username/password is incorrect. Please check your spelling.", layout: .CardView)
                            }
                        }

                        return
                    }

                    if let firstName = resDict["FirstName"] as? String {
                        userDefaults?.set(firstName, forKey: "firstName")
                    }

                    if let lastName = resDict["LastName"] as? String {
                        userDefaults?.set(lastName, forKey: "lastName")
                    }

                    if let photo = resDict["ProfilePhoto"] as? NSDictionary {
                        if let photolink = photo["ThumbFilenameUrl"] as? String {
                            userDefaults?.set(photolink, forKey: "photoLink")
                            self.downloadSmallProfilePhoto(photoLink: photolink)
                        }

                        let largePhotoLink = photo["LargeFilenameUrl"] as? String
                        userDefaults?.set(largePhotoLink, forKey: "largePhotoLink")
                    }

                    if let lockerNumber = resDict["LockerNbr"] as? String {
                        userDefaults?.set(lockerNumber, forKey: "lockerNumber")
                    }
                    if let lockerPassword = resDict["LockerCombo"] as? String {
                        userDefaults?.set(lockerPassword, forKey: "lockerPassword")
                    }
                    success = true

                } catch {
                    NSLog("Data parsing failed")
                    DispatchQueue.main.async {
                        self.errorMessage(presentMessage: error.localizedDescription)
                    }
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .CardView)
            }

            semaphore.signal()
        })

        semaphore.wait()

        return success
    }

    func downloadSmallProfilePhoto(photoLink: String) {
        let semaphore = DispatchSemaphore(value: 0)

        let urlString = "https://mfriends.myschoolapp.com" + photoLink
        let url = URL(string: urlString)
        //create request.
        let request3 = URLRequest(url: url!)
        let downloadTask = URLSession.shared.downloadTask(with: request3, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                //Temp location:
                print("location:\(String(describing: location))")
                let locationPath = location!.path
                //Copy to User Directory
                let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = photoPath.appending("/ProfilePhoto.png")
                //Init FileManager
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path) {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        NSLog("File does not exist! (Which is impossible)")
                    }
                }
                try! fileManager.moveItem(atPath: locationPath, toPath: path)
                print("new location:\(path)")
                userDefaults?.set(false, forKey: "didDownloadFullSizeImage")
            } else {
                DispatchQueue.main.async {
                    let presentMessage = error!.localizedDescription + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }
            semaphore.signal()
        })

        //使用resume方法启动任务
        downloadTask.resume()
        semaphore.wait()
    }

    //Get calendar's day data.
    func initDayData() -> Bool {
        var success = false
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
                    success = true
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: MessageView.Layout.StatusLine)
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

        return success
    }

    func getEvent() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(.getCalendarEvent, completion: { result in
            switch result {
            case .success(_):
                success = true
            case let .failure(error):
                DispatchQueue.main.async {
                    let presentMessage = error.localizedDescription + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }
            semaphore.signal()
        })

        semaphore.wait()
        return success
    }

    func versionCheck() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)

        provider.request(MyService.dataVersionCheck, completion: { result in
            switch result {
            case let .success(response):
                guard let version = String(data: response.data, encoding: .utf8) else {
                    return
                }
                let versionNumber = Int(version)
                print("Version: %@", versionNumber!)
                userDefaults?.set(versionNumber, forKey: "version")
                success = true
            case let .failure(error):
                DispatchQueue.main.async {
                    let presentMessage = error.localizedDescription + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }

            semaphore.signal()
        })

        semaphore.wait()
        return success
    }
}

