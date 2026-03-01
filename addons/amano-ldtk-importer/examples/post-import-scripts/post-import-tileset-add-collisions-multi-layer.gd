@tool
extends Node

const Tile = preload("res://addons/amano-ldtk-importer/util/tile.gd")

# Layers to ignore (won't create collisions for these)
var ignored_layers := ["Background"]

# Simple collision script - all IntGrid tiles get solid collision on layer 1
func post_import(tileset: TileSet) -> TileSet:
	print("\n=== [POST-IMPORT] Adding IntGrid Collisions ===")
	
	if tileset == null:
		print("ERROR: TileSet is null!")
		return tileset
	
	# Create a single physics layer for all collisions
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)  # Layer 1
	tileset.set_physics_layer_collision_mask(0, 0)
	print("✓ Created physics layer 0 on collision layer 1")
	
	var custom_data_layers_count := tileset.get_custom_data_layers_count()
	print("Found ", custom_data_layers_count, " custom data layers")
	
	# Find which custom data layers are IntGrid (to add collision to)
	var intgrid_layers := []
	for layer_idx in range(custom_data_layers_count):
		var layer_name := tileset.get_custom_data_layer_name(layer_idx)
		
		# Skip ignored layers
		if layer_name in ignored_layers:
			print("Skipping ignored layer: ", layer_name)
			continue
		
		# Check if this is an IntGrid layer
		if tileset.get_custom_data_layer_type(layer_idx) == TYPE_INT:
			intgrid_layers.append(layer_idx)
			print("✓ Will add collision for IntGrid layer: '", layer_name, "'")
	
	# Process all tile sources
	print("\n=== Processing Tile Sources ===")
	var source_count := tileset.get_source_count()
	print("Found ", source_count, " tile sources")
	
	for index in range(source_count):
		var tileset_source_id := tileset.get_source_id(index)
		var tileset_source := tileset.get_source(tileset_source_id)
		
		if tileset_source == null:
			continue
		
		if not tileset_source is TileSetAtlasSource:
			continue
		
		var atlas_source := tileset_source as TileSetAtlasSource
		print("Processing atlas source ID: ", tileset_source_id)
		
		var tile_size := tileset.tile_size
		var tile_extents := Vector2(tile_size.x / 2, tile_size.y / 2)
		var grid_size := atlas_source.get_atlas_grid_size()
		
		var tiles_processed := 0
		
		# Check each tile in the atlas
		for y in range(grid_size.y):
			for x in range(grid_size.x):
				var grid_coords := Vector2i(x, y)
				
				# Check if tile exists
				if atlas_source.get_tile_at_coords(grid_coords) == Vector2i(-1, -1):
					continue
				
				var tile_data := atlas_source.get_tile_data(grid_coords, 0)
				if tile_data == null:
					continue
				
				# Add collision to EVERY tile (not just IntGrid tiles)
				tile_data.add_collision_polygon(0)  # Physics layer 0
				tile_data.set_collision_polygon_points(
					0,
					0,
					PackedVector2Array([
						Vector2(-tile_extents.x, -tile_extents.y),
						Vector2(-tile_extents.x, tile_extents.y),
						Vector2(tile_extents.x, tile_extents.y),
						Vector2(tile_extents.x, -tile_extents.y)
					])
				)
				tiles_processed += 1
		
		print("  - Added collision to ", tiles_processed, " tiles")
	
	print("\n=== Collision Setup Complete ===\n")
	return tileset
	
	print("\n=== Collision Setup Complete ===\n")

	return tileset
