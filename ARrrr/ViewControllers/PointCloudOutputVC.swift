//
//  PointCloudMainVC.swift
//  ARrrr
//
//  Created by Timothy Poulsen on 5/16/19.
//  Copyright © 2019 Tim Poulsen. All rights reserved.
//

import AVFoundation
import SceneKit
import UIKit

class PointCloudOutputVC: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var sceneView: SCNView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func imageSwitchter(_ sender: UISegmentedControl) {
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
