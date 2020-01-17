//
//  ViewController.swift
//  QIS2T
//
//  Created by Santanu Das Adhikary. on 24/12/19.
//  Copyright © 2019 Santanu Das Adhikary. All rights reserved.
//

import UIKit
import Speech

class ViewController: ExpandingViewController,ATCWalkthroughViewControllerDelegate,SFSpeechRecognizerDelegate {

    typealias ItemInfo = (imageName: String, title: String)
    fileprivate var cellsIsOpen = [Bool]()
    fileprivate let items: [ItemInfo] = [("Image_dictionary", "Click To View Word Details"),("app_icon", "Click To View Recording Option")]
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var listenedText: UILabel!
    @IBOutlet weak var viewResultButton: UIButton!
    var listenedTextVaue : String = ""
    
    // walk through data model
    let walkthroughs = [
        ATCWalkthroughModel(title: "Dictionary", subtitle: "Check Dictionary option to get all the Dictionary data details!", icon: "dictionary_image"),
        ATCWalkthroughModel(title: "Microphone", subtitle: "Click on the microphone to open the recording option.", icon: "process_microphone"),
        ATCWalkthroughModel(title: "Speak", subtitle: "Click into the recording button to start and finish the recording.", icon: "process_speak"),
        ATCWalkthroughModel(title: "Process", subtitle: "Once done with recording, View Result will show the searched text in dictionary.", icon: "process_gear"),
        ATCWalkthroughModel(title: "Get Analysis", subtitle: "Check the search text analysis in dictionary. If text matches with dictionary data, background will be yellow - else app will show the tost for data unavailability!", icon: "process_graph"),
    ]
    
}

// MARK: - Lifecycle 🌎

extension ViewController {

