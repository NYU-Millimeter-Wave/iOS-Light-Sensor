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
    
    // MARK: - Class Properties
    
    let dm = DataManager.sharedManager
    
    var powerMeterVC: UIViewController!
    var calibrationVC: UIViewController!
    var lightsVC: UIViewController!
    var filterTuningVC: UIViewController!
    var experimentsTableVC: UIViewController!
    var controlVC: UIViewController!
    
    // MARK: - Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        self.powerMeterVC = storyboard.instantiateViewControllerWithIdentifier("PowerMeter") as! PowerMeterViewController
        self.powerMeterVC = UINavigationController(rootViewController: powerMeterVC)
        
        self.calibrationVC = storyboard.instantiateViewControllerWithIdentifier("Calibration") as! CalibrationViewController
        self.calibrationVC = UINavigationController(rootViewController: calibrationVC)
        
        self.lightsVC = storyboard.instantiateViewControllerWithIdentifier("Lights") as! LightControlViewController
        self.lightsVC = UINavigationController(rootViewController: lightsVC)
        
        self.filterTuningVC = storyboard.instantiateViewControllerWithIdentifier("FilterTuning") as! FilterTuningViewController
        self.filterTuningVC = UINavigationController(rootViewController: filterTuningVC)
        
        self.experimentsTableVC = storyboard.instantiateViewControllerWithIdentifier("experimentsVC") as! ExperimentsTableViewController
        self.experimentsTableVC = UINavigationController(rootViewController: experimentsTableVC)
        
        self.controlVC = storyboard.instantiateViewControllerWithIdentifier("controlVC") as! ControlViewController
        self.controlVC = UINavigationController(rootViewController: controlVC)
    }

    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table View Data Source
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 1:
            self.slideMenuController()?.changeMainViewController(self.powerMeterVC, close: true)
        case 2:
            self.slideMenuController()?.changeMainViewController(self.calibrationVC, close: true)
        case 3:
            self.slideMenuController()?.changeMainViewController(self.lightsVC, close: true)
        case 4:
            self.slideMenuController()?.changeMainViewController(self.filterTuningVC, close: true)
        case 5:
            self.slideMenuController()?.changeMainViewController(self.experimentsTableVC, close: true)
        case 6:
            self.slideMenuController()?.changeMainViewController(self.controlVC, close: true)
        default:
            print("[ ERR ] Unexpected error in SideMenuController")
        }
    }
    
}
