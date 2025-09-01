import Foundation
import RealmSwift
import UIKit

class RecipeStore {
    
    static let shared = RecipeStore()
    
    private let realm: Realm
    private let queue: DispatchQueue
    
    private init() {
        realm = try! Realm()
        queue = DispatchQueue(label: "com.recipeapp.recipestore", attributes: .concurrent)
        
        loadInitialData()
    }
    
    private func loadInitialData() {
        if realm.objects(RecipeType.self).isEmpty {
            loadRecipeTypesFromJSON()
        }
        
        if realm.objects(Recipe.self).isEmpty {
            seedSampleData()
        }
    }
    
    private func loadRecipeTypesFromJSON() {
        guard let url = Bundle.main.url(forResource: "recipetypes", withExtension: "json") else {
            assertionFailure("recipetypes.json missing from bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let recipeTypes = try JSONDecoder().decode([RecipeType].self, from: data)
            
            try realm.write {
                realm.add(recipeTypes, update: .modified)
            }
        } catch {
            print("Failed to load category types: \(error.localizedDescription)")
        }
    }
    
    private func seedSampleData() {
        let sampleRecipes = [
            Recipe(value: [
                "title": "Pancakes",
                "typeId": 1,
                "imageFilename": "Pancakes",
                "ingredients": ["1 cup flour", "1 egg", "1 cup milk", "1 tbsp sugar", "1 tsp baking powder", "Pinch of salt"],
                "steps": ["Mix dry ingredients", "Whisk in egg and milk", "Cook on greased pan until bubbles form", "Flip and finish"]
            ]),
            Recipe(value: [
                "title": "Iced Lemon Tea",
                "typeId": 5,
                "imageFilename": "Iced lemon tea",
                "ingredients": ["Black tea bag", "Lemon juice", "Ice", "Sugar"],
                "steps": ["Brew tea", "Add sugar while hot", "Cool, add lemon and ice"]
            ]),
            Recipe(value: [
                "title": "Spaghetti Aglio e Olio",
                "typeId": 3,
                "imageFilename": "Spaghetti",
                "ingredients": ["Spaghetti", "Olive oil", "Garlic", "Chilli flakes", "Parsley", "Salt"],
                "steps": ["Boil pasta", "Sauté garlic & chilli", "Toss pasta with oil", "Season and serve"]
            ])
        ]
        
        try? realm.write {
            realm.add(sampleRecipes)
        }
    }
    
//CRUD Operations
    func add(_ recipe: Recipe) {
        try? realm.write {
            realm.add(recipe)
        }
    }
    
    func getRecipeType(by id: Int) -> RecipeType? {
        return realm.objects(RecipeType.self).filter("id == %@", id).first
    }
    
    func update(_ recipe: Recipe) {
        try? realm.write {
            realm.add(recipe, update: .modified)
        }
    }
    
    func delete(id: String) {
        if let recipe = realm.object(ofType: Recipe.self, forPrimaryKey: id) {
            try? realm.write {
                realm.delete(recipe)
            }
        }
    }
    
    // Image Management
    private let imageStorage: ImageStorage = FileSystemImageStorage()
    
    func saveImage(_ image: UIImage) throws -> String {
        return try imageStorage.saveImage(image)
    }
    
    func loadImage(named filename: String?) -> UIImage? {
        return imageStorage.loadImage(named: filename)
    }
    
    func typeName(for id: Int) -> String {
        return realm.object(ofType: RecipeType.self, forPrimaryKey: id)?.name ?? "Unknown Type"
    }
    
    func getRecipesByType(_ typeId: Int?) -> Results<Recipe> {
        if let typeId = typeId {
            return realm.objects(Recipe.self).filter("typeId == %@", typeId)
        } else {
            return realm.objects(Recipe.self)
        }
    }
    
    func recipe(with id: String) -> Recipe? {
        return realm.object(ofType: Recipe.self, forPrimaryKey: id)
    }
    
    var recipes: Results<Recipe> {
        return realm.objects(Recipe.self)
    }
    
    var recipeTypes: Results<RecipeType> {
        return realm.objects(RecipeType.self)
    }
}
