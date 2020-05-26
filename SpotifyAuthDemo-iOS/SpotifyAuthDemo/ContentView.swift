//
//  ContentView.swift
//  SpotifyAuthDemo
//
//  Created by iosdv on 2020/5/14.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SAButton(text: "SwapToken") {
                    print("!!!!!")
                }
                
                SAButton(text: "RefreshToken") {
                    print("!!!!!")
                }
            }
            
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Spacer()
            
        }
    }
}

struct SAButton: View {
    var text: String
    var action: () -> Void
    
    init(text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            self.action()
        }) {
            HStack {
                Text(text)
                    .font(.title)
                    .fontWeight(.semibold)
            }
            .padding()
            .font(.largeTitle)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(20)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

