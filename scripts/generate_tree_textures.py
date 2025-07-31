#!/usr/bin/env python3
"""
VoxelForge Reimagined - Tree Texture Generation Script
Generates textures specifically for all wood types in the vlf_trees mod.
"""

import os
import sys
from PIL import Image, ImageDraw
from pathlib import Path

# Configuration
TEXTURE_SIZE = 16  # Standard Minetest texture size

# Color palettes for different wood types
WOOD_PALETTES = {
    # Wood type specific palettes
    "oak_wood": {
        "base": (160, 82, 45),
        "highlight": (205, 133, 63),
        "shadow": (139, 69, 19),
        "dark": (101, 67, 33)
    },
    "oak_planks": {
        "base": (222, 184, 135),
        "highlight": (245, 222, 179),
        "shadow": (160, 82, 45),
        "dark": (139, 69, 19)
    },
    "spruce_wood": {
        "base": (139, 90, 43),
        "highlight": (160, 110, 60),
        "shadow": (101, 67, 33),
        "dark": (83, 53, 10)
    },
    "spruce_planks": {
        "base": (205, 164, 96),
        "highlight": (222, 184, 135),
        "shadow": (139, 90, 43),
        "dark": (101, 67, 33)
    },
    "birch_wood": {
        "base": (245, 245, 220),
        "highlight": (255, 255, 240),
        "shadow": (222, 184, 135),
        "dark": (160, 82, 45)
    },
    "birch_planks": {
        "base": (255, 248, 220),
        "highlight": (255, 255, 255),
        "shadow": (245, 245, 220),
        "dark": (222, 184, 135)
    },
    "jungle_wood": {
        "base": (139, 69, 19),
        "highlight": (160, 82, 45),
        "shadow": (101, 67, 33),
        "dark": (83, 53, 10)
    },
    "jungle_planks": {
        "base": (205, 133, 63),
        "highlight": (222, 184, 135),
        "shadow": (139, 69, 19),
        "dark": (101, 67, 33)
    },
    "acacia_wood": {
        "base": (186, 85, 43),
        "highlight": (205, 133, 63),
        "shadow": (139, 69, 19),
        "dark": (101, 67, 33)
    },
    "acacia_planks": {
        "base": (222, 133, 63),
        "highlight": (245, 164, 96),
        "shadow": (186, 85, 43),
        "dark": (139, 69, 19)
    },
    "dark_oak_wood": {
        "base": (83, 53, 10),
        "highlight": (101, 67, 33),
        "shadow": (64, 42, 8),
        "dark": (42, 28, 5)
    },
    "dark_oak_planks": {
        "base": (139, 69, 19),
        "highlight": (160, 82, 45),
        "shadow": (83, 53, 10),
        "dark": (64, 42, 8)
    },
    "pine_wood": {
        "base": (160, 130, 90),
        "highlight": (186, 150, 110),
        "shadow": (139, 110, 70),
        "dark": (101, 80, 50)
    },
    "pine_planks": {
        "base": (205, 175, 135),
        "highlight": (222, 195, 155),
        "shadow": (160, 130, 90),
        "dark": (139, 110, 70)
    },
    "sakura_wood": {
        "base": (205, 164, 164),
        "highlight": (222, 184, 184),
        "shadow": (186, 144, 144),
        "dark": (160, 120, 120)
    },
    "sakura_planks": {
        "base": (245, 205, 205),
        "highlight": (255, 225, 225),
        "shadow": (205, 164, 164),
        "dark": (186, 144, 144)
    },
    # Leaf color palettes
    "oak_leaves": {
        "base": (34, 139, 34),
        "highlight": (50, 205, 50),
        "shadow": (0, 100, 0),
        "dark": (0, 64, 0)
    },
    "spruce_leaves": {
        "base": (0, 100, 0),
        "highlight": (34, 139, 34),
        "shadow": (0, 64, 0),
        "dark": (0, 32, 0)
    },
    "birch_leaves": {
        "base": (50, 205, 50),
        "highlight": (124, 252, 0),
        "shadow": (34, 139, 34),
        "dark": (0, 100, 0)
    },
    "jungle_leaves": {
        "base": (0, 128, 0),
        "highlight": (34, 139, 34),
        "shadow": (0, 100, 0),
        "dark": (0, 64, 0)
    },
    "acacia_leaves": {
        "base": (107, 142, 35),
        "highlight": (154, 205, 50),
        "shadow": (85, 107, 47),
        "dark": (46, 139, 87)
    },
    "dark_oak_leaves": {
        "base": (0, 64, 0),
        "highlight": (0, 100, 0),
        "shadow": (0, 32, 0),
        "dark": (0, 16, 0)
    },
    "pine_leaves": {
        "base": (0, 100, 0),
        "highlight": (34, 139, 34),
        "shadow": (0, 64, 0),
        "dark": (0, 32, 0)
    },
    "sakura_leaves": {
        "base": (255, 182, 193),
        "highlight": (255, 192, 203),
        "shadow": (219, 112, 147),
        "dark": (199, 21, 133)
    }
}

