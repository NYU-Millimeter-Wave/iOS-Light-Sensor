//
//  Experiment.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/23/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class Experiment: NSObject {
    
    // MARK: - Class Properties
    
    var title: String?
    var photoBuffer: [UIImage]?
    
    // Here will go our experiment variables
    
    // MARK: - Initalizers
    
    init(title: String) {
        super.init()
        
        self.title = title
        self.photoBuffer = []
    }
    
    override convenience init() {
        self.init(title: "New Experiment")
    }
    
    // MARK: - Experiment Methods
    
    func beginExperiment() {}
}
