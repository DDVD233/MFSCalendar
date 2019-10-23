//
//  ChatViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 5/10/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import ChatSDK
//import ChatSDKFirebase
import SnapKit
import SafariServices

class ChatViewController: UIViewController {
    @IBOutlet var mainView: UIView!
    var loginView: UIView? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        if BChatSDK.auth()!.isAuthenticated() {
            _ = BChatSDK.auth()!.authenticate()!.thenOnMain!({(result: Any?) -> Any? in
            self.setUpViews()
            return result
            }, {(error: Error?) -> Any? in
            return error
            })
            
            updateUserInfo()
        } else {
            setUpLoginViews()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !BChatSDK.auth()!.isAuthenticated() {
            setUpLoginViews()
        }
    }
    
    func setUpLoginViews() {
        self.navigationController?.isNavigationBarHidden = true
        let chatLoginViewController = storyboard!.instantiateViewController(withIdentifier: "ChatLoginVC") as! ChatLoginViewController
        self.addChild(chatLoginViewController)
        loginView = chatLoginViewController.view
        self.view.addSubview(loginView!)
    }
    
    @objc func showContactPage() {
        let contactsViewController = BChatSDK.ui()!.contactsViewController()! as! BContactsViewController
//        contactsViewController.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
//        contactsViewController.navigationItem.backBarButtonItem?.tintColor = UIColor.white
        show(contactsViewController, sender: self)
    }
    
    func updateUserInfo() {
        BChatSDK.push()!.registerForPushNotifications(with: UIApplication.shared, launchOptions: nil)
        let pref = Preferences()
        let name = (pref.firstName ?? "") + " " + (pref.lastName ?? "")
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        let profileImage = UIImage(contentsOfFile: path)
        
        let photoLink = pref.baseURL + (userDefaults.string(forKey: "largePhotoLink") ?? "")
        
        BIntegrationHelper.updateUser(withName: name, image: profileImage, url: photoLink)
    }
    
    func setUpViews() {
        updateUserInfo()
        self.navigationController?.isNavigationBarHidden = false
        let privateThreadsViewController = BChatSDK.ui()!.privateThreadsViewController()!
        self.addChild(privateThreadsViewController)
        self.mainView.addSubview(privateThreadsViewController.view)
        self.view.bringSubviewToFront(self.mainView)
        
        var barButtonItems = [UIBarButtonItem]()
        barButtonItems.append(privateThreadsViewController.navigationItem.rightBarButtonItem!)
        
        let contactButton = UIBarButtonItem(title: NSLocalizedString("Contact", comment: ""), style: .done, target: self, action: #selector(showContactPage))
        barButtonItems.append(contactButton)
        
        for button in barButtonItems {
            button.tintColor = UIColor.white
        }
        
        self.navigationItem.rightBarButtonItems = barButtonItems
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Help"), style: .done, target: self, action: #selector(displayHelpPage))
        
        title = NSLocalizedString("Chat", comment: "")
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationController?.navigationItem.largeTitleDisplayMode = .never
        }
        
        privateThreadsViewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(mainView.snp.top)
            make.bottom.equalTo(mainView.snp.bottom)
            make.left.equalTo(mainView.snp.left)
            make.right.equalTo(mainView.snp.right)
        }
        
        privateThreadsViewController.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc func displayHelpPage() {
        let url = URL(string: "https://classmaster.app/help-2/")!
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
}
