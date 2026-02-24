//
//  LearningOne.swift
//  TestUIProject
//
//  Created by Vishakh on 12/7/25.
//

import SwiftUI
internal import Combine

struct LearningOne: View {
    
    @State var countInc = 1
    
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
       
            Image(systemName: "heart.fill")
                .resizable()
                // .symbolEffect(.wiggle)
                .scaledToFit()
                .foregroundStyle(Color.red)
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .frame(width: 5, height: 5)
                        .foregroundStyle(.white)
                        .overlay(alignment: .center) {
                            Text("\(countInc)")
                                .onReceive(timer) { _ in
                                    
                                }
                        }
                }
                
            
        
        
    }
        
}

#Preview {
    LearningOne()
}
