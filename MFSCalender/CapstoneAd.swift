//
//  CapstoneAd.swift
//  MFSMobile
//
//  Created by 戴元平 on 11/27/18.
//  Copyright © 2018 David. All rights reserved.
//

import UIKit
import EventKit
import SwiftDate

class CapstoneAdViewController: UIViewController {
    
    @IBOutlet var addCalendar: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    }
    
    
    @IBAction func addToCalendar(_ sender: Any) {
        Preferences().didPresentCapstoneAd = true
        let eventStore : EKEventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { (granted, error) in
            
            if (granted) && (error == nil) {
                print("granted \(granted)")
                print("error \(error)")
                
                let event:EKEvent = EKEvent(eventStore: eventStore)
                
                event.title = "David's Capstone Presentation"
                event.startDate = "2018-11-30 12:56:00".toDate()!.date
                event.endDate = "2018-11-30 13:40:00".toDate()!.date
                event.notes = " "
                event.calendar = eventStore.defaultCalendarForNewEvents
                event.alarms = [EKAlarm(absoluteDate: "2018-11-30 12:10:00".toDate()!.date)]
                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch let error as NSError {
                    print("failed to save event with error : \(error)")
                }
                print("Saved Event")
                self.dismiss(animated: true, completion: nil)
            }
            else{
                
                print("failed to save event with error : \(String(describing: error)) or access not granted")
            }
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        Preferences().didPresentCapstoneAd = true
        self.dismiss(animated: true, completion: nil)
    }
}
