extends TileMap

# One-way platform that player can jump through from below
# but land on from above. Player can press down to drop through.

func _ready() -> void:
	# Enable one-way collision for this TileMap
	# This allows collision from above, but passes through from below/sides
	
	var tileset = tile_set
	if not tileset:
		print("❌ Platform: No tileset found!")
		return
	
	# Set physics layer to collision layer 2 ONLY (not layer 1)
	for physics_layer_idx in range(tileset.get_physics_layers_count()):
		tileset.set_physics_layer_collision_layer(physics_layer_idx, 2)
		tileset.set_physics_layer_collision_mask(physics_layer_idx, 0)
	
	# Add collision shapes to all tiles and enable one-way collision
	var source_count = tileset.get_source_count()
	var tile_size = tileset.tile_size
	var tile_extents = Vector2(tile_size.x / 2.0, tile_size.y / 2.0)
	
	for source_idx in range(source_count):
		var source_id = tileset.get_source_id(source_idx)
		var source = tileset.get_source(source_id)
		
		if source is TileSetAtlasSource:
			var atlas = source as TileSetAtlasSource
			var tiles_count = atlas.get_tiles_count()
			
			# Iterate through all tiles in this atlas
			for tile_id in range(tiles_count):
				var tile_coords = atlas.get_tile_id(tile_id)
				
				# Get tile data
				var tile_data = atlas.get_tile_data(tile_coords, 0)  # 0 = first alternative tile
				if tile_data:
					# Check all physics layers
					for physics_layer in range(tileset.get_physics_layers_count()):
						var polygons_count = tile_data.get_collision_polygons_count(physics_layer)
						
						# If tile doesn't have collision, add it
						if polygons_count == 0:
							tile_data.add_collision_polygon(physics_layer)
							tile_data.set_collision_polygon_points(
								physics_layer,
								0,
								PackedVector2Array([
									Vector2(-tile_extents.x, -tile_extents.y),
									Vector2(-tile_extents.x, tile_extents.y),
									Vector2(tile_extents.x, tile_extents.y),
									Vector2(tile_extents.x, -tile_extents.y)
								])
							)
							polygons_count = 1
						
						# Enable one-way collision on all polygons
						for polygon_idx in range(polygons_count):
							tile_data.set_collision_polygon_one_way(physics_layer, polygon_idx, true)
							tile_data.set_collision_polygon_one_way_margin(physics_layer, polygon_idx, 1.0)
			
			if tiles_count > 0:
				print("✅ Platform: Configured ", tiles_count, " one-way platform tiles")
