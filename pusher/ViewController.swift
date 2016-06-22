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
    
    var DOMAIN = "http://52.18.239.176"
    var channel: PusherChannel!
    var locationManager = CLLocationManager()
    let MAX_INTERVAL = 10.0
    var last_timestamp: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        message_view.text = ""
        self.message_view.editable = false
        
        submit.addTarget(self, action:#selector(self.send_message), forControlEvents: .TouchUpInside)
        
        let pusher = Pusher(
            key: "c45dc1d4310a0ac9d263",
            options: [
                "cluster": "eu",
                "authEndpoint": DOMAIN + "/users/" + "1234" + "/chats",
                "encrypted": true
            ]
        )
        
        // subscribe to channel and bind to event
        channel = pusher.subscribe("presence-test_channel")
        
        channel.bind("presence-test_channel", callback: { (data: AnyObject?) -> Void in
            print("message received: (data)")
        })
        
        channel.bind("send_message", callback: { (data: AnyObject?) -> Void in
            if let data = data as? Dictionary<String, AnyObject> {
                if let commenter = data["user_id"] as? String, message = data["message"] as? String {
                    self.message_view.text = self.message_view.text + "\(commenter): \(message)\n"
                }
            }
        })
        pusher.connect()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func send_message(sender: AnyObject?) {
        let parameters = [
            "message": String(input.text!),
            "user_id": "ios"//channel.members.me.info.name
        ]
        
        Alamofire.request(.POST, DOMAIN + "/home/send_comment", parameters: parameters)
            .responseJSON { response in
                print("success")
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
        print("\(location!.coordinate.latitude) - \(location!.coordinate.longitude) - \(interval)")
        if (interval > MAX_INTERVAL) {
            let parameters = [
                "lat": String(location!.coordinate.latitude),
                "long": String(location!.coordinate.longitude),
                "timestamp": String(location!.timestamp)
            ]
            last_timestamp = location?.timestamp
            Alamofire.request(.POST, DOMAIN + "/home/send_loc", parameters: parameters)
            .responseJSON { response in
                if response.result.isSuccess {
                    print("loc sent")
                }else{
                    print("error")
                }
            }
        }
    }
}

