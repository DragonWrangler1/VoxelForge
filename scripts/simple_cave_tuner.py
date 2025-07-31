#!/usr/bin/env python3
"""
Simple VoxelForge Cave Generation Tuner
Uses built-in random for noise simulation (no external dependencies)
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider, Button
import random
import math

class SimpleCaveTuner:
    def __init__(self):
        # Default parameters (conservative settings)
        self.params = {
            'binary_noise': {
                'spread_x': 200,
                'spread_z': 200,
                'octaves': 1,
                'persistence': 0.5,
                'seed': 12345
            },
            'cave_type_noise': {
                'spread_x': 300,
                'spread_z': 300,
                'octaves': 1,
                'persistence': 0.5,
                'seed': 54321
            },
            'cave_type_threshold': 0.0,
            'noodle_radius': {'min': 2, 'max': 4},
            'spaghetti_radius': {'min': 5, 'max': 7},
            'chunk_size': 80
        }
        
        self.setup_plot()
        self.generate_caves()
        
    def setup_plot(self):
        """Setup the matplotlib interface"""
        self.fig = plt.figure(figsize=(14, 10))
        
        # Main cave visualization
        self.ax_main = plt.subplot2grid((3, 3), (0, 0), colspan=2, rowspan=2)
        self.ax_main.set_title('Cave Generation (2D + Heightmaps)')
        self.ax_main.set_xlabel('X')
        self.ax_main.set_ylabel('Z')
        
        # Binary noise visualization
        self.ax_binary = plt.subplot2grid((3, 3), (0, 2))
        self.ax_binary.set_title('Binary Noise (-1/1)')
        
        # Cave type noise visualization
        self.ax_type = plt.subplot2grid((3, 3), (1, 2))
        self.ax_type.set_title('Cave Type Noise')
        
        # Statistics
        self.ax_stats = plt.subplot2grid((3, 3), (2, 2))
        self.ax_stats.set_title('Statistics')
        self.ax_stats.axis('off')
        
        # Sliders area
        slider_area = plt.subplot2grid((3, 3), (2, 0), colspan=2)
        slider_area.axis('off')
        
        self.create_sliders()
        self.create_buttons()
        
    def create_sliders(self):
        """Create parameter sliders"""
        slider_height = 0.03
        slider_spacing = 0.05
        left_margin = 0.1
        
        y_pos = 0.25
        self.sliders = {}
        
        # Binary noise spread
        ax_spread_x = plt.axes([left_margin, y_pos, 0.15, slider_height])
        self.sliders['spread_x'] = Slider(ax_spread_x, 'Spread X', 20, 200, 
                                         valinit=self.params['binary_noise']['spread_x'], valfmt='%d')
        
        ax_spread_z = plt.axes([left_margin + 0.2, y_pos, 0.15, slider_height])
        self.sliders['spread_z'] = Slider(ax_spread_z, 'Spread Z', 20, 200, 
                                         valinit=self.params['binary_noise']['spread_z'], valfmt='%d')
        
        # Octaves and persistence
        y_pos -= slider_spacing
        ax_octaves = plt.axes([left_margin, y_pos, 0.15, slider_height])
        self.sliders['octaves'] = Slider(ax_octaves, 'Octaves', 1, 4, 
                                        valinit=self.params['binary_noise']['octaves'], valfmt='%d')
        
        ax_persistence = plt.axes([left_margin + 0.2, y_pos, 0.15, slider_height])
        self.sliders['persistence'] = Slider(ax_persistence, 'Persistence', 0.1, 1.0, 
                                           valinit=self.params['binary_noise']['persistence'])
        
        # Cave type parameters
        y_pos -= slider_spacing
        ax_type_spread = plt.axes([left_margin, y_pos, 0.15, slider_height])
        self.sliders['type_spread'] = Slider(ax_type_spread, 'Type Spread', 50, 300, 
                                            valinit=self.params['cave_type_noise']['spread_x'], valfmt='%d')
        
        ax_type_threshold = plt.axes([left_margin + 0.2, y_pos, 0.15, slider_height])
        self.sliders['type_threshold'] = Slider(ax_type_threshold, 'Type Threshold', -1.0, 1.0, 
                                               valinit=self.params['cave_type_threshold'])
        
        # Connect sliders
        for slider in self.sliders.values():
            slider.on_changed(self.update_params)
            
    def create_buttons(self):
        """Create control buttons"""
        # Regenerate button
        ax_regen = plt.axes([0.7, 0.15, 0.1, 0.04])
        self.btn_regen = Button(ax_regen, 'Regenerate')
        self.btn_regen.on_clicked(self.regenerate)
        
        # Export button
        ax_export = plt.axes([0.82, 0.15, 0.1, 0.04])
        self.btn_export = Button(ax_export, 'Export Config')
        self.btn_export.on_clicked(self.export_config)
        
        # Preset buttons
        ax_sparse = plt.axes([0.7, 0.10, 0.1, 0.04])
        self.btn_sparse = Button(ax_sparse, 'Sparse Caves')
        self.btn_sparse.on_clicked(lambda x: self.load_preset('sparse'))
        
        ax_dense = plt.axes([0.82, 0.10, 0.1, 0.04])
        self.btn_dense = Button(ax_dense, 'Dense Caves')
        self.btn_dense.on_clicked(lambda x: self.load_preset('dense'))
    
    def simple_noise_2d(self, x, z, spread_x, spread_z, octaves, persistence, seed):
        """Simple noise function using built-in random"""
        random.seed(seed + int(x * 1000) + int(z * 1000))
        
        value = 0
        amplitude = 1
        frequency = 1
        
        for i in range(octaves):
            # Simple grid-based noise
            grid_x = int((x / spread_x) * frequency)
            grid_z = int((z / spread_z) * frequency)
            
            random.seed(seed + grid_x * 1000 + grid_z * 1000 + i * 10000)
            noise_val = random.random() * 2 - 1  # -1 to 1
            
            value += noise_val * amplitude
            amplitude *= persistence
            frequency *= 2
        
        return value
    
    def generate_binary_noise(self, size_x, size_z):
        """Generate binary noise (-1 or 1 only)"""
        binary_noise = np.zeros((size_z, size_x))
        
        for z in range(size_z):
            for x in range(size_x):
                noise_val = self.simple_noise_2d(
                    x, z,
                    self.params['binary_noise']['spread_x'],
                    self.params['binary_noise']['spread_z'],
                    self.params['binary_noise']['octaves'],
                    self.params['binary_noise']['persistence'],
                    self.params['binary_noise']['seed']
                )
                
                # Convert to binary
                binary_noise[z, x] = 1 if noise_val >= 0 else -1
                
        return binary_noise
    
    def generate_cave_type_noise(self, size_x, size_z):
        """Generate cave type noise"""
        type_noise = np.zeros((size_z, size_x))
        
        for z in range(size_z):
            for x in range(size_x):
                type_noise[z, x] = self.simple_noise_2d(
                    x, z,
                    self.params['cave_type_noise']['spread_x'],
                    self.params['cave_type_noise']['spread_z'],
                    self.params['cave_type_noise']['octaves'],
                    self.params['cave_type_noise']['persistence'],
                    self.params['cave_type_noise']['seed']
                )
                
        return type_noise
    
    def find_transitions(self, binary_noise):
        """Find transition points between -1 and 1"""
        size_z, size_x = binary_noise.shape
        transitions = np.zeros((size_z, size_x), dtype=bool)
        
        for z in range(1, size_z - 1):
            for x in range(1, size_x - 1):
                center_val = binary_noise[z, x]
                
                # Check 4 adjacent positions
                adjacent = [
                    binary_noise[z, x + 1],
                    binary_noise[z, x - 1],
                    binary_noise[z + 1, x],
                    binary_noise[z - 1, x]
                ]
                
                # If any adjacent value is different, it's a transition
                for adj_val in adjacent:
                    if adj_val != center_val:
                        transitions[z, x] = True
                        break
                        
        return transitions
    
    def generate_caves(self):
        """Generate cave positions and types"""
        size = self.params['chunk_size']
        
        # Generate noise maps
        self.binary_noise = self.generate_binary_noise(size, size)
        self.cave_type_noise = self.generate_cave_type_noise(size, size)
        
        # Find transitions
        self.transitions = self.find_transitions(self.binary_noise)
        
        # Generate caves at transition points
        self.caves = []
        transition_coords = np.where(self.transitions)
        
        random.seed(self.params['binary_noise']['seed'])
        
        for i in range(len(transition_coords[0])):
            z, x = transition_coords[0][i], transition_coords[1][i]
            
            # Determine cave type
            type_noise_val = self.cave_type_noise[z, x]
            is_spaghetti = type_noise_val > self.params['cave_type_threshold']
            
            # Determine radius
            if is_spaghetti:
                radius = random.randint(
                    self.params['spaghetti_radius']['min'],
                    self.params['spaghetti_radius']['max']
                )
                cave_type = 'spaghetti'
            else:
                radius = random.randint(
                    self.params['noodle_radius']['min'],
                    self.params['noodle_radius']['max']
                )
                cave_type = 'noodle'
            
            self.caves.append({
                'x': x, 'z': z, 'radius': radius, 'type': cave_type
            })
    
    def update_visualization(self):
        """Update all visualizations"""
        # Clear axes
        self.ax_main.clear()
        self.ax_binary.clear()
        self.ax_type.clear()
        self.ax_stats.clear()
        
        # Binary noise
        self.ax_binary.imshow(self.binary_noise, cmap='RdBu', vmin=-1, vmax=1)
        self.ax_binary.set_title('Binary Noise (-1/1)')
        
        # Cave type noise
        self.ax_type.imshow(self.cave_type_noise, cmap='viridis')
        self.ax_type.set_title('Cave Type Noise')
        
        # Main cave visualization
        self.ax_main.imshow(self.binary_noise, cmap='RdBu', alpha=0.3, vmin=-1, vmax=1)
        
        # Draw caves
        noodle_count = 0
        spaghetti_count = 0
        
        for cave in self.caves:
            color = 'red' if cave['type'] == 'spaghetti' else 'blue'
            circle = plt.Circle((cave['x'], cave['z']), cave['radius'], 
                              color=color, alpha=0.7, fill=False, linewidth=2)
            self.ax_main.add_patch(circle)
            
            if cave['type'] == 'spaghetti':
                spaghetti_count += 1
            else:
                noodle_count += 1
        
        self.ax_main.set_xlim(0, self.params['chunk_size'])
        self.ax_main.set_ylim(0, self.params['chunk_size'])
        self.ax_main.set_title('Cave Generation (2D + Heightmaps)')
        self.ax_main.set_xlabel('X')
        self.ax_main.set_ylabel('Z')
        
        # Statistics
        total_caves = len(self.caves)
        transition_count = np.sum(self.transitions)
        cave_density = total_caves / (self.params['chunk_size'] ** 2) * 100
        
        stats_text = f"""Total Caves: {total_caves}
