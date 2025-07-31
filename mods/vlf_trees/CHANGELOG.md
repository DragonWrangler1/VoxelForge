# VLF Trees Changelog

## Version 1.0.0 - Initial Release

### Features Added
- Complete tree registration API with `vlf_trees.register_tree()`
- Progressive sapling growth system with 5 stages
- ABM-based automatic growth with configurable timing
- Bonemeal support for accelerated growth
- Full block set generation for each tree:
  - Logs (with directional placement)
  - Stripped logs
  - Planks
  - Leaves (with sapling drops and leaf decay)
  - Saplings (with progressive growth)
  - Fences (with connection logic)
  - Fence gates (with open/close functionality)
  - Doors (two-block with open/close)
  - Trapdoors (with open/close)
- Automatic crafting recipe generation
- Custom tree generation support
- Pre-registered tree types:
  - Oak (balanced growth)
  - Spruce (slower growth)
  - Birch (fast growth)
  - Jungle (large trees, slow growth)
  - Acacia (unique branching shape)
  - Dark Oak (thick trunk, very slow)

### API Functions
- `vlf_trees.register_tree(name, def)` - Register complete tree set
- `vlf_trees.grow_tree(pos, name)` - Grow tree at position
- `vlf_trees.register_tree_recipes(name)` - Register crafting recipes

### Configuration Options
- `growth_time` - Base growth time between stages
- `growth_chance` - Probability of growth per ABM cycle
- `sapling_rarity` - Probability of sapling drops from leaves
- Custom tree generators for unique tree shapes
- Configurable node groups and properties

### Dependencies
- `vlf_blocks` (required) - For basic blocks and materials
- `vlf_bonemeal` (optional) - For bonemeal acceleration support

### Technical Details
- Uses ABM system for growth (30s interval, configurable chance)
- Light level requirement (8+) for sapling growth
- Soil requirement for sapling placement
- Automatic texture path generation
- Comprehensive error handling
- Performance optimized growth system

### Documentation
- Complete API reference in API.md
- Usage examples in examples.lua
- Comprehensive README with feature overview
- Inline code documentation