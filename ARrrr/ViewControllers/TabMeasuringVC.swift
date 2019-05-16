//
//  FirstViewController.swift
//  ARrrr
//
//  Created by Timothy Poulsen on 5/16/19.
//  Copyright © 2019 Tim Poulsen. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class TabMeasuringVC: UIViewController {

    let font = UIFont(name: "icomoon", size: 80)
    let btnTitleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                              NSAttributedString.Key.font: UIFont(name: "icomoon", size: 21)!]
    let TARGET = "\u{e900}"
    let STARTMEASURING = "\u{e901}"
    let TRASHCAN = "\u{e902}"
    var startPoint = SCNVector3()
    var endPoint = SCNVector3()
    let zeroPoint = SCNVector3()
    var measuring = false
    var readyToClear = false

    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var lblMeasureIt: UILabel!
    @IBOutlet weak var lblTarget: UILabel!
    @IBOutlet weak var btnStartStop: UIButton!
    
    @IBAction func didStartStop(_ sender: UIButton) {
        if !measuring && !readyToClear {
            // start measuring
            measuring = true
            readyToClear = false
            startPoint = SCNVector3()  // reset
            endPoint = SCNVector3()  // reset
            setMeasureItLabel(0.0)
            // actual tracking / measuring done in renderer() below
        } else if measuring {
            measuring = false
            readyToClear = true
            setButtonSymbol(TRASHCAN)
        } else {
            setMeasureItLabel(nil)
            measuring = false
            readyToClear = false
            setButtonSymbol(STARTMEASURING)
        }
    }
    
    fileprivate func measureDistance() {
        if let currentPoint = sceneView.realWorldVector(screenPos: view.center) {
            if startPoint == zeroPoint {
                startPoint = currentPoint
            }
            endPoint = currentPoint
            self.setMeasureItLabel(endPoint.distance(from: startPoint))
        }
    }
    
    fileprivate func setupUI() {
        // e902 is the trashcan
        self.lblTarget.font = font
        self.lblTarget.text = TARGET
        setButtonSymbol(STARTMEASURING)
    }
    
    fileprivate func setButtonSymbol(_ title: String) {
        let btnAttributedTitle = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.font: font!])
        btnStartStop.setAttributedTitle(btnAttributedTitle, for: .normal)
        btnStartStop.setAttributedTitle(btnAttributedTitle, for: .highlighted)
        btnStartStop.setAttributedTitle(btnAttributedTitle, for: .focused)
    }
    
    fileprivate func setMeasureItLabel(_ value: Float?) {
        if value != nil {
            let cm = value! * 100.0
            let inches = cm * 0.3937
            lblMeasureIt.text = String(format: "%.2f inches", inches)
        } else {
            lblMeasureIt.text = "MeasureIt"
        }
    }
    
}

// MARK: - VC overrrides

extension TabMeasuringVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupUI()
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

// MARK: - ARSCNViewDelegate

extension TabMeasuringVC: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if !measuring { return }
        DispatchQueue.main.async {
            self.measureDistance()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
