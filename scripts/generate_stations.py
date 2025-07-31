#!/usr/bin/env python3
"""
VoxelForge Reimagined - Crafting Station Texture Generator
Generates textures for crafting tables, forges, and cooking stoves.
"""

from PIL import Image, ImageDraw
from pathlib import Path
import sys

# Add the parent directory to path to import from generate_textures
sys.path.append(str(Path(__file__).parent))
from generate_textures import TextureGenerator, COLOR_PALETTES, TEXTURE_SIZE

class StationGenerator(TextureGenerator):
    def __init__(self):
        super().__init__()
        self.stations_dir = self.ensure_stations_dir()
    
    def ensure_stations_dir(self):
        """Create stations directory."""
        stations_dir = Path(__file__).parent.parent / "textures" / "stations"
        stations_dir.mkdir(parents=True, exist_ok=True)
        return stations_dir
    
    def generate_crafting_table(self):
        """Generate crafting table textures (top, side, front)."""
        # Top texture - with crafting grid
        top_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(top_img)
        
        # Wood base
        palette = COLOR_PALETTES["planks"]
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=palette["base"])
        
        # Add wood grain
        for y in range(0, TEXTURE_SIZE, 2):
            for x in range(0, TEXTURE_SIZE, 4):
                draw.point((x, y), fill=palette["shadow"])
        
        # Draw crafting grid (3x3)
        grid_start = 2
        grid_size = TEXTURE_SIZE - 4
        cell_size = grid_size // 3
        
        for i in range(4):  # 4 lines for 3x3 grid
            x = grid_start + i * cell_size
            y = grid_start + i * cell_size
            # Vertical lines
            if x < TEXTURE_SIZE:
                draw.line([(x, grid_start), (x, grid_start + grid_size)], fill=palette["dark"], width=1)
            # Horizontal lines
            if y < TEXTURE_SIZE:
                draw.line([(grid_start, y), (grid_start + grid_size, y)], fill=palette["dark"], width=1)
        
        self.add_shading(top_img)
        top_path = self.stations_dir / "voxelforge_crafting_table_top.png"
        top_img.save(top_path)
        print(f"Generated crafting table top: {top_path}")
        
        # Side texture - plain wood
        side_img = self.create_base_texture(palette, "planks")
        self.add_shading(side_img)
        side_path = self.stations_dir / "voxelforge_crafting_table_side.png"
        side_img.save(side_path)
        print(f"Generated crafting table side: {side_path}")
        
        return top_path, side_path
    
    def generate_forge(self):
        """Generate forge textures."""
        # Forge base - stone with metal elements
        forge_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(forge_img)
        
        # Stone base
        stone_palette = COLOR_PALETTES["stone"]
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=stone_palette["base"])
        
        # Add stone texture
        import random
        random.seed(42)
        for _ in range(15):
            x = random.randint(0, TEXTURE_SIZE-2)
            y = random.randint(0, TEXTURE_SIZE-2)
            color = random.choice([stone_palette["highlight"], stone_palette["shadow"]])
            draw.point((x, y), fill=color)
        
        # Add metal reinforcements
        iron_palette = COLOR_PALETTES["iron"]
        # Corner reinforcements
        for corner in [(0, 0), (TEXTURE_SIZE-3, 0), (0, TEXTURE_SIZE-3), (TEXTURE_SIZE-3, TEXTURE_SIZE-3)]:
            draw.rectangle([corner[0], corner[1], corner[0]+2, corner[1]+2], fill=iron_palette["base"])
        
        # Central anvil area
        center = TEXTURE_SIZE // 2
        draw.rectangle([center-2, center-2, center+2, center+2], fill=iron_palette["base"])
        draw.rectangle([center-1, center-1, center+1, center+1], fill=iron_palette["highlight"])
        
        self.add_shading(forge_img)
        forge_path = self.stations_dir / "voxelforge_forge.png"
        forge_img.save(forge_path)
        print(f"Generated forge: {forge_path}")
        
        # Forge front with opening
        forge_front_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(forge_front_img)
        
        # Stone base
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=stone_palette["base"])
        
        # Forge opening
        opening_y = TEXTURE_SIZE // 3
        opening_height = TEXTURE_SIZE // 3
        draw.rectangle([2, opening_y, TEXTURE_SIZE-3, opening_y + opening_height], fill=(20, 20, 20))
        
        # Fire glow effect
        draw.rectangle([3, opening_y+1, TEXTURE_SIZE-4, opening_y + opening_height-1], fill=(139, 69, 19))
        draw.rectangle([4, opening_y+2, TEXTURE_SIZE-5, opening_y + opening_height-2], fill=(255, 140, 0))
        
        self.add_shading(forge_front_img)
        forge_front_path = self.stations_dir / "voxelforge_forge_front.png"
        forge_front_img.save(forge_front_path)
        print(f"Generated forge front: {forge_front_path}")
        
        return forge_path, forge_front_path
    
    def generate_cooking_stove(self):
        """Generate cooking stove textures."""
        # Stove top
        stove_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(stove_img)
        
        # Iron base
        iron_palette = COLOR_PALETTES["iron"]
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=iron_palette["base"])
        
        # Cooking surface with burners
        burner_size = 4
        burner_positions = [
            (2, 2),
            (TEXTURE_SIZE-6, 2),
            (2, TEXTURE_SIZE-6),
            (TEXTURE_SIZE-6, TEXTURE_SIZE-6)
        ]
        
        for pos in burner_positions:
            # Burner ring
            draw.ellipse([pos[0], pos[1], pos[0]+burner_size, pos[1]+burner_size], 
                        fill=iron_palette["dark"])
            # Inner burner
            draw.ellipse([pos[0]+1, pos[1]+1, pos[0]+burner_size-1, pos[1]+burner_size-1], 
                        fill=(64, 64, 64))
        
        # Central control area
        center = TEXTURE_SIZE // 2
        draw.rectangle([center-1, center-1, center+1, center+1], fill=iron_palette["highlight"])
        
        self.add_shading(stove_img)
        stove_path = self.stations_dir / "voxelforge_cooking_stove_top.png"
        stove_img.save(stove_path)
        print(f"Generated cooking stove top: {stove_path}")
        
        # Stove front
        stove_front_img = Image.new('RGBA', (TEXTURE_SIZE, TEXTURE_SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(stove_front_img)
        
        # Iron base
        draw.rectangle([0, 0, TEXTURE_SIZE-1, TEXTURE_SIZE-1], fill=iron_palette["base"])
        
        # Oven door
        door_margin = 2
        draw.rectangle([door_margin, door_margin, TEXTURE_SIZE-door_margin-1, TEXTURE_SIZE-door_margin-1], 
                      fill=iron_palette["shadow"])
        
        # Door handle
        handle_x = TEXTURE_SIZE - 4
        handle_y = TEXTURE_SIZE // 2
        draw.rectangle([handle_x, handle_y-1, handle_x+1, handle_y+1], fill=iron_palette["highlight"])
        
        # Door window
        window_margin = 4
        draw.rectangle([window_margin, window_margin, TEXTURE_SIZE//2, TEXTURE_SIZE//2], 
                      fill=(40, 40, 40))
        
        self.add_shading(stove_front_img)
        stove_front_path = self.stations_dir / "voxelforge_cooking_stove_front.png"
        stove_front_img.save(stove_front_path)
        print(f"Generated cooking stove front: {stove_front_path}")
        
        return stove_path, stove_front_path

def generate_all_stations():
    """Generate all crafting station textures."""
    generator = StationGenerator()
    
    print("Generating crafting station textures...")
    
    # Generate all stations
    generator.generate_crafting_table()
    generator.generate_forge()
    generator.generate_cooking_stove()
    
    print(f"\nStation texture generation complete!")
    print(f"Textures saved to: {generator.stations_dir}")

if __name__ == "__main__":
    generate_all_stations()