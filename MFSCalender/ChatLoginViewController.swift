//
//  ChatLoginViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 5/10/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import NVActivityIndicatorView
import NotificationCenter
import ChatSDK
import ChatSDKFirebase

class ChatLoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var password: SkyFloatingLabelTextField!
    @IBOutlet var indicatorView: UIView!
    @IBOutlet var NVIndicator: NVActivityIndicatorView!
    @IBOutlet var logoPhoto: UIImageView!
    @IBOutlet var bottomLayoutConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        indicatorView.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        password.delegate = self
        usernameLabel.text = Preferences().email
        password.text = Preferences().password
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
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
    
    @IBAction func login(_ sender: Any) {
        self.view.endEditing(true)
        let passwordText = password.text
        
        guard passwordText.existsAndNotEmpty() else {
            presentErrorMessage(presentMessage: NSLocalizedString("Please enter your password", comment: ""), layout: .cardView)
            return
        }
        
        DispatchQueue.main.async {
            self.indicatorView.isHidden = false
            self.NVIndicator.startAnimating()
        }
        
        let loginDetail = BAccountDetails.username(Preferences().email ?? "", password: passwordText)
        _ = BChatSDK.auth()!.authenticate(loginDetail)?.thenOnMain!({(result: Any?) -> Any? in
            self.presentChatView()
            return result
        }, {(error: Error?) -> Any? in
            let signupDetail = BAccountDetails.signUp(Preferences().email ?? "", password: passwordText)
            _ = BChatSDK.auth()!.authenticate(signupDetail)?.thenOnMain({(result: Any?) -> Any? in
                self.presentChatView()
                return result
            }, {(error: Error?) -> Any? in
                presentErrorMessage(presentMessage: error?.localizedDescription ?? "", layout: .cardView)
                DispatchQueue.main.async {
                    self.indicatorView.isHidden = true
                }
                return error
            })
            return error
        })
    }
    
    
    func updateUserInfo() {
        BChatSDK.push()!.registerForPushNotifications(with: UIApplication.shared, launchOptions: nil)
        let pref = Preferences()
        let name = (pref.firstName ?? "") + " " + (pref.lastName ?? "")
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        let profileImage = UIImage(contentsOfFile: path)
        
        let photoLink = pref.baseURL + (userDefaults.string(forKey: "largePhotoLink") ?? "")
        
        let schoolName = pref.schoolName ?? ""
        BChatSDK.core()?.currentUserModel()?.setMetaValue(schoolName, forKey: "School")
        
//        BFirebaseSearchHandler().users(forIndexes: ["School"], withValue: schoolName, limit: 999) { (user) in
//            if user != nil {
//                _ = BChatSDK.contact()?.addContact(user!, with: bUserConnectionTypeContact)
//                BChatSDK.core()!.observeUser(user!.entityID())
//            }
//
//            print("-----------------")
//        }

        BIntegrationHelper.updateUser(withName: name, image: profileImage, url: photoLink)
    }
    
    func presentChatView() {
        let parentVC = self.parent as! ChatViewController
        BChatSDK.core()!.save()
        updateUserInfo()
//        _ = BChatSDK.a()?.auth()
        
        let currentUser = BChatSDK.currentUser()
        _ = AppDelegate().application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        BHookNotification.notificationDidAuthenticate(currentUser!)
        self.indicatorView.isHidden = true
        parentVC.setUpViews()
        self.view.removeFromSuperview()
    }
}
