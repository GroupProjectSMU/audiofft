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
                .frame(height: 300)
        Text("OK")
            Spacer()
        }
        .padding()
    }
}

struct FFTView: View {
    @ObservedObject var audioManager = AudioEngineManager()
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width / CGFloat(audioManager.output.count)
                
                for (index, value) in audioManager.outputLog.enumerated() {
                    let height = CGFloat(value) * geometry.size.height / 100.0  // Adjust as per your needs
                    path.move(to: CGPoint(x: CGFloat(index) * width, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: CGFloat(index) * width, y: geometry.size.height - height))
                }
            }
            .stroke(Color.blue)
        }.drawingGroup()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
