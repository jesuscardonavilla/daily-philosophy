import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 247 / 255, green: 244 / 255, blue: 238 / 255)
                .ignoresSafeArea()
            WebView()
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
