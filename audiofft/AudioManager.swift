//
//  AudioManager.swift
//  audiofft
//
//  Created by Yihao Wang on 9/18/23.
//

import SwiftUI
import AVFoundation
import Accelerate

class dspSplitComplexHolder{
    var realp: [Float]
    var imagp: [Float]
    let realPtr: UnsafeMutablePointer<Float>
    let imagPtr: UnsafeMutablePointer<Float>
    var complexValue: DSPSplitComplex
    
    init(length: Int) {
        realp = Array(repeating: 0.0, count: length)
        imagp = Array(repeating: 0.0, count: length)
        realPtr = UnsafeMutablePointer<Float>.allocate(capacity: length)
        imagPtr = UnsafeMutablePointer<Float>.allocate(capacity: length)
        realPtr.initialize(from: realp, count: length)
        imagPtr.initialize(from: imagp, count: length)
        complexValue = DSPSplitComplex(realp: realPtr, imagp: imagPtr)
    }
    
    deinit {
        realPtr.deallocate()
        imagPtr.deallocate()
    }
}

class AudioEngineManager: ObservableObject {
    var audioEngine = AVAudioEngine()
    var fftSetup: FFTSetup!
    let fftLength = vDSP_Length(4096)
    
    var fftInstance = vDSP.FFT(log2n: 12, radix: .radix2, ofType: DSPSplitComplex.self)
    var output: [Float] = Array(repeating: 0.0, count: 2048)  // half fftLength
    
    var inputComplex: dspSplitComplexHolder = dspSplitComplexHolder(length: 4096)
    var outputComplex: dspSplitComplexHolder = dspSplitComplexHolder(length: 4096)
    
    @Published var outputLog: [Float] = Array(repeating: 0.0, count: 2048)  // half fftLength
    init() {
        setupEngine()
        startEngine()
    }
    
    func setupEngine() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
//        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(fftLength), format: inputFormat) { [unowned self] buffer, _ in
            guard let floatData = buffer.floatChannelData?[0] else {return }
//            let length = vDSP_Length(buffer.frameLength)
            
            vDSP_mmov(floatData, inputComplex.realPtr, vDSP_Length(buffer.frameLength), 1, 1, vDSP_Length(buffer.frameLength))
            DispatchQueue.global(qos: .default).async { [unowned self] in
                fftInstance?.transform(input: inputComplex.complexValue, output: &outputComplex.complexValue, direction: .forward)
                vDSP.squareMagnitudes(outputComplex.complexValue, result: &self.output)
                DispatchQueue.main.async { [unowned self] in
                    vDSP.convert(amplitude: self.output, toDecibels: &self.outputLog, zeroReference: 1.0)
                }
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
