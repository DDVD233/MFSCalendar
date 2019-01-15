//
//  SchoolSelectionViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 1/15/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit

class SchoolSelectionViewController: UIViewController {
    
    @IBOutlet var MFS: UIButton!
    @IBOutlet var CMH: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    @IBAction func MFSClicked(_ sender: Any) {
        Preferences().schoolName = "MFS"
        showLoginVC()
    }
    
    @IBAction func CMHClicked(_ sender: Any) {
        Preferences().schoolName = "CMH"
        showLoginVC()
    }
    
    func showLoginVC() {
        let loginVC = self.storyboard!.instantiateViewController(withIdentifier: "loginController")
        show(loginVC, sender: self)
    }
}
