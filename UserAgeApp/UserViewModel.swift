import Foundation
import FirebaseDatabase
import SwiftUI
import Combine

struct UserInfo: Identifiable, Codable {
    var id: String
    var name: String
    var age: Int
    var imagePath: String?   // now stores local file path
}


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

    private let dbRef = Database.database().reference()
    private let usersPath = "users"

    var filteredUsers: [UserInfo] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: Load Local Image by User ID
    func loadImage(for id: String) -> UIImage? {
        guard let user = users.first(where: { $0.id == id }),
              let imagePath = user.imagePath else {
            return nil
        }

        let fileURL = URL(fileURLWithPath: imagePath)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }


    // MARK: Save New User with Local Image
    func save() {
        guard let age = Int(ageText), !name.isEmpty else { return }

        let id = UUID().uuidString
        var localImagePath: String? = nil

        if let imageData = selectedImageData {
            localImagePath = saveImageLocally(id: id, imageData: imageData)
        }

        let userInfo = UserInfo(id: id, name: name, age: age, imagePath: localImagePath)

        let data: [String: Any] = [
            "id": id,
            "name": name,
            "age": age,
            "imagePath": localImagePath ?? ""
        ]

        dbRef.child(usersPath).child(id).setValue(data) { error, _ in
            if error == nil {
                Task { @MainActor in
                    self.name = ""
                    self.ageText = ""
                    self.selectedImage = nil
                    self.selectedImageData = nil
                    self.fetchAll()
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
    
    // Add inside UserViewModel

    /// Return a UIImage loaded from the local imagePath for a user (or nil).
    func uiImage(for user: UserInfo) -> UIImage? {
        guard let path = user.imagePath, !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }

    /// Given an index in filteredUsers, return the matching index in users array.
    func indexInUsers(forFilteredIndex filteredIndex: Int) -> Int? {
        guard filteredIndex >= 0 && filteredIndex < filteredUsers.count else { return nil }
        let id = filteredUsers[filteredIndex].id
        return users.firstIndex(where: { $0.id == id })
    }

}
