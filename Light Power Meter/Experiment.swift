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
    
    
    // Here will go our experiment variables
    
    // MARK: - Initalizers
    
    init(title: String) {
        super.init()
        self.title = title
    }
    
    override convenience init() {
        self.init(title: "New Experiment")
    }
}
