extends Node

signal current_score_updated(score)
signal current_energy_updated(energy)
signal current_combo_updated(combo)

signal song_begin
signal song_end

# Playlist signals
signal playlist_song_started(song_index: int, total_songs: int)
signal playlist_completed
