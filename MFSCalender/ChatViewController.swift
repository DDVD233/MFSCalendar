//
//  ChatViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 5/10/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import ChatSDK
import SnapKit

class ChatViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if !BChatSDK.auth()!.isAuthenticated() {
            setUpLoginViews()
        }
        _ = BChatSDK.auth()!.authenticate()!.thenOnMain!({(result: Any?) -> Any? in
            self.setUpViews()
            return result
        }, {(error: Error?) -> Any? in
            return error
        })
    }
    
    func setUpLoginViews() {
        self.navigationController?.isNavigationBarHidden = true
        let chatLoginViewController = storyboard!.instantiateViewController(withIdentifier: "ChatLoginVC") as! ChatLoginViewController
        self.addChild(chatLoginViewController)
        self.view.addSubview(chatLoginViewController.view)
    }
    
    @objc func showContactPage() {
        let contactsViewController = BChatSDK.ui()!.contactsViewController()! as! BContactsViewController
//        contactsViewController.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
//        contactsViewController.navigationItem.backBarButtonItem?.tintColor = UIColor.white
        show(contactsViewController, sender: self)
    }
    
    func setUpViews() {
        self.navigationController?.isNavigationBarHidden = false
        let privateThreadsViewController = BChatSDK.ui()!.privateThreadsViewController()!
        self.addChild(privateThreadsViewController)
        self.view.addSubview(privateThreadsViewController.view)
        
        var barButtonItems = [UIBarButtonItem]()
        barButtonItems.append(privateThreadsViewController.navigationItem.rightBarButtonItem!)
        
        let contactButton = UIBarButtonItem(title: "Contact", style: .done, target: self, action: #selector(showContactPage))
        barButtonItems.append(contactButton)
        
        for button in barButtonItems {
            button.tintColor = UIColor.white
        }
        
        self.navigationItem.rightBarButtonItems = barButtonItems
        
        let pref = Preferences()
        let name = (pref.firstName ?? "") + " " + (pref.lastName ?? "")
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        let profileImage = UIImage(contentsOfFile: path)
        BIntegrationHelper.updateUser(withName: name, image: profileImage, url: nil)
        
        title = "Chat"
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationController?.navigationItem.largeTitleDisplayMode = .never
        }
        
        privateThreadsViewController.view.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leftMargin.equalToSuperview()
            make.rightMargin.equalToSuperview()
        }
        
        privateThreadsViewController.view.translatesAutoresizingMaskIntoConstraints = false
    }
}
