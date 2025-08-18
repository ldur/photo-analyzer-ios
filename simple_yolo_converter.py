#!/usr/bin/env python3
"""
Simple YOLOv8x to Core ML Converter
Uses Ultralytics built-in export for maximum compatibility
"""

import os
import sys
from ultralytics import YOLO

def convert_yolov8x_simple():
    """Simple conversion using Ultralytics export"""
    
    print("🚀 Simple YOLOv8x to Core ML Converter")
    print("=" * 50)
    
    try:
        # Download and load YOLOv8x
        print("📥 Downloading YOLOv8x model...")
        model = YOLO('yolov8x.pt')
        print("✅ YOLOv8x model loaded successfully!")
        
        # Export to Core ML using Ultralytics built-in method
        print("🔄 Converting to Core ML format...")
        model.export(
            format='coreml',
            imgsz=640,
            optimize=True,
            int8=False,
            half=False
        )
        
        print("✅ Successfully converted YOLOv8x to Core ML!")
        
        # Find the exported model
        exported_files = []
        for file in os.listdir('.'):
            if 'yolov8x' in file and (file.endswith('.mlpackage') or file.endswith('.mlmodel')):
                exported_files.append(file)
        
        if exported_files:
            print("\n📁 Exported files:")
            for file in exported_files:
                size_mb = get_size_mb(file)
                print(f"  - {file} ({size_mb:.1f} MB)")
            
            print("\n📋 Next steps:")
            print("1. Copy the .mlpackage or .mlmodel file to your Xcode project")
            print("2. Add it to your app bundle (drag into Xcode)")
            print("3. The app will automatically detect and use it")
            print("4. Make sure to add it to the target when prompted")
            
            return True
        else:
            print("❌ No exported model found!")
            return False
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def get_size_mb(path):
    """Get size of file or directory in MB"""
    if os.path.isfile(path):
        return os.path.getsize(path) / (1024 * 1024)
    elif os.path.isdir(path):
        total_size = 0
        for dirpath, dirnames, filenames in os.walk(path):
            for filename in filenames:
                filepath = os.path.join(dirpath, filename)
                if os.path.exists(filepath):
                    total_size += os.path.getsize(filepath)
        return total_size / (1024 * 1024)
    return 0

if __name__ == "__main__":
    success = convert_yolov8x_simple()
    if not success:
        sys.exit(1)
    
    print("\n🎉 Conversion completed successfully!")
    print("\n💡 Tip: The YOLOv8x model provides excellent object detection")
    print("   with 80+ object classes including people, animals, vehicles, etc.")

