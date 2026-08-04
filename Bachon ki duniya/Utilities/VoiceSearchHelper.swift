import AVFoundation
import Foundation
import Speech
import UIKit

/// Push-to-talk speech recognition for Search / Library mic buttons.
final class VoiceSearchHelper: NSObject {

    enum VoiceSearchError: LocalizedError {
        case speechUnavailable
        case speechDenied
        case microphoneDenied
        case recognitionFailed(String)

        var errorDescription: String? {
            switch self {
            case .speechUnavailable:
                return "Speech recognition is not available on this device."
            case .speechDenied:
                return "Please allow Speech Recognition in Settings to use voice search."
            case .microphoneDenied:
                return "Please allow Microphone access in Settings to use voice search."
            case .recognitionFailed(let message):
                return message
            }
        }
    }

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onListeningChanged: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private(set) var isListening = false

    func toggle(from presenter: UIViewController) {
        if isListening {
            stop()
            return
        }
        start(from: presenter)
    }

    func start(from presenter: UIViewController) {
        requestPermissions(from: presenter) { [weak self] granted, error in
            guard let self else { return }
            if let error {
                self.onError?(error)
                return
            }
            guard granted else { return }
            do {
                try self.beginListening()
            } catch {
                self.onError?(error)
            }
        }
    }

    func stop() {
        guard isListening || audioEngine.isRunning else {
            cleanup()
            return
        }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        cleanup(notifyListening: true)
    }

    // MARK: - Private

    private func requestPermissions(from presenter: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    AVAudioApplication.requestRecordPermission { micGranted in
                        DispatchQueue.main.async {
                            if micGranted {
                                completion(true, nil)
                            } else {
                                completion(false, VoiceSearchError.microphoneDenied)
                                Self.presentSettingsHint(on: presenter, message: VoiceSearchError.microphoneDenied.localizedDescription)
                            }
                        }
                    }
                case .denied, .restricted:
                    completion(false, VoiceSearchError.speechDenied)
                    Self.presentSettingsHint(on: presenter, message: VoiceSearchError.speechDenied.localizedDescription)
                case .notDetermined:
                    completion(false, VoiceSearchError.speechDenied)
                @unknown default:
                    completion(false, VoiceSearchError.speechUnavailable)
                }
            }
        }
    }

    private func beginListening() throws {
        stop()

        let locale = Self.speechLocale()
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw VoiceSearchError.speechUnavailable
        }
        self.recognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = false
        }
        self.request = request

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        onListeningChanged?(true)

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.onPartialResult?(text)
                    if result.isFinal {
                        self.onFinalResult?(text)
                        self.stop()
                    }
                }
            }
            if let error {
                DispatchQueue.main.async {
                    // Ignore cancellation when user stops intentionally.
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain", nsError.code == 216 {
                        return
                    }
                    if self.isListening {
                        self.onError?(VoiceSearchError.recognitionFailed(error.localizedDescription))
                    }
                    self.stop()
                }
            }
        }
    }

    private func cleanup(notifyListening: Bool = false) {
        task?.cancel()
        task = nil
        request = nil
        recognizer = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        let wasListening = isListening
        isListening = false
        if notifyListening || wasListening {
            onListeningChanged?(false)
        }
    }

    private static func speechLocale() -> Locale {
        let code = LanguageManager.shared.currentLanguageCode.lowercased()
        if code.hasPrefix("ur") { return Locale(identifier: "ur-PK") }
        if code.hasPrefix("ar") { return Locale(identifier: "ar-SA") }
        return Locale(identifier: "en-US")
    }

    private static func presentSettingsHint(on presenter: UIViewController, message: String) {
        let alert = UIAlertController(title: AppL10n.t(.errorTitle), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppL10n.t(.cancel), style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        presenter.present(alert, animated: true)
    }
}
