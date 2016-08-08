//
//  MonitorViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 8/3/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class MonitorViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var logOut: UITextView!
    
    // MARK: - Class Properties
    
    var experiment: Experiment!

    // MARK: - Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logOut.editable = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        experiment.logOutput = logOut
        experiment.beginExperiment()
    }

    func throwErrorMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "NO", style: .Default, handler: nil))
        alert.addAction(UIAlertAction(
            title: "YES",
            style: .Destructive,
            handler: {alert in self.endExperiment()}
        ))
        presentViewController(alert, animated: true, completion: nil)
    }

    func endExperiment() {
        self.experiment.endExperiment() { _ in }
    }
    
    // MARK: - Actions
    
    @IBAction func forceEndPressed(sender: AnyObject) {
        throwErrorMessage("Are you sure?", message: "This will result in incomplete readings")
    }
}
