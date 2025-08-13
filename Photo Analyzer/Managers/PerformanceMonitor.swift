import SwiftUI
import Foundation
import os.log

// MARK: - Performance Monitoring
class PerformanceMonitor: ObservableObject {
    @Published var metrics: AnalysisMetrics = AnalysisMetrics()
    @Published var isMonitoring = false
    
    private let logger = Logger(subsystem: "PhotoAnalyzer", category: "Performance")
    private var analysisStartTime: Date?
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    struct AnalysisMetrics {
        var averageProcessingTime: TimeInterval = 0.0
        var totalAnalysisCount: Int = 0
        var memoryUsage: Double = 0.0
        var cpuUsage: Double = 0.0
        var thermalState: ProcessInfo.ThermalState = .nominal
        var batteryLevel: Float = 1.0
        var lastAnalysisTime: TimeInterval = 0.0
        var performanceScore: Double = 100.0 // 0-100 scale
    }
    
    enum OptimizationLevel {
        case maximum    // Best quality, highest resource usage
        case balanced   // Good balance of quality and performance
        case efficient  // Lower quality, optimized for performance
        case battery    // Minimal processing, battery preservation
        
        var confidenceThreshold: Double {
            switch self {
            case .maximum: return 0.3
            case .balanced: return 0.5
            case .efficient: return 0.7
            case .battery: return 0.8
            }
        }
        
        var maxDetections: Int {
            switch self {
            case .maximum: return 50
            case .balanced: return 20
            case .efficient: return 10
            case .battery: return 5
            }
        }
        
        var textRecognitionLevel: String {
            switch self {
            case .maximum, .balanced: return "accurate"
            case .efficient, .battery: return "fast"
            }
        }
    }
    
    init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        // Monitor memory pressure
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: DispatchQueue.global(qos: .utility)
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.updateMemoryMetrics()
            }
        }
        
        memoryPressureSource?.resume()
        
        // Start periodic monitoring
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                await self.updateSystemMetrics()
            }
        }
    }
    
    func startAnalysisMonitoring() {
        analysisStartTime = Date()
        isMonitoring = true
        logger.info("Started performance monitoring")
    }
    
    func endAnalysisMonitoring() {
        guard let startTime = analysisStartTime else { return }
        
        let processingTime = Date().timeIntervalSince(startTime)
        updateAnalysisMetrics(processingTime: processingTime)
        
        isMonitoring = false
        analysisStartTime = nil
        
        logger.info("Analysis completed in \(processingTime, privacy: .public)s")
    }
    
    private func updateAnalysisMetrics(processingTime: TimeInterval) {
        DispatchQueue.main.async {
            self.metrics.lastAnalysisTime = processingTime
            self.metrics.totalAnalysisCount += 1
            
            // Update rolling average
            let previousTotal = self.metrics.averageProcessingTime * Double(self.metrics.totalAnalysisCount - 1)
            self.metrics.averageProcessingTime = (previousTotal + processingTime) / Double(self.metrics.totalAnalysisCount)
            
            // Calculate performance score
            self.updatePerformanceScore()
        }
    }
    
    private func updateMemoryMetrics() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = Double(info.resident_size) / (1024.0 * 1024.0) // Convert to MB
            DispatchQueue.main.async {
                self.metrics.memoryUsage = memoryUsage
            }
        }
    }
    
    @MainActor
    private func updateSystemMetrics() {
        // Update thermal state
        metrics.thermalState = ProcessInfo.processInfo.thermalState
        
        // Update battery level (if available)
        if let batteryLevel = getBatteryLevel() {
            metrics.batteryLevel = batteryLevel
        }
        
        updatePerformanceScore()
    }
    
    private func getBatteryLevel() -> Float? {
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel >= 0 ? UIDevice.current.batteryLevel : nil
        #else
        return nil
        #endif
    }
    
    private func updatePerformanceScore() {
        var score: Double = 100.0
        
        // Penalize for high processing time
        if metrics.lastAnalysisTime > 5.0 {
            score -= 20.0
        } else if metrics.lastAnalysisTime > 3.0 {
            score -= 10.0
        }
        
        // Penalize for thermal issues
        switch metrics.thermalState {
        case .serious:
            score -= 15.0
        case .critical:
            score -= 30.0
        default:
            break
        }
        
        // Penalize for low battery
        if metrics.batteryLevel < 0.2 {
            score -= 15.0
        } else if metrics.batteryLevel < 0.1 {
            score -= 30.0
        }
        
        // Penalize for high memory usage
        if metrics.memoryUsage > 500 { // 500MB
            score -= 10.0
        } else if metrics.memoryUsage > 1000 { // 1GB
            score -= 25.0
        }
        
        metrics.performanceScore = max(0, score)
    }
    
    func getOptimizedConfiguration() -> OptimizationLevel {
        if metrics.performanceScore > 80 {
            return .maximum
        } else if metrics.performanceScore > 60 {
            return .balanced
        } else if metrics.performanceScore > 40 {
            return .efficient
        } else {
            return .battery
        }
    }
    
    func getOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if metrics.lastAnalysisTime > 5.0 {
            recommendations.append("⚡ Consider reducing image resolution for faster processing")
        }
        
        if metrics.thermalState == .serious || metrics.thermalState == .critical {
            recommendations.append("🌡️ Device is overheating - reducing AI model complexity")
        }
        
        if metrics.batteryLevel < 0.2 {
            recommendations.append("🔋 Low battery detected - switching to power-efficient mode")
        }
        
        if metrics.memoryUsage > 500 {
            recommendations.append("💾 High memory usage - consider processing smaller batches")
        }
        
        if metrics.totalAnalysisCount > 0 && metrics.averageProcessingTime > 3.0 {
            recommendations.append("🚀 Consider downloading optimized models for better performance")
        }
        
        return recommendations
    }
    
    // MARK: - Performance Optimization Helpers
    func shouldSkipHeavyProcessing() -> Bool {
        return metrics.thermalState == .critical || 
               metrics.batteryLevel < 0.1 || 
               metrics.memoryUsage > 1000
    }
    
    func getOptimalImageSize(originalSize: CGSize) -> CGSize {
        let optimizationLevel = getOptimizedConfiguration()
        let maxDimension: CGFloat
        
        switch optimizationLevel {
        case .maximum:
            maxDimension = 1920
        case .balanced:
            maxDimension = 1280
        case .efficient:
            maxDimension = 640
        case .battery:
            maxDimension = 320
        }
        
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1.0)
        return CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
    }
    
    func logPerformanceMetrics() {
        logger.info("""
        📊 Performance Metrics:
        - Average Processing Time: \(self.metrics.averageProcessingTime, privacy: .public)s
        - Last Analysis Time: \(self.metrics.lastAnalysisTime, privacy: .public)s
        - Total Analyses: \(self.metrics.totalAnalysisCount, privacy: .public)
        - Memory Usage: \(self.metrics.memoryUsage, privacy: .public)MB
        - Thermal State: \(String(describing: self.metrics.thermalState), privacy: .public)
        - Battery Level: \(self.metrics.batteryLevel, privacy: .public)
        - Performance Score: \(self.metrics.performanceScore, privacy: .public)/100
        """)
    }
    
    deinit {
        memoryPressureSource?.cancel()
    }
}

// MARK: - Performance Extensions
// Note: AIAnalyzer optimization is handled internally within the AIAnalyzer class
// to avoid accessing private properties from extensions