class TreeTextureGenerator:
    def __init__(self, output_dir):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def create_base_texture(self, palette, pattern="solid"):
        """Create a base texture with the given palette and pattern."""
        img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        if pattern == "solid":
            draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=palette["base"])
        elif pattern == "wood":
            self._draw_wood_pattern(draw, palette)
        elif pattern == "planks":
            self._draw_planks_pattern(draw, palette)
        elif pattern == "leaves":
            self._draw_leaves_pattern(draw, palette)
        
        return img
    
    def _draw_wood_pattern(self, draw, palette):
        """Draw a wood log pattern with rings."""
        # Base fill
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=palette["base"])
        
        # Draw wood rings
        center = TEXTURE_SIZE // 2
        for radius in range(2, center, 2):
            draw.ellipse([center-radius, center-radius, center+radius, center+radius], 
                        outline=palette["shadow"], width=1)
        
        # Add some wood grain lines
        for i in range(0, TEXTURE_SIZE, 3):
            draw.line([(i, 0), (i, TEXTURE_SIZE-1)], fill=palette["shadow"], width=1)
    
    def _draw_planks_pattern(self, draw, palette):
        """Draw a wooden planks pattern."""
        # Base fill
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=palette["base"])
        
        # Draw plank separations
        plank_height = TEXTURE_SIZE // 4
        for i in range(1, 4):
            y = i * plank_height
            draw.line([(0, y), (TEXTURE_SIZE-1, y)], fill=palette["dark"], width=1)
        
        # Add wood grain
        for y in range(0, TEXTURE_SIZE, 2):
            for x in range(0, TEXTURE_SIZE, 4):
                draw.point((x, y), fill=palette["shadow"])
    
    def _draw_leaves_pattern(self, draw, palette):
        """Draw a leaves pattern with organic texture."""
        # Base fill
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=palette["base"])
        
        # Add organic leaf-like details
        import random
        random.seed(42)  # Consistent generation
        
        # Add highlights for leaf texture
        for _ in range(15):
            x = random.randint(0, TEXTURE_SIZE-1)
            y = random.randint(0, TEXTURE_SIZE-1)
            draw.point((x, y), fill=palette["highlight"])
        
        # Add shadows for depth
        for _ in range(10):
            x = random.randint(0, TEXTURE_SIZE-1)
            y = random.randint(0, TEXTURE_SIZE-1)
            draw.point((x, y), fill=palette["shadow"])
        
        # Add some darker spots for variation
        for _ in range(5):
            x = random.randint(0, TEXTURE_SIZE-2)
            y = random.randint(0, TEXTURE_SIZE-2)
            draw.rectangle([x, y, x+1, y+1], fill=palette["dark"])
    
    def add_shading(self, img):
        """Add basic shading to make the texture look more 3D."""
        draw = ImageDraw.Draw(img)
        
        # Add highlight on top-left
        for i in range(3):
            draw.line([(i, 0), (i, TEXTURE_SIZE-1-i)], fill=(255, 255, 255, 30))
            draw.line([(0, i), (TEXTURE_SIZE-1-i, i)], fill=(255, 255, 255, 30))
        
        # Add shadow on bottom-right
        for i in range(3):
            x = TEXTURE_SIZE - 1 - i
            y = TEXTURE_SIZE - 1 - i
            draw.line([(x, i), (x, TEXTURE_SIZE-1)], fill=(0, 0, 0, 30))
            draw.line([(i, y), (TEXTURE_SIZE-1, y)], fill=(0, 0, 0, 30))
        
        return img
    
    def generate_wood_textures(self, wood_type):
        """Generate all textures for a specific wood type."""
        print(f"Generating textures for {wood_type} wood...")
        
        # Generate log texture
        log_palette = WOOD_PALETTES.get(f"{wood_type}_wood", WOOD_PALETTES["oak_wood"])
        log_img = self.create_base_texture(log_palette, "wood")
        log_img = self.add_shading(log_img)
        log_output = self.output_dir / f"vlf_trees_{wood_type}_log.png"
        log_img.save(log_output)
        print(f"  Generated log texture: {log_output}")
        
        # Generate planks texture
        planks_palette = WOOD_PALETTES.get(f"{wood_type}_planks", WOOD_PALETTES["oak_planks"])
        planks_img = self.create_base_texture(planks_palette, "planks")
        planks_img = self.add_shading(planks_img)
        planks_output = self.output_dir / f"vlf_trees_{wood_type}_planks.png"
        planks_img.save(planks_output)
        print(f"  Generated planks texture: {planks_output}")
        
        # Generate leaves texture
        leaves_palette = WOOD_PALETTES.get(f"{wood_type}_leaves", WOOD_PALETTES["oak_leaves"])
        leaves_img = self.create_base_texture(leaves_palette, "leaves")
        leaves_img = self.add_shading(leaves_img)
        leaves_output = self.output_dir / f"vlf_trees_{wood_type}_leaves.png"
        leaves_img.save(leaves_output)
        print(f"  Generated leaves texture: {leaves_output}")
        
        # Generate stripped log texture (lighter version of log)
        stripped_palette = {
            "base": tuple(min(255, c + 20) for c in log_palette["base"]),
            "highlight": tuple(min(255, c + 20) for c in log_palette["highlight"]),
            "shadow": tuple(min(255, c + 10) for c in log_palette["shadow"]),
            "dark": tuple(min(255, c + 10) for c in log_palette["dark"])
        }
        stripped_img = self.create_base_texture(stripped_palette, "wood")
        stripped_img = self.add_shading(stripped_img)
        stripped_output = self.output_dir / f"vlf_trees_{wood_type}_log_stripped.png"
        stripped_img.save(stripped_output)
        print(f"  Generated stripped log texture: {stripped_output}")
        
        # Generate fence inventory image
        fence_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(fence_img)
        # Simple fence post representation
        draw.rectangle([6, 0, 9, 15], fill=planks_palette["base"])  # Vertical post
        draw.rectangle([2, 4, 13, 6], fill=planks_palette["base"])   # Top rail
        draw.rectangle([2, 9, 13, 11], fill=planks_palette["base"])  # Bottom rail
        # Add some shading
        draw.line([(6, 0), (6, 15)], fill=planks_palette["highlight"])
        draw.line([(9, 0), (9, 15)], fill=planks_palette["shadow"])
        fence_output = self.output_dir / f"vlf_trees_{wood_type}_fence.png"
        fence_img.save(fence_output)
        print(f"  Generated fence texture: {fence_output}")
        
        # Generate door texture
        door_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(door_img)
        # Door panel
        draw.rectangle([0, 0, 15, 15], fill=planks_palette["base"])
        # Door frame
        draw.rectangle([0, 0, 15, 1], fill=planks_palette["dark"])    # Top
        draw.rectangle([0, 14, 15, 15], fill=planks_palette["dark"])  # Bottom
        draw.rectangle([0, 0, 1, 15], fill=planks_palette["dark"])    # Left
        draw.rectangle([14, 0, 15, 15], fill=planks_palette["dark"])  # Right
        # Door handle
        draw.rectangle([12, 7, 13, 8], fill=(139, 69, 19))
        door_output = self.output_dir / f"vlf_trees_{wood_type}_door.png"
        door_img.save(door_output)
        print(f"  Generated door texture: {door_output}")
        
        # Generate door item texture (smaller version)
        door_item_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(door_item_img)
        # Smaller door representation
        draw.rectangle([4, 2, 11, 13], fill=planks_palette["base"])
        draw.rectangle([4, 2, 11, 3], fill=planks_palette["dark"])    # Top
        draw.rectangle([4, 12, 11, 13], fill=planks_palette["dark"])  # Bottom
        draw.rectangle([4, 2, 5, 13], fill=planks_palette["dark"])    # Left
        draw.rectangle([10, 2, 11, 13], fill=planks_palette["dark"])  # Right
        draw.point((9, 7), fill=(139, 69, 19))  # Handle
        door_item_output = self.output_dir / f"vlf_trees_{wood_type}_door_item.png"
        door_item_img.save(door_item_output)
        print(f"  Generated door item texture: {door_item_output}")
        
        # Generate trapdoor texture
        trapdoor_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(trapdoor_img)
        # Trapdoor panel (horizontal planks)
        draw.rectangle([0, 0, 15, 15], fill=planks_palette["base"])
        # Horizontal plank lines
        for i in range(1, 4):
            y = i * 4
            draw.line([(0, y), (15, y)], fill=planks_palette["dark"])
        # Frame
        draw.rectangle([0, 0, 15, 1], fill=planks_palette["shadow"])
        draw.rectangle([0, 14, 15, 15], fill=planks_palette["shadow"])
        draw.rectangle([0, 0, 1, 15], fill=planks_palette["shadow"])
        draw.rectangle([14, 0, 15, 15], fill=planks_palette["shadow"])
        trapdoor_output = self.output_dir / f"vlf_trees_{wood_type}_trapdoor.png"
        trapdoor_img.save(trapdoor_output)
        print(f"  Generated trapdoor texture: {trapdoor_output}")
        
        # Generate sapling texture
        sapling_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(sapling_img)
        # Simple sapling - small green plant
        draw.rectangle([7, 12, 8, 15], fill=(139, 69, 19))  # Brown stem
        draw.rectangle([6, 8, 9, 12], fill=leaves_palette["base"])  # Green top
        draw.point((5, 9), fill=leaves_palette["highlight"])
        draw.point((10, 9), fill=leaves_palette["highlight"])
        sapling_output = self.output_dir / f"vlf_trees_{wood_type}_sapling.png"
        sapling_img.save(sapling_output)
        print(f"  Generated sapling texture: {sapling_output}")

def main():
    # Get the vlf_trees texture directory
    script_dir = Path(__file__).parent
    vlf_trees_texture_dir = script_dir.parent / "mods" / "vlf_trees" / "textures"
    
    generator = TreeTextureGenerator(vlf_trees_texture_dir)
    
    print("Generating tree textures for VoxelForge Reimagined...")
    
    # Define all wood types
    wood_types = ["oak", "spruce", "birch", "jungle", "acacia", "dark_oak", "pine", "sakura"]
    
    for wood_type in wood_types:
        generator.generate_wood_textures(wood_type)
    
    print(f"\nTree texture generation complete!")
    print(f"Textures saved to: {vlf_trees_texture_dir}")

if __name__ == "__main__":
    main()