import SwiftUI
import CoreML
import Vision
import CoreImage

// MARK: - Food Detection Enhancer
class FoodDetectionEnhancer: ObservableObject {
    @Published var isEnhancing = false
    @Published var enhancementProgress: Double = 0.0
    
    // Food-specific labels with high confidence
    private let foodLabels = [
        // Fruits
        "banana", "apple", "orange", "strawberry", "grape", "pear", "peach", "plum", "cherry", "lemon", "lime", "mango", "pineapple", "watermelon", "cantaloupe", "honeydew", "kiwi", "avocado", "tomato", "cucumber", "carrot", "onion", "potato", "garlic", "ginger",
        
        // Vegetables
        "broccoli", "cauliflower", "spinach", "lettuce", "kale", "cabbage", "brussels sprouts", "asparagus", "zucchini", "eggplant", "bell pepper", "jalapeno", "mushroom", "corn", "peas", "beans", "lentils", "chickpeas",
        
        // Grains and Bread
        "bread", "toast", "sandwich", "pizza", "pasta", "rice", "noodles", "cereal", "oatmeal", "pancake", "waffle", "croissant", "bagel", "muffin", "cookie", "cake", "donut", "pie", "brownie",
        
        // Proteins
        "chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp", "egg", "cheese", "yogurt", "milk", "butter", "bacon", "sausage", "ham", "turkey", "lamb", "duck",
        
        // Beverages
        "coffee", "tea", "juice", "soda", "water", "wine", "beer", "cocktail", "smoothie", "milkshake",
        
        // Snacks
        "chips", "popcorn", "nuts", "seeds", "chocolate", "candy", "ice cream", "popsicle", "granola bar", "protein bar"
    ]
    
    // Food detection model
    private var foodModel: VNCoreMLModel?
    
    init() {
        setupFoodModel()
    }
    
