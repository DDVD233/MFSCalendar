//
//  MoyaNetworkLayer.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/9.
//  Copyright © 2017年 David. All rights reserved.
//

import Foundation
import Moya

let provider = MoyaProvider<MyService>()

enum MyService {
    case downloadLargeProfilePhoto(link: String)
    case getProfile(userID: String, token: String)
    case getPossibleContent(sectionId: String)
    case getCalendarData
    case getCalendarEvent
    case dataVersionCheck
}

fileprivate let assetDir: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!

extension MyService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .getCalendarData, .getCalendarEvent, .dataVersionCheck:
            return URL(string: "https://dwei.org")!
        default:
            return URL(string: "https://mfriends.myschoolapp.com")!
        }
    }
    var path: String {
        switch self {
        //myMFS
        case .downloadLargeProfilePhoto(let link):
            return "/\(link)"
        case .getProfile(let userID, _):
            return "/api/user/\(userID)/"
        case .getPossibleContent:
            return "/api/datadirect/BulletinBoardContentGet/"
            
        // Dwei
        case .getCalendarData:
            return "/data"
        case .getCalendarEvent:
            return "/events.plist"
        case .dataVersionCheck:
            return "/dataversion"
        }
    }
    
    var assetName: String {
        switch self {
        case .downloadLargeProfilePhoto: return "/ProfilePhoto.png"
        case .getCalendarEvent: return "Events.plist"
        default: return ""
        }
    }
    
    var localLocation: URL {
        return assetDir.appendingPathComponent(assetName)
    }
    
    var method: Moya.Method {
        switch self {
        default:
            return .get
        }
    }
    
    var parameters: [String: Any]? {
        switch self {
        case .getProfile(_, let token):
            return ["t": token, "format": "json"]
        case .getPossibleContent(let sectionId):
            return ["format": "json", "sectionId": sectionId, "associationId": "1", "pendingInd": "false"]
        default: return nil
        }
    }
    
    var parameterEncoding: ParameterEncoding {
        switch self {
        default:
            return URLEncoding.default
//        URLEncoding.default: Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
//        URLEncoding.queryString: Always sends parameters in URL, regardless of which HTTP method is used
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var downloadDestination: DownloadDestination {
        return { _, _ in return (self.localLocation, .removePreviousFile) }
    }
    
    var task: Task {
        switch self {
        case .downloadLargeProfilePhoto:
            return .download(.request(downloadDestination))
        default:
            return .request
        }
    }
}
