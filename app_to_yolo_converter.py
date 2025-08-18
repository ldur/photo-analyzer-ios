#!/usr/bin/env python3
"""
App Data to YOLO Converter
Converts Photo Analyzer app data to YOLO training format with Norwegian package detection classes
"""

import json
import cv2
import os
from pathlib import Path
import shutil
from typing import List, Dict, Tuple
import numpy as np

class AppDataToYOLO:
    def __init__(self, app_data_path: str, output_path: str):
        self.app_data_path = Path(app_data_path)
        self.output_path = Path(output_path)
        
        # Norwegian package detection classes based on your specification
        self.target_classes = [
            "no_objects",           # 0 - No relevant objects detected
            "pakke",               # 1 - Package/parcel
            "postkasse",           # 2 - Mailbox
            "etikett",             # 3 - Label/address label
            "postkasseskilt",      # 4 - Mailbox sign/number
            "pakke_i_postkasse",   # 5 - Package in mailbox
            "pakke_ved_inngangsparti", # 6 - Package at entrance
            "inngangsparti"        # 7 - Entrance/doorway
        ]
        
        self.setup_directories()
    
    def setup_directories(self):
        """Create YOLO directory structure"""
        self.output_path.mkdir(parents=True, exist_ok=True)
        
        # Create YOLO directory structure
        (self.output_path / "images" / "train").mkdir(parents=True, exist_ok=True)
        (self.output_path / "images" / "val").mkdir(parents=True, exist_ok=True)
        (self.output_path / "labels" / "train").mkdir(parents=True, exist_ok=True)
        (self.output_path / "labels" / "val").mkdir(parents=True, exist_ok=True)
        
        print(f"📁 Created YOLO directory structure at: {self.output_path}")
    
    def calculate_package_detection_score(self, detected_objects: Dict[str, int]) -> float:
        """
        Calculate package detection confidence score based on your logic
        """
        # Extract counts for each object type
        no_objects = detected_objects.get("no_objects", 0)
        pakke = detected_objects.get("pakke", 0)
        postkasse = detected_objects.get("postkasse", 0)
        etikett = detected_objects.get("etikett", 0)
        postkasseskilt = detected_objects.get("postkasseskilt", 0)
        pakke_i_postkasse = detected_objects.get("pakke_i_postkasse", 0)
        pakke_ved_inngangsparti = detected_objects.get("pakke_ved_inngangsparti", 0)
        inngangsparti = detected_objects.get("inngangsparti", 0)
        
        # Apply your scoring logic
        if no_objects > 0:
            return 0.0
        elif pakke > 0 and postkasse > 0 and etikett > 0 and postkasseskilt > 0:
            return 1.0
        elif pakke_i_postkasse > 0 and etikett > 0 and postkasseskilt > 0:
            return 1.0
        elif pakke_ved_inngangsparti > 0:
            return 1.0
        elif pakke > 0 and inngangsparti > 0:
            return 1.0
        elif etikett > 0 and postkasseskilt > 0:
            return 0.8
        elif pakke > 0 and postkasse > 0 and postkasseskilt > 0:
            return 0.7
        elif pakke > 0 and postkasseskilt > 0:
            return 0.6
        elif pakke > 0 and postkasse > 0 and etikett > 0:
            return 0.5
        elif inngangsparti > 0:
            return 0.5
        elif pakke > 0 and postkasse > 0:
            return 0.25
        elif postkasse > 0 and postkasseskilt > 0:
            return 0.25
        elif postkasseskilt > 0:
            return 0.2
        elif pakke > 0:
            return 0.1
        elif postkasse > 0:
            return 0.1
        elif etikett > 0:
            return 0.05
        else:
            return 0.0
    
    def convert_app_data(self):
        """Convert Photo Analyzer app data to YOLO format"""
        print("🔄 Starting conversion of app data to YOLO format...")
        
        # Read app's training manifest
        manifest_path = self.app_data_path / "manifest.json"
        
        if not manifest_path.exists():
            print("❌ No manifest.json found. Export training data from the app first.")
            print(f"   Expected path: {manifest_path}")
            return False
        
        with open(manifest_path, 'r', encoding='utf-8') as f:
            manifest = json.load(f)
        
        print(f"📊 Found {len(manifest.get('photos', []))} photos in manifest")
        
        # Create dataset.yaml
        self.create_dataset_yaml()
        
        # Process each labeled photo
        train_count = 0
        val_count = 0
        skipped_count = 0
        
        for i, photo_data in enumerate(manifest.get('photos', [])):
            # Determine train/val split (80/20)
            is_val = i % 5 == 0
            split = "val" if is_val else "train"
            
            # Process image and create YOLO label
            success = self.process_photo(photo_data, split)
            
            if success:
                if is_val:
                    val_count += 1
                else:
                    train_count += 1
            else:
                skipped_count += 1
        
        print(f"✅ Conversion completed!")
        print(f"   📈 Training images: {train_count}")
        print(f"   📊 Validation images: {val_count}")
        print(f"   ⚠️  Skipped images: {skipped_count}")
        print(f"   📁 Dataset ready at: {self.output_path}")
        
        return True
    
    def process_photo(self, photo_data: Dict, split: str) -> bool:
        """Process individual photo and create YOLO annotation"""
        image_path = Path(photo_data['imagePath'])
        
        if not image_path.exists():
            print(f"⚠️  Image not found: {image_path}")
            return False
        
        try:
            # Load and optimize image
            img = cv2.imread(str(image_path))
            if img is None:
                print(f"⚠️  Could not load image: {image_path}")
                return False
            
            # Resize to YOLO format while maintaining aspect ratio
            img_optimized = self.optimize_image_for_yolo(img)
            
            # Save optimized image
            img_name = f"{photo_data['id']}.jpg"
            img_output_path = self.output_path / "images" / split / img_name
            cv2.imwrite(str(img_output_path), img_optimized)
            
            # Create YOLO label file
            label_output_path = self.output_path / "labels" / split / f"{photo_data['id']}.txt"
            self.create_yolo_label(photo_data, label_output_path, img_optimized.shape)
            
            return True
            
        except Exception as e:
            print(f"❌ Error processing {image_path}: {e}")
            return False
    
    def optimize_image_for_yolo(self, img: np.ndarray) -> np.ndarray:
        """Optimize image for YOLO training with iPhone-specific enhancements"""
        target_size = 640
        h, w = img.shape[:2]
        
        # Calculate scale to maintain aspect ratio
        scale = min(target_size/w, target_size/h)
        new_w, new_h = int(w * scale), int(h * scale)
        
        # Resize image
        img_resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LINEAR)
        
        # Create padded image with gray background
        img_padded = np.full((target_size, target_size, 3), 114, dtype=np.uint8)
        
        # Calculate padding
        pad_w = (target_size - new_w) // 2
        pad_h = (target_size - new_h) // 2
        
        # Place resized image in center
        img_padded[pad_h:pad_h + new_h, pad_w:pad_w + new_w] = img_resized
        
        # Apply iPhone-specific optimizations
        img_optimized = self.enhance_for_iphone_photos(img_padded)
        
        return img_optimized
    
    def enhance_for_iphone_photos(self, img: np.ndarray) -> np.ndarray:
        """Apply enhancements specific to iPhone photos"""
        # Slight blur to reduce iPhone's sometimes over-sharpened look
        img = cv2.GaussianBlur(img, (1, 1), 0)
        
        # Adjust contrast and brightness for iPhone color profile
        img = cv2.convertScaleAbs(img, alpha=0.95, beta=5)
        
        return img
    
    def create_yolo_label(self, photo_data: Dict, label_path: Path, img_shape: Tuple[int, int, int]):
        """Create YOLO format label file"""
        h, w = img_shape[:2]
        
        with open(label_path, 'w', encoding='utf-8') as f:
            if photo_data.get('boundingBoxes'):
                # If bounding boxes exist, use them
                for bbox in photo_data['boundingBoxes']:
                    if bbox['label'] in self.target_classes:
                        class_id = self.target_classes.index(bbox['label'])
                        
                        # Convert to YOLO format (normalized center coordinates + width/height)
                        x_center = (bbox['x'] + bbox['width']/2) / w
                        y_center = (bbox['y'] + bbox['height']/2) / h
                        width = bbox['width'] / w
                        height = bbox['height'] / h
                        
                        f.write(f"{class_id} {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}\n")
            else:
                # For image classification labels, create full-image bounding box
                label = photo_data.get('label', 'no_objects')
                if label in self.target_classes:
                    class_id = self.target_classes.index(label)
                    # Full image bounding box (center at 0.5, 0.5 with full width/height)
                    f.write(f"{class_id} 0.5 0.5 1.0 1.0\n")
                else:
                    # Unknown label, mark as no_objects
                    f.write("0 0.5 0.5 1.0 1.0\n")
    
    def create_dataset_yaml(self):
        """Create dataset.yaml for YOLO training"""
        yaml_content = f"""# Norwegian Package Detection Dataset
# Generated from Photo Analyzer app data

path: {self.output_path.absolute()}
train: images/train
val: images/val

# Number of classes
nc: {len(self.target_classes)}

# Class names (Norwegian package detection)
names:
{chr(10).join(f"  {i}: '{name}'" for i, name in enumerate(self.target_classes))}

# Scoring logic for package detection:
# 1.0: Definite package delivery
# 0.5-0.8: Likely package delivery
# 0.1-0.25: Possible package-related activity
# 0.0: No package detected
"""
        
        with open(self.output_path / "dataset.yaml", 'w', encoding='utf-8') as f:
            f.write(yaml_content)
        
        print(f"📄 Created dataset.yaml with {len(self.target_classes)} classes")

def main():
    """Main function to run the converter"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Convert Photo Analyzer app data to YOLO format')
    parser.add_argument('--app_data', type=str, required=True, 
                       help='Path to exported training data from Photo Analyzer app')
    parser.add_argument('--output', type=str, required=True,
                       help='Output directory for YOLO dataset')
    
    args = parser.parse_args()
    
    # Create converter and run conversion
    converter = AppDataToYOLO(args.app_data, args.output)
    success = converter.convert_app_data()
    
    if success:
        print("🎉 Conversion completed successfully!")
        print(f"📁 YOLO dataset ready at: {args.output}")
        print("\n🚀 Next steps:")
        print("1. Review the generated dataset.yaml file")
        print("2. Run the training script with this dataset")
        print("3. Evaluate model performance on your photos")
    else:
        print("❌ Conversion failed. Please check the error messages above.")

if __name__ == "__main__":
    main()
