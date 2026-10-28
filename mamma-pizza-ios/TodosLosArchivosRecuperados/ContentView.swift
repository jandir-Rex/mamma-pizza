import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/jandir/Documents/mamma-pizza/mamma-pizza-app-cliente-ios/MammaPizzaClient/MammaPizzaClient/ContentView.swift", line: 1)
//
//  ContentView.swift
//  MammaPizzaClient
//
//  Created by Jandirx on 30/09/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: __designTimeString("#1205_0", fallback: "globe"))
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(__designTimeString("#1205_1", fallback: "Hello, world!"))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
