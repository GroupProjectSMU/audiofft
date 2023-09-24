//
//  AudioManager.swift
//  audiofft
//
//  Created by Yihao Wang on 9/18/23.
//

import SwiftUI
import AVFoundation
import Accelerate
import Charts

class dspSplitComplexHolder{

    let realPtr: UnsafeMutablePointer<Float>
    let imagPtr: UnsafeMutablePointer<Float>
    var complexValue: DSPSplitComplex
    
    init(length: Int) {
        realPtr = UnsafeMutablePointer<Float>.allocate(capacity: length)
        imagPtr = UnsafeMutablePointer<Float>.allocate(capacity: length)
        realPtr.initialize(repeating: 0.0, count: length)
        imagPtr.initialize(repeating: 0.0, count: length)
        complexValue = DSPSplitComplex(realp: realPtr, imagp: imagPtr)
    }
    
    deinit {
        realPtr.deallocate()
        imagPtr.deallocate()
    }
}

class AudioEngineManager: ObservableObject {
    var audioEngine = AVAudioEngine()
    
    var fftInstance = vDSP.FFT(log2n: 12, radix: .radix2, ofType: DSPSplitComplex.self)
    var output: [Float] = Array(repeating: 0.0, count: 2048)  // half fftLength
    
    var inputComplex: dspSplitComplexHolder!
    var outputComplex: dspSplitComplexHolder!
    var landMarkModel: Bool = false
    @Published var outputLog: [Float] = Array(repeating: 0.0, count: 2048)  // half fftLength
    @Published var lineMarks: [LineMark] = []
    @Published var initDone: Bool = false
    init() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Permission OK")
            setupEngine(length: 4096)
            startEngine()
            initDone = true
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    init(landMarkModel: Bool) {
        self.landMarkModel = landMarkModel
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Permission OK")
            setupEngine(length: 4096)
            startEngine()
            initDone = true
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    func setupEngine(length: Int) {
        inputComplex =  dspSplitComplexHolder(length: length)
        outputComplex = dspSplitComplexHolder(length: length)
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        print("Sampling Frequency: \(inputFormat.sampleRate)")
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(length), format: inputFormat) { [unowned self] buffer, _ in
            guard let floatData = buffer.floatChannelData?[0] else {return }
            vDSP_mmov(floatData, inputComplex.realPtr, vDSP_Length(buffer.frameLength), 1, 1, vDSP_Length(buffer.frameLength))
        }

    }
    
    func updateFFT(){
        DispatchQueue.global(qos: .default).async { [unowned self] in
            fftInstance?.transform(input: inputComplex.complexValue, output: &outputComplex.complexValue, direction: .forward)
            vDSP.squareMagnitudes(outputComplex.complexValue, result: &self.output)
            DispatchQueue.main.async { [unowned self] in
                vDSP.convert(amplitude: self.output, toDecibels: &self.outputLog, zeroReference: 1.0)
                if landMarkModel{
                    lineMarks = outputLog.prefix(outputLog.count / 2).enumerated().map { (index, value) in
                        LineMark(x: .value("Index", index), y: .value("Value", value))
                    }
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
