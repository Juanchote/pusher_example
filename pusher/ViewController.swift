//
//  ViewController.swift
//  pusher
//
//  Created by Juan Manuel Rodulfo Salcedo on 26/05/16.
//  Copyright © 2016 Juan Manuel Rodulfo Salcedo. All rights reserved.
//

import UIKit
import PusherSwift
import Alamofire
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var message_view: UITextView!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var input: UITextField!
    
    //let DOMAIN = "http://stg-dashboard.eelp.com/api/v1"
    let DOMAIN = "http://192.168.33.11:3000/api/v1"
    //let PUSHER_KEY = "6c807f43b2f40aa4bcf4" //staging key
    let PUSHER_KEY = "c45dc1d4310a0ac9d263" //dev key

    var chan: PresencePusherChannel!
    var locationManager = CLLocationManager()
    let MAX_INTERVAL = 10.0
    var last_timestamp: NSDate?
    
    
    let headers = [
        "X-User-Email": "juanma@eelp.com",
        "X-User-Token": "4NHqtJmPwicE8iFdUZPE",
        "X-User-Uuid": "1ef0bac0-0bac-0134-b7d7-080027b36349"
    ]
    
    let token = "4NHqtJmPwicE8iFdUZPE" //dev
    let uuid = "1ef0bac0-0bac-0134-b7d7-080027b36349"
    
    //let token = "-ss3YFeskTsCcTCE6FHC" //staging
    //let uuid = "b5431240-1f5f-0134-c2bc-0a1c7ccf19a7"
    //tecnico@eelp.com
    //let token = "pg19bpW2B5exfnarYTnK" //staging
    //let uuid = "f06716a0-1f67-0134-c2bd-0a1c7ccf19a7"
    
    
    //let headers = [
    //    "X-User-Email": "tecnico@eelp.com",
    //    "X-User-Token": "pg19bpW2B5exfnarYTnK",
    //    "X-User-Uuid": "f06716a0-1f67-0134-c2bd-0a1c7ccf19a7"
    //]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        message_view.text = ""
        self.message_view.editable = false
        
        submit.addTarget(self, action:#selector(self.send_message), forControlEvents: .TouchUpInside)
        
        let request = {(urlRequest:NSMutableURLRequest) -> NSMutableURLRequest in
            urlRequest.setValue(self.token, forHTTPHeaderField: "X-User-Token")
            urlRequest.setValue(self.uuid, forHTTPHeaderField: "X-User-Uuid")
            urlRequest.setValue("juanma@eelp.com", forHTTPHeaderField: "X-User-Email")
            return urlRequest
        }
        
        let auth = [
            "email": "juanma@eelp.com",
            "password": "12345678"
        ]
        
        Alamofire.request(.POST, DOMAIN + "/user/sign_in", parameters: auth)
        .responseJSON { response in
            if response.result.isSuccess {
                print("auth ok")
            }else{
                print("error")
            }
        }
        
        let pusher = Pusher(
            key: PUSHER_KEY,
            options: [
                "cluster": "eu",
                "authEndpoint": DOMAIN + "/user/me/chats/auth",
                "encrypted": true,
                "authRequestCustomizer": request
            ]
        )
        
        // subscribe to channel and bind to event

        let channel = pusher.subscribe("presence-test_channel")
        chan = channel as! PresencePusherChannel
        chan.bind("presence-test_channel", callback: { (data: AnyObject?) -> Void in
            print("message received: (data)")
        })
        
        chan.bind("plain_message", callback: { (data: AnyObject?) -> Void in
            if let data = data as? Dictionary<String, AnyObject> {
                if let commenter = data["user_id"] as? Dictionary<String, AnyObject>, message = data["message"] as? String {
                    self.message_view.text = self.message_view.text + "\(commenter["name"]!): \(message)\n"
                }
            }
        })
        pusher.connect()

        locationManager.requestAlwaysAuthorization()
        //locationManager.startUpdatingLocation()
    }
    
    func send_message(sender: AnyObject?) {
        let parameters = [
            "message": String(input.text!),
            "user_id": chan.me()!.userInfo!
        ]
        
        Alamofire.request(.POST, DOMAIN + "/user/me/chats/default/messages", headers: headers, parameters: parameters)
            .responseJSON { response in
                //print("success")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager,
                                    didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        if (last_timestamp == nil) {
            self.last_timestamp = location?.timestamp
        }
        let interval = Double(abs(last_timestamp!.timeIntervalSinceNow))
        //print("\(location!.coordinate.latitude) - \(location!.coordinate.longitude) - \(interval)")
        if (interval > MAX_INTERVAL) {
            let parameters = [
                "lat": String(location!.coordinate.latitude),
                "long": String(location!.coordinate.longitude),
                "timestamp": String(location!.timestamp)
            ]
            last_timestamp = location?.timestamp
            //Alamofire.request(.POST, DOMAIN + "/home/send_loc", parameters: parameters)
            //.responseJSON { response in
            //    if response.result.isSuccess {
            //        //print("loc sent")
            //    }else{
            //        //print("error")
            //    }
            //}
        }
    }
}

