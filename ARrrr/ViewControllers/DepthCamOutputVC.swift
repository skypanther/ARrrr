//
//  DepthCamOutputVC.swift
//  ARrrr
//
//  Created by Timothy Poulsen on 5/16/19.
//  Copyright © 2019 Tim Poulsen. All rights reserved.
//

import AVFoundation
import UIKit

enum FilterType: Int {
    case greenScreen
    case blur
}

class DepthCamOutputVC: UIViewController {

    var outputImage: AVCapturePhoto?
    var normalImage: UIImage?
    var depthData: AVDepthData?
    var depthMap: CIImage?
    var backgroundImage: CIImage?
    var mask: CIImage?
    var currentImage: CIImage?
    
    var scale: CGFloat = 0.0
    var sliderValue: CGFloat = 0.0
    var currentFilter: FilterType = .greenScreen
    var depthFilters = DepthImageFilters()

    @IBOutlet weak var imageView: UIImageView!
    @IBAction func sliderChanged(_ sender: UISlider) {
        sliderValue = CGFloat(sender.value)

        if let depthMap = self.depthMap {
            mask = depthFilters.createHighPassMask(for: depthMap,
                                                   withFocus: sliderValue,
                                                   andScale: scale,
                                                   isSharp: true)
        }
        if let background = backgroundImage, let image = normalImage, mask != nil {
            currentImage = depthFilters.greenScreen(image: CIImage(image: image)!,
                                                    background: background,
                                                    mask: mask!)
        }
        if let currentImage = currentImage {
            imageView.image = UIImage(ciImage: currentImage)
        }
    }
    
}

// MARK: - VC overrides

extension DepthCamOutputVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let bgImage = UIImage(named: "arrr_bg") {
            backgroundImage = CIImage(image: bgImage)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let oi = outputImage, let cgiVersion = oi.cgImageRepresentation() {
            let img = UIImage(cgImage: cgiVersion.takeUnretainedValue())
            self.normalImage = img.rotate(radians: .pi/2)
            self.depthData =  oi.depthData
            imageView.image = self.normalImage
            if let imgWidth = self.normalImage?.size.width,
                let imgHeight = self.normalImage?.size.height {
                depthData.output
                scale = max(imgWidth, imgHeight) / max(depthData.width, depthData.height)
            }
        }
        
        let disparityData = self.depthData?.convertToDisparity()
        if let pixelBuffer = disparityData?.depthDataMap {
            // pixelBuffer.clamp()
            self.depthMap = CIImage(cvPixelBuffer: pixelBuffer)
        }
    }
}
