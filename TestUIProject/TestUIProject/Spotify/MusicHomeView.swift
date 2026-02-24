//
//  MusicHomeView.swift
//  TestUIProject
//
//  Created by Vishakh on 1/11/26.
//

import SwiftUI

struct MusicHomeView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView {
                Tab("Home", image: "house.fill") {
                    HomeView()
                }
                Tab("Search", image: "magnifyingglass") {
                    SearchView()
                }
                Tab("Library", image: "building.columns.fill") {
                    LibraryView()
                }
                Tab("Premium", image: "dollarsign.bank.building.fill") {
                    PremiumView()
                }
                Tab("Create", image: "plus") {
                    CreateView()
                }
            }
            .toolbarBackground(.hidden, for: .tabBar)
        }
    }
}


struct HomeView: View {
    var body: some View {
        Text("HomeView")
    }
}

struct SearchView: View {
    var body: some View {
        Text("SearchView")
    }
}

struct LibraryView: View {
    var body: some View {
        Text("LibraryView")
    }
}


struct PremiumView: View {
    var body: some View {
        Text("PremiumView")
    }
}


struct CreateView: View {
    var body: some View {
        Text("CreateView")
    }
}


#Preview {
    MusicHomeView()
}
