# VoxelForge Cave Generation Tuner

Interactive tool for tuning the binary noise transition cave system parameters.

## Features

- **Real-time visualization** of cave generation
- **Interactive sliders** for all parameters
- **Multiple views**: Binary noise, cave type noise, transitions, and final caves
- **Statistics panel** showing cave counts and density
- **Preset configurations** for sparse and dense caves
- **Export functionality** to generate Lua configuration files

## Usage

### 1. Run the Cave Tuner

```bash
cd /home/joshua/.minetest/games/voxelforge-reimagined/scripts
python3 cave_tuner.py
```

### 2. Adjust Parameters

Use the sliders to adjust:

- **Spread X/Z**: Controls how frequently transitions occur (lower = more caves)
- **Octaves**: Number of noise layers (higher = more complex patterns)
- **Persistence**: How much each octave contributes (higher = more chaotic)
- **Type Spread X**: Controls distribution of noodle vs spaghetti caves
- **Type Threshold**: Balance between noodle and spaghetti caves
- **Y Level**: Which vertical level to visualize

### 3. Use Presets

- **Sparse Caves**: Fewer, more spread out caves
- **Dense Caves**: Many caves close together

### 4. Export Configuration

Click "Export Config" to save your settings to `cave_config.lua`

### 5. Apply to Game

```bash
python3 apply_cave_config.py
```

To restore the original configuration:
```bash
python3 apply_cave_config.py restore
```

## Understanding the Visualization

### Main View (Top-left)
- **Background**: Binary noise pattern (red = 1, blue = -1)
- **Blue circles**: Noodle caves (2-5 block radius)
- **Red circles**: Spaghetti caves (6-9 block radius)

### Binary Noise (Top-right)
- Shows the -1/1 noise pattern
- Caves appear where these values transition

### Cave Type Noise (Middle-right)
- Determines noodle vs spaghetti placement
- Brighter areas = more likely to be spaghetti caves

### Transition Points (Bottom-right)
- White dots show where -1 and 1 values meet
- These are potential cave locations

### Statistics Panel
- **Total Caves**: Number of caves in the test chunk
- **Cave Density**: Percentage of chunk area with caves
- **Caves/Transitions**: How many transitions become actual caves

## Tips for Tuning

### For Fewer Caves:
- Increase Spread X/Z values (100+)
- Decrease Octaves (1-2)
- Lower Persistence (0.3-0.5)

### For More Caves:
- Decrease Spread X/Z values (20-40)
- Increase Octaves (3-5)
- Higher Persistence (0.6-0.8)

### For Balanced Cave Types:
- Keep Type Threshold near 0.0
- Adjust Type Spread X to control clustering

## Technical Details

The cave system works by:

1. **Generating binary noise** (only -1 or 1 values)
2. **Finding transitions** where -1 meets 1
3. **Placing caves** at transition points
4. **Determining cave type** using separate noise
5. **Setting radius** based on type (noodle 2-5, spaghetti 6-9)

## Files Generated

- `cave_config.lua`: Exported configuration in Lua format
- `init.lua.backup`: Backup of original cave system (created automatically)

## Troubleshooting

### "No module named 'noise'"
The noise library should be installed via apt. If not:
```bash
sudo apt install python3-noise
```

### "Permission denied"
Make sure scripts are executable:
```bash
chmod +x cave_tuner.py apply_cave_config.py
```

### Changes not appearing in game
Make sure to:
1. Export configuration from the tuner
2. Run `apply_cave_config.py`
3. Restart your Minetest world (caves generate during world creation)