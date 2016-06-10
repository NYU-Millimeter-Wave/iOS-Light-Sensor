//
//  LightControlViewController.swift
//  Light Power Meter
//
//  Created by Cole Smith on 6/10/16.
//  Copyright © 2016 Cole Smith. All rights reserved.
//

import UIKit

class LightControlViewController: UIViewController {

    // MARK: - Class Properties
    
    @IBOutlet var switches: [UISwitch]!
    @IBOutlet var sliders: [UISlider]!
    
    @IBOutlet var purpleButtons: [UIButton]!
    @IBOutlet var yellowButtons: [UIButton]!
    @IBOutlet var redButtons: [UIButton]!
    
    let lightManager = LightControlManager.sharedManager
    
    let purple = 56100
    let yellow = 12750
    let red =    0
    let saturationConstant = 255
    
    // MARK: - Initalizers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Handlers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set all lights to default position
        for i in 1...3 {
            lightManager.setLightOn(i, lightOn: false)
            //lightManager.setLight(i, saturation: saturationConstant, brightness: 100, hue: 10000)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Event Handlers
    
    @IBAction func switchFlipped(sender: AnyObject) {
        self.lightManager.setLightOn((sender.tag + 1), lightOn: (switches[sender.tag].on))
    }
    
    @IBAction func sliderDidChangeValue(sender: AnyObject) {
        let sliderVal = Int(sliders[sender.tag].value)
        self.lightManager.setLightBrightness((sender.tag + 1), brightness: sliderVal)
    }
    
    @IBAction func buttonPressed(sender: AnyObject) {
        switch sender.tag {
        case 0,3,6:
            // Set light purple
            let lightVal = ((sender.tag / 3) + 1)
            self.lightManager.setLight(lightVal, saturation: saturationConstant, brightness: Int(sliders[lightVal - 1].value), hue: purple)
        case 1,4,7:
            // Set light yellow
            let lightVal = (((sender.tag + 1) / 3) + 1)
            self.lightManager.setLight(lightVal, saturation: saturationConstant, brightness: Int(sliders[lightVal - 1].value), hue: yellow)
        case 2,5,8:
            // Set light red
            let lightVal = ((sender.tag / 3) + 1)
            self.lightManager.setLight(lightVal, saturation: saturationConstant, brightness: Int(sliders[lightVal - 1].value), hue: red)
        default:
            print("[ ERR ] Light Value Not valid")
        }
    }
    
    @IBAction func resetPressed(sender: AnyObject) {
        self.lightManager.resetAllLights()
        for s in switches {
            s.on = true
        }
        for s in sliders {
            s.value = 255
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
