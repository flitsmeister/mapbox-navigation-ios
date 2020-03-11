
import AVFoundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxSpeech

open class SystemSpeechSynthesizer: NSObject, SpeechSynthesizerController {
    
    // MARK: - Properties
    
    public var delegate: SpeechSynthesizerDelegate?
    public var muted: Bool = false {
        didSet {
            if isSpeaking {
                interruptSpeaking()
            }
        }
    }
    public var volume: Float {
        get {
            return NavigationSettings.shared.voiceVolume
        }
        set {
            // Do Nothing
            // AVSpeechSynthesizer uses 'AVAudioSession.sharedInstance().outputVolume' by default
        }
    }
    public var isSpeaking: Bool { return speechSynth.isSpeaking }
    public var locale: Locale = Locale.autoupdatingCurrent
    
    private lazy var speechSynth: AVSpeechSynthesizer = {
        let synth = AVSpeechSynthesizer()
        synth.delegate = self
        return synth
    } ()
    
    private var completion: SpeechSynthesizerCompletion?
    private var previousInstrcution: SpokenInstruction?
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(processAudioSessionInterrupt(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        interruptSpeaking()
    }
    
    // MARK: - Public methods
    
    public func changedIncomingSpokenInstructions(_ instructions: [SpokenInstruction]) {
        // Do nothing
    }
    
    public func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, completion: SpeechSynthesizerCompletion?) {
        print("iOS SPEAKS!")
        guard !muted else {
            completion?(nil)
            return
        }
        
        var utterance: AVSpeechUtterance?
        if Locale.preferredLocalLanguageCountryCode == "en-US" {
            // Alex can’t handle attributed text.
            utterance = AVSpeechUtterance(string: instruction.text)
            utterance!.voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
        }
        
        let modifiedInstruction = delegate?.voiceController(self, willSpeak: instruction) ?? instruction
        
        if utterance?.voice == nil {
            utterance = AVSpeechUtterance(attributedString: modifiedInstruction.attributedText(for: legProgress))
        }
        
        // Only localized languages will have a proper fallback voice
        if utterance?.voice == nil {
            utterance?.voice = AVSpeechSynthesisVoice(language: Locale.preferredLocalLanguageCountryCode)
        }
        
        guard let utteranceToSpeak = utterance else {
            completion?(SpeechError.unsupportedLocale(languageCode: Locale.preferredLocalLanguageCountryCode))
            return
        }
        if let previousInstrcution = previousInstrcution, speechSynth.isSpeaking {
            delegate?.voiceController(self,
                                      didInterrupt: previousInstrcution,
                                      with: modifiedInstruction)
        }
        
        self.completion = completion
        previousInstrcution = modifiedInstruction
        speechSynth.speak(utteranceToSpeak)
    }
    
    public func stopSpeaking() {
        speechSynth.stopSpeaking(at: .word)
    }
    
    public func interruptSpeaking() {
        speechSynth.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Methods
    
    @discardableResult
    private func safeDuckAudio() -> SpeechError? {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if #available(iOS 12.0, *) {
                try audioSession.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            } else {
                try audioSession.setCategory(.ambient, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            }
            try audioSession.setActive(true)
        } catch {
            return SpeechError.unableToControlAudio(instruction: previousInstrcution,
                                                    action: .duck,
                                                    underlying: error)
        }
        return nil
    }
    
    @discardableResult
    private func safeUnduckAudio() -> SpeechError? {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: [.notifyOthersOnDeactivation])
        } catch {
            return SpeechError.unableToControlAudio(instruction: previousInstrcution,
                                                    action: .duck,
                                                    underlying: error)
        }
        return nil
    }
}

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        if let error = safeDuckAudio() {
            delegate?.voiceController(self, spokenInstructionsDidFailWith: error)
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        if let error = safeDuckAudio() {
            delegate?.voiceController(self, spokenInstructionsDidFailWith: error)
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let error = safeUnduckAudio() {
            delegate?.voiceController(self, spokenInstructionsDidFailWith: error)
            completion?(error)
        }
        else {
            completion?(nil)
        }
        completion = nil
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        if let error = safeUnduckAudio() {
            delegate?.voiceController(self, spokenInstructionsDidFailWith: error)
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if let error = safeUnduckAudio() {
            delegate?.voiceController(self, spokenInstructionsDidFailWith: error)
            completion?(error)
        }
        else {
            completion?(nil)
        }
        completion = nil
    }
    
    @objc func processAudioSessionInterrupt(_ notification: NSNotification) {
        safeUnduckAudio() // run a completion?
    }
}