import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVAudioRecorderDelegate {
  private let channelName = "com.example.echoes_flutter/audio_recorder"
  private var audioRecorder: AVAudioRecorder?
  private var currentRecordingPath: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "EchoesAudioRecorder")
    let messenger = registrar?.messenger() ?? (window?.rootViewController as? FlutterViewController)?.binaryMessenger

    if let messenger = messenger {
      setupMethodChannel(messenger: messenger)
    }
  }

  private func setupMethodChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate deallocated", details: nil))
        return
      }
      switch call.method {
      case "hasPermission":
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
          result(true)
        case .denied:
          result(false)
        case .undetermined:
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
              result(granted)
            }
          }
        @unknown default:
          result(false)
        }
      case "startRecording":
        let args = call.arguments as? [String: Any]
        let path = args?["path"] as? String
        do {
          let recordedPath = try self.startRecording(customPath: path)
          result(recordedPath)
        } catch {
          result(FlutterError(code: "RECORDING_ERROR", message: error.localizedDescription, details: nil))
        }
      case "stopRecording":
        let path = self.stopRecording()
        result(path)
      case "getAmplitude":
        if let recorder = self.audioRecorder, recorder.isRecording {
          recorder.updateMeters()
          let peak = recorder.peakPower(forChannel: 0)
          result(Double(peak))
        } else {
          result(Double(-160.0))
        }
      case "isRecording":
        result(self.audioRecorder?.isRecording ?? false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startRecording(customPath: String?) throws -> String {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
    try session.setActive(true)

    let url: URL
    if let customPath = customPath, !customPath.isEmpty {
      url = URL(fileURLWithPath: customPath)
    } else {
      let tempDir = FileManager.default.temporaryDirectory
      let filename = "recording_\(Int(Date().timeIntervalSince1970 * 1000)).m4a"
      url = tempDir.appendingPathComponent(filename)
    }
    currentRecordingPath = url.path

    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      AVEncoderBitRateKey: 128000
    ]

    let recorder = try AVAudioRecorder(url: url, settings: settings)
    recorder.delegate = self
    recorder.isMeteringEnabled = true
    recorder.prepareToRecord()
    recorder.record()
    self.audioRecorder = recorder

    return url.path
  }

  private func stopRecording() -> String? {
    if let recorder = audioRecorder {
      if recorder.isRecording {
        recorder.stop()
      }
      audioRecorder = nil
    }
    return currentRecordingPath
  }
}
