#!/usr/bin/env python3
"""
VoxelForge Reimagined - Plank Colorization Script
Takes a base plank texture and colorizes it for each wood type using proper color mapping.
"""

import os
import sys
from PIL import Image, ImageEnhance
import numpy as np
from pathlib import Path

# Realistic wood type color palettes based on actual wood characteristics
WOOD_PALETTES = {
    "oak_planks": {
        "base": (218, 165, 103),        # Classic oak honey tone
        "highlight": (242, 201, 142),   # Light oak highlights
        "shadow": (168, 124, 78),       # Medium oak shadow
        "dark": (134, 98, 62),          # Dark oak grain
        "temperature": "warm",          # Warm undertones
        "saturation": 1.1               # Slightly saturated
    },
    "spruce_planks": {
        "base": (196, 154, 108),        # Cool spruce tone
        "highlight": (218, 176, 130),   # Light spruce
        "shadow": (156, 122, 86),       # Spruce shadow
        "dark": (118, 92, 65),          # Dark spruce grain
        "temperature": "cool",          # Cool undertones
        "saturation": 0.95              # Slightly desaturated
    },
    "birch_planks": {
        "base": (248, 231, 185),        # Pale birch
        "highlight": (255, 248, 220),   # Very light birch
        "shadow": (228, 208, 165),      # Birch shadow
        "dark": (198, 178, 142),        # Birch grain
        "temperature": "neutral",       # Neutral temperature
        "saturation": 0.85              # Low saturation
    },
    "jungle_planks": {
        "base": (188, 134, 74),         # Rich jungle wood
        "highlight": (218, 164, 104),   # Jungle highlights
        "shadow": (148, 104, 54),       # Deep jungle shadow
        "dark": (118, 84, 44),          # Dark jungle grain
        "temperature": "warm",          # Warm tropical tone
        "saturation": 1.2               # More saturated
    },
    "acacia_planks": {
        "base": (208, 128, 64),         # Orange-red acacia
        "highlight": (238, 158, 94),    # Bright acacia
        "shadow": (168, 98, 44),        # Acacia shadow
        "dark": (138, 78, 34),          # Dark acacia grain
        "temperature": "warm",          # Very warm
        "saturation": 1.25              # High saturation
    },
    "dark_oak_planks": {
        "base": (101, 67, 33),          # Dark chocolate oak
        "highlight": (131, 87, 53),     # Dark oak highlights
        "shadow": (81, 54, 26),         # Very dark shadow
        "dark": (61, 40, 19),           # Almost black grain
        "temperature": "warm",          # Warm but muted
        "saturation": 1.0               # Natural saturation
    },
    "pine_planks": {
        "base": (218, 188, 138),        # Light pine
        "highlight": (238, 208, 158),   # Pale pine highlights
        "shadow": (188, 158, 108),      # Pine shadow
        "dark": (158, 128, 88),         # Pine grain
        "temperature": "cool",          # Cool pine tone
        "saturation": 0.9               # Slightly muted
    },
    "sakura_planks": {
        "base": (238, 188, 168),        # Warm pink sakura
        "highlight": (255, 218, 198),   # Light sakura
        "shadow": (208, 158, 138),      # Sakura shadow
        "dark": (178, 128, 108),        # Dark sakura grain
        "temperature": "warm",          # Warm pink undertones
        "saturation": 1.15              # Enhanced pink saturation
    }
}

