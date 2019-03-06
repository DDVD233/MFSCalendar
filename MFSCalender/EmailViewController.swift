//
//  EmailViewController.swift
//  MFSMobile
//
//  Created by David Dai on 3/2/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit

class EmailViewController: UIViewController {
    let emailLoginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EmailLoginVC") as! EmailLoginViewController
    let emailListVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EmailListVC")
    override func viewDidLoad() {
        super.viewDidLoad()
        if Preferences().emailPassword == nil {
            self.navigationController?.isNavigationBarHidden = true
            self.addChild(emailLoginVC)
            self.view.addSubview(emailLoginVC.view)
        } else {
            addEmailListView()
        }
    }
    
    func addEmailListView() {
        self.navigationController?.isNavigationBarHidden = false
        self.addChild(emailListVC)
        self.view.addSubview(emailListVC.view)
    }
}
