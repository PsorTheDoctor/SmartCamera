//
//  CameraViewController.swift
//  SmartCamera
//
//  Created by Adam Wolkowycki on 01/11/2021.
//

import UIKit
import AVKit
import Vision

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet var label: UILabel!

    let accuracy = Float(0.5)
    let defaultText = "Point the camera at an object..."
    
    let screenWidth = Int(UIScreen.main.bounds.width)
    let thickness = 10
    
    let topLeft = UIView(frame: CGRect(x: Int(UIScreen.main.bounds.width / 2), y: 80, width: 0, height: 10))
    let topRight = UIView(frame: CGRect(x: Int(UIScreen.main.bounds.width / 2), y: 80, width: 0, height: 10))
    let left = UIView(frame: CGRect(x: 0, y: 80, width: 10, height: 0))
    let right = UIView(frame: CGRect(x: UIScreen.main.bounds.width, y: 80, width: 10, height: 0))
    let bottomLeft = UIView(frame: CGRect(x: 0, y: 500, width: 0, height: 10))
    let bottomRight = UIView(frame: CGRect(x: UIScreen.main.bounds.width, y: 500, width: 0, height: 10))

    override func viewDidLoad() {

        super.viewDidLoad()
        label.text = defaultText
        setupSession()
    }

    override func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()
        
        let shapes = [topLeft, topRight, right, left, bottomLeft, bottomRight]
        
        for shape in shapes {
            shape.backgroundColor = .systemMint
            view.addSubview(shape)
        }
    }

    func setupSession() {
        // Start up the camera
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.addInput(input)
        session.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(dataOutput)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let config = MLModelConfiguration()
        guard let model = try? VNCoreMLModel(for: Resnet50(configuration: config).model) else { return }

        let request = VNCoreMLRequest(model: model) {
            (finishedReq, err) in

            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let observation = results.first else { return }
            let identifier = observation.identifier
            let confidence = observation.confidence

            DispatchQueue.main.async {
                if (confidence > self.accuracy) {
                    self.speak(text: identifier)
                    self.label.text = "\(identifier)"
                    // self.view.backgroundColor = UIColor(red: 0, green: CGFloat(confidence * 255), blue: 0, alpha: 0.1)
                    self.animate()
                } else {
                    // self.view.backgroundColor = .black
                    self.unanimate()
                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

    func speak(text: String) {

        let synthesizer = AVSpeechSynthesizer()
        let utterence = AVSpeechUtterance(string: text)
        utterence.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterence)
    }

    @objc func animate() {
        
        UIView.animate(withDuration: 1, animations: {
            self.topLeft.frame = CGRect(x: 0, y: 80,
                                        width: Int(self.screenWidth / 2),
                                        height: self.thickness)
            
            self.topRight.frame = CGRect(x: Int(self.screenWidth / 2), y: 80,
                                         width: Int(self.screenWidth / 2),
                                         height: self.thickness)
            
            self.left.frame = CGRect(x: 0, y: 80,
                                     width: self.thickness, height: 500)
            
            self.right.frame = CGRect(x: self.screenWidth - self.thickness, y: 80,
                                      width: self.thickness, height: 500)
            
            self.bottomLeft.frame = CGRect(x: 0, y: 580,
                                           width: Int(self.screenWidth / 2),
                                           height: self.thickness)
            
            self.bottomRight.frame = CGRect(x: Int(self.screenWidth / 2), y: 580,
                                            width: Int(self.screenWidth / 2),
                                            height: self.thickness)
        })
    }

    @objc func unanimate() {
        
        UIView.animate(withDuration: 0, animations: {
            self.topLeft.frame = CGRect(x: Int(UIScreen.main.bounds.width / 2), y: 80, width: 0, height: 10)
            self.topRight.frame = CGRect(x: Int(UIScreen.main.bounds.width / 2), y: 80, width: 0, height: 10)
            self.left.frame = CGRect(x: 0, y: 80, width: 10, height: 0)
            self.right.frame = CGRect(x: UIScreen.main.bounds.width, y: 80, width: 10, height: 0)
            self.bottomLeft.frame = CGRect(x: 0, y: 500, width: 0, height: 10)
            self.bottomRight.frame = CGRect(x: UIScreen.main.bounds.width, y: 500, width: 0, height: 10)
        })
    }
}
