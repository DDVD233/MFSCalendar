//
//  MobileServeIntroViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 10/19/17.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit

class MobileServeViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func login(_ sender: Any) {
        userDefaults?.set(true, forKey: "doPresentServiceView")
        dismiss(animated: true, completion: nil)
    }
    
    func presentLoginView() {
        let moreView = storyboard!.instantiateViewController(withIdentifier: "more") as! NewMoreViewController
        DispatchQueue.main.async {
            self.show(moreView, sender: self)
        }
    }
}

class MobileServeRegister: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func register(_ sender: Any) {
        let urlString = "https://app.mobileserve.com/login/?next=/user/setup/organization/code/%3Forg_code%3DMFS123"
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: urlString)!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: urlString)!)
            // Fallback on earlier versions
        }
    }
}


