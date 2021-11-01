//
//  ViewController.swift
//  SmartCamera
//
//  Created by Adam Wolkowycki on 29/10/2021.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var label: UILabel!
    
    // let screenWidth = UIScreen.main.bounds.width
    let rect = UIView(frame: CGRect(x: 0, y: 80, width: 10, height: 10))
    
    let accuracy = Float(0.5)
    let defaultText = "Point the camera at an object..."
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        label.text = defaultText
        setupSession()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        rect.backgroundColor = .green
        view.addSubview(rect)
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
            self.rect.frame = CGRect(x: 0, y: 80, width: UIScreen.main.bounds.width, height: 10)
        })
    }
    
    @objc func unanimate() {
        UIView.animate(withDuration: 1, animations: {
            self.rect.frame = CGRect(x: 0, y: 80, width: 10, height: 10)
        })
    }
}
