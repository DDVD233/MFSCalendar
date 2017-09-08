//
//  A Day.swift
//  MFSCalender
//
//  Created by David Dai on 2017/2/25.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class customCell: UITableViewCell {

    @IBOutlet weak var ClassName: UILabel!

    @IBOutlet weak var PeriodNumber: UILabel!

    @IBOutlet weak var RoomNumber: UILabel!

    @IBOutlet weak var PeriodTime: UILabel!

    @IBOutlet var teachersName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

class ADay: UIViewController {
    
    var daySelected: String? = nil

    @IBOutlet weak var tableView: UITableView!

    var listClasses: NSMutableArray = []

    override func viewDidLoad() {
        // Do any additional setup after loading the view, typically from a nib.
        super.viewDidLoad()
        dataFetching()
        self.tableView.separatorStyle = .none

//        if !UIAccessibilityIsReduceTransparencyEnabled() {
//            self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName:"background.png"))
//            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
//            let blurEffectView = UIVisualEffectView(effect: blurEffect)
//            //always fill the view
//            blurEffectView.frame = self.view.bounds
//            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//
//            self.view.insertSubview(blurEffectView, at: 0)
//        }
    }

    override func viewDidAppear(_ animated: Bool) {

        if userDefaults?.bool(forKey: "reloadTable") != false {
            self.dataFetching()
            self.tableView.reloadData()
            userDefaults?.set(false, forKey: "reloadTable")
            NSLog("table reloaded")
        }
    }

    func dataFetching() {
        guard daySelected != nil else {
            return
        }
        
        self.title = daySelected! + " Day"
        NSLog("Day: %@", daySelected!)
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + daySelected! + ".plist"
        NSLog(fileName)
        let path = plistPath.appending(fileName)
        NSLog(path)

        self.listClasses = NSMutableArray(contentsOfFile: path)!
        print(listClasses)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {
    }
}

extension ADay: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listClasses.count
    }


    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath as IndexPath) as? customCell

        let row = indexPath.row

        let rowDict = self.listClasses[row] as! NSDictionary

        cell?.ClassName.text = rowDict["className"] as? String
        if let period = rowDict["period"] as? Int {
            cell?.PeriodNumber.text = String(describing: period)

            cell?.PeriodTime.text = ClassView().getMeetTime(period: period)
        }

        let roomN = rowDict["roomNumber"] as? String
        cell?.RoomNumber.text = roomN
        
        cell?.teachersName.text = rowDict["teacherName"] as? String

        return cell!
    }
}

