//
//  TopicDetailViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/8/8.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class topicDetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension topicDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "plainCell", for: indexPath)
        
        return cell
    }
}

extension topicDetailViewController {
//    Network
    
}

class topicDetailDescriptionCell: UITableViewCell {
    
}
