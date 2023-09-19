//
//  ContentView.swift
//  audiofft
//
//  Created by Yihao Wang on 9/18/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            FFTView()
                .frame(height: 350)
            Text("OK")
            Spacer()
        }
        .padding()
    }
}

struct FFTView: View {
    @ObservedObject var audioManager = AudioEngineManager()
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width / CGFloat(audioManager.output.count / 2 - 512) // Dividing by 2 to only use half
                    
                    // Initialize the starting point for the path
                    if let firstValue = audioManager.outputLog.first {
                        let height = CGFloat(firstValue) * geometry.size.height / 250.0
                        path.move(to: CGPoint(x: 0, y: geometry.size.height - height - 150))
                    }
                    
                    // Looping only over the first half
                    for (index, value) in audioManager.outputLog.prefix(audioManager.output.count / 2 - 512).enumerated() {
                        let height = CGFloat(value) * geometry.size.height / 250.0  // Adjust as per your needs
                        path.addLine(to: CGPoint(x: CGFloat(index) * width, y: geometry.size.height - height - 150))
                    }
                }
                .stroke(Color.blue)
            }
            .clipped()
            .drawingGroup()
        }

    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
