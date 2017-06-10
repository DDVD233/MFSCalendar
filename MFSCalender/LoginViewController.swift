//
//  firstTimeLaunch.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/4/23.
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
    
    let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")
    

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
        
        self.username.text = self.userDefaults?.string(forKey: "username")
        self.password.text = self.userDefaults?.string(forKey: "password")
        
        self.username.placeholder = "Username"
        self.username.title = "Username"
        
        self.password.placeholder = "Password"
        self.password.title = "Password"
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHide(notification:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
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
            UIApplication.shared.open(URL(string: "https://mfriends.myschoolapp.com/app/#login")!, options: [:], completionHandler: nil)
        })
        loginNotice.showInfo("Welcome", subTitle: "Welcome to MFS Calendar. Please use your myMFS account to log in.", animationStyle: .bottomToTop)
    }
    
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
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
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
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
        UIApplication.shared.open(URL(string: "https://mfriends.myschoolapp.com/app/#login/request")!, options: [:], completionHandler: nil)
    }
    
    //When you click "Log in".
    @IBAction func done(_ sender: Any) {

        self.wrongPassword.isHidden = true
        if (self.username.text?.isEmpty)! || (self.password.text?.isEmpty)! {
        
        } else if self.username.text == "testaccount" && self.password.text == "test" {
            self.userDefaults?.set(self.username.text, forKey: "username")
            self.userDefaults?.set(self.password.text, forKey: "password")
            self.userDefaults?.set("David", forKey: "firstName")
            self.userDefaults?.set("Dai", forKey: "lastName")
            self.userDefaults?.set("77", forKey: "lockerNumber")
            self.userDefaults?.set("233", forKey: "lockerPassword")
            DispatchQueue.global().async(execute: {
                DispatchQueue.main.sync {
                    self.indicatorView.isHidden = false
                    self.NVIndicator.startAnimating()
                }
                if self.initDayData() && self.getEvent() && self.versionCheck() {
                    self.userDefaults?.set(true, forKey: "didLogin")
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
                        self.userDefaults?.set(self.username.text, forKey: "username")
                        self.userDefaults?.set(self.password.text, forKey: "password")
                        self.userDefaults?.set(true, forKey: "didLogin")
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
        var token: String? = nil
        var userID: String? = nil
        var success: Bool = false
        // This may hurt people who use space as their password.
        let usernameText = self.username.text?.replace(target: " ", withString: "")
        let passwordText = self.password.text?.replace(target: " ", withString: "")
        let accountCheckURL = "https://mfriends.myschoolapp.com/api/authentication/login/?username=" + usernameText! + "&password=" + passwordText! + "&format=json"
        let url = NSURL(string: accountCheckURL)
        let request = URLRequest(url: url! as URL)
        let session = URLSession.shared
        let semaphore = DispatchSemaphore.init(value: 0)
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                do {
                    let resDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                    print(resDict)
                    if resDict["Error"] != nil {
                        //                        When error occured. Like the username or password is not correct.
                        print("Login Error!")
                        if (resDict["ErrorType"] as! String) == "UNAUTHORIZED_ACCESS" {
                            DispatchQueue.main.async {
                                let presentMessage = "The username/password is incorrect. Please check your spelling."
                                self.errorMessage(presentMessage: presentMessage)
                            }
                        }
                    } else {
                        //                      When authentication is success.
                        success = true
                        token = resDict["Token"] as? String
                        userID = String(describing: resDict["UserId"]!)
                        self.userDefaults?.set(token, forKey: "token")
                        self.userDefaults?.set(userID, forKey: "userID")
                        
                    }
                } catch {
                    NSLog("Data parsing failed")
                    DispatchQueue.main.async {
                        let presentMessage = "The server is not returning the right data. Please contact David."
                        self.errorMessage(presentMessage: presentMessage)
                        
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
                
            }
            semaphore.signal()
            
        })
        
        task.resume()
        semaphore.wait()
        return success
    }
    
    func getProfile() -> Bool {
        let session = URLSession.shared
        let semaphore = DispatchSemaphore.init(value: 0)
        let token = userDefaults?.string(forKey: "token")
        let userID = userDefaults?.string(forKey: "userID")
        var success: Bool = false
        
        //            Copy & Paste (-_-). Gat: 1. Name 2.Locker Number & Password  3. Photo
        let profileCheckURL = "https://mfriends.myschoolapp.com/api/user/" + userID! + "/?t=" + token! + "&format=json"
        let url2 = NSURL(string: profileCheckURL)
        let request2 = URLRequest(url: url2! as URL)
        var photolink: String? = nil
        let task2: URLSessionDataTask = session.dataTask(with: request2, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                do {
                    let resDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
//                    print(resDict)
                    if resDict["Error"] != nil {
                        //                        When error occured.
                        print("Login Error!")
                        if (resDict["ErrorType"] as! String) == "UNAUTHORIZED_ACCESS" {
                            DispatchQueue.main.async {
                                self.wrongPassword.text = "The username/password is incorrect. Please check your spelling."
                                self.wrongPassword.isHidden = false
                            }
                        }
                    } else {
                        //When profile retrival is success.
                        
                        print(resDict)
                        let firstName = resDict["FirstName"] as? String
                        let lastName = resDict["LastName"] as? String
                        let photo = resDict["ProfilePhoto"] as? NSDictionary
                        let lockerNumber = resDict["LockerNbr"] as? String
                        let lockerPassword = resDict["LockerCombo"] as? String
                        
                        
                        photolink = photo?["ThumbFilenameUrl"] as? String
                        
                        success = true
                        
                        DispatchQueue.main.async {
                            self.userDefaults?.set(firstName, forKey: "firstName")
                            self.userDefaults?.set(lastName, forKey: "lastName")
                            self.userDefaults?.set(lockerNumber, forKey: "lockerNumber")
                            self.userDefaults?.set(lockerPassword, forKey: "lockerPassword")
                            self.userDefaults?.set(photolink, forKey: "photoLink")
                        }
                        
                    }
                } catch {
                    NSLog("Data parsing failed")
                    DispatchQueue.main.async {
                        let presentMessage = "The server is not returning the right data. Please contact David."
                        DispatchQueue.main.async {
                            self.errorMessage(presentMessage: presentMessage)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }
            semaphore.signal()
        })
        
        task2.resume()
        semaphore.wait()
        
        //            Get profile photo
        if photolink != nil {
            success = false
            let urlString = "https://mfriends.myschoolapp.com" + photolink!
            let url = URL(string: urlString)
            //create request.
            let request3 = URLRequest(url: url!)
            let downloadTask = session.downloadTask(with: request3, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
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
                    success = true
                } else {
                    DispatchQueue.main.async {
                        let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                        self.errorMessage(presentMessage: presentMessage)
                    }
                }
                semaphore.signal()
            })
            //使用resume方法启动任务
            downloadTask.resume()
            semaphore.wait()
        }
        return success
    }
    
    //获取每天的Day数据
    func initDayData() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)
        let dayCheckURL = "https://dwei.org/data"
        let url = NSURL(string: dayCheckURL)
        let request = URLRequest(url: url! as URL)
        let session = URLSession.shared
        
        //Task 1: Getting day data.
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if error == nil {
                do {
                    let resDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                    
                    let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                    let path = plistPath.appending("/Day.plist")
                    resDict.write(toFile: path, atomically: true)
                    success = true
                } catch {
                    NSLog("Data parsing failed")
                }
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        return success
    }

    func getEvent() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)
        let downloadLink = "https://dwei.org/events.plist"
        let url = NSURL(string: downloadLink)
        let request = URLRequest(url: url! as URL)
        let session = URLSession.shared
        //create request.
        let downloadTask = session.downloadTask(with: request, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                //Temp location:
                print("location:\(String(describing: location))")
                let locationPath = location!.path
                //Copy to User Directory
                let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = photoPath.appending("/Events.plist")
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
                success = true
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }
            semaphore.signal()
        })
        //使用resume方法启动任务
        downloadTask.resume()
        semaphore.wait()
        
        return success
    }

    func versionCheck() -> Bool {
        var success = false
        let versionCheckURL = "https://dwei.org/dataversion"
        let versionUrl = NSURL(string: versionCheckURL)
        let versionRequest = URLRequest(url: versionUrl! as URL)
        let session = URLSession.shared
        let semaphore = DispatchSemaphore.init(value: 0)
        let task: URLSessionDataTask = session.dataTask(with: versionRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in

            if error == nil {
                guard let version = String(data: data!, encoding: .utf8) else {
                    return
                }
                let versionNumber = Int(version)
                print("Version: %@", versionNumber!)
                self.userDefaults?.set(versionNumber, forKey: "version")
                success = true
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    self.errorMessage(presentMessage: presentMessage)
                }
            }
            semaphore.signal()
        })

        task.resume()
        semaphore.wait()
        return success
    }
}

