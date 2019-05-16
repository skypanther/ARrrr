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

    var outputImage: AVCapturePhoto?
    var normalImage: UIImage?
    var depthData: AVDepthData?
    let scene = SCNScene()
    var pointNode: SCNNode!
    let zCamera: Float = 0.3

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var sceneView: SCNView!
    
    @IBAction func imageSwitchter(_ sender: UISegmentedControl) {
        scene.rootNode.childNodes.forEach { childNode in
            childNode.removeFromParentNode()
        }
        if sender.selectedSegmentIndex == 0 {
            showImage()
        } else if sender.selectedSegmentIndex == 1 {
            show3DScene()
        }
    }
    
    fileprivate func showImage() {
        sceneView.isHidden = true
        imgView.isHidden = false
        self.imgView.image = normalImage?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: -20, right: -20))
    }
    
    fileprivate func show3DScene() {
        sceneView.isHidden = false
        imgView.isHidden = true
        drawPointCloud()
    }
    
    private func setupScene() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.0
        cameraNode.camera?.zFar = 10.0
        scene.rootNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: zCamera)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 3, z: 3)
        scene.rootNode.addChildNode(lightNode)
        
        let sphere = SCNSphere(radius: 0.001)
        sphere.firstMaterial?.diffuse.contents = UIColor.blue
        pointNode = SCNNode(geometry: sphere)
        
        
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.showsStatistics = true
        sceneView.backgroundColor = UIColor.black
    }
    
    private func drawPointCloud() {
        guard let colorImage = normalImage, let cgColorImage = colorImage.cgImage else { fatalError() }

        guard let depthData = depthData?.convertToDepth() else { fatalError() }

        let depthPixelBuffer = depthData.depthDataMap
        let width  = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)
        
        let resizeScale = CGFloat(width) / colorImage.size.width
        let resizedColorImage = CIImage(cgImage: cgColorImage).transformed(by: CGAffineTransform(scaleX: resizeScale, y: resizeScale))
        guard let pixelDataColor = resizedColorImage.createCGImage().pixelData() else { fatalError() }
        
        let pixelDataDepth: [Float32]
        pixelDataDepth = depthPixelBuffer.grayPixelData()
        
        // Sometimes the z values of the depth are bigger than the camera's z
        // So, determine a z scale factor to make it visible
        let zMax = pixelDataDepth.max()!
        let zNear = zCamera - 0.2
        let zScale = zMax > zNear ? zNear / zMax : 1.0
        print("z scale: \(zScale)")
        let xyScale: Float = 0.0002
        
        let pointCloud: [SCNVector3] = pixelDataDepth.enumerated().map {
            let index = $0.offset
            // Adjusting scale and translating to the center
            let x = Float(index % width - width / 2) * xyScale
            let y = Float(height / 2 - index / width) * xyScale
            // z comes as Float32 value
            let z = Float($0.element) * zScale
            return SCNVector3(x, y, z)
        }
        
        // Draw as a custom geometry
        let pc = PointCloud()
        pc.pointCloud = pointCloud
        pc.colors = pixelDataColor
        let pcNode = pc.pointCloudNode()
        pcNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(pcNode)
        
    }
}

// MARK: - VC overrides

extension PointCloudOutputVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let oi = outputImage, let cgiVersion = oi.cgImageRepresentation() {
            let img = UIImage(cgImage: cgiVersion.takeUnretainedValue())
            self.normalImage = img.rotate(radians: .pi/2)
            self.depthData =  oi.depthData
            showImage()
        }

    }
}
