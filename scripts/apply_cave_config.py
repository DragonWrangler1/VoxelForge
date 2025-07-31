#!/usr/bin/env python3
"""
Apply cave configuration from cave_tuner.py to the game
"""

import os
import shutil

def apply_cave_config():
    """Apply the exported cave configuration to the game"""
    config_file = '/home/joshua/.minetest/games/voxelforge-reimagined/scripts/cave_config.lua'
    cave_init_file = '/home/joshua/.minetest/games/voxelforge-reimagined/mods/voxelforge_core/caves/init.lua'
    
    if not os.path.exists(config_file):
        print("Error: No cave configuration found!")
        print("Run cave_tuner.py first and export a configuration.")
        return False
    
    # Backup original file
    backup_file = cave_init_file + '.backup'
    if not os.path.exists(backup_file):
        shutil.copy2(cave_init_file, backup_file)
        print(f"Backed up original cave file to: {backup_file}")
    
    # Read the exported configuration
    with open(config_file, 'r') as f:
        new_config = f.read()
    
    # Read the current cave file
    with open(cave_init_file, 'r') as f:
        current_content = f.read()
    
    # Find the config section and replace it
    config_start = current_content.find('voxelforge.caves.config = {')
    if config_start == -1:
        print("Error: Could not find config section in cave file!")
        return False
    
    # Find the end of the config (look for the closing brace and comma)
    brace_count = 0
    config_end = config_start
    in_config = False
    
    for i, char in enumerate(current_content[config_start:], config_start):
        if char == '{':
            brace_count += 1
            in_config = True
        elif char == '}':
            brace_count -= 1
            if in_config and brace_count == 0:
                config_end = i + 1
                break
    
    if config_end == config_start:
        print("Error: Could not find end of config section!")
        return False
    
    # Replace the config section
    new_content = (
        current_content[:config_start] + 
        new_config.split('\n', 2)[2] +  # Skip the comment lines
        current_content[config_end:]
    )
    
    # Write the updated file
    with open(cave_init_file, 'w') as f:
        f.write(new_content)
    
    print("Cave configuration applied successfully!")
    print("Restart your Minetest world to see the changes.")
    return True

def restore_backup():
    """Restore the original cave configuration"""
    cave_init_file = '/home/joshua/.minetest/games/voxelforge-reimagined/mods/voxelforge_core/caves/init.lua'
    backup_file = cave_init_file + '.backup'
    
    if not os.path.exists(backup_file):
        print("Error: No backup file found!")
        return False
    
    shutil.copy2(backup_file, cave_init_file)
    print("Original cave configuration restored!")
    return True

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == 'restore':
        restore_backup()
    else:
        apply_cave_config()