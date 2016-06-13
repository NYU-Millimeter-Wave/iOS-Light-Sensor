//
//  MenuTableViewController.swift
//  
//
//  Created by Cole Smith on 6/13/16.
//
//

import UIKit
import SlideMenuControllerSwift

class MenuTableViewController: UITableViewController {
    
    var calibrationVC: UIViewController!
    var lightsVC: UIViewController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let calibrationVC = storyboard.instantiateViewControllerWithIdentifier("Calibration") as! CalibrationViewController
        self.calibrationVC = UINavigationController(rootViewController: calibrationVC)
        
        let lightsVC = storyboard.instantiateViewControllerWithIdentifier("Lights") as! LightControlViewController
        self.lightsVC = UINavigationController(rootViewController: lightsVC)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 1:
            self.slideMenuController()?.changeMainViewController(self.calibrationVC, close: true)
        case 2:
            self.slideMenuController()?.changeMainViewController(self.lightsVC, close: true)
        default:
            print("Unexpected error in menu")
        }
    }
    
}
