#!/usr/bin/env python3
"""
Norwegian Package Detection Training Script
Train YOLOv8x model optimized for detecting packages at Norwegian mailboxes using iPhone photos
"""

import torch
from ultralytics import YOLO
from pathlib import Path
import json
import time
import yaml
from datetime import datetime
import argparse
import os

class NorwegianPackageYOLOTrainer:
    def __init__(self, dataset_path: str, output_dir: str = "runs/package_detector"):
        self.dataset_path = Path(dataset_path)
        self.output_dir = Path(output_dir)
        self.device = self.get_best_device()
        
        # Norwegian package detection classes
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
        
        print(f"🔧 Using device: {self.device}")
        print(f"📁 Dataset path: {self.dataset_path}")
        print(f"📂 Output directory: {self.output_dir}")
    
    def get_best_device(self):
        """Determine best available device for training"""
        if torch.backends.mps.is_available():
            return "mps"  # Apple Silicon Metal Performance Shaders
        elif torch.cuda.is_available():
            return "cuda"
        else:
            return "cpu"
    
    def validate_dataset(self):
        """Validate that the dataset is properly formatted"""
        print("🔍 Validating dataset...")
        
        # Check if dataset.yaml exists
        yaml_path = self.dataset_path / "dataset.yaml"
        if not yaml_path.exists():
            raise FileNotFoundError(f"❌ dataset.yaml not found at {yaml_path}")
        
        # Load and validate yaml
        with open(yaml_path, 'r', encoding='utf-8') as f:
            dataset_config = yaml.safe_load(f)
        
        required_keys = ['path', 'train', 'val', 'nc', 'names']
        for key in required_keys:
            if key not in dataset_config:
                raise ValueError(f"❌ Missing required key '{key}' in dataset.yaml")
        
        # Check directories
        train_images = self.dataset_path / "images" / "train"
        train_labels = self.dataset_path / "labels" / "train"
        val_images = self.dataset_path / "images" / "val"
        val_labels = self.dataset_path / "labels" / "val"
        
        for dir_path in [train_images, train_labels, val_images, val_labels]:
            if not dir_path.exists():
                raise FileNotFoundError(f"❌ Directory not found: {dir_path}")
        
        # Count files
        train_img_count = len(list(train_images.glob("*.jpg")))
        train_lbl_count = len(list(train_labels.glob("*.txt")))
        val_img_count = len(list(val_images.glob("*.jpg")))
        val_lbl_count = len(list(val_labels.glob("*.txt")))
        
        print(f"✅ Dataset validation passed:")
        print(f"   📈 Training: {train_img_count} images, {train_lbl_count} labels")
        print(f"   📊 Validation: {val_img_count} images, {val_lbl_count} labels")
        print(f"   🏷️  Classes: {dataset_config['nc']} ({len(self.target_classes)} expected)")
        
        if train_img_count < 10:
            print("⚠️  Warning: Very few training images. Consider collecting more data.")
        
        return dataset_config
        print(f"   📈 Training: {train_img_count} images, {train_lbl_count} labels")
        print(f"   📊 Validation: {val_img_count} images, {val_lbl_count} labels")
        print(f"   🏷️  Classes: {dataset_config['nc']} ({len(self.target_classes)} expected)")
        
        if train_img_count < 10:
            print("⚠️  Warning: Very few training images. Consider collecting more data.")
        
        return dataset_config
    
    def train_norwegian_package_detector(self, epochs: int = 200, batch: int = 8, resume: bool = False):
        """Train YOLOv8x for Norwegian package detection"""
        print("🚀 Starting Norwegian package detection training...")
        
        # Validate dataset first
        dataset_config = self.validate_dataset()
        
        # Load base YOLOv8x model
        if resume and (self.output_dir / "last.pt").exists():
            print("🔄 Resuming training from last checkpoint...")
            model = YOLO(str(self.output_dir / "last.pt"))
        else:
            print("📥 Loading base YOLOv8x model...")
            model = YOLO('yolov8x.pt')\n        \n        # Create output directory\n        self.output_dir.mkdir(parents=True, exist_ok=True)
        \n        # Training parameters optimized for Norwegian package detection
        training_args = {\n            # Dataset\n            'data': str(self.dataset_path / "dataset.yaml"),\n            \n            # Training parameters\n            'epochs': epochs,\n            'batch': batch,\n            'imgsz': 640,  # Standard YOLO input size\n            \n            # Learning parameters - tuned for package detection\n            'lr0': 0.001,      # Lower learning rate for fine-tuning\n            'lrf': 0.01,       # Final learning rate\n            'momentum': 0.937, # Good momentum for fine-tuning\n            'weight_decay': 0.0005,  # Prevent overfitting\n            'warmup_epochs': 5,      # Warm-up epochs\n            'warmup_momentum': 0.8,  # Warm-up momentum\n            'warmup_bias_lr': 0.1,   # Warm-up bias learning rate\n            \n            # Augmentation - reduced for iPhone photos of packages\n            'hsv_h': 0.015,    # Slight hue shift (outdoor/indoor lighting)\n            'hsv_s': 0.6,      # Saturation augmentation \n            'hsv_v': 0.4,      # Value/brightness augmentation\n            'degrees': 3.0,    # Small rotation (packages usually upright)\n            'translate': 0.05, # Small translation\n            'scale': 0.15,     # Small scaling variation\n            'shear': 1.0,      # Minimal shear\n            'perspective': 0.0, # No perspective for package photos\n            'flipud': 0.0,     # No vertical flip (packages have orientation)\n            'fliplr': 0.5,     # Horizontal flip OK\n            'mosaic': 0.9,     # Mosaic augmentation (good for detection)\n            'mixup': 0.1,      # Light mixup\n            'copy_paste': 0.1, # Copy-paste augmentation\n            \n            # Model optimization\n            'name': 'norwegian_package_detector',\n            'project': str(self.output_dir.parent),\n            \n            # Validation and monitoring\n            'val': True,\n            'patience': 30,    # Early stopping patience\n            'save_period': 10, # Save every 10 epochs\n            \n            # Hardware optimization\n            'device': self.device,\n            'workers': min(8, os.cpu_count()),  # Use available CPU cores\n            'single_cls': False,  # Multi-class detection\n            \n            # Optimization for deployment\n            'optimize': True,   # Optimize for inference\n            'half': True,       # Use FP16 precision\n            \n            # Logging and visualization\n            'verbose': True,\n            'plots': True,\n            'save_txt': True,   # Save predictions in txt format\n            'save_conf': True,  # Save confidences in txt files\n        }\n        \n        print("🎯 Training configuration:\")\n        print(f\"   📊 Epochs: {epochs}\")\n        print(f\"   🔢 Batch size: {batch}\")\n        print(f\"   🏷️  Classes: {len(self.target_classes)}\")\n        print(f\"   ⚡ Device: {self.device}\")\n        \n        # Start training\n        start_time = time.time()\n        try:\n            results = model.train(**training_args)\n            training_time = time.time() - start_time\n            \n            print(f\"✅ Training completed in {training_time/3600:.1f} hours\")\n            \n            # Export model for iPhone deployment\n            self.export_for_iphone(model, results)\n            \n            # Generate training summary\n            self.generate_training_summary(results, training_time, training_args)\n            \n            return results\n            \n        except Exception as e:\n            print(f\"❌ Training failed: {e}\")\n            raise\n    \n    def export_for_iphone(self, model, training_results):\n        \"\"\"Export trained model optimized for iPhone Core ML\"\"\"\n        print(\"📱 Exporting model for iPhone deployment...\")\n        \n        try:\n            # Export to Core ML with iPhone optimizations\n            export_path = model.export(\n                format='coreml',\n                optimize=True,       # Enable Core ML optimizations\n                int8=False,         # Keep FP16 for accuracy on iPhone Neural Engine\n                dynamic=False,      # Fixed input size for better performance\n                simplify=True,      # Simplify model graph\n                half=True,          # Use FP16 precision\n                imgsz=640,         # Fixed image size\n                keras=False,       # Don't use Keras backend\n                opset=12,          # ONNX opset version\n            )\n            \n            if export_path:\n                print(f\"✅ Model exported to: {export_path}\")\n                \n                # Create model metadata for the app\n                self.create_model_metadata(export_path, training_results)\n                \n                return export_path\n            else:\n                print(\"❌ Export failed\")\n                return None\n                \n        except Exception as e:\n            print(f\"❌ Export error: {e}\")\n            return None\n    \n    def create_model_metadata(self, model_path, training_results):\n        \"\"\"Create metadata file for the custom model\"\"\"\n        \n        # Extract metrics from training results\n        if hasattr(training_results, 'results_dict'):\n            metrics = training_results.results_dict\n            final_map50 = metrics.get('metrics/mAP50(B)', 0.0)\n            final_map50_95 = metrics.get('metrics/mAP50-95(B)', 0.0)\n        else:\n            final_map50 = 0.0\n            final_map50_95 = 0.0\n        \n        metadata = {\n            \"version\": \"v1.0_norwegian_packages\",\n            \"classNames\": self.target_classes,\n            \"trainingDate\": datetime.now().isoformat(),\n            \"modelType\": \"YOLOv8x\",\n            \"inputSize\": [640, 640],\n            \"numClasses\": len(self.target_classes),\n            \"mAP50\": float(final_map50),\n            \"mAP50_95\": float(final_map50_95),\n            \"description\": \"YOLOv8x trained for Norwegian package detection at mailboxes\",\n            \"optimizations\": [\n                \"iPhone-specific augmentations\",\n                \"Package-oriented training parameters\",\n                \"Reduced geometric distortions\",\n                \"Core ML FP16 precision\",\n                \"Neural Engine optimization\"\n            ],\n            \"training_parameters\": {\n                \"base_model\": \"yolov8x.pt\",\n                \"dataset_classes\": len(self.target_classes),\n                \"image_size\": 640,\n                \"device\": self.device\n            },\n            \"usage_notes\": [\n                \"Optimized for iPhone camera photos\",\n                \"Best performance on well-lit outdoor scenes\",\n                \"Designed for Norwegian postal/package scenarios\",\n                \"Confidence threshold 0.3-0.5 recommended\"\n            ]\n        }\n        \n        # Save metadata next to the model\n        model_dir = Path(model_path).parent\n        metadata_path = model_dir / \"norwegian_package_detector_metadata.json\"\n        \n        with open(metadata_path, 'w', encoding='utf-8') as f:\n            json.dump(metadata, f, indent=2, ensure_ascii=False)\n        \n        print(f\"📄 Model metadata saved to: {metadata_path}\")\n        \n        return metadata_path\n    \n    def generate_training_summary(self, results, training_time, training_args):\n        \"\"\"Generate a comprehensive training summary\"\"\"\n        \n        summary = f\"\"\"\n# Norwegian Package Detection Training Summary\n\n## Training Configuration\n- **Model**: YOLOv8x\n- **Dataset**: Norwegian Package Detection\n- **Classes**: {len(self.target_classes)}\n- **Training Time**: {training_time/3600:.1f} hours\n- **Device**: {self.device}\n- **Epochs**: {training_args['epochs']}\n- **Batch Size**: {training_args['batch']}\n\n## Class Mapping\n{chr(10).join(f'{i}: {name}' for i, name in enumerate(self.target_classes))}\n\n## Package Detection Score Logic\n- **1.0**: Definite package delivery (pakke + postkasse + etikett + postkasseskilt)\n- **0.8**: High confidence (etikett + postkasseskilt)\n- **0.7**: Good confidence (pakke + postkasse + postkasseskilt)\n- **0.5**: Medium confidence (pakke + etikett + postkasse OR inngangsparti)\n- **0.25**: Low confidence (pakke + postkasse OR postkasse + postkasseskilt)\n- **0.1**: Minimal evidence (pakke OR postkasse alone)\n- **0.0**: No package detected\n\n## Next Steps\n1. Test the exported Core ML model in your iPhone app\n2. Evaluate performance on real iPhone photos\n3. Collect more training data for classes with low performance\n4. Fine-tune confidence thresholds based on real-world usage\n\n## Files Generated\n- **best.pt**: Best performing model weights\n- **last.pt**: Latest model weights\n- ***.mlpackage**: Core ML model for iPhone\n- **metadata.json**: Model metadata for app integration\n\"\"\"\n        \n        summary_path = self.output_dir / \"training_summary.md\"\n        with open(summary_path, 'w', encoding='utf-8') as f:\n            f.write(summary)\n        \n        print(f\"📝 Training summary saved to: {summary_path}\")\n\ndef main():\n    \"\"\"Main training function\"\"\"\n    parser = argparse.ArgumentParser(description='Train Norwegian Package Detection YOLOv8x model')\n    parser.add_argument('--dataset', type=str, required=True,\n                       help='Path to YOLO dataset directory (containing dataset.yaml)')\n    parser.add_argument('--epochs', type=int, default=200,\n                       help='Number of training epochs (default: 200)')\n    parser.add_argument('--batch', type=int, default=8,\n                       help='Batch size (default: 8, adjust based on GPU memory)')\n    parser.add_argument('--output', type=str, default='runs/norwegian_packages',\n                       help='Output directory (default: runs/norwegian_packages)')\n    parser.add_argument('--resume', action='store_true',\n                       help='Resume training from last checkpoint')\n    \n    args = parser.parse_args()\n    \n    print(\"🇳🇴 Norwegian Package Detection Training\")\n    print(\"==========================================\")\n    \n    # Create trainer\n    trainer = NorwegianPackageYOLOTrainer(\n        dataset_path=args.dataset,\n        output_dir=args.output\n    )\n    \n    try:\n        # Start training\n        results = trainer.train_norwegian_package_detector(\n            epochs=args.epochs,\n            batch=args.batch,\n            resume=args.resume\n        )\n        \n        print(\"\\n🎉 Training completed successfully!\")\n        print(f\"📁 Results saved to: {args.output}\")\n        print(\"\\n🚀 Next steps:\")\n        print(\"1. Copy the .mlpackage file to your Xcode project\")\n        print(\"2. Update your app to use the new model\")\n        print(\"3. Test on real iPhone photos\")\n        print(\"4. Iterate based on performance\")\n        \n    except Exception as e:\n        print(f\"❌ Training failed: {e}\")\n        return 1\n    \n    return 0\n\nif __name__ == \"__main__\":\n    exit(main())"}
