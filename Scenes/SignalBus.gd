extends Node

# === BOARD GENERAL ===
signal board_refresh_requested

# === DECK GENERAL ===

# === PLAYER EVENTS ===
signal player_moved(final_tile_index: int, final_hour: int)
signal player_landed_on_tile(tile_index: int, hour: int)

# === DAY/TIME EVENTS ===
signal day_changed(new_day: int)
signal midnight_crossed

# === EVENT SYSTEM ===
signal event_triggered(event: Event)
signal popup_requested(event: Event)
signal popup_closed

# === CHARACTER/DECK EVENTS (for future) ===
signal character_collected(character: Character)
signal deck_updated
signal dialogue_requested(card: Card)
signal dialogue_finished(card: Card)
