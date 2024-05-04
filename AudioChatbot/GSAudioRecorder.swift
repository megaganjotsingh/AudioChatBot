
import Foundation
import Combine
import AVFoundation

class GSAudioRecorder: NSObject {
    static var shared = GSAudioRecorder()
    
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer:AVAudioPlayer = AVAudioPlayer()
    private let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    fileprivate var timer:Timer!
    
    let objectWillChange = PassthroughSubject<GSAudioRecorder, Never>()
    
    var isPlaying: Bool = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    var isRecording: Bool = false {
        didSet {
            objectWillChange.send(self)
        }
    }
    var url: URL?
    var recordedUrl: URL?
    var time: Int = 0
    var recordName: String? = "navaiRecordedVoice"
    
    override init() {
        super.init()

        isAuth()
    }
    
    private func recordSetup() {
       
        let newVideoName = getDir().appendingPathComponent(recordName?.appending(".m4a") ?? "sound.m4a")
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
            
                audioRecorder = try AVAudioRecorder(url: newVideoName, settings: self.settings)
                audioRecorder.delegate = self as AVAudioRecorderDelegate
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
            
        } catch {
            print("Recording update error:",error.localizedDescription)
        }
    }
    
    func record() {
        
        recordSetup()
        
        if let recorder = self.audioRecorder {
            if !isRecording {
                recordedUrl = nil
                do {
                    try audioSession.setActive(true)
                    
                    time = 0
                    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
                
                    recorder.record()
                    isRecording = true
   
                } catch {
                    print("Record error:",error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func updateTimer() {
        
        if isRecording && !isPlaying {
            
            time += 1
            
        } else {
            timer.invalidate()
        }
    }
    
    func stop() {
        
       audioRecorder.stop()
    
        do {
            try audioSession.setActive(false)
        } catch {
            print("stop()",error.localizedDescription)
        }
    }
    
    func play() {
        
        if !isRecording && !isPlaying {
            if let recorder = self.audioRecorder  {
                
                if recorder.url.path == url?.path && url != nil {
                    audioPlayer.play()
                    return
                }
                
                do {
                    
                    audioPlayer = try AVAudioPlayer(contentsOf: recorder.url)
                    audioPlayer.delegate = self as AVAudioPlayerDelegate
                    url = audioRecorder.url
                    audioPlayer.play()
                    
                } catch {
                    print("play(), ",error.localizedDescription)
                }
            }
            
        } else {
            return
        }
    }
    
    func playURL(_ url: URL?) {
        guard let url else { return }
        _play(url: url)
    }
    
    func play(name: String) {
        
        let bundle = getDir().appendingPathComponent(name.appending(".m4a"))
        
        _play(url: bundle)
    }
    
    private func _play(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) && !isRecording && !isPlaying {
            
            do {
                
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer.delegate = self as AVAudioPlayerDelegate
                audioPlayer.play()
                
            } catch {
                print("play(with name:), ",error.localizedDescription)
            }
        } else {
            return
        }
    }
    
    func delete(name: String) {
        
        let bundle = getDir().appendingPathComponent(name.appending(".m4a"))
        let manager = FileManager.default
        
        if manager.fileExists(atPath: bundle.path) {
            
            do {
                try manager.removeItem(at: bundle)
            } catch {
                print("delete()",error.localizedDescription)
            }
            
        } else {
            print("File is not exist.")
        }
    }
    
    func stopPlaying() {
        
        audioPlayer.stop()
        isPlaying = false
    }
    
    private func getDir() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths.first!
    }
    
    @discardableResult
    func isAuth() -> Bool {
        
        var result: Bool = false
        
        AVAudioSession.sharedInstance().requestRecordPermission { (res) in
            result = res == true ? true : false
        }
        
        return result
    }
    
    public func write(data: Data) -> URL? {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        
        let targetURL = tempDirectoryURL.appendingPathComponent("navaiVoice.m4a")

            // write the file.
            do {
                try data.write(to: targetURL)
                return targetURL
            } catch let error {
                NSLog("Unable to write file: \(error)")
            }

        return nil
    }
    
    public func writeInBundle(data: Data) -> URL? {
        // Get the file path in the bundle
        let bundleURL = getDir()

        let tempDirectoryURL = NSURL.fileURL(withPath: bundleURL.absoluteString, isDirectory: true)
        
        let targetURL = tempDirectoryURL.appendingPathComponent("navaiVoice.m4a")

            // write the file.
            do {
                try data.write(to: targetURL)
                return targetURL
            } catch let error {
                NSLog("Unable to write file: \(error)")
            }

        return nil
    }
    
    func writeDataAndPlay(data: Data) {
        delete(name: "navaiVoice")
        let url = writeInBundle(data: data)
        playURL(url)
    }
    
    func getTime() -> String {
        
        var result: String = ""
        
        if time < 60 {
            
            result = "\(time)"
            
        } else if time >= 60 {
            
            result = "\(time / 60):\(time % 60)"
        }
        
        return result
    }
    
}

extension GSAudioRecorder: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recordedUrl = recorder.url
        isRecording = false
        url = nil
        timer.invalidate()
        print("record finish")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print(error.debugDescription)
    }
}

extension GSAudioRecorder: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("playing finish")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print(error.debugDescription)
    }
}
