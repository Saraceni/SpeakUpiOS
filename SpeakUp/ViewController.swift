//
//  ViewController.swift
//  SpeakUp
//
//  Created by Saraceni on 10/16/16.
//  Copyright © 2016 Saraceni. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet var micButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var statusMessage: UITextView!
    @IBOutlet var listeningOverlay: UIView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        micButton.isEnabled = false
        speechRecognizer?.delegate = self
        listeningOverlay.isHidden = true
        
        checkMicrophoneAuth()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func speakButtonPressed(_ sender: UIButton) {
        startRecording()
    }
    
    @IBAction func speakButtonReleased(_ sender: UIButton) {
        listeningOverlay.isHidden = true
        audioEngine.stop()
        recognitionRequest?.endAudio()
        micButton.isEnabled = false
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.statusMessage.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.micButton.isEnabled = true
            }
            
            guard let text = result?.bestTranscription.formattedString , error == nil && isFinal else { return }
            self.activityIndicator.startAnimating()
            RestHelper.sendRequest(text: text, callback: {
                json in
                self.activityIndicator.stopAnimating()
                self.handleServerResponse(response: json)
            })
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            listeningOverlay.isHidden = false
        } catch {
            print("audioEngine couldn't start because of an error.")
            listeningOverlay.isHidden = true
        }
        
        
    }
    
    func handleServerResponse(response: NSDictionary?) {
        
        guard let data = response else {
            statusMessage.text = "Não foi possível processar a requisição."
            return
        }
        
        if let entities = data["entities"] as? NSArray,
            let intents = data["intents"] as? NSArray,
            let entity = entities.firstObject as? NSDictionary,
            let intent = intents.firstObject as? NSDictionary,
            let intentStr = intent["intent"] as? String,
            let entityStr = entity["value"] as? String
            {
                
            statusMessage.text = intentStr + " " + entityStr
        } else {
            statusMessage.text = "Não foi possível processar a requisição."
        }
    }
    
    
    
    func checkMicrophoneAuth() {
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.micButton.isEnabled = isButtonEnabled
            }
        }
    }


}

extension ViewController: SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            micButton.isEnabled = true
        } else {
            micButton.isEnabled = false
        }
    }
}

