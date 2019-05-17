//
//  SecondViewController.swift
//  ARrrr
//
//  Created by Timothy Poulsen on 5/16/19.
//  Copyright © 2019 Tim Poulsen. All rights reserved.
//

import AVFoundation
import UIKit

enum SelectedCamera {
    case back, front
}

class TabDepthMapVC: UIViewController {
    
    let font = UIFont(name: "icomoon", size: 80)
    let btnTitleAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                              NSAttributedString.Key.font: UIFont(name: "icomoon", size: 21)!]
    let SHUTTER = "\u{e901}"
    var cameraSelected: SelectedCamera = .back
    var camera: AVCaptureDevice?
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    var videoOutputAdded = false
    let photoOutput = AVCapturePhotoOutput()
    let sessionQueue = DispatchQueue(label: "session queue")
    let dataOutputQueue = DispatchQueue(label: "video data queue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .workItem)
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var cameraButtonOutlet: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBAction func cameraSelector(_ sender: UISegmentedControl) {
        reset()
        if sender.selectedSegmentIndex == 0 {
            cameraSelected = .back
        } else {
            cameraSelected = .front
        }
        configureCaptureSession()
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        self.session.beginConfiguration()
        self.session.removeOutput(self.videoOutput)
        var photoSettings = AVCapturePhotoSettings()
        photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isDepthDataDeliveryEnabled = true
        photoSettings.embedsDepthDataInPhoto = true
        photoSettings.isDepthDataFiltered = true
        self.session.addOutput(photoOutput)
        self.session.commitConfiguration()
        photoOutput.isDepthDataDeliveryEnabled = true
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    fileprivate func reset() {
        guard let camera = self.camera else {
            return
        }
        if self.session.isRunning {
            self.session.stopRunning()
        }
        do {
            try camera.lockForConfiguration()
            self.session.beginConfiguration()
            guard let currentCameraInput: AVCaptureInput = self.session.inputs.first else {
                fatalError("cannot get old camera")
            }
            self.session.removeInput(currentCameraInput)
            self.session.removeOutput(self.videoOutput)
            self.videoOutputAdded = false
            self.session.commitConfiguration()
        } catch {
            print("unable to lock camera for configuration")
        }
        camera.unlockForConfiguration()
        self.camera = nil
    }
    
    fileprivate func whenDoneCapturingPhoto(with photo: AVCapturePhoto) {
        // segue to a viewcontroller showing the output / depth / 3D representation
        self.session.beginConfiguration()
        self.session.removeOutput(photoOutput)
        self.session.addOutput(self.videoOutput)
        self.session.commitConfiguration()
        let vc: PointCloudOutputVC? = self.storyboard?.instantiateViewController(withIdentifier: "PointCloudOutputVC") as? PointCloudOutputVC
        if let validVC: PointCloudOutputVC = vc {
            validVC.outputImage = photo
            navigationController?.pushViewController(validVC, animated: true)
        }
    }
    
    fileprivate func setButtonSymbol(_ title: String) {
        let btnAttributedTitle = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white, NSAttributedString.Key.font: font!])
        cameraButton.setAttributedTitle(btnAttributedTitle, for: .normal)
        cameraButton.setAttributedTitle(btnAttributedTitle, for: .highlighted)
        cameraButton.setAttributedTitle(btnAttributedTitle, for: .focused)
    }

}

// MARK: - Camera configuration

extension TabDepthMapVC {
    fileprivate func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            // Not yet asked; prompt for permission
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    fatalError("Cannot run without camera permissions")
                }
                self.sessionQueue.resume()
            })
            return
        default:
            // The user has previously denied access
            fatalError("Cannot run without camera permissions")
        }
    }
    
    fileprivate func configureCaptureSession() {
        switch cameraSelected {
        case .back:
            self.camera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
        case .front:
            self.camera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
        }
        guard let camera = self.camera else {
            fatalError("Unable to access the camera")
        }
        if self.videoOutputAdded == false {
            self.videoOutput.setSampleBufferDelegate(self, queue: self.dataOutputQueue)
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
        }
        sessionQueue.async {
            do {
                try camera.lockForConfiguration()
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo
                let cameraInput = try AVCaptureDeviceInput(device: camera)
                self.session.addInput(cameraInput)
                self.session.addOutput(self.videoOutput)
                self.videoOutputAdded = true
                self.session.commitConfiguration()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        camera.unlockForConfiguration()
        self.session.startRunning()
    }
    
}

// MARK: - Capture Video Data Delegate Methods

extension TabDepthMapVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = CIImage(cvPixelBuffer: pixelBuffer!)
        
//        var displayImage = UIImage(ciImage: image)
//        displayImage = displayImage.rotate(radians: .pi/2)
        DispatchQueue.main.async { [weak self] in
            self?.imgView.image = UIImage(ciImage: image)
        }
    }
}

extension TabDepthMapVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        whenDoneCapturingPhoto(with: photo)
    }
}


// MARK: - VC overrides

extension TabDepthMapVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermissions()
        configureCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setButtonSymbol(SHUTTER)
    }
}
