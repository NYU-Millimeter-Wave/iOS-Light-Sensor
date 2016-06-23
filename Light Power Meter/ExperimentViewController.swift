//
//  ExperimentViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/23/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class ExperimentViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var text: UITextView!

    // MARK: - Class Properties
    
    let dm = DataManager.sharedManager
    let experimentAtIndex: Experiment? = nil
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
