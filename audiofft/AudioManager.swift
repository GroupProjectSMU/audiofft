//
//  AudioManager.swift
//  audiofft
//
//  Created by Yihao Wang on 9/18/23.
//

import SwiftUI
import AVFoundation
import Accelerate

class AudioEngineManager: ObservableObject {
    var audioEngine = AVAudioEngine()
    var fftSetup: FFTSetup!
    let fftLength = vDSP_Length(4096)
    let log2n: vDSP_Length = 12
    var output: [Float] = Array(repeating: 0.0, count: 2048)  // half fftLength
    @Published var outputLog: [Float] = Array(repeating: 0.0, count: 2048)  // half fftLength
    init() {
        setupEngine()
        startEngine()
    }
    
    func setupEngine() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        var realp: [Float] = Array(repeating: 0.0, count: 2048)
        var imagp: [Float] = Array(repeating: 0.0, count: 2048)
        let realPtr = UnsafeMutablePointer<Float>.allocate(capacity: 2048)
        let imagPtr = UnsafeMutablePointer<Float>.allocate(capacity: 2048)
        realPtr.initialize(from: &realp, count: 2048)
        imagPtr.initialize(from: &imagp, count: 2048)
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(fftLength), format: inputFormat) { [unowned self] buffer, _ in
            
            var tempOutput = DSPSplitComplex(realp: realPtr, imagp: imagPtr)
            
            guard let floatData = buffer.floatChannelData?[0] else {return }
            let length = vDSP_Length(buffer.frameLength)
            
            floatData.withMemoryRebound(to: DSPComplex.self, capacity: Int(length)) { dspComplexBuffer in
                vDSP_ctoz(dspComplexBuffer, 2, &tempOutput, 1, vDSP_Length(2048))
            }
            
            vDSP_fft_zrip(self.fftSetup, &tempOutput, 1, self.log2n, FFTDirection(FFT_FORWARD))
            
            vDSP_zvmags(&tempOutput, 1, &self.output, 1, vDSP_Length(2048))
            
            DispatchQueue.main.async {
                self.outputLog = self.output.map { 10 * log10($0) }
            }
        }

    }
    
    func startEngine() {
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
}
