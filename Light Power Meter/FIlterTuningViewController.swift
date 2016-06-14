//
//  FilterTuningViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/14/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class FilterTuningViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet var labels: [UILabel]!
    @IBOutlet var sliders: [UISlider]!
    
    // MARK: - Class Properties
    
    let ip = ImageProcessor.sharedProcessor
    
    // MARK: - Initalizers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sen = ip.thresholdSensitivity {
            sliders[0].value = sen
            labels[1].text = "\(sen)"
        }
        if let lume = ip.lumeThreshold {
            sliders[1].value = lume
            labels[2].text = "\(lume)"
        }
        if let edge = ip.edgeTolerance {
            sliders[2].value = edge
            labels[3].text = "\(edge)"
        }
    }

    @IBAction func slilderChanged(sender: AnyObject) {
    }
}
