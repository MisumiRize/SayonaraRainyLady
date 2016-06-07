//
//  ViewController.swift
//  SayonaraRainyLady
//
//  Created by hoaxster on 2016/06/04.
//  Copyright © 2016年 Rize MISUMI. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate {

    var locationManager: CLLocationManager?
    weak var timer: NSTimer?
    var coordinate: CLLocationCoordinate2D?
    var notification: UILocalNotification?
    var rainfall: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let notificationSettings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if notificationSettings != nil && notificationSettings! != .None {
            notification = UILocalNotification()
            notification?.fireDate = NSDate(timeIntervalSinceNow: 0)
            notification?.timeZone = NSTimeZone.localTimeZone()
            notification?.alertBody = "test"
            notification?.alertAction = "OK"
            notification?.soundName = UILocalNotificationDefaultSoundName
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager?.delegate = self
            if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
                locationManager?.requestAlwaysAuthorization()
            }
            locationManager?.startUpdatingLocation()
            coordinate = locationManager?.location?.coordinate
            fetchWeather { weather in
                print(weather)
            }
        }

        timer = NSTimer.scheduledTimerWithTimeInterval(300.0,
                                                       target: self,
                                                       selector: #selector(ViewController.checkWeather(_:)),
                                                       userInfo: nil,
                                                       repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else {
            return
        }
        coordinate = coord
    }

    func fetchWeather(cb: ([JSON]) -> Void) {
        guard let coord = coordinate else {
            return
        }
        
        Alamofire.request(.GET, "http://weather.olp.yahooapis.jp/v1/place?coordinates=\(coord.longitude),\(coord.latitude)&appid=\(Constants.appId)&output=json")
            .responseJSON { res in
                guard let val = res.result.value else {
                    return
                }
                let obj = JSON(val)
                if let weather = obj["Feature"][0]["Property"]["WeatherList"]["Weather"].array {
                    cb(weather)
                }
        }
    }

    @objc func checkWeather(timer: NSTimer) {
        fetchWeather { weather in
            for (i, w) in weather.enumerate() {
                if i != 1 {
                    continue
                }
                if let r = w["Rainfall"].float {
                    let p = self.rainfall
                    self.rainfall = r
                    if p == 0.0 && self.rainfall > 0.0 && self.notification != nil {
                        print(p)
                        UIApplication.sharedApplication().scheduleLocalNotification(self.notification!)
                    }
                }
            }
        }
    }
}