Noodle Caves: {noodle_count}
Spaghetti Caves: {spaghetti_count}
Transition Points: {transition_count}
Cave Density: {cave_density:.2f}%"""
        
        self.ax_stats.text(0.1, 0.5, stats_text, fontsize=10, verticalalignment='center')
        self.ax_stats.set_title('Statistics')
        
        plt.draw()
    
    def update_params(self, val):
        """Update parameters from sliders"""
        self.params['binary_noise']['spread_x'] = int(self.sliders['spread_x'].val)
        self.params['binary_noise']['spread_z'] = int(self.sliders['spread_z'].val)
        self.params['binary_noise']['octaves'] = int(self.sliders['octaves'].val)
        self.params['binary_noise']['persistence'] = self.sliders['persistence'].val
        self.params['cave_type_noise']['spread_x'] = int(self.sliders['type_spread'].val)
        self.params['cave_type_noise']['spread_z'] = int(self.sliders['type_spread'].val)
        self.params['cave_type_threshold'] = self.sliders['type_threshold'].val
        
        # Auto-regenerate
        self.generate_caves()
        self.update_visualization()
    
    def regenerate(self, event):
        """Regenerate with new random seed"""
        self.params['binary_noise']['seed'] = random.randint(1, 100000)
        self.params['cave_type_noise']['seed'] = random.randint(1, 100000)
        self.generate_caves()
        self.update_visualization()
    
    def load_preset(self, preset_name):
        """Load preset configurations"""
        if preset_name == 'sparse':
            # Sparse caves - larger spreads, fewer transitions
            self.params['binary_noise']['spread_x'] = 400
            self.params['binary_noise']['spread_z'] = 400
            self.params['binary_noise']['octaves'] = 1
            self.params['binary_noise']['persistence'] = 0.3
            self.params['cave_type_noise']['spread_x'] = 500
            self.params['cave_type_noise']['spread_z'] = 500
        elif preset_name == 'dense':
            # Dense caves - smaller spreads, more transitions
            self.params['binary_noise']['spread_x'] = 100
            self.params['binary_noise']['spread_z'] = 100
            self.params['binary_noise']['octaves'] = 2
            self.params['binary_noise']['persistence'] = 0.7
            self.params['cave_type_noise']['spread_x'] = 150
            self.params['cave_type_noise']['spread_z'] = 150
        
        # Update sliders
        self.sliders['spread_x'].set_val(self.params['binary_noise']['spread_x'])
        self.sliders['spread_z'].set_val(self.params['binary_noise']['spread_z'])
        self.sliders['octaves'].set_val(self.params['binary_noise']['octaves'])
        self.sliders['persistence'].set_val(self.params['binary_noise']['persistence'])
        self.sliders['type_spread'].set_val(self.params['cave_type_noise']['spread_x'])
        
        self.generate_caves()
        self.update_visualization()
    
    def export_config(self, event):
        """Export current configuration to Lua format"""
        lua_config = f"""-- VoxelForge Cave Configuration (2D + Heightmaps)
