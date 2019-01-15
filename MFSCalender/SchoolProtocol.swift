//
//  SchoolProtocol.swift
//  MFSMobile
//
//  Created by David on 1/15/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation

protocol School {
    func classesOnADayAfter(date: Date) -> [[String: Any]]
    
}
