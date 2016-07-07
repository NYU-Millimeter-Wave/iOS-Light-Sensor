//
//  AppDelegate.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/7/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Init Singletons
        LightControlManager.sharedManager
        DataManager.sharedManager
        
        // Slide Menu Controller Setup
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateViewControllerWithIdentifier("PowerMeter") as! PowerMeterViewController
        let leftViewController = storyboard.instantiateViewControllerWithIdentifier("Menu") as! MenuTableViewController
        let navController = UINavigationController(rootViewController: mainViewController)
        let slideMenuController = SlideMenuController(mainViewController: navController, leftMenuViewController: leftViewController)
        
        slideMenuController.automaticallyAdjustsScrollViewInsets = true
        
        self.window?.rootViewController = slideMenuController
        self.window?.makeKeyAndVisible()
        
        // Start Socket Listener
        let dm = DataManager.sharedManager
        dm.initalizeSocketConnection("ws://172.16.24.202:9000")
        
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

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // Terminate Socket Connection
        let dm = DataManager.sharedManager
        dm.socket?.close()
    }


}

