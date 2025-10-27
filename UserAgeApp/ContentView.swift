

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter your info")) {
                    TextField("Name", text: $viewModel.name)
                    TextField("Age", text: $viewModel.ageText)
                        .keyboardType(.numberPad)
                }

                Button("Save") {
                    viewModel.save()
                }

                if let stored = viewModel.storedData {
                    Section(header: Text("Stored data")) {
                        Text("Name: \(stored.name)")
                        Text("Age: \(stored.age)")
                    }
                }
            }
            .navigationTitle("User Info")
            .onAppear {
                viewModel.fetch()
            }
        }
    }
}

#Preview {
    ContentView()
}
