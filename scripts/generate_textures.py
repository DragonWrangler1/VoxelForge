#!/usr/bin/env python3
"""
VoxelForge Reimagined - Texture Generation Script
Generates pixel art textures for blocks and items according to Phase 1 roadmap.
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFilter
import json
from pathlib import Path
import argparse

# Configuration
TEXTURE_SIZE = 16  # Standard Minetest texture size
OUTPUT_DIR = Path(__file__).parent.parent / "textures"
BLOCKS_DIR = OUTPUT_DIR / "blocks"
ITEMS_DIR = OUTPUT_DIR / "items"

# Color palettes for different material types
COLOR_PALETTES = {
    "stone": {
        "base": (120, 120, 120),
        "highlight": (140, 140, 140),
        "shadow": (80, 80, 80),
        "dark": (60, 60, 60)
    },
    "dirt": {
        "base": (139, 69, 19),
        "highlight": (160, 82, 45),
        "shadow": (101, 67, 33),
        "dark": (83, 53, 10)
    },
    "wood": {
        "base": (160, 82, 45),
        "highlight": (205, 133, 63),
        "shadow": (139, 69, 19),
        "dark": (101, 67, 33)
    },
    "planks": {
        "base": (222, 184, 135),
        "highlight": (245, 222, 179),
        "shadow": (160, 82, 45),
        "dark": (139, 69, 19)
    },
    "iron": {
        "base": (169, 169, 169),
        "highlight": (211, 211, 211),
        "shadow": (105, 105, 105),
        "dark": (64, 64, 64)
    },
    "copper": {
        "base": (184, 115, 51),
        "highlight": (205, 127, 50),
        "shadow": (139, 69, 19),
        "dark": (101, 67, 33)
    },
    "coal": {
        "base": (64, 64, 64),
        "highlight": (105, 105, 105),
        "shadow": (47, 47, 47),
        "dark": (25, 25, 25)
    },
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

class TextureGenerator:
    def __init__(self):
        self.ensure_directories()
    
    def ensure_directories(self):
        """Create necessary directories if they don't exist."""
        BLOCKS_DIR.mkdir(parents=True, exist_ok=True)
        ITEMS_DIR.mkdir(parents=True, exist_ok=True)
    
    def create_base_texture(self, palette, pattern="solid"):
        """Create a base texture with the given palette and pattern."""
        img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        if pattern == "solid":
            draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=palette["base"])
        elif pattern == "stone":
            self._draw_stone_pattern(draw, palette)
        elif pattern == "wood":
            self._draw_wood_pattern(draw, palette)
        elif pattern == "planks":
            self._draw_planks_pattern(draw, palette)
        elif pattern == "ore":
            self._draw_ore_pattern(draw, palette)
        elif pattern == "leaves":
            self._draw_leaves_pattern(draw, palette)
        
        return img
    
    def _draw_stone_pattern(self, draw, palette):
        """Draw a stone-like pattern."""
        # Base fill
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=palette["base"])
        
        # Add some random stone-like details
        import random
        random.seed(42)  # Consistent generation
        
        for _ in range(20):
            x = random.randint(0, TEXTURE_SIZE-2)
            y = random.randint(0, TEXTURE_SIZE-2)
            color = random.choice([palette["highlight"], palette["shadow"]])
            draw.point((x, y), fill=color)
        
        # Add some cracks
        for _ in range(3):
            x1 = random.randint(0, TEXTURE_SIZE-1)
            y1 = random.randint(0, TEXTURE_SIZE-1)
            x2 = x1 + random.randint(-3, 3)
            y2 = y1 + random.randint(-3, 3)
            if 0 <= x2 < TEXTURE_SIZE and 0 <= y2 < TEXTURE_SIZE:
                draw.line([(x1, y1), (x2, y2)], fill=palette["dark"], width=1)
    
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
    
    def _draw_ore_pattern(self, draw, palette):
        """Draw an ore pattern with mineral veins."""
        # Base stone
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=COLOR_PALETTES["stone"]["base"])
        
        # Add ore veins
        import random
        random.seed(42)
        
        for _ in range(8):
            x = random.randint(0, TEXTURE_SIZE-1)
            y = random.randint(0, TEXTURE_SIZE-1)
            size = random.randint(1, 3)
            draw.ellipse([x-size//2, y-size//2, x+size//2, y+size//2], fill=palette["base"])
    
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
    
    def generate_block_texture(self, name, material_type, pattern=None):
        """Generate a block texture."""
        if pattern is None:
            pattern = material_type
        
        palette = COLOR_PALETTES.get(material_type, COLOR_PALETTES["stone"])
        img = self.create_base_texture(palette, pattern)
        img = self.add_shading(img)
        
        output_path = BLOCKS_DIR / f"voxelforge_{name}.png"
        img.save(output_path)
        print(f"Generated block texture: {output_path}")
        return output_path
    
    def generate_item_texture(self, name, material_type, item_type="tool"):
        """Generate an item texture."""
        palette = COLOR_PALETTES.get(material_type, COLOR_PALETTES["stone"])
        img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        if item_type == "tool":
            self._draw_tool(draw, palette, name)
        elif item_type == "ingot":
            self._draw_ingot(draw, palette)
        elif item_type == "ore_lump":
            self._draw_ore_lump(draw, palette)
        
        output_path = ITEMS_DIR / f"voxelforge_{name}.png"
        img.save(output_path)
        print(f"Generated item texture: {output_path}")
        return output_path
    
    def _draw_tool(self, draw, palette, tool_name):
        """Draw a tool shape."""
        if "pick" in tool_name:
            # Pickaxe shape
            # Handle
            draw.rectangle([7, 10, 8, 15], fill=(139, 69, 19))  # Brown handle
            # Head
            draw.rectangle([4, 6, 11, 9], fill=palette["base"])
            draw.rectangle([2, 7, 4, 8], fill=palette["base"])  # Left point
            draw.rectangle([11, 7, 13, 8], fill=palette["base"])  # Right point
        elif "axe" in tool_name:
            # Axe shape
            # Handle
            draw.rectangle([7, 8, 8, 15], fill=(139, 69, 19))
            # Head
            draw.rectangle([5, 5, 10, 8], fill=palette["base"])
            draw.rectangle([3, 6, 5, 7], fill=palette["base"])  # Blade
        elif "shovel" in tool_name:
            # Shovel shape
            # Handle
            draw.rectangle([7, 8, 8, 15], fill=(139, 69, 19))
            # Head
            draw.rectangle([6, 4, 9, 8], fill=palette["base"])
        elif "sword" in tool_name:
            # Sword shape
            # Handle
            draw.rectangle([7, 12, 8, 15], fill=(139, 69, 19))
            # Guard
            draw.rectangle([5, 11, 10, 12], fill=palette["shadow"])
            # Blade
            draw.rectangle([7, 2, 8, 11], fill=palette["base"])
            draw.rectangle([6, 3, 9, 4], fill=palette["base"])  # Tip
    
    def _draw_ingot(self, draw, palette):
        """Draw an ingot shape."""
        # Main ingot body
        draw.rectangle([3, 6, 12, 10], fill=palette["base"])
        # Highlight
        draw.line([(3, 6), (12, 6)], fill=palette["highlight"])
        draw.line([(3, 6), (3, 10)], fill=palette["highlight"])
        # Shadow
        draw.line([(3, 10), (12, 10)], fill=palette["shadow"])
        draw.line([(12, 6), (12, 10)], fill=palette["shadow"])
    
    def _draw_ore_lump(self, draw, palette):
        """Draw an ore lump shape."""
        # Irregular lump shape
        points = [(4, 8), (6, 5), (10, 6), (12, 9), (10, 12), (6, 11)]
        draw.polygon(points, fill=palette["base"])
        # Add some highlights
        draw.point((6, 7), fill=palette["highlight"])
        draw.point((9, 8), fill=palette["highlight"])

def generate_tree_textures():
    """Generate all tree-related textures."""
    generator = TextureGenerator()
    
    print("Generating tree textures for VoxelForge Reimagined...")
    
    # Create vlf_trees texture directory
    vlf_trees_texture_dir = Path(__file__).parent.parent / "mods" / "vlf_trees" / "textures"
    vlf_trees_texture_dir.mkdir(parents=True, exist_ok=True)
    
    # Define all wood types
    wood_types = ["oak", "spruce", "birch", "jungle", "acacia", "dark_oak", "pine", "sakura"]
    
    for wood_type in wood_types:
        # Generate log texture
        log_palette = COLOR_PALETTES.get(f"{wood_type}_wood", COLOR_PALETTES["wood"])
        log_img = generator.create_base_texture(log_palette, "wood")
        log_img = generator.add_shading(log_img)
        log_output = vlf_trees_texture_dir / f"vlf_trees_{wood_type}_log.png"
        log_img.save(log_output)
        print(f"Generated log texture: {log_output}")
        
        # Generate planks texture
        planks_palette = COLOR_PALETTES.get(f"{wood_type}_planks", COLOR_PALETTES["planks"])
        planks_img = generator.create_base_texture(planks_palette, "planks")
        planks_img = generator.add_shading(planks_img)
        planks_output = vlf_trees_texture_dir / f"vlf_trees_{wood_type}_planks.png"
        planks_img.save(planks_output)
        print(f"Generated planks texture: {planks_output}")
        
        # Generate leaves texture
        leaves_palette = COLOR_PALETTES.get(f"{wood_type}_leaves", COLOR_PALETTES["oak_leaves"])
        leaves_img = generator.create_base_texture(leaves_palette, "leaves")
        leaves_img = generator.add_shading(leaves_img)
        leaves_output = vlf_trees_texture_dir / f"vlf_trees_{wood_type}_leaves.png"
        leaves_img.save(leaves_output)
        print(f"Generated leaves texture: {leaves_output}")
        
        # Generate sapling texture (simplified for now)
        sapling_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(sapling_img)
        # Simple sapling - small green plant
        draw.rectangle([7, 12, 8, 15], fill=(139, 69, 19))  # Brown stem
        draw.rectangle([6, 8, 9, 12], fill=leaves_palette["base"])  # Green top
        draw.point((5, 9), fill=leaves_palette["highlight"])
        draw.point((10, 9), fill=leaves_palette["highlight"])
        sapling_output = vlf_trees_texture_dir / f"vlf_trees_{wood_type}_sapling.png"
        sapling_img.save(sapling_output)
        print(f"Generated sapling texture: {sapling_output}")

def generate_phase1_textures():
    """Generate all textures needed for Phase 1 of the roadmap."""
    generator = TextureGenerator()
    
    print("Generating Phase 1 textures for VoxelForge Reimagined...")
    
    # Terrain blocks
    blocks = [
        ("stone", "stone", "stone"),
        ("dirt", "dirt", "solid"),
        ("wood", "wood", "wood"),
        ("planks", "planks", "planks"),
        ("iron_ore", "iron", "ore"),
        ("copper_ore", "copper", "ore"),
        ("coal_ore", "coal", "ore"),
    ]
    
    for name, material, pattern in blocks:
        generator.generate_block_texture(name, material, pattern)
    
    # Generate tree textures
    generate_tree_textures()
    
    # Tools and items
    tools = [
        ("wooden_pickaxe", "wood", "tool"),
        ("wooden_axe", "wood", "tool"),
        ("wooden_shovel", "wood", "tool"),
        ("wooden_sword", "wood", "tool"),
        ("stone_pickaxe", "stone", "tool"),
        ("stone_axe", "stone", "tool"),
        ("stone_shovel", "stone", "tool"),
        ("stone_sword", "stone", "tool"),
        ("iron_pickaxe", "iron", "tool"),
        ("iron_axe", "iron", "tool"),
        ("iron_shovel", "iron", "tool"),
        ("iron_sword", "iron", "tool"),
    ]
    
    for name, material, item_type in tools:
        generator.generate_item_texture(name, material, item_type)
    
    # Ingots and lumps
    materials = [
        ("iron_ingot", "iron", "ingot"),
        ("copper_ingot", "copper", "ingot"),
        ("iron_lump", "iron", "ore_lump"),
        ("copper_lump", "copper", "ore_lump"),
        ("coal_lump", "coal", "ore_lump"),
    ]
    
    for name, material, item_type in materials:
        generator.generate_item_texture(name, material, item_type)
    
    print(f"\nTexture generation complete!")
    print(f"Block textures saved to: {BLOCKS_DIR}")
    print(f"Item textures saved to: {ITEMS_DIR}")

def main():
    parser = argparse.ArgumentParser(description="Generate pixel art textures for VoxelForge Reimagined")
    parser.add_argument("--phase", type=int, default=1, help="Roadmap phase to generate textures for")
    parser.add_argument("--output", type=str, help="Custom output directory")
    
    args = parser.parse_args()
    
    if args.output:
        global OUTPUT_DIR, BLOCKS_DIR, ITEMS_DIR
        OUTPUT_DIR = Path(args.output)
        BLOCKS_DIR = OUTPUT_DIR / "blocks"
        ITEMS_DIR = OUTPUT_DIR / "items"
    
    if args.phase == 1:
        generate_phase1_textures()
    else:
        print(f"Phase {args.phase} texture generation not yet implemented.")

if __name__ == "__main__":
    main()