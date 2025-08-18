#!/usr/bin/env python3
"""
Custom YOLOv8x Training Script for Photo Analyzer App

This script trains a custom YOLOv8x model on your specific objects
and exports it to Core ML format for iOS integration.
"""

import os
import yaml
import json
from pathlib import Path
from ultralytics import YOLO
from datetime import datetime

class CustomYOLOTrainer:
    def __init__(self, data_path: str, output_path: str = "custom_models"):
        self.data_path = Path(data_path)
        self.output_path = Path(output_path)
        self.output_path.mkdir(exist_ok=True)
        
        # Default target classes (customize as needed)
        self.target_classes = [
            'computer', 'door', 'parcel', 'parcel_at_door', 
            'cup', 'banana', 'person', 'car', 'phone', 
            'keys', 'package', 'mail'
        ]
    
    def prepare_dataset(self, train_split: float = 0.8):
        """
        Prepare dataset in YOLO format from Photo Analyzer export
        """
        print("📚 Preparing dataset...")
        
        # Create dataset structure
        dataset_path = self.output_path / "dataset"
        train_path = dataset_path / "train"
        val_path = dataset_path / "val"
        
        for path in [train_path, val_path]:
            (path / "images").mkdir(parents=True, exist_ok=True)
            (path / "labels").mkdir(parents=True, exist_ok=True)
        
        # Load manifest from Photo Analyzer export
        manifest_file = self.data_path / "manifest.json"
        if not manifest_file.exists():
            raise FileNotFoundError(f"Training manifest not found: {manifest_file}")
        
        with open(manifest_file, 'r') as f:
            manifest = json.load(f)
        
        self.target_classes = manifest['classes']
        
        # Split data into train/val
        photos = manifest['photos']
        split_idx = int(len(photos) * train_split)
        
        train_photos = photos[:split_idx]
        val_photos = photos[split_idx:]
        
        # Process training data
        self._process_photos(train_photos, train_path)
        self._process_photos(val_photos, val_path)
        
        # Create dataset config
        self._create_dataset_config(dataset_path)
        
        print(f"✅ Dataset prepared: {len(train_photos)} train, {len(val_photos)} val")
        return dataset_path / "dataset.yaml"
    
    def _process_photos(self, photos: list, output_path: Path):
        """Process photos and create YOLO format labels"""
        for photo in photos:
            src_image = Path(photo['imagePath'])
            if not src_image.exists():
                continue
            
            # Copy image
            dst_image = output_path / "images" / src_image.name
            dst_image.write_bytes(src_image.read_bytes())
            
            # Create YOLO label file
            label_file = output_path / "labels" / f"{src_image.stem}.txt"
            
            # Convert bounding boxes to YOLO format
            yolo_labels = []
            for bbox in photo.get('boundingBoxes', []):
                class_id = self._get_class_id(bbox['label'])
                if class_id is not None:
                    # Convert to YOLO format (normalized coordinates)
                    x_center = bbox['x'] + bbox['width'] / 2
                    y_center = bbox['y'] + bbox['height'] / 2
                    yolo_labels.append(f"{class_id} {x_center} {y_center} {bbox['width']} {bbox['height']}")
            
            # If no bounding boxes, create whole-image label
            if not yolo_labels and photo['label'] in self.target_classes:
                class_id = self._get_class_id(photo['label'])
                if class_id is not None:
                    yolo_labels.append(f"{class_id} 0.5 0.5 1.0 1.0")  # Whole image
            
            # Write label file
            if yolo_labels:
                label_file.write_text('\n'.join(yolo_labels))
    
    def _get_class_id(self, class_name: str) -> int:
        """Get class ID for class name"""
        try:
            return self.target_classes.index(class_name)
        except ValueError:
            return None
    
    def _create_dataset_config(self, dataset_path: Path):
        """Create YOLO dataset configuration file"""
        config = {
            'train': str(dataset_path / "train" / "images"),
            'val': str(dataset_path / "val" / "images"),
            'nc': len(self.target_classes),
            'names': self.target_classes
        }
        
        config_file = dataset_path / "dataset.yaml"
        with open(config_file, 'w') as f:
            yaml.dump(config, f, default_flow_style=False)
        
        print(f"✅ Dataset config created: {config_file}")
    
    def train_model(self, dataset_config: Path, epochs: int = 100, batch_size: int = 16):
        """
        Train custom YOLOv8x model
        """
        print("🚀 Starting model training...")
        
        # Load base YOLOv8x model
        model = YOLO('yolov8x.pt')
        
        # Training configuration
        training_args = {
            'data': str(dataset_config),
            'epochs': epochs,
            'imgsz': 640,
            'batch': batch_size,
            'name': 'custom_yolov8x',
            'patience': 10,
            'save': True,
            'save_period': 10,
            'project': str(self.output_path),
            'exist_ok': True,
            'pretrained': True,
            'optimizer': 'AdamW',
            'lr0': 0.01,
            'lrf': 0.01,
            'momentum': 0.937,
            'weight_decay': 0.0005,
            'warmup_epochs': 3,
            'warmup_momentum': 0.8,
            'warmup_bias_lr': 0.1,
            'box': 7.5,
            'cls': 0.5,
            'dfl': 1.5,
            'pose': 12.0,
            'kobj': 1.0,
            'label_smoothing': 0.0,
            'nbs': 64,
            'hsv_h': 0.015,
            'hsv_s': 0.7,
            'hsv_v': 0.4,
            'degrees': 0.0,
            'translate': 0.1,
            'scale': 0.5,
            'shear': 0.0,
            'perspective': 0.0,
            'flipud': 0.0,
            'fliplr': 0.5,
            'mosaic': 1.0,
            'mixup': 0.0,
            'copy_paste': 0.0
        }
        
        # Train the model
        results = model.train(**training_args)
        
        print("✅ Training completed!")
        return model, results
    
    def export_to_coreml(self, model: YOLO, model_name: str = "CustomYOLOv8x"):
        """
        Export trained model to Core ML format
        """
        print("📱 Exporting to Core ML...")
        
        # Export to Core ML
        model.export(
            format='coreml',
            optimize=True,
            half=False,  # Keep full precision for better accuracy
            int8=False,  # Disable quantization initially
            dynamic=False,
            simplify=True,
            opset=None,
            workspace=4,
            nms=True,
            batch=1,
            device='cpu'
        )
        
        # Create model metadata
        metadata = {
            'version': f"v{datetime.now().strftime('%Y%m%d_%H%M')}",
            'classNames': self.target_classes,
            'trainingDate': datetime.now().isoformat(),
            'accuracy': None,  # Would need validation results
            'description': f'Custom YOLOv8x trained on {len(self.target_classes)} object classes'
        }
        
        # Save metadata
        metadata_file = self.output_path / f"{model_name}_metadata.json"
        with open(metadata_file, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"✅ Core ML model exported with metadata")
        print(f"📁 Model files saved in: {self.output_path}")
        
        return metadata
    
    def full_training_pipeline(self, epochs: int = 100, batch_size: int = 16):
        """
        Complete training pipeline from data preparation to Core ML export
        """
        print("🎯 Starting Custom YOLOv8x Training Pipeline")
        print(f"📊 Target Classes: {', '.join(self.target_classes)}")
        
        try:
            # Step 1: Prepare dataset
            dataset_config = self.prepare_dataset()
            
            # Step 2: Train model
            model, results = self.train_model(dataset_config, epochs, batch_size)
            
            # Step 3: Export to Core ML
            metadata = self.export_to_coreml(model)
            
            print("\n🎉 Training Pipeline Complete!")
            print(f"📱 Ready to deploy: {metadata['version']}")
            print(f"📁 Files location: {self.output_path}")
            
            return model, metadata
            
        except Exception as e:
            print(f"❌ Training failed: {str(e)}")
            raise


def main():
    """
    Main training script
    """
    import argparse
    
    parser = argparse.ArgumentParser(description='Train Custom YOLOv8x for Photo Analyzer')
    parser.add_argument('data_path', help='Path to exported training data from Photo Analyzer')
    parser.add_argument('--epochs', type=int, default=100, help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=16, help='Training batch size')
    parser.add_argument('--output', default='custom_models', help='Output directory for trained models')
    
    args = parser.parse_args()
    
    # Create trainer
    trainer = CustomYOLOTrainer(args.data_path, args.output)
    
    # Run training pipeline
    model, metadata = trainer.full_training_pipeline(args.epochs, args.batch_size)
    
    print("\n📱 Next Steps:")
    print("1. Copy the .mlpackage file to your iOS project")
    print("2. Replace 'yolov8x 2.mlpackage' with your custom model")
    print("3. Update the app to use CustomYOLODetector")
    print("4. Test detection accuracy with real photos")


if __name__ == "__main__":
    main()
