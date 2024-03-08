//
//  ViewController.swift
//  AudioVisulizer
//
//  Created by Meet Budheliya on 08/03/24.
//

import UIKit
import AVKit
import MediaPlayer

class ViewController: UIViewController {
    
    //MARK: - UI Variables
    let stack_container = UIStackView()
    let view_container = UIStackView()
    let button_play_pause = UIButton()
    let button_mute = UIButton()
    let slider_volume = MPVolumeView()
    var margins = UILayoutGuide()
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    
    var audioData = [Float]()
    var displayLink: CADisplayLink!
    var audioEngine: AVAudioEngine!
    var playerLayer: AVPlayerLayer!
    
    //MARK: - Variables
    var isPlaying = false{
        didSet{
            if isPlaying{
                player.play()
                button_play_pause.setImage(UIImage(named: "ic_pause"), for: .normal)
            }else{
                player.pause()
                button_play_pause.setImage(UIImage(named: "ic_play"), for: .normal)
            }
        }
    }
    
    var isMute = false{
        didSet{
            player.isMuted = isMute
            if isMute{
                button_mute.setImage(UIImage(named: "ic_mute"), for: .normal)
            }else{
                button_mute.setImage(UIImage(named: "ic_speaker"), for: .normal)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.loadingStart()
        
        self.makeLayout()
        
        self.setLiveStreamingPlayer()
    }
    
    //MARK: - Methods
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print(player.status)
        if keyPath == "status", let player = object as? AVPlayer {
            if player.status == .readyToPlay {
                print(Keys.ready_to_play)
                self.loadingStop()
            }else {
                print(Keys.unable_to_play)
            }
        }
    }
    
    func makeLayout(){
        margins = view.layoutMarginsGuide
        
        stack_container.translatesAutoresizingMaskIntoConstraints = false
        view_container.addSubview(stack_container)
        
        // Add constraints for controls container stack
        NSLayoutConstraint.activate([
            stack_container.topAnchor.constraint(equalTo: view_container.topAnchor),
            stack_container.leadingAnchor.constraint(equalTo: view_container.leadingAnchor, constant: 10),
            stack_container.trailingAnchor.constraint(equalTo: view_container.trailingAnchor, constant: -10),
            stack_container.bottomAnchor.constraint(equalTo: view_container.bottomAnchor)
        ])
        
        // controlls container stack
        view_container.layer.cornerRadius = 10
        view_container.layer.borderColor = UIColor.lightGray.cgColor
        view_container.layer.borderWidth = 1
        view_container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(view_container)
        
        // assign constraints and activate
        NSLayoutConstraint.activate([
            view_container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            view_container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 10),
            view_container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -10),
            view_container.heightAnchor.constraint(equalToConstant: 70),
        ])
        
        
        // Create play/pause button
        button_play_pause.setImage(UIImage(named: "ic_play"), for: .normal)
        button_play_pause.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        button_play_pause.translatesAutoresizingMaskIntoConstraints = false
        stack_container.addArrangedSubview(button_play_pause)
        
        // Create volume slider
        slider_volume.translatesAutoresizingMaskIntoConstraints = false
        slider_volume.tintColor = UIColor(named: Keys.app_color)
        stack_container.addArrangedSubview(slider_volume)
        
