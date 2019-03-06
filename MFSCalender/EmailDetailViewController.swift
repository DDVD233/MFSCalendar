//
//  EmailDetailViewController.swift
//  MFSMobile
//                                                       
//  Created by David Dai on 3/5/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit

class EmailDetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
}

extension EmailDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    }
    
    
}

class EmailDetailBodyCell: UITableViewCell {
    @IBOutlet var bodyTextView: UITextView!
}
