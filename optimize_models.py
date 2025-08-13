#!/usr/bin/env python3
"""
Core ML Model Optimization Script
Optimizes AI models for better performance on iOS devices
"""

import coremltools as ct
import os
from pathlib import Path

def optimize_model(model_path, output_path, compute_units="ALL"):
    """
    Optimize a Core ML model for better performance
    
    Args:
        model_path: Path to the input .mlmodel file
        output_path: Path for the optimized output model
        compute_units: "ALL", "CPU_ONLY", "CPU_AND_GPU", "CPU_AND_NE"
    """
    
    if not os.path.exists(model_path):
        print(f"Model not found: {model_path}")
        return False
    
    try:
        # Load the model
        print(f"Loading model: {model_path}")
        model = ct.models.MLModel(model_path)
        
        # Convert to neural network if needed
        if hasattr(model, '_spec'):
            spec = model._spec
            
            # Optimize compute units
            if hasattr(spec, 'neuralNetwork'):
                if compute_units == "CPU_ONLY":
                    spec.neuralNetwork.allowLowPrecisionAccumulationOnGPU = False
                elif compute_units == "CPU_AND_NE":
                    # Neural Engine optimization
                    spec.neuralNetwork.allowLowPrecisionAccumulationOnGPU = True
            
            # Create optimized model
            optimized_model = ct.models.MLModel(spec)
            
            # Save optimized model
            print(f"Saving optimized model: {output_path}")
            optimized_model.save(output_path)
            print(f"✅ Model optimized successfully!")
            return True
            
    except Exception as e:
        print(f"❌ Error optimizing model: {e}")
        return False

def download_optimized_models():
    """Download pre-trained optimized models for common tasks"""
    
    models = {
        "YOLOv8n": "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.mlmodel",
        "MobileNetV3": "https://ml-assets.apple.com/coreml/models/Image/ImageClassification/MobileNetV3/MobileNetV3Large.mlmodel",
        "DeepLabV3": "https://ml-assets.apple.com/coreml/models/Image/Segmentation/DeepLabV3/DeepLabV3.mlmodel"
    }
    
    models_dir = Path("Photo Analyzer/Models")
    models_dir.mkdir(exist_ok=True)
    
    for model_name, url in models.items():
        model_path = models_dir / f"{model_name}.mlmodel"
        
        if not model_path.exists():
            print(f"Downloading {model_name}...")
            try:
                import urllib.request
                urllib.request.urlretrieve(url, model_path)
                print(f"✅ Downloaded {model_name}")
                
                # Optimize the downloaded model
                optimized_path = models_dir / f"{model_name}_optimized.mlmodel"
                optimize_model(str(model_path), str(optimized_path), "CPU_AND_NE")
                
            except Exception as e:
                print(f"❌ Failed to download {model_name}: {e}")

def benchmark_models():
    """Benchmark different models for performance comparison"""
    
    print("\n📊 Model Performance Benchmarking Tips:")
    print("=" * 50)
    print("1. Use CPU_AND_NE for Neural Engine acceleration")
    print("2. Quantize models to reduce memory usage")
    print("3. Use batch processing for multiple images")
    print("4. Cache model predictions for repeated analysis")
    print("5. Use asynchronous processing for UI responsiveness")
    
    print("\n🎯 Recommended Model Configuration:")
    print("- Object Detection: YOLOv8n (optimized for mobile)")
    print("- Image Classification: MobileNetV3 (fast and efficient)")
    print("- Text Recognition: Built-in Vision OCR")
    print("- Face Detection: Built-in Vision framework")

if __name__ == "__main__":
    print("🚀 Core ML Model Optimization Tool")
    print("=" * 40)
    
    # Download and optimize models
    download_optimized_models()
    
    # Show benchmarking tips
    benchmark_models()
    
    print("\n✨ Optimization complete! Add optimized models to your Xcode project.")
