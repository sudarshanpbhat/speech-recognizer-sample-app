//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Sudarshan Bhat on 29/05/19.
//  Copyright © 2019 Sudarshan Bhat. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var speakButton: UIButton!
    @IBOutlet weak var recognizedText: UILabel!
    @IBOutlet weak var sineWaveView: UIView!
    @IBOutlet weak var sineWaveViewHeight: NSLayoutConstraint!
    
    private var previouslyRecognizedText: String?
    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private let request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Timer?
    
    private var displayLink: CADisplayLink?
    private var startTime: CFAbsoluteTime?
    private var shapeLayer: CAShapeLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup button
        setupSpeakButton()
        
        // Setup text area
        setupTextArea()
        
        // Setup sine view
        setupSineWave()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupSineWave() {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor(red: 14/255.0, green: 154/255.0, blue: 122/255.0, alpha: 1.0).cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 2
        layer.path = nil
        shapeLayer?.removeFromSuperlayer()
        shapeLayer = layer
        sineWaveView.layer.addSublayer(shapeLayer!)
    }
    
    // Display link is used for the sine wave animation while listening to audio
    private func startDisplayLink() {
        startTime = CFAbsoluteTimeGetCurrent()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
        setupSineWave()
        sineWaveViewHeight.constant = 0
        self.view.layoutIfNeeded()
    }
    
    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        let elapsed = CFAbsoluteTimeGetCurrent() - self.startTime!
        shapeLayer?.path = wave(at: elapsed).cgPath
    }
    
    private func wave(at elapsed: Double) -> UIBezierPath {
        let centerY = sineWaveView.bounds.height / 2
        let amplitude = CGFloat(25) - abs(fmod(CGFloat(elapsed), 3) - 1.5) * 30
        
        func f(_ x: Int) -> CGFloat {
            return sin(((CGFloat(x) / view.bounds.width) + CGFloat(elapsed)) * 4 * .pi) * amplitude + centerY
        }
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: f(0)))
        for x in stride(from: 0, to: Int(view.bounds.width + 9), by: 10) {
            path.addLine(to: CGPoint(x: CGFloat(x), y: f(x)))
        }
        
        return path
    }
    
    private func setupSpeakButton() {
        let image = UIImage(named: "mic")
        speakButton.imageView?.tintColor = UIColor.white
        speakButton.setImage(image, for: UIControl.State.normal)
        speakButton.backgroundColor = UIColor(red: 14/255.0, green: 154/255.0, blue: 122/255.0, alpha: 1.0)
        speakButton.layer.cornerRadius = 0.5 * speakButton.bounds.size.width
    }
    
    private func setupTextArea() {
        
    }
    
    private func setRecognizedText(recognizedText: String) {
        self.recognizedText.text = recognizedText
    }
    
    @IBAction func onSpeakButtonClicked(_ sender: Any) {
        if (audioEngine.isRunning) {
            return
        }
        checkPermissionAndRecordAudio();
    }
    
    private func checkPermissionAndRecordAudio() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    do {
                        try self.startRecording()
                    } catch {
                        NSLog("Error recording audio")
                    }
                    
                    
                default:
                    self.showPermissionDeniedError()
                }
            }
        }
    }
    
    private func startRecording() throws {
        if (!(recognizer?.isAvailable ?? false)) {
            return
        }
        
        setRecognizedText(recognizedText: "Hi")
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [unowned self] buffer,_ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = recognizer?.recognitionTask(with: request) { (result, _) in
            let recognizedText = result?.bestTranscription.formattedString ?? ""
            if (recognizedText.count > 0) {
                self.setRecognizedText(recognizedText: recognizedText)
            }
            self.updateTimer(timeInterval: 2.0)
        }
        updateTimer(timeInterval: 3.0)
        startDisplayLink()
    }
    
    
    private func stopRecording() {
        audioEngine.stop()
        request.endAudio()
        recognitionTask?.cancel()
        audioEngine.inputNode.removeTap(onBus: 0)
        stopDisplayLink()
    }
    
    private func showPermissionDeniedError() {
        NSLog("showPermissionDeniedError()")
    }
 
    private func updateTimer(timeInterval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { timer in
            self.stopRecording()
        }
    }
}

