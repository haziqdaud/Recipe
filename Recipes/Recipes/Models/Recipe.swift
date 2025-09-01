import Foundation
import RealmSwift

class Recipe: Object, Codable, Identifiable {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var title: String = ""
    @objc dynamic var typeId: Int = 0
    @objc dynamic var imageFilename: String?
    @objc dynamic var imageAssetName: String?
    @objc dynamic var createdAt: Date = Date()
    
    let ingredients = List<String>()
    let steps = List<String>()
    
    // Primary key for Realm
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // Codable support
    enum CodingKeys: String, CodingKey {
        case id, title, typeId, imageFilename, imageAssetName, ingredients, steps, createdAt
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        typeId = try container.decode(Int.self, forKey: .typeId)
        imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
        imageAssetName = try container.decodeIfPresent(String.self, forKey: .imageAssetName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        let ingredientsArray = try container.decode([String].self, forKey: .ingredients)
        ingredients.append(objectsIn: ingredientsArray)
        
        let stepsArray = try container.decode([String].self, forKey: .steps)
        steps.append(objectsIn: stepsArray)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(typeId, forKey: .typeId)
        try container.encodeIfPresent(imageFilename, forKey: .imageFilename)
        try container.encodeIfPresent(imageAssetName, forKey: .imageAssetName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(Array(ingredients), forKey: .ingredients)
        try container.encode(Array(steps), forKey: .steps)
    }
    
    // Custom Equatable implementation (compare by primary key)
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Helper to get the appropriate image identifier
    func imageIdentifier() -> String? {
        return imageFilename ?? imageAssetName
    }
}
