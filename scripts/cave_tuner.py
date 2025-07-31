#!/usr/bin/env python3
"""
VoxelForge Cave Generation Tuner
Interactive tool for tuning binary noise transition cave parameters
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider, Button, CheckButtons
import noise
from mpl_toolkits.mplot3d import Axes3D

class CaveTuner:
    def __init__(self):
        # Default parameters (matching the Lua code)
        self.params = {
            'binary_noise': {
                'scale': 1.0,
                'spread_x': 50,
                'spread_y': 30,
                'spread_z': 50,
                'octaves': 3,
                'persistence': 0.6,
                'lacunarity': 2.0,
                'seed': 12345
            },
            'cave_type_noise': {
                'scale': 1.0,
                'spread_x': 80,
                'spread_y': 40,
                'spread_z': 80,
                'octaves': 2,
                'persistence': 0.5,
                'lacunarity': 2.0,
                'seed': 54321
            },
            'cave_type_threshold': 0.0,
            'noodle_radius': {'min': 2, 'max': 5},
            'spaghetti_radius': {'min': 6, 'max': 9},
            'chunk_size': 80,  # Size of the test chunk
            'y_level': 0       # Y level to visualize
        }
        
        self.setup_plot()
        self.generate_caves()
        
    def setup_plot(self):
        """Setup the matplotlib interface"""
        self.fig = plt.figure(figsize=(16, 10))
        
        # Main cave visualization
        self.ax_main = plt.subplot2grid((3, 4), (0, 0), colspan=2, rowspan=2)
        self.ax_main.set_title('Cave Generation (Top View)')
        self.ax_main.set_xlabel('X')
        self.ax_main.set_ylabel('Z')
        
        # Binary noise visualization
        self.ax_binary = plt.subplot2grid((3, 4), (0, 2))
        self.ax_binary.set_title('Binary Noise (-1/1)')
        
        # Cave type noise visualization
        self.ax_type = plt.subplot2grid((3, 4), (0, 3))
        self.ax_type.set_title('Cave Type Noise')
        
        # Transition detection
        self.ax_transitions = plt.subplot2grid((3, 4), (1, 2))
        self.ax_transitions.set_title('Transition Points')
        
        # Statistics
        self.ax_stats = plt.subplot2grid((3, 4), (1, 3))
        self.ax_stats.set_title('Statistics')
        self.ax_stats.axis('off')
        
        # Sliders area
        slider_area = plt.subplot2grid((3, 4), (2, 0), colspan=4)
        slider_area.axis('off')
        
        # Create sliders
        self.create_sliders()
        
        # Create buttons
        self.create_buttons()
        
    def create_sliders(self):
        """Create parameter sliders"""
        slider_height = 0.03
        slider_spacing = 0.04
        left_margin = 0.1
        
        # Binary noise sliders
        y_pos = 0.25
        
        self.sliders = {}
        
        # Binary noise spread
        ax_spread_x = plt.axes([left_margin, y_pos, 0.15, slider_height])
        self.sliders['spread_x'] = Slider(ax_spread_x, 'Spread X', 10, 200, 
                                         valinit=self.params['binary_noise']['spread_x'], valfmt='%d')
        
        ax_spread_z = plt.axes([left_margin + 0.2, y_pos, 0.15, slider_height])
        self.sliders['spread_z'] = Slider(ax_spread_z, 'Spread Z', 10, 200, 
                                         valinit=self.params['binary_noise']['spread_z'], valfmt='%d')
        
        # Octaves and persistence
        y_pos -= slider_spacing
        ax_octaves = plt.axes([left_margin, y_pos, 0.15, slider_height])
        self.sliders['octaves'] = Slider(ax_octaves, 'Octaves', 1, 6, 
                                        valinit=self.params['binary_noise']['octaves'], valfmt='%d')
        
        ax_persistence = plt.axes([left_margin + 0.2, y_pos, 0.15, slider_height])
        self.sliders['persistence'] = Slider(ax_persistence, 'Persistence', 0.1, 1.0, 
                                           valinit=self.params['binary_noise']['persistence'])
        
        # Cave type noise
        y_pos -= slider_spacing
        ax_type_spread_x = plt.axes([left_margin, y_pos, 0.15, slider_height])
        self.sliders['type_spread_x'] = Slider(ax_type_spread_x, 'Type Spread X', 20, 300, 
                                              valinit=self.params['cave_type_noise']['spread_x'], valfmt='%d')
        
        ax_type_threshold = plt.axes([left_margin + 0.2, y_pos, 0.15, slider_height])
        self.sliders['type_threshold'] = Slider(ax_type_threshold, 'Type Threshold', -1.0, 1.0, 
                                               valinit=self.params['cave_type_threshold'])
        
        # Y level selector
        y_pos -= slider_spacing
        ax_y_level = plt.axes([left_margin, y_pos, 0.15, slider_height])
        self.sliders['y_level'] = Slider(ax_y_level, 'Y Level', -50, 20, 
                                        valinit=self.params['y_level'], valfmt='%d')
        
        # Connect sliders to update function
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
        
    def generate_binary_noise(self, size_x, size_z, y_level):
        """Generate binary noise (-1 or 1 only)"""
        binary_noise = np.zeros((size_z, size_x))
        
        for z in range(size_z):
            for x in range(size_x):
                # Convert coordinates to world coordinates
                world_x = x / self.params['binary_noise']['spread_x']
                world_y = y_level / self.params['binary_noise']['spread_y']
                world_z = z / self.params['binary_noise']['spread_z']
                
                # Generate noise
                noise_val = noise.pnoise3(
                    world_x, world_y, world_z,
                    octaves=self.params['binary_noise']['octaves'],
                    persistence=self.params['binary_noise']['persistence'],
                    lacunarity=self.params['binary_noise']['lacunarity'],
                    base=self.params['binary_noise']['seed']
                )
                
                # Convert to binary
                binary_noise[z, x] = 1 if noise_val >= 0 else -1
                
        return binary_noise
    
    def generate_cave_type_noise(self, size_x, size_z, y_level):
        """Generate cave type noise"""
        type_noise = np.zeros((size_z, size_x))
        
        for z in range(size_z):
            for x in range(size_x):
                world_x = x / self.params['cave_type_noise']['spread_x']
                world_y = y_level / self.params['cave_type_noise']['spread_y']
                world_z = z / self.params['cave_type_noise']['spread_z']
                
                type_noise[z, x] = noise.pnoise3(
                    world_x, world_y, world_z,
                    octaves=self.params['cave_type_noise']['octaves'],
                    persistence=self.params['cave_type_noise']['persistence'],
                    lacunarity=self.params['cave_type_noise']['lacunarity'],
                    base=self.params['cave_type_noise']['seed']
                )
                
        return type_noise
    
    def find_transitions(self, binary_noise):
        """Find transition points between -1 and 1"""
        size_z, size_x = binary_noise.shape
        transitions = np.zeros((size_z, size_x), dtype=bool)
        
        for z in range(1, size_z - 1):
            for x in range(1, size_x - 1):
                center_val = binary_noise[z, x]
                
                # Check 4 adjacent positions (2D for visualization)
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
        y_level = self.params['y_level']
        
        # Generate noise maps
        self.binary_noise = self.generate_binary_noise(size, size, y_level)
        self.cave_type_noise = self.generate_cave_type_noise(size, size, y_level)
        
        # Find transitions
        self.transitions = self.find_transitions(self.binary_noise)
        
        # Generate caves at transition points
        self.caves = []
        transition_coords = np.where(self.transitions)
        
        for i in range(len(transition_coords[0])):
            z, x = transition_coords[0][i], transition_coords[1][i]
            
            # Determine cave type
            type_noise_val = self.cave_type_noise[z, x]
            is_spaghetti = type_noise_val > self.params['cave_type_threshold']
            
            # Determine radius
            if is_spaghetti:
                radius = np.random.randint(
                    self.params['spaghetti_radius']['min'],
                    self.params['spaghetti_radius']['max'] + 1
                )
                cave_type = 'spaghetti'
            else:
                radius = np.random.randint(
                    self.params['noodle_radius']['min'],
                    self.params['noodle_radius']['max'] + 1
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
        self.ax_transitions.clear()
        self.ax_stats.clear()
        
        # Binary noise
        self.ax_binary.imshow(self.binary_noise, cmap='RdBu', vmin=-1, vmax=1)
        self.ax_binary.set_title('Binary Noise (-1/1)')
        
        # Cave type noise
        self.ax_type.imshow(self.cave_type_noise, cmap='viridis')
        self.ax_type.set_title('Cave Type Noise')
        
        # Transitions
        self.ax_transitions.imshow(self.transitions, cmap='gray')
        self.ax_transitions.set_title('Transition Points')
        
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
        self.ax_main.set_title(f'Cave Generation (Y={self.params["y_level"]})')
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
Cave Density: {cave_density:.2f}%
Caves/Transitions: {total_caves/max(transition_count, 1):.2f}"""
        
        self.ax_stats.text(0.1, 0.5, stats_text, fontsize=10, verticalalignment='center')
        self.ax_stats.set_title('Statistics')
        
        plt.draw()
    
    def update_params(self, val):
        """Update parameters from sliders"""
        self.params['binary_noise']['spread_x'] = int(self.sliders['spread_x'].val)
        self.params['binary_noise']['spread_z'] = int(self.sliders['spread_z'].val)
        self.params['binary_noise']['octaves'] = int(self.sliders['octaves'].val)
        self.params['binary_noise']['persistence'] = self.sliders['persistence'].val
        self.params['cave_type_noise']['spread_x'] = int(self.sliders['type_spread_x'].val)
        self.params['cave_type_threshold'] = self.sliders['type_threshold'].val
        self.params['y_level'] = int(self.sliders['y_level'].val)
        
        # Auto-regenerate
        self.generate_caves()
        self.update_visualization()
    
    def regenerate(self, event):
        """Regenerate with new random seed"""
        self.params['binary_noise']['seed'] = np.random.randint(1, 100000)
        self.params['cave_type_noise']['seed'] = np.random.randint(1, 100000)
        self.generate_caves()
        self.update_visualization()
    
    def load_preset(self, preset_name):
        """Load preset configurations"""
        if preset_name == 'sparse':
            # Sparse caves - larger spreads, fewer transitions
            self.params['binary_noise']['spread_x'] = 100
            self.params['binary_noise']['spread_z'] = 100
            self.params['binary_noise']['octaves'] = 2
            self.params['binary_noise']['persistence'] = 0.4
            self.params['cave_type_noise']['spread_x'] = 150
        elif preset_name == 'dense':
            # Dense caves - smaller spreads, more transitions
            self.params['binary_noise']['spread_x'] = 25
            self.params['binary_noise']['spread_z'] = 25
            self.params['binary_noise']['octaves'] = 4
            self.params['binary_noise']['persistence'] = 0.8
            self.params['cave_type_noise']['spread_x'] = 50
        
        # Update sliders
        self.sliders['spread_x'].reset()
        self.sliders['spread_z'].reset()
        self.sliders['octaves'].reset()
        self.sliders['persistence'].reset()
        self.sliders['type_spread_x'].reset()
        
        self.sliders['spread_x'].set_val(self.params['binary_noise']['spread_x'])
        self.sliders['spread_z'].set_val(self.params['binary_noise']['spread_z'])
        self.sliders['octaves'].set_val(self.params['binary_noise']['octaves'])
        self.sliders['persistence'].set_val(self.params['binary_noise']['persistence'])
        self.sliders['type_spread_x'].set_val(self.params['cave_type_noise']['spread_x'])
        
        self.generate_caves()
        self.update_visualization()
    
    def export_config(self, event):
        """Export current configuration to Lua format"""
        lua_config = f"""-- VoxelForge Cave Configuration
-- Generated by cave_tuner.py

voxelforge.caves.config = {{
    -- Binary noise parameters - creates only -1 or 1 values
    binary_noise_params = {{
        offset = 0,
        scale = 1,
        spread = {{x = {self.params['binary_noise']['spread_x']}, y = {self.params['binary_noise']['spread_y']}, z = {self.params['binary_noise']['spread_z']}}},
        seed = {self.params['binary_noise']['seed']},
        octaves = {self.params['binary_noise']['octaves']},
        persist = {self.params['binary_noise']['persistence']},
        lacunarity = {self.params['binary_noise']['lacunarity']},
    }},
    
    -- Cave type determination noise
    cave_type_noise_params = {{
        offset = 0,
        scale = 1,
        spread = {{x = {self.params['cave_type_noise']['spread_x']}, y = {self.params['cave_type_noise']['spread_y']}, z = {self.params['cave_type_noise']['spread_z']}}},
        seed = {self.params['cave_type_noise']['seed']},
        octaves = {self.params['cave_type_noise']['octaves']},
        persist = {self.params['cave_type_noise']['persistence']},
        lacunarity = {self.params['cave_type_noise']['lacunarity']},
    }},
    
    -- Cave sizes
    noodle_radius = {{min = {self.params['noodle_radius']['min']}, max = {self.params['noodle_radius']['max']}}},
    spaghetti_radius = {{min = {self.params['spaghetti_radius']['min']}, max = {self.params['spaghetti_radius']['max']}}},
    
    -- Cave type threshold (determines noodle vs spaghetti)
    cave_type_threshold = {self.params['cave_type_threshold']},
    
    -- Y level limits
    min_y = -50,
    max_y = 20,
    
    -- Transition detection sensitivity
    transition_check_radius = 1,
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
    print("VoxelForge Cave Generation Tuner")
    print("Use sliders to adjust parameters and see real-time results")
    print("Red circles = Spaghetti caves (6-9 radius)")
    print("Blue circles = Noodle caves (2-5 radius)")
    print("Click 'Export Config' to save settings to Lua file")
    
    tuner = CaveTuner()
    tuner.run()