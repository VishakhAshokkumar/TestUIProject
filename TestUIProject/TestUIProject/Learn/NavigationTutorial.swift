//
//  NavigationTutorial.swift
//  TestUIProject
//
//  Created by Vishakh on 2/16/26.
//

import SwiftUI

enum Route: Hashable {

    case productList
    case productDetail(id: Int)
    case checkout(id: Int)
    case orderSuccess
}


@Observable
class NavigationManager {

    var navigationPath = NavigationPath()

    func navigate(to route: Route) {
        navigationPath.append(route)
    }

    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }

    func popTo(_ count: Int) {
        if navigationPath.count >= count {
            navigationPath.removeLast(count)
        }
    }
}


struct ShoppingRootView: View {
    
    @State var nav = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $nav.navigationPath) {
            ProductView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .productList:
                        ProductView()
                        
                    case .productDetail(let id):
                        ProductDetailView(id: id)
                        
                    case .checkout(let id):
                        CheckoutView(productID: id)
                        
                    case .orderSuccess:
                        OrderSuccessView()
                    }
                }
        }
        .environment(nav)
    }
}

struct ProductView: View {
    @Environment(NavigationManager.self) var nav
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🛒 Products")
                .font(.largeTitle)
            
            Button("Buy iPhone (ID:101)") {
                nav.navigate(to: .productDetail(id: 101))
            }
            
            Button("Buy MacBook (ID:202)") {
                nav.navigate(to: .productDetail(id: 202))
            }
        }
    }
}

struct ProductDetailView: View {
    @Environment(NavigationManager.self) var nav
    var id: Int
    var body: some View {
        VStack {
            Text("Product Detail \(id)")
            .font(.largeTitle)
            
            Button("Checkout") {
                nav.navigate(to: .checkout(id: id))
            }
        }
            
        
    }
}

struct CheckoutView: View {
    var productID: Int
    @Environment(NavigationManager.self) var nav
    var body: some View {
        VStack {
            Text("Checkout")
                .font(.largeTitle)
            Button("Go to order Summary") {
                nav.navigate(to: .orderSuccess)
            }
        }
        
    }
}

struct OrderSuccessView: View {
    @Environment(NavigationManager.self) private var nav
    var body: some View {
        VStack {
            Text("Order Success")
                .font(.largeTitle)
            
            Button("Take me home") {
                nav.popToRoot()
            }
        }
        
    }
}


struct NavigationLinkTest: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Some link") {
                Text("Scren 1")
            }
        }
    }
}

#Preview {
    NavigationLinkTest()
}
