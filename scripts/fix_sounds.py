#!/usr/bin/env python3
"""
Quick script to fix sound references in setup_phase1.py
"""

import re
from pathlib import Path

def fix_sounds():
    setup_file = Path(__file__).parent / "setup_phase1.py"
    
    with open(setup_file, 'r') as f:
        content = f.read()
    
    # Replace all default sound references
    replacements = [
        ('default.node_sound_stone_defaults()', 'voxelforge.sounds.node_sound_stone_defaults()'),
        ('default.node_sound_dirt_defaults()', 'voxelforge.sounds.node_sound_dirt_defaults()'),
        ('default.node_sound_wood_defaults()', 'voxelforge.sounds.node_sound_wood_defaults()'),
        ('default.node_sound_metal_defaults()', 'voxelforge.sounds.node_sound_metal_defaults()'),
        ('"default_tool_breaks"', 'voxelforge.sounds.tool_breaks'),
    ]
    
    for old, new in replacements:
        content = content.replace(old, new)
    
    with open(setup_file, 'w') as f:
        f.write(content)
    
    print("✓ Fixed all sound references in setup_phase1.py")

if __name__ == "__main__":
    fix_sounds()