        // Create mute/unmute button
        button_mute.setImage(UIImage(named: "ic_speaker"), for: .normal)
        button_mute.tintColor = UIColor(named: Keys.app_color)
        button_mute.addTarget(self, action: #selector(playerMuteUnmuteTapped), for: .touchUpInside)
        stack_container.addArrangedSubview(button_mute)
        
        // Assign constraints for play/pause button and volume slider within the controls container stack
        NSLayoutConstraint.activate([
            button_play_pause.widthAnchor.constraint(equalToConstant: 50),
            button_play_pause.heightAnchor.constraint(equalToConstant: 50),
            slider_volume.heightAnchor.constraint(equalToConstant: 20),
            button_mute.widthAnchor.constraint(equalToConstant: 50),
            button_mute.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // container stack view
        // adding controlls in one horizontal stack
        stack_container.addArrangedSubview(button_play_pause)
        stack_container.addArrangedSubview(slider_volume)
        stack_container.addArrangedSubview(button_mute)
        
        stack_container.axis = .horizontal
        stack_container.spacing = 10.0
        stack_container.distribution = .fill
        stack_container.alignment = .center
        
    }
    
    func setLiveStreamingPlayer(){
        // Create the player item
        if let stream_url = URL(string: stream_url){
            playerItem = AVPlayerItem(url: stream_url)
            
            // Create the player with the player item
            player = AVPlayer(playerItem: playerItem)
            
            // Add observer for player status
            player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
            
            //set slider value as per player volume
            //volume_slider.value = player.volume
            
            // Start playing
            isPlaying = true
            
            
            // Set up AVAudioEngine
            audioEngine = AVAudioEngine()
            let inputNode = audioEngine.inputNode
            
            // Get the input audio format
            let inputFormat = inputNode.inputFormat(forBus: 0)
            
            // Install an audio tap on the input node
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, time in
                self.processAudioBuffer(buffer)
            }
            
            // Start the audio engine
            do {
                try audioEngine.start()
            } catch {
                print("Error starting audio engine: \(error.localizedDescription)")
            }
            
            // Create a CADisplayLink to update the sound wave visualization
            displayLink = CADisplayLink(target: self, selector: #selector(updateSoundWave))
            displayLink.add(to: .current, forMode: .default)
        }else{
            // can show toast message here
            print(Keys.unable_to_play)
        }
    }
    
    //MARK: - Actions
    @objc func playPauseButtonTapped() {
        isPlaying.toggle()
    }
    
    @objc func playerMuteUnmuteTapped() {
        isMute.toggle()
    }
    
    //    // Function to update the sound wave visualization
    //    @objc func updateSoundWave() {
    //        guard let currentItem = player.currentItem else { return }
    //        let asset = currentItem.asset
    //
    //        // Create AVAssetReader
    //        do {
    //            let assetReader = try AVAssetReader(asset: asset)
    //
    //            // Create AVAssetReaderTrackOutput
    //            let track = asset.tracks(withMediaType: .audio)[0]
    //            let outputSettings: [String: Any] = [
    //                AVFormatIDKey: kAudioFormatLinearPCM,
    //                AVLinearPCMBitDepthKey: 32,
    //                AVLinearPCMIsFloatKey: true,
    //                AVLinearPCMIsNonInterleaved: false
    //            ]
    //            let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
    //
    //            // Add output to reader
    //            assetReader.add(trackOutput)
    //
    //            // Start reading
    //            assetReader.startReading()
    //
    //            // Process audio samples
    //            while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
    //                guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
    //                var length = 0
    //                var data: UnsafeMutablePointer<Int8>?
    //                CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &length, totalLengthOut: nil, dataPointerOut: &data)
    //                let floatArray = data?.withMemoryRebound(to: Float.self, capacity: length / MemoryLayout<Float>.size) { $0 }
    //                let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
    //                let samples = UnsafeBufferPointer(start: floatArray, count: sampleCount)
    //                audioData = Array(samples)
    //
    //                // Release the buffer
    //                CMSampleBufferInvalidate(sampleBuffer)
    //            }
    //        } catch {
    //            print("Error reading audio: \(error.localizedDescription)")
    //        }
    //
    //        // Render sound wave visualization using Core Graphics
    //        let path = UIBezierPath()
    //        path.move(to: CGPoint(x: 0, y: view.bounds.height / 2))
    //        let step = view.bounds.width / CGFloat(audioData.count)
    //        for (index, sample) in audioData.enumerated() {
    //            let x = step * CGFloat(index)
    //            let y = CGFloat(sample) * (view.bounds.height / 4) + (view.bounds.height / 2)
    //            path.addLine(to: CGPoint(x: x, y: y))
    //        }
    //
    //        let shapeLayer = CAShapeLayer()
    //        shapeLayer.path = path.cgPath
    //        shapeLayer.strokeColor = UIColor.blue.cgColor
    //        shapeLayer.fillColor = UIColor.clear.cgColor
    //        view.layer.addSublayer(shapeLayer)
    //    }
    
    // Function to process audio buffer
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count:Int(buffer.frameLength)))
        audioData = floatArray
    }
    
    // Function to update the sound wave visualization
    @objc func updateSoundWave() {
        view.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
        
        // Render sound wave visualization using Core Graphics
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: view.bounds.height / 2))
        let step = view.bounds.width / CGFloat(audioData.count)
        for (index, sample) in audioData.enumerated() {
            let x = step * CGFloat(index)
            let y = CGFloat(sample) * (view.bounds.height / 4) + (view.bounds.height / 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.blue.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        view.layer.addSublayer(shapeLayer)
    }
}