-- Generated by simple_cave_tuner.py

voxelforge.caves.config = {{
    -- 2D Binary noise parameters - creates only -1 or 1 values
    binary_noise_params = {{
        offset = 0,
        scale = 1,
        spread = {{x = {self.params['binary_noise']['spread_x']}, y = {self.params['binary_noise']['spread_x']}, z = {self.params['binary_noise']['spread_z']}}},
        seed = {self.params['binary_noise']['seed']},
        octaves = {self.params['binary_noise']['octaves']},
        persist = {self.params['binary_noise']['persistence']},
        lacunarity = 2.0,
    }},
    
    -- Cave type determination noise (2D)
    cave_type_noise_params = {{
        offset = 0,
        scale = 1,
        spread = {{x = {self.params['cave_type_noise']['spread_x']}, y = {self.params['cave_type_noise']['spread_x']}, z = {self.params['cave_type_noise']['spread_z']}}},
        seed = {self.params['cave_type_noise']['seed']},
        octaves = {self.params['cave_type_noise']['octaves']},
        persist = {self.params['cave_type_noise']['persistence']},
        lacunarity = 2.0,
    }},
    
    -- Cave heightmap noise (determines cave floor/ceiling)
    heightmap_noise_params = {{
        offset = 0,
        scale = 1,
        spread = {{x = 60, y = 60, z = 60}},
        seed = 98765,
        octaves = 2,
        persist = 0.6,
        lacunarity = 2.0,
    }},
    
    -- Cave sizes (horizontal radius)
    noodle_radius = {{min = {self.params['noodle_radius']['min']}, max = {self.params['noodle_radius']['max']}}},
    spaghetti_radius = {{min = {self.params['spaghetti_radius']['min']}, max = {self.params['spaghetti_radius']['max']}}},
    
    -- Cave heights (vertical size)
    noodle_height = {{min = 3, max = 5}},
    spaghetti_height = {{min = 4, max = 7}},
    
    -- Cave type threshold (determines noodle vs spaghetti)
    cave_type_threshold = {self.params['cave_type_threshold']},
    
    -- Y level limits
    min_y = -30,
    max_y = 10,
    
    -- Cave floor variation
    floor_variation = 2,
    ceiling_variation = 1,
}}"""
        
        # Save to file
        config_path = '/home/joshua/.minetest/games/voxelforge-reimagined/scripts/cave_config.lua'
        with open(config_path, 'w') as f:
            f.write(lua_config)
        
        print(f"Configuration exported to: {config_path}")
        print(f"Total caves in test chunk: {len(self.caves)}")
        print(f"Cave density: {len(self.caves) / (self.params['chunk_size'] ** 2) * 100:.2f}%")
    
    def run(self):
        """Start the interactive tuner"""
        self.update_visualization()
        plt.show()

if __name__ == "__main__":
    print("VoxelForge 2D Cave Generation Tuner (Simple Version)")
    print("Use sliders to adjust parameters and see real-time results")
    print("Red circles = Spaghetti caves (6-9 radius, 5-10 height)")
    print("Blue circles = Noodle caves (2-5 radius, 3-6 height)")
    print("Click 'Export Config' to save settings to Lua file")
    
    tuner = SimpleCaveTuner()
    tuner.run()