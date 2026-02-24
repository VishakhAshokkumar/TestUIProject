//
//  ContentView.swift
//  TestUIProject
//
//  Created by Vishakh on 12/7/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
                .font(Font.largeTitle)
                .padding()
                .background(Color.blue)
                .padding(.top)
                .background(Color.gray)
                .padding(.all)
                .background(Color.red)
            
        }
        
    }
}

#Preview {
    ContentView()
}
