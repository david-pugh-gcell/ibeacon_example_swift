//
//  AppDelegate.swift
//  GCell_Example_Swift_iBeacon
//
//  Created by David Pugh on 21/08/2015.
//  Copyright (c) 2015 G24 Power Ltd David Pugh. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager?
    var lastProximity: CLProximity? //This will store the last notification


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Set up Beacon UUID and region.
        let uuidString = "96530D4D-09AF-4159-B99E-951A5E826584"
        let beaconIdentifier = "gcell.ibeacon.com"
        let beaconUUID = NSUUID(UUIDString: uuidString)
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID!,
            identifier: beaconIdentifier)
        
        //Set up Location Manager and handle authorisation
        locationManager = CLLocationManager()
        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            if #available(iOS 8.0, *) {
                locationManager!.requestAlwaysAuthorization()
            } else {
                // Fallback on earlier versions
            }
        }
        
        //Start monitoring for the beacon region
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        
        locationManager!.startMonitoringForRegion(beaconRegion)
        locationManager!.startRangingBeaconsInRegion(beaconRegion)
        locationManager!.startUpdatingLocation()
        
        
        //App permission handling to send notifications
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            if #available(iOS 8.0, *) {
                application.registerUserNotificationSettings(
                    UIUserNotificationSettings(
                        forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Sound],
                        categories: nil
                    )
                )
            } else {
                // Fallback on earlier versions
            }
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
  
}

//Extension to class to add notifications when in background mode

extension AppDelegate {
    func sendLocalNotificationWithMessage(message: String!) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon],inRegion region: CLBeaconRegion)  {
            
            print("didRangeBeacons");
            var message:String = ""
        
            //Pass beacons to view controller
            let viewController:ViewController = window!.rootViewController as! ViewController
            viewController.beacons = (beacons as [CLBeacon]?)!
            viewController.tableView!.reloadData()
        
            if(beacons.count > 0) {
                let nearestBeacon:CLBeacon = beacons[0] 
                
                //Check to see if the proximity has changed, so we eleimiante redundent notifications
                if(nearestBeacon.proximity == lastProximity ||
                    nearestBeacon.proximity == CLProximity.Unknown) {
                        return;
                }
                //Update the proximity variable
                lastProximity = nearestBeacon.proximity;
                
                switch nearestBeacon.proximity {
                case CLProximity.Far:
                    message = "You are far away from the beacon"
                case CLProximity.Near:
                    message = "You are near the beacon"
                case CLProximity.Immediate:
                    message = "You are in the immediate proximity of the beacon"
                case CLProximity.Unknown:
                    return
                }
            } else {
                message = "No beacons are nearby"
            }
            
            print("%@", message)
            sendLocalNotificationWithMessage(message)
    }
    
    
    //Start Ranging beacon if region has been entered
    func locationManager(manager: CLLocationManager,
        didEnterRegion region: CLRegion) {
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.startUpdatingLocation()
            
            print("You entered the region")
            sendLocalNotificationWithMessage("You entered the region")
    }
    
    
    //Stop ranging if the beacon region has exited - saves power
    func locationManager(manager: CLLocationManager,
        didExitRegion region: CLRegion) {
            manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
            manager.stopUpdatingLocation()
            
            print("You exited the region")
            sendLocalNotificationWithMessage("You exited the region")
    }
}

