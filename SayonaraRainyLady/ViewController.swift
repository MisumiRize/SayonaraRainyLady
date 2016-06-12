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

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    var locationManager: CLLocationManager?
    var lastFetched: NSDate = NSDate()
    var lastNotificated: NSDate = NSDate()
    var weather: Array<JSON> = []

    @IBOutlet weak var tv: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        tv.delegate = self
        tv.dataSource = self

        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager!.allowsBackgroundLocationUpdates = true
            locationManager!.delegate = self
            if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
                locationManager!.requestAlwaysAuthorization()
            }
            locationManager!.startUpdatingLocation()
            locationManager!.requestLocation()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        fetchWeather(locationManager?.location?.coordinate) { weather in
            self.weather = weather
            self.tv.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weather.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("id")
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "id")
        }
        cell!.textLabel?.text = String(weather[indexPath.row]["Rainfall"].floatValue)
        cell!.detailTextLabel?.text = weather[indexPath.row]["Date"].stringValue
        return cell!
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations.last?.coordinate)
        if lastFetched.timeIntervalSinceNow < -10 * 60 {
            lastFetched = NSDate()
            fetchWeather(locations.last?.coordinate) { weather in
                if let rainfall = weather[2]["Rainfall"].float {
                    if rainfall > 0 && self.lastNotificated.timeIntervalSinceNow < -20 * 60 {
                        let notificationSettings = UIApplication.sharedApplication().currentUserNotificationSettings()
                        if notificationSettings != nil && notificationSettings! != .None {
                            self.lastNotificated = NSDate()
                            let notification = UILocalNotification()
                            notification.fireDate = NSDate(timeIntervalSinceNow: 0)
                            notification.timeZone = NSTimeZone.defaultTimeZone()
                            notification.alertBody = "It will rain in 20 minutes."
                            notification.alertAction = "OK"
                            notification.soundName = UILocalNotificationDefaultSoundName
                        }
                    }
                }
            }
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    }

    func fetchWeather(coordinate: CLLocationCoordinate2D?, cb: ([JSON]) -> Void) {
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
}

