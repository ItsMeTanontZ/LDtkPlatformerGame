extends TileMap

# Spikes that kill the player on contact

func _ready() -> void:
	var tileset = tile_set
	if not tileset:
		print("❌ Spike: No tileset found!")
		return
	
	# Set physics layer to collision layer 3 (spikes)
	for physics_layer_idx in range(tileset.get_physics_layers_count()):
		tileset.set_physics_layer_collision_layer(physics_layer_idx, 4)  # Layer 3 = bit 2 = value 4
		tileset.set_physics_layer_collision_mask(physics_layer_idx, 0)
	
	# Add collision shapes to all spike tiles
	var source_count = tileset.get_source_count()
	var tile_size = tileset.tile_size
	var tile_extents = Vector2(tile_size.x / 2.0, tile_size.y / 2.0)
	
	for source_idx in range(source_count):
		var source_id = tileset.get_source_id(source_idx)
		var source = tileset.get_source(source_id)
		
		if source is TileSetAtlasSource:
			var atlas = source as TileSetAtlasSource
			var tiles_count = atlas.get_tiles_count()
			
			for tile_id in range(tiles_count):
				var tile_coords = atlas.get_tile_id(tile_id)
				var tile_data = atlas.get_tile_data(tile_coords, 0)
				
				if tile_data:
					for physics_layer in range(tileset.get_physics_layers_count()):
						var polygons_count = tile_data.get_collision_polygons_count(physics_layer)
						
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