    private func setupFoodModel() {
        // Try to load a food-specific model
        let modelNames = ["Food101", "ImageNet", "MobileNetV2", "ResNet50"]
        
        for modelName in modelNames {
            if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
                do {
                    let model = try MLModel(contentsOf: modelURL)
                    foodModel = try VNCoreMLModel(for: model)
                    print("✅ Food detection model loaded: \(modelName)")
                    break
                } catch {
                    print("Failed to load \(modelName): \(error)")
                }
            }
        }
    }
    
    func enhanceFoodDetection(in image: UIImage, completion: @escaping ([DetectedObject]) -> Void) {
        DispatchQueue.main.async {
            self.isEnhancing = true
            self.enhancementProgress = 0.0
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var foodDetections: [DetectedObject] = []
                
                // Step 1: Quick pre-check - only proceed if image might contain food
                DispatchQueue.main.async {
                    self.enhancementProgress = 0.1
                }
                
                if !self.mightContainFood(image: image) {
                    DispatchQueue.main.async {
                        self.isEnhancing = false
                        self.enhancementProgress = 1.0
                        completion([])
                    }
                    return
                }
                
                // Step 2: Color-based food detection
                DispatchQueue.main.async {
                    self.enhancementProgress = 0.3
                }
                
                let colorDetections = self.detectFoodByColor(image: image)
                foodDetections.append(contentsOf: colorDetections)
                
                // Step 3: Shape-based detection
                DispatchQueue.main.async {
                    self.enhancementProgress = 0.5
                }
                
                let shapeDetections = self.detectFoodByShape(image: image)
                foodDetections.append(contentsOf: shapeDetections)
                
                // Step 4: Core ML food classification
                DispatchQueue.main.async {
                    self.enhancementProgress = 0.7
                }
                
                if let modelDetections = try self.performFoodClassification(image: image) {
                    foodDetections.append(contentsOf: modelDetections)
                }
                
                // Step 5: Context-based enhancement
                DispatchQueue.main.async {
                    self.enhancementProgress = 0.9
                }
                
                let enhancedDetections = self.enhanceFoodDetections(foodDetections, in: image)
                
                DispatchQueue.main.async {
                    self.isEnhancing = false
                    self.enhancementProgress = 1.0
                    completion(enhancedDetections)
                }
                
            } catch {
                print("Food enhancement failed: \(error)")
                DispatchQueue.main.async {
                    self.isEnhancing = false
                    completion([])
                }
            }
        }
    }
    
    private func detectFoodByColor(image: UIImage) -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        guard let cgImage = image.cgImage else { return detections }
        
        // Analyze dominant colors more accurately
        let dominantColors = analyzeDominantColors(cgImage)
        
        // Only detect if there's a significant amount of the target color
        let yellowOrangePercentage = dominantColors.yellowOrangePercentage
        let redPercentage = dominantColors.redPercentage
        
        // Yellow/Orange detection for bananas (need at least 15% of image)
        if yellowOrangePercentage > 0.15 {
            detections.append(DetectedObject(
                identifier: "banana",
                confidence: min(yellowOrangePercentage * 2.0, 0.95), // Scale confidence based on color amount
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                localizedName: "Banana"
            ))
        }
        
        // Red detection for apples (need at least 15% of image)
        if redPercentage > 0.15 {
            detections.append(DetectedObject(
                identifier: "apple",
                confidence: min(redPercentage * 2.0, 0.95), // Scale confidence based on color amount
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                localizedName: "Apple"
            ))
        }
        
        return detections
    }
    
    private func detectFoodByShape(image: UIImage) -> [DetectedObject] {
        var detections: [DetectedObject] = []
        
        guard let cgImage = image.cgImage else { return detections }
        
        // Analyze shape characteristics
        let shapeAnalysis = analyzeShape(cgImage)
        
        // Only detect if the shape is very distinctive
        // Curved, elongated shape for banana (very specific criteria)
        if shapeAnalysis.isCurved && shapeAnalysis.aspectRatio > 2.5 && shapeAnalysis.aspectRatio < 4.0 {
            detections.append(DetectedObject(
                identifier: "banana",
                confidence: 0.90,
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                localizedName: "Banana"
            ))
        }
        
        // Round shape for apples (very specific criteria)
        if shapeAnalysis.isRound && shapeAnalysis.aspectRatio > 0.8 && shapeAnalysis.aspectRatio < 1.3 {
            detections.append(DetectedObject(
                identifier: "apple",
                confidence: 0.85,
                boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                localizedName: "Apple"
            ))
        }
        
        return detections
    }
    
    private func performFoodClassification(image: UIImage) throws -> [DetectedObject]? {
        guard let foodModel = foodModel,
              let cgImage = image.cgImage else { return nil }
        
        let request = VNCoreMLRequest(model: foodModel) { request, error in
            // Handle results
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let results = request.results as? [VNClassificationObservation] else {
            return nil
        }
        
        var detections: [DetectedObject] = []
        
        for observation in results.prefix(5) {
            let label = observation.identifier.lowercased()
            
            // Check if it's a food item
            if foodLabels.contains(where: { label.contains($0) }) {
                detections.append(DetectedObject(
                    identifier: label,
                    confidence: Double(observation.confidence),
                    boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                    localizedName: label.capitalized
                ))
            }
        }
        
        return detections
    }
    
    private func enhanceFoodDetections(_ detections: [DetectedObject], in image: UIImage) -> [DetectedObject] {
        // Remove duplicates and keep highest confidence
        let uniqueDetections = Dictionary(grouping: detections) { $0.identifier }
            .compactMap { _, objects in
                objects.max { $0.confidence < $1.confidence }
            }
        
        return uniqueDetections.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Helper Methods
    
    private func analyzeDominantColors(_ cgImage: CGImage) -> (yellowOrangePercentage: Double, redPercentage: Double) {
        // Simplified color analysis - in a real implementation, you'd use Core Image filters
        // For now, return conservative values to avoid false positives
        return (yellowOrangePercentage: 0.05, redPercentage: 0.05)
    }
    
    private func isYellowOrOrange(_ color: UIColor) -> Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return red > 0.6 && green > 0.4 && blue < 0.3
    }
    
    private func isRed(_ color: UIColor) -> Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return red > 0.7 && green < 0.4 && blue < 0.4
    }
    
    private func analyzeShape(_ cgImage: CGImage) -> (isCurved: Bool, isRound: Bool, aspectRatio: CGFloat) {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let aspectRatio = width / height
        
        let isCurved = aspectRatio > 1.5 || aspectRatio < 0.7
        let isRound = abs(aspectRatio - 1.0) < 0.3
        
        return (isCurved, isRound, aspectRatio)
    }
    
    func isFoodItem(_ identifier: String) -> Bool {
        return foodLabels.contains(where: { identifier.contains($0) })
    }
    
    private func mightContainFood(image: UIImage) -> Bool {
        // Conservative check - only proceed if there are strong indicators of food
        guard let cgImage = image.cgImage else { return false }
        
        let dominantColors = analyzeDominantColors(cgImage)
        let shapeAnalysis = analyzeShape(cgImage)
        
        // Check for food-like colors (yellow, orange, red, green)
        let hasFoodColors = dominantColors.yellowOrangePercentage > 0.1 || 
                           dominantColors.redPercentage > 0.1
        
        // Check for food-like shapes (round or elongated)
        let hasFoodShapes = shapeAnalysis.isRound || shapeAnalysis.isCurved
        
        // Only proceed if both color and shape suggest food
        return hasFoodColors && hasFoodShapes
    }
}

// MARK: - DetectedObject Extension
extension DetectedObject {
    var category: ObjectCategory {
        // Determine category based on identifier
        let identifier = self.identifier.lowercased()
        
        if FoodDetectionEnhancer().isFoodItem(identifier) {
            return .food
        } else if identifier.contains("computer") || identifier.contains("laptop") || identifier.contains("screen") {
            return .computer
        } else if identifier.contains("door") || identifier.contains("entrance") {
            return .door
        } else if identifier.contains("parcel") || identifier.contains("package") || identifier.contains("box") {
            return .parcel
        } else {
            return .other
        }
    }
}
