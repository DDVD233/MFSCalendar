//
//  CustomSchoolViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 8/29/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import Alamofire

class customSchoolViewController: UIViewController {
    
    @IBOutlet var prefix: UITextField!
    
    @IBAction func Confirm(_ sender: Any) {
        guard prefix.text.existsAndNotEmpty() else {
            presentErrorMessage(presentMessage: "Please enter a prefix.", layout: .cardView)
            return
        }
        
        let prefixString = prefix.text!
        
        let testURL = "https://" + prefixString + ".myschoolapp.com"
        
//        Alamofire.request(testURL).response(queue: DispatchQueue.global()) { (response) in
//            if response.error != nil {
//                print("This is NOT a valid URL")
//            } else {
//                print("This is a valid url")
//            }
//        }
    }
    
}