    override func viewDidLoad() {
        itemSize = CGSize(width: 256, height: 460)
        super.viewDidLoad()
        
        registerCell()
        fillCellIsOpenArray()
        addGesture(to: collectionView!)
        configureNavBar()
        
        let walkthroughVC = self.walkthroughVC()
        walkthroughVC.delegate = self
        self.addChildViewControllerWithView(walkthroughVC)

        enableMicIcon(isEnabled: false)
        speechRecognizer.delegate = self
        listenedText.isHidden = true;
        viewResultButton.isHidden = true;
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
                    
            var isButtonEnabled = false
            
            switch authStatus {
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
            @unknown default:
                fatalError()
            }
            
            OperationQueue.main.addOperation() {
                self.enableMicIcon(isEnabled: isButtonEnabled)
            }
        }
    }
    
    func walkthroughViewControllerDidFinishFlow(_ vc: ATCWalkthroughViewController) {
      UIView.transition(with: self.view, duration: 1, options: .transitionCrossDissolve, animations: {
        vc.view.removeFromSuperview()
      }, completion: nil)
    }
    
    fileprivate func walkthroughVC() -> ATCWalkthroughViewController {
      let viewControllers = walkthroughs.map { ATCClassicWalkthroughViewController(model: $0, nibName: "ATCClassicWalkthroughViewController", bundle: nil) }
      return ATCWalkthroughViewController(nibName: "ATCWalkthroughViewController",
                                          bundle: nil,
                                          viewControllers: viewControllers)
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        
            // cell instance
            let indexPath = IndexPath(row: currentIndex, section: 0)
            guard let cell = collectionView?.cellForItem(at: indexPath) as? DemoCollectionViewCell else { return }
        
            if audioEngine.isRunning {
                audioEngine.stop()
                recognitionRequest?.endAudio()
                enableMicIcon(isEnabled: false)
                
                cell.microphoneButton.backgroundColor = UIColor(hexString:"#4285F4",alpha: 1.0)
                cell.microphoneStatusTitle.text = "Click to Start Recording..."
            } else {
                startRecording()
                
                cell.microphoneButton.backgroundColor = UIColor(hexString:"#0F9D58",alpha: 1.0)
                cell.microphoneStatusTitle.text = "Click to Stop Recording..."
            }
        }

        func startRecording() {
            
            if recognitionTask != nil {  //1
                recognitionTask?.cancel()
                recognitionTask = nil
            }
            
            let audioSession = AVAudioSession.sharedInstance()  //2
            do {
                try audioSession.setCategory(AVAudioSession.Category.record)
                try audioSession.setMode(AVAudioSession.Mode.measurement)
                //try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("audioSession properties weren't set because of an error.")
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
            
            let inputNode = audioEngine.inputNode
            
            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
            } //5
            
            recognitionRequest.shouldReportPartialResults = true  //6
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
                
                var isFinal = false  //8
                
                if result != nil {
                    if !result!.isFinal {
                        
                        self.listenedText.isHidden = false;
                        self.viewResultButton.isHidden = false;
                        self.listenedText.text = String(format: "We have Listened - %@",result?.bestTranscription.formattedString ?? "Unable to get you") //9
                        self.listenedTextVaue = result?.bestTranscription.formattedString ?? ""
                    }
                    isFinal = (result?.isFinal)!
                    print(result!.bestTranscription.formattedString)
                    print(result!.transcriptions.map({$0.formattedString}))
                    print(isFinal)
                }
                
                
                if error != nil || isFinal {  //10
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus
                        : 0)
                    
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    
                    self.enableMicIcon(isEnabled: true)
                }
            })
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()  //12
            
            do {
                try audioEngine.start()
            } catch {
                print("audioEngine couldn't start because of an error.")
            }
            
            listenedText.text = ""
            
        }
        
        func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
            enableMicIcon(isEnabled: available)
        }
        
        func enableMicIcon(isEnabled: Bool) {
            
            // cell instance
            let indexPath = IndexPath(row: currentIndex, section: 0)
            guard let cell = collectionView?.cellForItem(at: indexPath) as? DemoCollectionViewCell else { return }
            cell.microphoneButton.isEnabled = isEnabled
    
        }
    
    @IBAction func viewResultTapped(_ sender: AnyObject) {
        
        let indexPath = IndexPath(row: currentIndex, section: 0)
        guard let cell = collectionView?.cellForItem(at: indexPath) as? DemoCollectionViewCell else { return }
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            enableMicIcon(isEnabled: false)
            cell.microphoneButton.backgroundColor = UIColor(hexString:"#4285F4",alpha: 1.0)
            cell.microphoneStatusTitle.text = "Click to Start Recording..."
        }
        
        // TO DO
        // We can add alert before sending to next view to confirm the text
        
        if self.listenedTextVaue.count > 0 {
            let storyboard = UIStoryboard(storyboard: .Main)
            let toViewController: DemoTableViewController = storyboard.instantiateViewController()
            toViewController.selectedText = listenedTextVaue
            pushToViewController(toViewController)

            if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
                rightButton.animationSelected(true)
            }
        } else {
            // Show alert
            let alert = UIAlertController(title: "Hello!!", message: "We haven't hard anything from you.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

            self.present(alert, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.listenedText.isHidden = true;
        self.viewResultButton.isHidden = true;
    }
}

// MARK: Helpers

extension ViewController {

    fileprivate func registerCell() {

        let nib = UINib(nibName: String(describing: DemoCollectionViewCell.self), bundle: nil)
        collectionView?.register(nib, forCellWithReuseIdentifier: String(describing: DemoCollectionViewCell.self))
    }

    fileprivate func fillCellIsOpenArray() {
        cellsIsOpen = Array(repeating: false, count: items.count)
    }

    fileprivate func getViewController() -> ExpandingTableViewController {
        let storyboard = UIStoryboard(storyboard: .Main)
        let toViewController: DemoTableViewController = storyboard.instantiateViewController()
        return toViewController
    }

    fileprivate func configureNavBar() {
        navigationItem.leftBarButtonItem?.image = navigationItem.leftBarButtonItem?.image!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
    }
}

/// MARK: Gesture
extension ViewController {

    fileprivate func addGesture(to view: UIView) {
        let upGesture = Init(UISwipeGestureRecognizer(target: self, action: #selector(DemoViewController.swipeHandler(_:)))) {
            $0.direction = .up
        }

        let downGesture = Init(UISwipeGestureRecognizer(target: self, action: #selector(DemoViewController.swipeHandler(_:)))) {
            $0.direction = .down
        }
        view.addGestureRecognizer(upGesture)
        view.addGestureRecognizer(downGesture)
    }

    @objc func swipeHandler(_ sender: UISwipeGestureRecognizer) {
        let indexPath = IndexPath(row: currentIndex, section: 0)
        
        if indexPath.row != 0 {
            guard let cell = collectionView?.cellForItem(at: indexPath) as? DemoCollectionViewCell else { return }

            let open = sender.direction == .up ? true : false
            cell.cellIsOpen(open)
            cellsIsOpen[indexPath.row] = cell.isOpened
            
            if cell.isOpened {
                // TO DO
            } else {
                
                let indexPath = IndexPath(row: currentIndex, section: 0)
                guard let cell = collectionView?.cellForItem(at: indexPath) as? DemoCollectionViewCell else { return }
                        
                if audioEngine.isRunning {
                    audioEngine.stop()
                    recognitionRequest?.endAudio()
                    enableMicIcon(isEnabled: false)
                    cell.microphoneButton.backgroundColor = UIColor(hexString:"#4285F4",alpha: 1.0)
                    cell.microphoneStatusTitle.text = "Click to Start Recording..."
                }
                
                self.listenedText.isHidden = true;
                self.viewResultButton.isHidden = true;
            }
        }
        
    }
}

// MARK: UICollectionViewDataSource

extension ViewController {

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        guard let cell = cell as? DemoCollectionViewCell else { return }

        let index = indexPath.row % items.count
        let info = items[index]
        cell.backgroundImageView?.image = UIImage(named: info.imageName)
        cell.customTitle.text = info.title
        cell.cellIsOpen(cellsIsOpen[index], animated: false)
        
        cell.microphoneButton.addTarget(self, action:#selector(self.microphoneTapped(_:)), for: .touchUpInside)
        
        if indexPath.row == 0 {
            cell.microphoneStatusTitle.isHidden = true
            cell.microphoneButton.isHidden = true
        } else {
            cell.microphoneStatusTitle.isHidden = false
            cell.microphoneButton.isHidden = false
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            // Dictionary details
            let storyboard = UIStoryboard(storyboard: .Main)
            let toViewController: DemoTableViewController = storyboard.instantiateViewController()
            toViewController.selectedText = ""
            pushToViewController(toViewController)

            if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
                rightButton.animationSelected(true)
            }
        } else if indexPath.row == 1 {
            guard let cell = collectionView.cellForItem(at: indexPath) as? DemoCollectionViewCell
                , currentIndex == indexPath.row else { return }

            if cell.isOpened == false {
                cell.cellIsOpen(true)
            }
        }
    }
}

// MARK: UICollectionViewDataSource

extension ViewController {

    override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: DemoCollectionViewCell.self), for: indexPath)
    }
}
