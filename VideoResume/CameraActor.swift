//
//  CameraActor.swift
//  VideoResume
//
//  Created by Nathan Merz on 7/1/24.
//

import Foundation
import AVFoundation



actor CameraActor {
    var movieOutput = AVCaptureMovieFileOutput()
    var setup: Bool = false
    var movieUrl: Optional<URL> = nil
    var captureSession = AVCaptureSession()
    private var delegate: MovieCaptureDelegate?

    static var shared = CameraActor()
    
    init() {
        previewSource = DefaultPreviewSource(session: captureSession)
    }
    static var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    nonisolated let previewSource: PreviewSource

    private class MovieCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
        
        var continuation: CheckedContinuation<URL, Error>?
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error {
                // If an error occurs, throw it to the caller.
                continuation?.resume(throwing: error)
            } else {
                // Return a new movie object.
                continuation?.resume(returning: outputFileURL)
            }
        }
    }

    func setUpCaptureSession() async throws {
        guard await CameraActor.isAuthorized else { throw CameraError("not authorized to use camera+mic") }
        if setup {
            return
        }
//        let audioEngine = AVAudioEngine()
//        audioEngine.attach(AVAudioPlayerNode())
//        try audioEngine.inputNode.setVoiceProcessingEnabled(true)
//        captureSession.beginConfiguration()
        
        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) == nil {
            throw CameraError("no camera")
        }
        let defaultCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: defaultCamera),
            captureSession.canAddInput(videoDeviceInput)
            else { throw CameraError("bad input setting") }
        captureSession.addInput(videoDeviceInput)
        
        if AVCaptureDevice.default(for: .audio) == nil {
            throw CameraError("no camera")
        }
        let defaultMic = AVCaptureDevice.default(for: .audio)!
        guard
            let audioDeviceInput = try? AVCaptureDeviceInput(device: defaultMic),
            captureSession.canAddInput(audioDeviceInput)
            else { throw CameraError("bad input setting") }
        captureSession.addInput(audioDeviceInput)
        

        captureSession.addOutput(movieOutput)
        captureSession.commitConfiguration()
        captureSession.startRunning()
        setup = true
    }

    
    private var recordingUrl: Optional<URL> = nil
    
    func stopRecording() async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            delegate?.continuation = continuation
            
            movieOutput.stopRecording()
        }
    }
    
    func startRecording() -> URL? {
        guard let connection = movieOutput.connection(with: .video) else {
            fatalError("Configuration error. No video connection found.")
        }
        recordingUrl = URL.temporaryDirectory.appending(component: UUID().uuidString).appendingPathExtension(for: .quickTimeMovie)
        print(recordingUrl!)
        delegate = MovieCaptureDelegate()
        movieOutput.startRecording(to: recordingUrl!, recordingDelegate: delegate!)
        if movieOutput.availableVideoCodecTypes.contains(.hevc) {
            movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
        }
        return recordingUrl
    }
}

class CameraError: Error {
    init (_ errorString: String) {
        print(errorString)
    }
}
