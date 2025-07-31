#!/usr/bin/env python3
"""
Generate GUI textures for VoxelForge Reimagined cooking interface
"""

from PIL import Image, ImageDraw
from pathlib import Path

def create_fire_textures():
    """Create fire background and foreground textures for cooking stove."""
    
    # Fire background (empty)
    fire_bg = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    draw_bg = ImageDraw.Draw(fire_bg)
    
    # Draw fire container outline
    draw_bg.rectangle([2, 2, 13, 13], outline=(100, 100, 100, 255), width=1)
    
    # Fire foreground (flames)
    fire_fg = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(fire_fg)
    
    # Draw flames
    flame_colors = [
        (255, 100, 0, 255),  # Orange
        (255, 150, 0, 255),  # Light orange
        (255, 200, 0, 255),  # Yellow-orange
        (255, 255, 0, 255),  # Yellow
    ]
    
    # Bottom flame base
    draw_fg.rectangle([4, 10, 11, 12], fill=flame_colors[0])
    
    # Middle flames
    draw_fg.rectangle([3, 8, 5, 10], fill=flame_colors[1])
    draw_fg.rectangle([6, 7, 9, 10], fill=flame_colors[2])
    draw_fg.rectangle([10, 8, 12, 10], fill=flame_colors[1])
    
    # Top flame tips
    draw_fg.rectangle([5, 5, 6, 7], fill=flame_colors[3])
    draw_fg.rectangle([7, 4, 8, 7], fill=flame_colors[3])
    draw_fg.rectangle([9, 5, 10, 7], fill=flame_colors[3])
    
    return fire_bg, fire_fg

def create_arrow_textures():
    """Create cooking progress arrow textures."""
    
    # Arrow background (empty)
    arrow_bg = Image.new('RGBA', (24, 16), (0, 0, 0, 0))
    draw_bg = ImageDraw.Draw(arrow_bg)
    
    # Draw arrow outline
    arrow_points = [(2, 8), (18, 8), (18, 5), (22, 8), (18, 11), (18, 8)]
    draw_bg.polygon(arrow_points, outline=(100, 100, 100, 255), width=1)
    
    # Arrow foreground (filled)
    arrow_fg = Image.new('RGBA', (24, 16), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(arrow_fg)
    
    # Draw filled arrow
    draw_fg.polygon(arrow_points, fill=(0, 200, 0, 255), outline=(0, 150, 0, 255))
    
    return arrow_bg, arrow_fg

def generate_gui_textures():
    """Generate all GUI textures for cooking interface."""
    
    base_dir = Path(__file__).parent.parent
    textures_dir = base_dir / "textures" / "gui"
    textures_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate fire textures
    fire_bg, fire_fg = create_fire_textures()
    
    fire_bg_path = textures_dir / "voxelforge_fire_bg.png"
    fire_fg_path = textures_dir / "voxelforge_fire_fg.png"
    
    fire_bg.save(fire_bg_path)
    fire_fg.save(fire_fg_path)
    
    print(f"Generated fire background: {fire_bg_path}")
    print(f"Generated fire foreground: {fire_fg_path}")
    
    # Generate arrow textures
    arrow_bg, arrow_fg = create_arrow_textures()
    
    arrow_bg_path = textures_dir / "gui_furnace_arrow_bg.png"
    arrow_fg_path = textures_dir / "gui_furnace_arrow_fg.png"
    
    arrow_bg.save(arrow_bg_path)
    arrow_fg.save(arrow_fg_path)
    
    print(f"Generated arrow background: {arrow_bg_path}")
    print(f"Generated arrow foreground: {arrow_fg_path}")
    
    print("\nGUI texture generation complete!")

if __name__ == "__main__":
    generate_gui_textures()