//
//  ClassTimetableViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/8/7.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class ClassSchedule: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func aDayButton(_ sender: Any) {
        userDefaults?.set("A", forKey: "daySelect")
    }
    
    @IBAction func bDayButton(_ sender: Any) {
        userDefaults?.set("B", forKey: "daySelect")
    }
    
    @IBAction func cDayButton(_ sender: Any) {
        userDefaults?.set("C", forKey: "daySelect")
    }
    
    @IBAction func eDayButton(_ sender: Any) {
        userDefaults?.set("E", forKey: "daySelect")
    }
    
    @IBAction func dDayButton(_ sender: Any) {
        userDefaults?.set("D", forKey: "daySelect")
    }
    
    
    @IBAction func fDayButton(_ sender: Any) {
        userDefaults?.set("F", forKey: "daySelect")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {
        
    }
    
}
