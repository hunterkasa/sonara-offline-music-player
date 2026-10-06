import 'package:drift/drift.dart';

@TableIndex(name: 'idx_tracks_artist_id', columns: {#artistId})
@TableIndex(name: 'idx_tracks_album_id', columns: {#albumId})
@TableIndex(name: 'idx_tracks_title_sort', columns: {#titleSort})
@TableIndex(name: 'idx_tracks_date_added', columns: {#dateAdded})
@TableIndex(name: 'idx_tracks_last_played', columns: {#lastPlayedAt})
@TableIndex(name: 'idx_tracks_play_count', columns: {#playCount})
@TableIndex(name: 'idx_tracks_is_favorite', columns: {#isFavorite})
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackKey => text().unique()();
  IntColumn get mediaStoreId => integer().nullable()();
  TextColumn get contentUri => text()();
  TextColumn get path => text()();
  TextColumn get relativeDir => text().withDefault(const Constant(''))();
  TextColumn get title => text()();
  TextColumn get titleSort => text()();
  IntColumn get artistId => integer().nullable()();
  IntColumn get albumId => integer().nullable()();
  IntColumn get albumArtistId => integer().nullable()();
  IntColumn get trackNo => integer().nullable()();
  IntColumn get discNo => integer().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get durationMs => integer()();
  IntColumn get bitrate => integer().nullable()();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get bitDepth => integer().nullable()();
  IntColumn get channels => integer().nullable()();
  TextColumn get mime => text().nullable()();
  IntColumn get sizeBytes => integer()();
  IntColumn get dateAdded => integer().nullable()();
  IntColumn get dateModified => integer().nullable()();
  TextColumn get artworkKey => text().nullable()();
  RealColumn get replayGainTrackDb => real().nullable()();
  RealColumn get replayGainAlbumDb => real().nullable()();
  BoolColumn get hasLyrics => boolean().withDefault(const Constant(false))();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get skipCount => integer().withDefault(const Constant(0))();
  IntColumn get lastPlayedAt => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isMissing => boolean().withDefault(const Constant(false))();
  IntColumn get rating => integer().withDefault(const Constant(0))();
  IntColumn get cueStartMs => integer().nullable()();
  IntColumn get cueEndMs => integer().nullable()();
}

class Artists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get nameSort => text()();
  TextColumn get artworkKey => text().nullable()();
}

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get titleSort => text()();
  IntColumn get albumArtistId => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get artworkKey => text().nullable()();
  TextColumn get paletteJson => text().nullable()();
}

class Genres extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class TrackGenres extends Table {
  IntColumn get trackId => integer()();
  IntColumn get genreId => integer()();

  @override
  Set<Column> get primaryKey => {trackId, genreId};
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get coverUri => text().nullable()();
  BoolColumn get isSmart => boolean().withDefault(const Constant(false))();
  TextColumn get rulesJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class PlaylistTracks extends Table {
  IntColumn get playlistId => integer()();
  TextColumn get trackKey => text()();
  IntColumn get position => integer()();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, trackKey};
}

class QueueStateTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get currentTrackKey => text().nullable()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  BoolColumn get shuffle => boolean().withDefault(const Constant(false))();
  IntColumn get repeatMode => integer().withDefault(const Constant(0))();
  IntColumn get seed => integer().withDefault(const Constant(0))();
  TextColumn get queueJson => text().withDefault(const Constant('[]'))();
}

class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackKey => text()();
  IntColumn get startedAt => integer()();
  IntColumn get listenedMs => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().nullable()();
}

class LibraryFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  TextColumn get mode => text().withDefault(const Constant('include'))();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();

  @override
  Set<Column> get primaryKey => {key};
}
