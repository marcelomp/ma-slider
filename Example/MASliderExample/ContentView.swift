// Copyright (c) 2017 mpmarcelomp@gmail.com
// See LICENSE for license information.

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            UIKitSampleView()
                .tabItem { Label("UIKit", systemImage: "hammer") }
            SwiftUISampleView()
                .tabItem { Label("SwiftUI", systemImage: "swift") }
        }
    }
}

#Preview {
    ContentView()
}
