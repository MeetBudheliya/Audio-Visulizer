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
    let picker = UIColorPickerViewController()
    //    var waveformView = SwiftSiriWaveformView()
    
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    
    var audioUnit: AudioUnit?
    var waveformView = WaveformView()
    var displayLink: CADisplayLink?
    var waveformPath: UIBezierPath = UIBezierPath()
    
    //    var audioData = [Float]()
    //    var displayLink: CADisplayLink!
    //    var audioEngine: AVAudioEngine!
    var playerLayer: AVPlayerLayer!
    //    var eqUnit: AVAudioUnitEQ!
    //    var inputNode: AVAudioInputNode!
    //    var playerNode: AVAudioPlayerNode!
    
    fileprivate var startRendering = Date()
    fileprivate var endRendering = Date()
    fileprivate var startLoading = Date()
    fileprivate var endLoading = Date()
    fileprivate var profileResult = ""
    
    
    //MARK: - Variables
    var isPlaying = false{
        didSet{
            if isPlaying{
                audioPlayer?.play()
                button_play_pause.setImage(UIImage(named: "ic_pause"), for: .normal)
                //                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateVisualization), userInfo: nil, repeats: true)
                //                timer.fire()
            }else{
                audioPlayer?.pause()
                button_play_pause.setImage(UIImage(named: "ic_play"), for: .normal)
                //                timer.invalidate()
            }
        }
    }
    
    var last_volume: Float = 0.0
    var isMute = false{
        didSet{
            
            //            player.isMuted = isMute
            if isMute{
                last_volume = audioPlayer?.volume ?? 0
                audioPlayer?.setVolume(0, fadeDuration: 0.5)
                button_mute.setImage(UIImage(named: "ic_mute"), for: .normal)
            }else{
                audioPlayer?.setVolume(last_volume, fadeDuration: 0.5)
                button_mute.setImage(UIImage(named: "ic_speaker"), for: .normal)
            }
        }
    }
    var audioPlayer : AVAudioPlayer?
    //    var timer = Timer()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //        setupAudioSession()
        
        
        self.loadingStart()
        
        self.makeLayout()
        
        self.setLiveStreamingPlayer()
        
       
    }
    
    override func viewDidLayoutSubviews() {
        activityIndicator.center = view.center
        activityIndicator.layoutIfNeeded()
    }
    
    //MARK: - Methods
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print(player.status)
        if keyPath == "status", let player = object as? AVPlayer {
            if player.status == .readyToPlay {
                print(Keys.ready_to_play)
                self.loadingStop()
                
                //                setupVisualization()
            }else {
                print(Keys.unable_to_play)
            }
        }
    }
    
    @objc func playerDidFinish(){
        print("Player did finish")
        audioPlayer?.play()
    }
    
    func makeLayout(){
        
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
        stack_container.spacing = 10
        stack_container.distribution = .fill
        stack_container.alignment = .center
        
        
        // Create a waveform view to visualize the audio waveform
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        waveformView.backgroundColor = .lightGray
        waveformView.layer.masksToBounds = true
        waveformView.layer.cornerRadius = 10
        view.addSubview(waveformView)
        
        // assign constraints and activate
        NSLayoutConstraint.activate([
            //            waveformView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 0),
            waveformView.bottomAnchor.constraint(equalTo: stack_container.topAnchor, constant: -10),
            waveformView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,constant: 10),
            waveformView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,constant: -10),
            waveformView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
            //            ,waveformView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        //        view_wave.frame = CGRect(x: 0, y: 0, width: waveformView.bounds.width, height: 50)
        //        view_wave.center = waveformView.center
        //        view_wave.backgroundColor = .yellow
        //        waveformView.addSubview(view_wave)
        
        // Setting the Initial Color of the Picker and delegate
        picker.selectedColor = .white
        picker.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(changeLineColor))
        waveformView.addGestureRecognizer(tap)
    }
    
    func setLiveStreamingPlayer(){
        
        // Check if audioURL is not nil
        let local_url = Bundle.main.url(forResource: "sample", withExtension: "mp3")
        
        guard let url = local_url else {
            print("Audio file not found.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.isMeteringEnabled = true
            
            startVisualization()
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
//        
//        // Create the player item
//        if let stream_url = URL(string: stream_url){
//            
//            player = AVPlayer(url: stream_url)
//            
//            // Create player layer
//            playerLayer = AVPlayerLayer(player: player)
//            playerLayer.frame = view.bounds
//            view.layer.addSublayer(playerLayer)
//            
//            // Add observer for player status
//            player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
//            
//            //set slider value as per player volume
//            //volume_slider.value = player.volume
//            
//            // Start playing
//            isPlaying = true
//            
//            //            self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main, using: { (time) in
//            //                self.player!.currentItem
//            //                if self.player!.currentItem?.status == .readyToPlay {
//            //                    let currentTime = CMTimeGetSeconds(self.player!.currentTime())
//            //
//            //                    let secs = Int(currentTime)
//            //                    print(NSString(format: "%02d:%02d", secs/60, secs%60))
//            //
//            //                }
//            //            })
//           
//            //            // Set up AVAudioEngine
//            //            audioEngine = AVAudioEngine()
//            //            let inputNode = audioEngine.inputNode
//            //
//            //            // Get the input audio format
//            //            let inputFormat = inputNode.inputFormat(forBus: 0)
//            //
//            //            // Install an audio tap on the input node
//            //            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, time in
//            //                self.processAudioBuffer(buffer)
//            //            }
//            //
//            //            // Start the audio engine
//            //            do {
//            //                try audioEngine.start()
//            //            } catch {
//            //                print("Error starting audio engine: \(error.localizedDescription)")
//            //            }
//            //
//            //            // Create a CADisplayLink to update the sound wave visualization
//            //            displayLink = CADisplayLink(target: self, selector: #selector(updateSoundWave))
//            //            displayLink.add(to: .current, forMode: .default)
//        }else{
//            // can show toast message here
//            print(Keys.unable_to_play)
//        }
    }
    
    
    @objc func changeLineColor(){
        // Presenting the Color Picker
        self.present(picker, animated: true, completion: nil)
    }
    
    // Function to update the waveform visualization
    @objc func updateWaveform() {
        
        //        // Retrieve audio PCM data
        //        let audioFormat = playerNode.outputFormat(forBus: 0)
        //        guard let audioPCMBuffer = playerNode.outputFormat(forBus: 0).sampleRate else {
        //            print("Error retrieving PCM data")
        //            return
        //        }
        //
        //        // Process PCM data to generate waveform path
        //        let waveformPath = UIBezierPath()
        //        let waveformHeight = waveformView.bounds.height
        //
        //        // Example: Generate waveform based on audio PCM data
        //        let sampleRate = audioFormat.sampleRate
        //        let bufferSize = 1024 // Adjust buffer size as needed
        //        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(bufferSize))
        //        playerNode.renderIntoBuffer(audioBuffer, frameCount: AVAudioFrameCount(bufferSize))
        //
        //        let channelData = audioBuffer.floatChannelData!
        //        let channelCount = Int(audioBuffer.format.channelCount)
        //
        //        let path = UIBezierPath()
        //        let pathWidth = waveformView.bounds.width
        //        let pathHeight = waveformView.bounds.height / CGFloat(channelCount)
        //
        //        for i in 0..<bufferSize {
        //            let x = CGFloat(i) / CGFloat(bufferSize) * pathWidth
        //            let y = (1.0 + CGFloat(channelData?[0][i] ?? 0)) * pathHeight / 2.0 // Assuming mono audio
        //
        //            if i == 0 {
        //                path.move(to: CGPoint(x: x, y: y))
        //            } else {
        //                path.addLine(to: CGPoint(x: x, y: y))
        //            }
        //        }
        //
        //        waveformPath.append(path)
        //
        //        // Clear previous waveform
        //        waveformView.layer.sublayers = nil
        //
        //        // Add waveform path to waveformView
        //        let waveformLayer = CAShapeLayer()
        //        waveformLayer.path = waveformPath.cgPath
        //        waveformLayer.strokeColor = UIColor.blue.cgColor
        //        waveformLayer.lineWidth = 2.0
        //        waveformLayer.fillColor = UIColor.clear.cgColor
        //        waveformView.layer.addSublayer(waveformLayer)
        //
        //        // Clear previous waveform
        //        waveformView.layer.sublayers = nil
        //
        //        // Create waveform layer
        //        let waveformLayer = CAShapeLayer()
        //        waveformLayer.path = waveformPath.cgPath
        //        waveformLayer.strokeColor = UIColor.blue.cgColor
        //        waveformLayer.lineWidth = 2.0
        //        waveformLayer.fillColor = UIColor.clear.cgColor
        //        waveformView.layer.addSublayer(waveformLayer)
        //
        //        // Reset waveform path for the next update
        //        waveformPath.removeAllPoints()
        
    }

    
    func startVisualization() {
        isPlaying = true
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateVisualization))
        displayLink?.add(to: .current, forMode: .common)
        //         // Set up the audio player for visualization
        
        //
        //         // Create a timer to update the visualization
        //         timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateVisualization), userInfo: nil, repeats: true)
    }
    
    @objc func updateVisualization() {
        
        audioPlayer?.updateMeters()
        
        // Get the average power of the first channel
        let averagePower = audioPlayer?.averagePower(forChannel: 0) ?? 0
        let normalizedPower = max(0, averagePower + 60) / 60 // Normalize to [0, 1]
        print(normalizedPower)
        
        waveformView.pulseValue = CGFloat(normalizedPower)
    }
    
    
    //MARK: - Actions
    @objc func playPauseButtonTapped() {
        isPlaying.toggle()
    }
    
    @objc func playerMuteUnmuteTapped() {
        isMute.toggle()
    }
}

//MARK: - Audio player delegate
extension ViewController: AVAudioPlayerDelegate{
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag{
            self.audioPlayer?.play()
        }
    }
}


//MARK: - Color Picker
extension ViewController: UIColorPickerViewControllerDelegate{
    
    //  Called once you have finished picking the color.
       func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
           self.waveformView.waveColor = viewController.selectedColor
           
       }
       
       //  Called on every color selection done in the picker.
       func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
           print(viewController.selectedColor)
       }
}