class PlankColorizer:
    def __init__(self, color_dir, pattern_dir, output_dir):
        self.color_dir = Path(color_dir)
        self.pattern_dir = Path(pattern_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        if not self.color_dir.exists():
            raise FileNotFoundError(f"Color directory not found: {color_dir}")
        if not self.pattern_dir.exists():
            raise FileNotFoundError(f"Pattern directory not found: {pattern_dir}")
        
        print(f"Color directory: {self.color_dir}")
        print(f"Pattern directory: {self.pattern_dir}")
        print(f"Output directory: {self.output_dir}")
        
        # Find all images
        self.color_files, self.pattern_files = self.find_all_images()
        total_combinations = len(self.color_files) * len(self.pattern_files)
        print(f"Will generate {total_combinations} combinations")
    
    def find_all_images(self):
        """Find all color and pattern images."""
        # Supported image extensions
        image_extensions = {'.png', '.jpg', '.jpeg', '.bmp', '.tiff', '.tga'}
        
        # Get all image files from both directories
        color_files = []
        pattern_files = []
        
        for file_path in self.color_dir.iterdir():
            if file_path.suffix.lower() in image_extensions:
                color_files.append(file_path)
        
        for file_path in self.pattern_dir.iterdir():
            if file_path.suffix.lower() in image_extensions:
                pattern_files.append(file_path)
        
        print(f"  Found {len(color_files)} color images")
        print(f"  Found {len(pattern_files)} pattern images")
        
        return color_files, pattern_files
    

    
    def extract_brightest_color(self, color_image):
        """Extract the brightest color from a color image."""
        color_array = np.array(color_image)
        
        # Find the brightest pixel (highest luminance)
        rgb_array = color_array[:, :, :3]
        luminance = 0.299 * rgb_array[:, :, 0] + 0.587 * rgb_array[:, :, 1] + 0.114 * rgb_array[:, :, 2]
        
        # Find the coordinates of the brightest pixel
        max_lum_idx = np.unravel_index(np.argmax(luminance), luminance.shape)
        brightest_color = color_array[max_lum_idx][:3]  # RGB only
        
        return brightest_color
    
    def colorize_texture(self, color_image, pattern_image):
        """Colorize using color image and greyscale pattern."""
        
        # Extract the brightest color from the color image
        brightest_color = self.extract_brightest_color(color_image)
        
        # Convert pattern image to numpy arrays
        pattern_array = np.array(pattern_image, dtype=np.float32)
        pattern_alpha = pattern_array[:, :, 3] if pattern_image.mode == 'RGBA' else None
        
        # Get greyscale values from pattern (use red channel since it should be greyscale)
        greyscale = pattern_array[:, :, 0]
        
        # Create result array
        height, width = greyscale.shape
        result_array = np.zeros((height, width, 3), dtype=np.float32)
        
        # Normalize greyscale to 0-1 range
        grey_normalized = greyscale / 255.0
        
        # Simple colorization: multiply the brightest color by the greyscale pattern
        target_color = np.array(brightest_color, dtype=np.float32)
        
        for y in range(height):
            for x in range(width):
                grey_val = grey_normalized[y, x]
                
                # Apply the greyscale pattern as a multiplier to the target color
                final_color = target_color * grey_val
                
                # Clamp values
                final_color = np.clip(final_color, 0, 255)
                result_array[y, x] = final_color
        
        # Convert back to uint8
        result_array = result_array.astype(np.uint8)
        
        # Convert to PIL Image
        result_image = Image.fromarray(result_array, 'RGB')
        
        # Convert to RGBA and restore alpha channel
        result_rgba = result_image.convert('RGBA')
        if pattern_alpha is not None:
            alpha_channel = Image.fromarray(pattern_alpha.astype(np.uint8), 'L')
            result_rgba.putalpha(alpha_channel)
        
        return result_rgba
    
    def apply_color_temperature(self, color, temperature):
        """Apply color temperature adjustment to a color."""
        r, g, b = color
        
        if temperature == "warm":
            # Increase red, slightly decrease blue
            r = min(255, r * 1.05)
            g = min(255, g * 1.02)
            b = min(255, b * 0.95)
        elif temperature == "cool":
            # Decrease red, increase blue
            r = min(255, r * 0.95)
            g = min(255, g * 0.98)
            b = min(255, b * 1.05)
        # neutral temperature = no change
        
        return (int(r), int(g), int(b))
    

    
    def generate_all_combinations(self):
        """Generate all combinations of color and pattern images."""
        if not self.color_files or not self.pattern_files:
            print("No images found!")
            return
        
        print(f"\nProcessing all combinations...")
        
        output_counter = 1
        total_combinations = len(self.color_files) * len(self.pattern_files)
        
        for color_path in self.color_files:
            for pattern_path in self.pattern_files:
                print(f"Processing combination {output_counter}/{total_combinations}")
                print(f"  Color: {color_path.name}")
                print(f"  Pattern: {pattern_path.name}")
                
                try:
                    # Load the images
                    color_image = Image.open(color_path).convert('RGBA')
                    pattern_image = Image.open(pattern_path).convert('RGBA')
                    
                    # Ensure both images are the same size
                    if color_image.size != pattern_image.size:
                        print(f"  Resizing color image to match pattern size: {pattern_image.size}")
                        color_image = color_image.resize(pattern_image.size, Image.LANCZOS)
                    
                    # Colorize the texture
                    colorized_texture = self.colorize_texture(color_image, pattern_image)
                    
                    # Save with simple numbered filename
                    output_filename = f"{output_counter}.png"
                    output_path = self.output_dir / output_filename
                    
                    colorized_texture.save(output_path)
                    print(f"  Saved: {output_filename}")
                    
                    output_counter += 1
                    
                except Exception as e:
                    print(f"  Error processing combination: {e}")
                    output_counter += 1  # Still increment counter to maintain numbering
                    continue
        
        print(f"\nColorization complete!")
        print(f"Generated {output_counter - 1} combinations in: {self.output_dir}")
        print(f"Color images: {len(self.color_files)}")
        print(f"Pattern images: {len(self.pattern_files)}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Directory-Based Plank Colorization Script')
    parser.add_argument('color_dir', type=str,
                       help='Directory containing solid color images')
    parser.add_argument('pattern_dir', type=str,
                       help='Directory containing greyscale pattern/texture images')
    parser.add_argument('output_dir', type=str,
                       help='Output directory for colorized textures')
    
    args = parser.parse_args()
    
    # Get paths
    color_dir = Path(args.color_dir)
    pattern_dir = Path(args.pattern_dir)
    output_dir = Path(args.output_dir)
    
    try:
        colorizer = PlankColorizer(color_dir, pattern_dir, output_dir)
        colorizer.generate_all_combinations()
        
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("Make sure both directories exist:")
        print(f"  Color directory: {color_dir}")
        print(f"  Pattern directory: {pattern_dir}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()