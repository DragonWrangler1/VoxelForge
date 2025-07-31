#!/bin/bash
# VoxelForge Reimagined - Game Launcher Script

echo "🔥 VoxelForge Reimagined - Game Launcher"
echo "========================================"

# Check if Minetest is installed
if ! command -v minetest &> /dev/null; then
    echo "❌ Minetest is not installed or not in PATH"
    echo "Please install Minetest first:"
    echo "  Ubuntu/Debian: sudo apt install minetest"
    echo "  Arch: sudo pacman -S minetest"
    echo "  Or download from: https://www.minetest.net/downloads/"
    exit 1
fi

# Get the game directory
GAME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Game directory: $GAME_DIR"

# Check if VoxelForge Core mod exists
if [ ! -d "$GAME_DIR/mods/voxelforge_core" ]; then
    echo "❌ VoxelForge Core mod not found!"
    echo "Please run the setup script first:"
    echo "  cd scripts && python3 setup_phase1.py"
    exit 1
fi

echo "✅ VoxelForge Core mod found"
echo "✅ Ready to launch!"
echo ""
echo "Instructions:"
echo "1. Create a new world"
echo "2. Select 'VoxelForge Reimagined' as the game"
echo "3. Enable the 'VoxelForge Core' mod in mod selection"
echo "4. Start playing and test the Phase 1 features!"
echo ""
echo "Phase 1 Goals:"
echo "- Mine terrain blocks (stone, dirt, wood, ores)"
echo "- Craft tools and gain XP"
echo "- Build crafting stations (table, forge, stove)"
echo "- Reach Level 2 to complete the milestone!"
echo ""

# Launch Minetest with the game
echo "Launching Minetest..."
minetest --gameid voxelforge-reimagined --go