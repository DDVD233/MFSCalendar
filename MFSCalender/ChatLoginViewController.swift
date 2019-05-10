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
            presentErrorMessage(presentMessage: "Please enter your password", layout: .cardView)
            return
        }
        
        let loginDetail = BAccountDetails.username(Preferences().email ?? "", password: passwordText)
        _ = BChatSDK.auth()!.authenticate(loginDetail)?.thenOnMain!({(result: Any?) -> Any? in
            let parentVC = self.parent as! ChatViewController
            parentVC.setUpViews()
            return result
        }, {(error: Error?) -> Any? in
            let signupDetail = BAccountDetails.signUp(Preferences().email ?? "", password: passwordText)
            _ = BChatSDK.auth()!.authenticate(signupDetail)?.thenOnMain({(result: Any?) -> Any? in
                let parentVC = self.parent as! ChatViewController
                parentVC.setUpViews()
                return result
            }, {(error: Error?) -> Any? in
                presentErrorMessage(presentMessage: error?.localizedDescription ?? "", layout: .cardView)
                return error
            })
            return error
        })
        
//        switch authenticationResult {
//        case "Success":
//            let preferences = Preferences()
////            preferences.emailName = nameText!
//            preferences.emailPassword = passwordText!
//            let parentVC = parent as! EmailViewController
//            parentVC.addEmailListView()
//        case "WrongPassword":
//            presentErrorMessage(presentMessage: "The username/password is incorrect. Please check your spelling.", layout: .cardView)
//        case "InternalError":
//            presentErrorMessage(presentMessage: "The server is not working. Please contact David.", layout: .cardView)
//        default:
//            break
//        }
    }
    
    
    
    func authenticate(nameText: String, passwordText: String) -> String {
        DispatchQueue.main.async {
            self.indicatorView.isHidden = false
            self.NVIndicator.startAnimating()
        }
        
        guard let usernameTextUrlEscaped = nameText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            presentErrorMessage(presentMessage: "Cannot convert to URL String", layout: .statusLine)
            return ""
        }
        
        guard let passwordTextUrlEscaped = passwordText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            presentErrorMessage(presentMessage: "Cannot convert to URL String", layout: .statusLine)
            return ""
        }
        
        let accountCheckURL = Preferences().davidBaseURL + "/email/authenticate/" + usernameTextUrlEscaped + "/" + passwordTextUrlEscaped
        let url = NSURL(string: accountCheckURL)
        let request = URLRequest(url: url! as URL)
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession.init(configuration: config)
        
        let semaphore = DispatchSemaphore.init(value: 0)
        var result = ""
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                guard data != nil else {
                    DispatchQueue.main.async {
                        presentErrorMessage(presentMessage: "Failed. Please check your internet", layout: .cardView)
                    }
                    semaphore.signal()
                    return
                }
                result = String(data: data!, encoding: .utf8) ?? ""
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    presentErrorMessage(presentMessage: presentMessage, layout: .cardView)
                }
                
            }
            semaphore.signal()
            
        })
        
        task.resume()
        semaphore.wait()
        return result
    }
    
    
}
