//
//  moreViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/4/23.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import SafariServices
import SCLAlertView

class moreViewController: UITableViewController, UIDocumentInteractionControllerDelegate {

    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var name: UILabel!

    @IBOutlet weak var settingImage: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setLargeTitle(on: self)
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

extension moreViewController {
}
