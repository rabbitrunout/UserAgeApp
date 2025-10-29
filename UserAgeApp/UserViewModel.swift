import Foundation
import SwiftUI
import FirebaseDatabase
import Combine

// MARK: - User Model
struct UserInfo: Identifiable, Codable {
    var id: String
    var name: String
    var age: Int
    var imagePath: String?   // now stores local file path
}

// MARK: - ViewModel
@MainActor
class UserViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var ageText: String = ""
    @Published var users: [UserInfo] = []
    @Published var searchText: String = ""
    @Published var selectedImageData: Data? = nil
    @Published var selectedImage: UIImage? = nil
    
    // Editing
    @Published var selectedUser: UserInfo?
    @Published var isEditing: Bool = false
    
    // Progress bar
    @Published var isSaving: Bool = false
    @Published var progress: Double = 0.0
    
    private let dbRef = Database.database().reference()
    private let usersPath = "users"
    
    var filteredUsers: [UserInfo] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: Save New User with Local Image and Progress Bar
    func save() {
        guard let age = Int(ageText), !name.isEmpty else { return }

        let id = UUID().uuidString
        var localImagePath: String? = nil

        // Save image locally if selected
        if let imageData = selectedImageData {
            localImagePath = saveImageLocally(id: id, imageData: imageData)
        }

        // Create UserInfo for local UI update
        let newUser = UserInfo(id: id, name: name, age: age, imagePath: localImagePath)

        let data: [String: Any] = [
            "id": id,
            "name": name,
            "age": age,
            "imagePath": localImagePath ?? ""
        ]

        // Start progress
        isSaving = true
        progress = 0.0

        Task {
            // Simulate 5-second save delay for testing
            for i in 1...50 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s per step
                await MainActor.run {
                    progress = Double(i) / 50.0
                }
            }

            // Save to Firebase
            dbRef.child(usersPath).child(id).setValue(data) { error, _ in
                Task { @MainActor in
                    self.isSaving = false
                    self.progress = 0.0

                    if error == nil {
                        // Clear inputs
                        self.name = ""
                        self.ageText = ""
                        self.selectedImage = nil
                        self.selectedImageData = nil

                        // Append the new user and sort alphabetically
                        self.users.append(newUser)
                        self.users.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    }
                }
            }
        }
    }
    
    private func saveImageLocally(id: String, imageData: Data) -> String? {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let folderURL = documentsURL.appendingPathComponent("userImages")
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        let fileURL = folderURL.appendingPathComponent("\(id).jpg")
        do {
            try imageData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("❌ Failed to save image locally:", error)
            return nil
        }
    }
    
    func fetchAll() {
        dbRef.child(usersPath).observeSingleEvent(of: .value) { snapshot in
            var newUsers: [UserInfo] = []
            
            if let dict = snapshot.value as? [String: Any] {
                for user in dict.values {
                    if let data = user as? [String: Any],
                       let id = data["id"] as? String,
                       let name = data["name"] as? String,
                       let age = data["age"] as? Int {
                        let imagePath = data["imagePath"] as? String
                        newUsers.append(UserInfo(id: id, name: name, age: age, imagePath: imagePath))
                    }
                }
            }
            
            newUsers.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.users = newUsers
            }
        }
    }
    
    func deleteUser(at offsets: IndexSet) {
        for index in offsets {
            let user = users[index]
            
            // Remove local image
            if let imagePath = user.imagePath {
                try? FileManager.default.removeItem(atPath: imagePath)
            }
            
            // Remove database entry
            dbRef.child(usersPath).child(user.id).removeValue()
        }
        
        fetchAll()
    }
    
    func uiImage(for user: UserInfo) -> UIImage? {
        guard let path = user.imagePath, !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }
    
    func indexInUsers(forFilteredIndex filteredIndex: Int) -> Int? {
        guard filteredIndex >= 0 && filteredIndex < filteredUsers.count else { return nil }
        let id = filteredUsers[filteredIndex].id
        return users.firstIndex(where: { $0.id == id })
    }
}
