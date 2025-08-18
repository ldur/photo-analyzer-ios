#!/usr/bin/env python3
"""
YOLOv8x to Core ML Converter
Converts YOLOv8x model to Core ML format for iOS app
"""

import os
import sys
import torch
import coremltools as ct
from ultralytics import YOLO
import argparse

def convert_yolov8x_to_coreml(input_path, output_path, confidence_threshold=0.25, nms_threshold=0.45):
    """
    Convert YOLOv8x model to Core ML format
    
    Args:
        input_path: Path to YOLOv8x model (.pt file)
        output_path: Output path for Core ML model (.mlmodel)
        confidence_threshold: Confidence threshold for detections
        nms_threshold: NMS threshold for removing overlapping detections
    """
    
    print(f"🔄 Converting YOLOv8x model from: {input_path}")
    print(f"📱 Output Core ML model to: {output_path}")
    
    try:
        # Load YOLOv8x model
        print("📥 Loading YOLOv8x model...")
        model = YOLO(input_path)
        
        # Convert to Core ML
        print("🔄 Converting to Core ML format...")
        
        # Use Ultralytics built-in export for better compatibility
        print("📱 Using Ultralytics export method...")
        model.export(format='coreml', 
                    int8=False, 
                    half=False, 
                    imgsz=640,
                    optimize=True)
        
        # The exported model will be saved as yolov8x.mlpackage
        import shutil
        import os
        
        # Find the exported model
        exported_path = None
        for file in os.listdir('.'):
            if file.endswith('.mlpackage') and 'yolov8x' in file:
                exported_path = file
                break
        
        if exported_path:
            # Rename to desired output
            if os.path.exists(output_path):
                if os.path.isdir(output_path):
                    shutil.rmtree(output_path)
                else:
                    os.remove(output_path)
            
            shutil.move(exported_path, output_path)
            print(f"✅ Model exported and renamed to: {output_path}")
        else:
            # Fallback: try manual conversion with corrected API
            print("🔄 Trying manual conversion...")
            coreml_model = ct.convert(
                model.model,
                inputs=[ct.ImageType(name="image", shape=ct.Shape(shape=[1, 3, 640, 640]))],
                minimum_deployment_target=ct.target.iOS17,
                compute_units=ct.ComputeUnit.CPU_AND_NE
            )
        
            # Add metadata if we used manual conversion
            if 'coreml_model' in locals():
                coreml_model.author = "Photo Analyzer App"
                coreml_model.license = "MIT"
                coreml_model.short_description = "YOLOv8x object detection model converted for iOS"
                coreml_model.version = "1.0"
                
                # Save the model
                print("💾 Saving Core ML model...")
                coreml_model.save(output_path)
        
        print(f"✅ Successfully converted YOLOv8x to Core ML!")
        print(f"📁 Model saved to: {output_path}")
        
        # Check final file size
        if os.path.exists(output_path):
            if os.path.isdir(output_path):
                # Calculate directory size for .mlpackage
                total_size = 0
                for dirpath, dirnames, filenames in os.walk(output_path):
                    for filename in filenames:
                        filepath = os.path.join(dirpath, filename)
                        total_size += os.path.getsize(filepath)
                print(f"📊 Model size: {total_size / (1024*1024):.2f} MB")
            else:
                print(f"📊 Model size: {os.path.getsize(output_path) / (1024*1024):.2f} MB")
        
        return True
        
    except Exception as e:
        print(f"❌ Error converting model: {str(e)}")
        return False

def download_yolov8x_if_needed():
    """Download YOLOv8x model if not present"""
    model_path = "yolov8x.pt"
    
    if not os.path.exists(model_path):
        print("📥 Downloading YOLOv8x model...")
        try:
            model = YOLO("yolov8x.pt")
            print("✅ YOLOv8x model downloaded successfully!")
        except Exception as e:
            print(f"❌ Error downloading YOLOv8x: {str(e)}")
            return None
    else:
        print("✅ YOLOv8x model already exists!")
    
    return model_path

def main():
    parser = argparse.ArgumentParser(description="Convert YOLOv8x to Core ML")
    parser.add_argument("--input", "-i", default="yolov8x.pt", help="Input YOLOv8x model path")
    parser.add_argument("--output", "-o", default="YOLOv8x.mlmodel", help="Output Core ML model path")
    parser.add_argument("--confidence", "-c", type=float, default=0.25, help="Confidence threshold")
    parser.add_argument("--nms", "-n", type=float, default=0.45, help="NMS threshold")
    parser.add_argument("--download", "-d", action="store_true", help="Download YOLOv8x if not present")
    
    args = parser.parse_args()
    
    print("🚀 YOLOv8x to Core ML Converter")
    print("=" * 40)
    
    # Check if input model exists
    if not os.path.exists(args.input):
        if args.download:
            args.input = download_yolov8x_if_needed()
            if not args.input:
                sys.exit(1)
        else:
            print(f"❌ Input model not found: {args.input}")
            print("💡 Use --download flag to download YOLOv8x automatically")
            sys.exit(1)
    
    # Convert the model
    success = convert_yolov8x_to_coreml(
        args.input, 
        args.output, 
        args.confidence, 
        args.nms
    )
    
    if success:
        print("\n🎉 Conversion completed successfully!")
        print("\n📋 Next steps:")
        print("1. Copy the .mlmodel file to your Xcode project")
        print("2. Add it to your app bundle")
        print("3. The app will automatically detect and use it")
        print(f"4. Model file: {args.output}")
    else:
        print("\n❌ Conversion failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
