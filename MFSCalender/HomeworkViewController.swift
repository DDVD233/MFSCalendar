//
//  HomeworkViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/6/14.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class homeworkViewController: UITableViewController {
    
    let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func getHomework() {
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
}

class homeworkViewCell: UITableViewCell {
    
}
