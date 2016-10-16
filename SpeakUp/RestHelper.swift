//
//  RestHelper.swift
//  SpeakUp
//
//  Created by Saraceni on 10/16/16.
//  Copyright © 2016 Saraceni. All rights reserved.
//

import UIKit
import Alamofire

class RestHelper: NSObject {
    
    //typealias ServerResponse = (Response<AnyObject, NSError>) -> Void
    
    static let ws_url = "http://ec2-52-38-143-218.us-west-2.compute.amazonaws.com:2424/api/message"
    
    static func sendRequest(text: String, callback: @escaping (NSDictionary?) -> Void) {
        
        let params: Parameters = [
            "input": [
                "text": text
            ]
        ]
        
        let url = ws_url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        Alamofire.request(url!, method: HTTPMethod.post, parameters: params, encoding: JSONEncoding.default).responseJSON {
            response in
            if let json = response.result.value as? NSDictionary {
                callback(json)
                
            } else {
                print("Error")
                callback(nil)
            }
        }
        
    }

}
