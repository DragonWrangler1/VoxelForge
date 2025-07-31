# Plank Colorization Summary

## Overview
Successfully created a Python script that takes the base plank texture and properly colorizes it for each wood type, addressing exposure issues and making sakura more peachy.

## Improvements Made

### 1. Fixed Exposure Issues
- **Better Brightness Mapping**: Analyzes the actual brightness range of the base texture (103-167) instead of assuming standard values
- **Smooth Interpolation**: Uses gradual blending between color zones instead of hard cutoffs
- **Contrast Enhancement**: Applies a 1.1x contrast boost to compensate for colorization flattening
- **Texture Detail Preservation**: Maintains relative brightness variations to preserve wood grain details
- **Sharpening Filter**: Applies subtle unsharp mask to enhance texture details

### 2. Enhanced Sakura Color
- **More Peachy Tones**: 
  - Base: `(245, 195, 185)` - warmer, more peach-like
  - Highlight: `(255, 215, 205)` - peachy highlight
  - Shadow: `(205, 154, 144)` - peachy shadow
  - Dark: `(186, 134, 124)` - peachy dark tone

### 3. Advanced Colorization Algorithm
- **Four-Zone Mapping**:
  - Brightest areas (75-100%) → Highlight colors
  - Mid-bright areas (50-75%) → Base colors  
  - Mid-dark areas (25-50%) → Shadow colors
  - Darkest areas (0-25%) → Dark colors
- **Local Variation Preservation**: Maintains texture details by preserving relative brightness differences
- **Floating Point Precision**: Uses float32 for calculations to avoid rounding errors

## Technical Features

### Color Analysis
The script analyzes the base texture and reports:
- Most common colors in the base texture
- Brightness range for proper mapping
- Texture size and format validation

### Processing Pipeline
1. **Load Base Texture**: Loads the grayscale base plank texture
2. **Analyze Colors**: Identifies brightness range and color distribution
3. **Map Colors**: Maps grayscale values to wood-specific color palettes
4. **Preserve Details**: Maintains texture grain and wood patterns
5. **Enhance Quality**: Applies contrast boost and sharpening
6. **Save Results**: Outputs properly formatted PNG files

## Generated Textures
All 8 wood types now have properly colorized plank textures:
- ✅ **Oak**: Classic warm brown tones
- ✅ **Spruce**: Darker brown with subtle green undertones
- ✅ **Birch**: Light cream/white wood
- ✅ **Jungle**: Rich reddish-brown
- ✅ **Acacia**: Orange-tinted wood
- ✅ **Dark Oak**: Very dark brown/black
- ✅ **Pine**: Light brown with yellowish tint
- ✅ **Sakura**: Peachy pink wood tones (enhanced)

## File Details
- **Script**: `scripts/colorize_planks.py`
- **Base Texture**: `mods/vlf_trees/textures/vlf_trees_plank_base.png` (16x16 grayscale)
- **Output**: 8 colorized plank textures in `mods/vlf_trees/textures/`
- **Processing Time**: ~1 second for all textures

## Quality Improvements
1. **Better Exposure**: Fixed over/under-exposure issues by using actual brightness range
2. **Enhanced Detail**: Preserved wood grain texture through local variation analysis
3. **Improved Contrast**: Applied subtle contrast enhancement to maintain visual clarity
4. **Peachy Sakura**: Made sakura planks more peachy as requested
5. **Consistent Quality**: All textures maintain the same level of detail and sharpness

## Usage
```bash
cd /home/joshua/.minetest/games/voxelforge-reimagined/scripts
python3 colorize_planks.py
```

The script automatically:
- Finds the base plank texture
- Analyzes its properties
- Colorizes for all 8 wood types
- Saves the results with proper naming
- Reports progress and completion

## Result
All plank textures now have proper exposure, enhanced detail preservation, and the sakura planks have the requested peachy tone. The textures maintain the original wood grain pattern while displaying distinct colors for each wood type.