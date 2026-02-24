//
//  LearningTwo.swift
//  TestUIProject
//
//  Created by Vishakh on 12/9/25.
//

import SwiftUI

struct LearningTwo: View {
    var body: some View {
            NavigationStack {
                Text("Instagram content")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Image(systemName: "plus")
                        }
                        
                        
                        ToolbarItem(placement: .principal) {
                            Text("Instagram")
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            LearningOne()
                                .frame(width: 22, height: 22)
                        }
                    }
                
                
            }
    }
}

#Preview {
    LearningTwo()
}
