#!/usr/bin/env python3
"""
VoxelForge Reimagined - Setup Validation Script
Validates that Phase 1 setup completed successfully.
"""

import os
from pathlib import Path

def validate_setup():
    """Validate that Phase 1 setup completed successfully."""
    base_dir = Path(__file__).parent.parent
    issues = []
    
    print("🔍 Validating VoxelForge Reimagined Phase 1 Setup")
    print("=" * 50)
    
    # Check mod structure
    mod_dir = base_dir / "mods" / "voxelforge_core"
    required_files = [
        "mod.conf",
        "init.lua",
        "sounds/init.lua",
        "mapgen/init.lua",
        "cooking/init.lua",
        "caves/init.lua",
        "nodes/init.lua",
        "items/init.lua",
        "tools/init.lua",
        "crafting/init.lua"
    ]
    
    print("\n📁 Checking mod structure...")
    for file_path in required_files:
        full_path = mod_dir / file_path
        if full_path.exists():
            print(f"✅ {file_path}")
        else:
            print(f"❌ {file_path}")
            issues.append(f"Missing file: {file_path}")
    
    # Check textures
    print("\n🎨 Checking textures...")
    texture_dir = mod_dir / "textures"
    
    required_textures = [
        # Blocks
        "voxelforge_stone.png",
        "voxelforge_dirt.png", 
        "voxelforge_wood.png",
        "voxelforge_planks.png",
        "voxelforge_iron_ore.png",
        "voxelforge_copper_ore.png",
        "voxelforge_coal_ore.png",
        # Tools
        "voxelforge_wooden_pickaxe.png",
        "voxelforge_iron_pickaxe.png",
        # Items
        "voxelforge_iron_ingot.png",
        "voxelforge_iron_lump.png",
        # Stations
        "voxelforge_crafting_table_top.png",
        "voxelforge_forge.png",
        "voxelforge_cooking_stove_top.png"
    ]
    
    for texture in required_textures:
        texture_path = texture_dir / texture
        if texture_path.exists():
            print(f"✅ {texture}")
        else:
            print(f"❌ {texture}")
            issues.append(f"Missing texture: {texture}")
    
    # Check game.conf
    print("\n🎮 Checking game configuration...")
    game_conf = base_dir / "game.conf"
    if game_conf.exists():
        print("✅ game.conf")
        with open(game_conf, 'r') as f:
            content = f.read()
            if "VoxelForge Reimagined" in content:
                print("✅ Game title configured")
            else:
                issues.append("Game title not properly configured")
    else:
        print("❌ game.conf")
        issues.append("Missing game.conf")
    
    # Check scripts
    print("\n🔧 Checking scripts...")
    scripts_dir = base_dir / "scripts"
    script_files = [
        "generate_textures.py",
        "generate_stations.py", 
        "setup_phase1.py",
        "run_game.sh"
    ]
    
    for script in script_files:
        script_path = scripts_dir / script
        if script_path.exists():
            print(f"✅ {script}")
        else:
            print(f"❌ {script}")
            issues.append(f"Missing script: {script}")
    
    # Summary
    print("\n" + "=" * 50)
    if not issues:
        print("🎉 Validation successful! Phase 1 setup is complete.")
        print("\nNext steps:")
        print("1. Run: ./scripts/run_game.sh")
        print("2. Create a new world with VoxelForge Reimagined")
        print("3. Enable the VoxelForge Core mod")
        print("4. Test mining, crafting, and XP progression!")
        return True
    else:
        print(f"❌ Validation failed! Found {len(issues)} issues:")
        for issue in issues:
            print(f"  - {issue}")
        print("\nPlease run setup_phase1.py again to fix these issues.")
        return False

if __name__ == "__main__":
    success = validate_setup()
    exit(0 if success else 1)