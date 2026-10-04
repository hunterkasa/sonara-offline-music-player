// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackKeyMeta = const VerificationMeta(
    'trackKey',
  );
  @override
  late final GeneratedColumn<String> trackKey = GeneratedColumn<String>(
    'track_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _mediaStoreIdMeta = const VerificationMeta(
    'mediaStoreId',
  );
  @override
  late final GeneratedColumn<int> mediaStoreId = GeneratedColumn<int>(
    'media_store_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentUriMeta = const VerificationMeta(
    'contentUri',
  );
  @override
  late final GeneratedColumn<String> contentUri = GeneratedColumn<String>(
    'content_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativeDirMeta = const VerificationMeta(
    'relativeDir',
  );
  @override
  late final GeneratedColumn<String> relativeDir = GeneratedColumn<String>(
    'relative_dir',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleSortMeta = const VerificationMeta(
    'titleSort',
  );
  @override
  late final GeneratedColumn<String> titleSort = GeneratedColumn<String>(
    'title_sort',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<int> artistId = GeneratedColumn<int>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtistIdMeta = const VerificationMeta(
    'albumArtistId',
  );
  @override
  late final GeneratedColumn<int> albumArtistId = GeneratedColumn<int>(
    'album_artist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNoMeta = const VerificationMeta(
    'trackNo',
  );
  @override
  late final GeneratedColumn<int> trackNo = GeneratedColumn<int>(
    'track_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNoMeta = const VerificationMeta('discNo');
  @override
  late final GeneratedColumn<int> discNo = GeneratedColumn<int>(
    'disc_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bitrateMeta = const VerificationMeta(
    'bitrate',
  );
  @override
  late final GeneratedColumn<int> bitrate = GeneratedColumn<int>(
    'bitrate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleRateMeta = const VerificationMeta(
    'sampleRate',
  );
  @override
  late final GeneratedColumn<int> sampleRate = GeneratedColumn<int>(
    'sample_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitDepthMeta = const VerificationMeta(
    'bitDepth',
  );
  @override
  late final GeneratedColumn<int> bitDepth = GeneratedColumn<int>(
    'bit_depth',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelsMeta = const VerificationMeta(
    'channels',
  );
  @override
  late final GeneratedColumn<int> channels = GeneratedColumn<int>(
    'channels',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<int> dateAdded = GeneratedColumn<int>(
    'date_added',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateModifiedMeta = const VerificationMeta(
    'dateModified',
  );
  @override
  late final GeneratedColumn<int> dateModified = GeneratedColumn<int>(
    'date_modified',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkKeyMeta = const VerificationMeta(
    'artworkKey',
  );
  @override
  late final GeneratedColumn<String> artworkKey = GeneratedColumn<String>(
    'artwork_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replayGainTrackDbMeta = const VerificationMeta(
    'replayGainTrackDb',
  );
  @override
  late final GeneratedColumn<double> replayGainTrackDb =
      GeneratedColumn<double>(
        'replay_gain_track_db',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _replayGainAlbumDbMeta = const VerificationMeta(
    'replayGainAlbumDb',
  );
  @override
  late final GeneratedColumn<double> replayGainAlbumDb =
      GeneratedColumn<double>(
        'replay_gain_album_db',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _hasLyricsMeta = const VerificationMeta(
    'hasLyrics',
  );
  @override
  late final GeneratedColumn<bool> hasLyrics = GeneratedColumn<bool>(
    'has_lyrics',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_lyrics" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skipCountMeta = const VerificationMeta(
    'skipCount',
  );
  @override
  late final GeneratedColumn<int> skipCount = GeneratedColumn<int>(
    'skip_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<int> lastPlayedAt = GeneratedColumn<int>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isMissingMeta = const VerificationMeta(
    'isMissing',
  );
  @override
  late final GeneratedColumn<bool> isMissing = GeneratedColumn<bool>(
    'is_missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_missing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackKey,
    mediaStoreId,
    contentUri,
    path,
    relativeDir,
    title,
    titleSort,
    artistId,
    albumId,
    albumArtistId,
    trackNo,
    discNo,
    year,
    durationMs,
    bitrate,
    sampleRate,
    bitDepth,
    channels,
    mime,
    sizeBytes,
    dateAdded,
    dateModified,
    artworkKey,
    replayGainTrackDb,
    replayGainAlbumDb,
    hasLyrics,
    playCount,
    skipCount,
    lastPlayedAt,
    isFavorite,
    isHidden,
    isMissing,
    rating,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_key')) {
      context.handle(
        _trackKeyMeta,
        trackKey.isAcceptableOrUnknown(data['track_key']!, _trackKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_trackKeyMeta);
    }
    if (data.containsKey('media_store_id')) {
      context.handle(
        _mediaStoreIdMeta,
        mediaStoreId.isAcceptableOrUnknown(
          data['media_store_id']!,
          _mediaStoreIdMeta,
        ),
      );
    }
    if (data.containsKey('content_uri')) {
      context.handle(
        _contentUriMeta,
        contentUri.isAcceptableOrUnknown(data['content_uri']!, _contentUriMeta),
      );
    } else if (isInserting) {
      context.missing(_contentUriMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('relative_dir')) {
      context.handle(
        _relativeDirMeta,
        relativeDir.isAcceptableOrUnknown(
          data['relative_dir']!,
          _relativeDirMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_sort')) {
      context.handle(
        _titleSortMeta,
        titleSort.isAcceptableOrUnknown(data['title_sort']!, _titleSortMeta),
      );
    } else if (isInserting) {
      context.missing(_titleSortMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('album_artist_id')) {
      context.handle(
        _albumArtistIdMeta,
        albumArtistId.isAcceptableOrUnknown(
          data['album_artist_id']!,
          _albumArtistIdMeta,
        ),
      );
    }
    if (data.containsKey('track_no')) {
      context.handle(
        _trackNoMeta,
        trackNo.isAcceptableOrUnknown(data['track_no']!, _trackNoMeta),
      );
    }
    if (data.containsKey('disc_no')) {
      context.handle(
        _discNoMeta,
        discNo.isAcceptableOrUnknown(data['disc_no']!, _discNoMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('bitrate')) {
      context.handle(
        _bitrateMeta,
        bitrate.isAcceptableOrUnknown(data['bitrate']!, _bitrateMeta),
      );
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
        _sampleRateMeta,
        sampleRate.isAcceptableOrUnknown(data['sample_rate']!, _sampleRateMeta),
      );
    }
    if (data.containsKey('bit_depth')) {
      context.handle(
        _bitDepthMeta,
        bitDepth.isAcceptableOrUnknown(data['bit_depth']!, _bitDepthMeta),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    if (data.containsKey('date_modified')) {
      context.handle(
        _dateModifiedMeta,
        dateModified.isAcceptableOrUnknown(
          data['date_modified']!,
          _dateModifiedMeta,
        ),
      );
    }
    if (data.containsKey('artwork_key')) {
      context.handle(
        _artworkKeyMeta,
        artworkKey.isAcceptableOrUnknown(data['artwork_key']!, _artworkKeyMeta),
      );
    }
    if (data.containsKey('replay_gain_track_db')) {
      context.handle(
        _replayGainTrackDbMeta,
        replayGainTrackDb.isAcceptableOrUnknown(
          data['replay_gain_track_db']!,
          _replayGainTrackDbMeta,
        ),
      );
    }
    if (data.containsKey('replay_gain_album_db')) {
      context.handle(
        _replayGainAlbumDbMeta,
        replayGainAlbumDb.isAcceptableOrUnknown(
          data['replay_gain_album_db']!,
          _replayGainAlbumDbMeta,
        ),
      );
    }
    if (data.containsKey('has_lyrics')) {
      context.handle(
        _hasLyricsMeta,
        hasLyrics.isAcceptableOrUnknown(data['has_lyrics']!, _hasLyricsMeta),
      );
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('skip_count')) {
      context.handle(
        _skipCountMeta,
        skipCount.isAcceptableOrUnknown(data['skip_count']!, _skipCountMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_missing')) {
      context.handle(
        _isMissingMeta,
        isMissing.isAcceptableOrUnknown(data['is_missing']!, _isMissingMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_key'],
      )!,
      mediaStoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_store_id'],
      ),
      contentUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_uri'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      relativeDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_dir'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleSort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_sort'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}artist_id'],
      ),
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      ),
      albumArtistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_artist_id'],
      ),
      trackNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_no'],
      ),
      discNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_no'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      bitrate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bitrate'],
      ),
      sampleRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate'],
      ),
      bitDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bit_depth'],
      ),
      channels: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channels'],
      ),
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_added'],
      ),
      dateModified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_modified'],
      ),
      artworkKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_key'],
      ),
      replayGainTrackDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replay_gain_track_db'],
      ),
      replayGainAlbumDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replay_gain_album_db'],
      ),
      hasLyrics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_lyrics'],
      )!,
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      skipCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skip_count'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_played_at'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isMissing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_missing'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final int id;
  final String trackKey;
  final int? mediaStoreId;
  final String contentUri;
  final String path;
  final String relativeDir;
  final String title;
  final String titleSort;
  final int? artistId;
  final int? albumId;
  final int? albumArtistId;
  final int? trackNo;
  final int? discNo;
  final int? year;
  final int durationMs;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final int? channels;
  final String? mime;
  final int sizeBytes;
  final int? dateAdded;
  final int? dateModified;
  final String? artworkKey;
  final double? replayGainTrackDb;
  final double? replayGainAlbumDb;
  final bool hasLyrics;
  final int playCount;
  final int skipCount;
  final int? lastPlayedAt;
  final bool isFavorite;
  final bool isHidden;
  final bool isMissing;
  final int rating;
  const Track({
    required this.id,
    required this.trackKey,
    this.mediaStoreId,
    required this.contentUri,
    required this.path,
    required this.relativeDir,
    required this.title,
    required this.titleSort,
    this.artistId,
    this.albumId,
    this.albumArtistId,
    this.trackNo,
    this.discNo,
    this.year,
    required this.durationMs,
    this.bitrate,
    this.sampleRate,
    this.bitDepth,
    this.channels,
    this.mime,
    required this.sizeBytes,
    this.dateAdded,
    this.dateModified,
    this.artworkKey,
    this.replayGainTrackDb,
    this.replayGainAlbumDb,
    required this.hasLyrics,
    required this.playCount,
    required this.skipCount,
    this.lastPlayedAt,
    required this.isFavorite,
    required this.isHidden,
    required this.isMissing,
    required this.rating,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_key'] = Variable<String>(trackKey);
    if (!nullToAbsent || mediaStoreId != null) {
      map['media_store_id'] = Variable<int>(mediaStoreId);
    }
    map['content_uri'] = Variable<String>(contentUri);
    map['path'] = Variable<String>(path);
    map['relative_dir'] = Variable<String>(relativeDir);
    map['title'] = Variable<String>(title);
    map['title_sort'] = Variable<String>(titleSort);
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<int>(artistId);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || albumArtistId != null) {
      map['album_artist_id'] = Variable<int>(albumArtistId);
    }
    if (!nullToAbsent || trackNo != null) {
      map['track_no'] = Variable<int>(trackNo);
    }
    if (!nullToAbsent || discNo != null) {
      map['disc_no'] = Variable<int>(discNo);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || bitrate != null) {
      map['bitrate'] = Variable<int>(bitrate);
    }
    if (!nullToAbsent || sampleRate != null) {
      map['sample_rate'] = Variable<int>(sampleRate);
    }
    if (!nullToAbsent || bitDepth != null) {
      map['bit_depth'] = Variable<int>(bitDepth);
    }
    if (!nullToAbsent || channels != null) {
      map['channels'] = Variable<int>(channels);
    }
    if (!nullToAbsent || mime != null) {
      map['mime'] = Variable<String>(mime);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || dateAdded != null) {
      map['date_added'] = Variable<int>(dateAdded);
    }
    if (!nullToAbsent || dateModified != null) {
      map['date_modified'] = Variable<int>(dateModified);
    }
    if (!nullToAbsent || artworkKey != null) {
      map['artwork_key'] = Variable<String>(artworkKey);
    }
    if (!nullToAbsent || replayGainTrackDb != null) {
      map['replay_gain_track_db'] = Variable<double>(replayGainTrackDb);
    }
    if (!nullToAbsent || replayGainAlbumDb != null) {
      map['replay_gain_album_db'] = Variable<double>(replayGainAlbumDb);
    }
    map['has_lyrics'] = Variable<bool>(hasLyrics);
    map['play_count'] = Variable<int>(playCount);
    map['skip_count'] = Variable<int>(skipCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<int>(lastPlayedAt);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['is_missing'] = Variable<bool>(isMissing);
    map['rating'] = Variable<int>(rating);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      trackKey: Value(trackKey),
      mediaStoreId: mediaStoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaStoreId),
      contentUri: Value(contentUri),
      path: Value(path),
      relativeDir: Value(relativeDir),
      title: Value(title),
      titleSort: Value(titleSort),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      albumArtistId: albumArtistId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtistId),
      trackNo: trackNo == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNo),
      discNo: discNo == null && nullToAbsent
          ? const Value.absent()
          : Value(discNo),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      durationMs: Value(durationMs),
      bitrate: bitrate == null && nullToAbsent
          ? const Value.absent()
          : Value(bitrate),
      sampleRate: sampleRate == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRate),
      bitDepth: bitDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(bitDepth),
      channels: channels == null && nullToAbsent
          ? const Value.absent()
          : Value(channels),
      mime: mime == null && nullToAbsent ? const Value.absent() : Value(mime),
      sizeBytes: Value(sizeBytes),
      dateAdded: dateAdded == null && nullToAbsent
          ? const Value.absent()
          : Value(dateAdded),
      dateModified: dateModified == null && nullToAbsent
          ? const Value.absent()
          : Value(dateModified),
      artworkKey: artworkKey == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkKey),
      replayGainTrackDb: replayGainTrackDb == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGainTrackDb),
      replayGainAlbumDb: replayGainAlbumDb == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGainAlbumDb),
      hasLyrics: Value(hasLyrics),
      playCount: Value(playCount),
      skipCount: Value(skipCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      isFavorite: Value(isFavorite),
      isHidden: Value(isHidden),
      isMissing: Value(isMissing),
      rating: Value(rating),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<int>(json['id']),
      trackKey: serializer.fromJson<String>(json['trackKey']),
      mediaStoreId: serializer.fromJson<int?>(json['mediaStoreId']),
      contentUri: serializer.fromJson<String>(json['contentUri']),
      path: serializer.fromJson<String>(json['path']),
      relativeDir: serializer.fromJson<String>(json['relativeDir']),
      title: serializer.fromJson<String>(json['title']),
      titleSort: serializer.fromJson<String>(json['titleSort']),
      artistId: serializer.fromJson<int?>(json['artistId']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      albumArtistId: serializer.fromJson<int?>(json['albumArtistId']),
      trackNo: serializer.fromJson<int?>(json['trackNo']),
      discNo: serializer.fromJson<int?>(json['discNo']),
      year: serializer.fromJson<int?>(json['year']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      bitrate: serializer.fromJson<int?>(json['bitrate']),
      sampleRate: serializer.fromJson<int?>(json['sampleRate']),
      bitDepth: serializer.fromJson<int?>(json['bitDepth']),
      channels: serializer.fromJson<int?>(json['channels']),
      mime: serializer.fromJson<String?>(json['mime']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      dateAdded: serializer.fromJson<int?>(json['dateAdded']),
      dateModified: serializer.fromJson<int?>(json['dateModified']),
      artworkKey: serializer.fromJson<String?>(json['artworkKey']),
      replayGainTrackDb: serializer.fromJson<double?>(
        json['replayGainTrackDb'],
      ),
      replayGainAlbumDb: serializer.fromJson<double?>(
        json['replayGainAlbumDb'],
      ),
      hasLyrics: serializer.fromJson<bool>(json['hasLyrics']),
      playCount: serializer.fromJson<int>(json['playCount']),
      skipCount: serializer.fromJson<int>(json['skipCount']),
      lastPlayedAt: serializer.fromJson<int?>(json['lastPlayedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      isMissing: serializer.fromJson<bool>(json['isMissing']),
      rating: serializer.fromJson<int>(json['rating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackKey': serializer.toJson<String>(trackKey),
      'mediaStoreId': serializer.toJson<int?>(mediaStoreId),
      'contentUri': serializer.toJson<String>(contentUri),
      'path': serializer.toJson<String>(path),
      'relativeDir': serializer.toJson<String>(relativeDir),
      'title': serializer.toJson<String>(title),
      'titleSort': serializer.toJson<String>(titleSort),
      'artistId': serializer.toJson<int?>(artistId),
      'albumId': serializer.toJson<int?>(albumId),
      'albumArtistId': serializer.toJson<int?>(albumArtistId),
      'trackNo': serializer.toJson<int?>(trackNo),
      'discNo': serializer.toJson<int?>(discNo),
      'year': serializer.toJson<int?>(year),
      'durationMs': serializer.toJson<int>(durationMs),
      'bitrate': serializer.toJson<int?>(bitrate),
      'sampleRate': serializer.toJson<int?>(sampleRate),
      'bitDepth': serializer.toJson<int?>(bitDepth),
      'channels': serializer.toJson<int?>(channels),
      'mime': serializer.toJson<String?>(mime),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'dateAdded': serializer.toJson<int?>(dateAdded),
      'dateModified': serializer.toJson<int?>(dateModified),
      'artworkKey': serializer.toJson<String?>(artworkKey),
      'replayGainTrackDb': serializer.toJson<double?>(replayGainTrackDb),
      'replayGainAlbumDb': serializer.toJson<double?>(replayGainAlbumDb),
      'hasLyrics': serializer.toJson<bool>(hasLyrics),
      'playCount': serializer.toJson<int>(playCount),
      'skipCount': serializer.toJson<int>(skipCount),
      'lastPlayedAt': serializer.toJson<int?>(lastPlayedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isHidden': serializer.toJson<bool>(isHidden),
      'isMissing': serializer.toJson<bool>(isMissing),
      'rating': serializer.toJson<int>(rating),
    };
  }

  Track copyWith({
    int? id,
    String? trackKey,
    Value<int?> mediaStoreId = const Value.absent(),
    String? contentUri,
    String? path,
    String? relativeDir,
    String? title,
    String? titleSort,
    Value<int?> artistId = const Value.absent(),
    Value<int?> albumId = const Value.absent(),
    Value<int?> albumArtistId = const Value.absent(),
    Value<int?> trackNo = const Value.absent(),
    Value<int?> discNo = const Value.absent(),
    Value<int?> year = const Value.absent(),
    int? durationMs,
    Value<int?> bitrate = const Value.absent(),
    Value<int?> sampleRate = const Value.absent(),
    Value<int?> bitDepth = const Value.absent(),
    Value<int?> channels = const Value.absent(),
    Value<String?> mime = const Value.absent(),
    int? sizeBytes,
    Value<int?> dateAdded = const Value.absent(),
    Value<int?> dateModified = const Value.absent(),
    Value<String?> artworkKey = const Value.absent(),
    Value<double?> replayGainTrackDb = const Value.absent(),
    Value<double?> replayGainAlbumDb = const Value.absent(),
    bool? hasLyrics,
    int? playCount,
    int? skipCount,
    Value<int?> lastPlayedAt = const Value.absent(),
    bool? isFavorite,
    bool? isHidden,
    bool? isMissing,
    int? rating,
  }) => Track(
    id: id ?? this.id,
    trackKey: trackKey ?? this.trackKey,
    mediaStoreId: mediaStoreId.present ? mediaStoreId.value : this.mediaStoreId,
    contentUri: contentUri ?? this.contentUri,
    path: path ?? this.path,
    relativeDir: relativeDir ?? this.relativeDir,
    title: title ?? this.title,
    titleSort: titleSort ?? this.titleSort,
    artistId: artistId.present ? artistId.value : this.artistId,
    albumId: albumId.present ? albumId.value : this.albumId,
    albumArtistId: albumArtistId.present
        ? albumArtistId.value
        : this.albumArtistId,
    trackNo: trackNo.present ? trackNo.value : this.trackNo,
    discNo: discNo.present ? discNo.value : this.discNo,
    year: year.present ? year.value : this.year,
    durationMs: durationMs ?? this.durationMs,
    bitrate: bitrate.present ? bitrate.value : this.bitrate,
    sampleRate: sampleRate.present ? sampleRate.value : this.sampleRate,
    bitDepth: bitDepth.present ? bitDepth.value : this.bitDepth,
    channels: channels.present ? channels.value : this.channels,
    mime: mime.present ? mime.value : this.mime,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    dateAdded: dateAdded.present ? dateAdded.value : this.dateAdded,
    dateModified: dateModified.present ? dateModified.value : this.dateModified,
    artworkKey: artworkKey.present ? artworkKey.value : this.artworkKey,
    replayGainTrackDb: replayGainTrackDb.present
        ? replayGainTrackDb.value
        : this.replayGainTrackDb,
    replayGainAlbumDb: replayGainAlbumDb.present
        ? replayGainAlbumDb.value
        : this.replayGainAlbumDb,
    hasLyrics: hasLyrics ?? this.hasLyrics,
    playCount: playCount ?? this.playCount,
    skipCount: skipCount ?? this.skipCount,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    isHidden: isHidden ?? this.isHidden,
    isMissing: isMissing ?? this.isMissing,
    rating: rating ?? this.rating,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      trackKey: data.trackKey.present ? data.trackKey.value : this.trackKey,
      mediaStoreId: data.mediaStoreId.present
          ? data.mediaStoreId.value
          : this.mediaStoreId,
      contentUri: data.contentUri.present
          ? data.contentUri.value
          : this.contentUri,
      path: data.path.present ? data.path.value : this.path,
      relativeDir: data.relativeDir.present
          ? data.relativeDir.value
          : this.relativeDir,
      title: data.title.present ? data.title.value : this.title,
      titleSort: data.titleSort.present ? data.titleSort.value : this.titleSort,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      albumArtistId: data.albumArtistId.present
          ? data.albumArtistId.value
          : this.albumArtistId,
      trackNo: data.trackNo.present ? data.trackNo.value : this.trackNo,
      discNo: data.discNo.present ? data.discNo.value : this.discNo,
      year: data.year.present ? data.year.value : this.year,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      bitrate: data.bitrate.present ? data.bitrate.value : this.bitrate,
      sampleRate: data.sampleRate.present
          ? data.sampleRate.value
          : this.sampleRate,
      bitDepth: data.bitDepth.present ? data.bitDepth.value : this.bitDepth,
      channels: data.channels.present ? data.channels.value : this.channels,
      mime: data.mime.present ? data.mime.value : this.mime,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      dateModified: data.dateModified.present
          ? data.dateModified.value
          : this.dateModified,
      artworkKey: data.artworkKey.present
          ? data.artworkKey.value
          : this.artworkKey,
      replayGainTrackDb: data.replayGainTrackDb.present
          ? data.replayGainTrackDb.value
          : this.replayGainTrackDb,
      replayGainAlbumDb: data.replayGainAlbumDb.present
          ? data.replayGainAlbumDb.value
          : this.replayGainAlbumDb,
      hasLyrics: data.hasLyrics.present ? data.hasLyrics.value : this.hasLyrics,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      skipCount: data.skipCount.present ? data.skipCount.value : this.skipCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      isMissing: data.isMissing.present ? data.isMissing.value : this.isMissing,
      rating: data.rating.present ? data.rating.value : this.rating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('trackKey: $trackKey, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('contentUri: $contentUri, ')
          ..write('path: $path, ')
          ..write('relativeDir: $relativeDir, ')
          ..write('title: $title, ')
          ..write('titleSort: $titleSort, ')
          ..write('artistId: $artistId, ')
          ..write('albumId: $albumId, ')
          ..write('albumArtistId: $albumArtistId, ')
          ..write('trackNo: $trackNo, ')
          ..write('discNo: $discNo, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('bitrate: $bitrate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('channels: $channels, ')
          ..write('mime: $mime, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('dateModified: $dateModified, ')
          ..write('artworkKey: $artworkKey, ')
          ..write('replayGainTrackDb: $replayGainTrackDb, ')
          ..write('replayGainAlbumDb: $replayGainAlbumDb, ')
          ..write('hasLyrics: $hasLyrics, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isHidden: $isHidden, ')
          ..write('isMissing: $isMissing, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    trackKey,
    mediaStoreId,
    contentUri,
    path,
    relativeDir,
    title,
    titleSort,
    artistId,
    albumId,
    albumArtistId,
    trackNo,
    discNo,
    year,
    durationMs,
    bitrate,
    sampleRate,
    bitDepth,
    channels,
    mime,
    sizeBytes,
    dateAdded,
    dateModified,
    artworkKey,
    replayGainTrackDb,
    replayGainAlbumDb,
    hasLyrics,
    playCount,
    skipCount,
    lastPlayedAt,
    isFavorite,
    isHidden,
    isMissing,
    rating,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.trackKey == this.trackKey &&
          other.mediaStoreId == this.mediaStoreId &&
          other.contentUri == this.contentUri &&
          other.path == this.path &&
          other.relativeDir == this.relativeDir &&
          other.title == this.title &&
          other.titleSort == this.titleSort &&
          other.artistId == this.artistId &&
          other.albumId == this.albumId &&
          other.albumArtistId == this.albumArtistId &&
          other.trackNo == this.trackNo &&
          other.discNo == this.discNo &&
          other.year == this.year &&
          other.durationMs == this.durationMs &&
          other.bitrate == this.bitrate &&
          other.sampleRate == this.sampleRate &&
          other.bitDepth == this.bitDepth &&
          other.channels == this.channels &&
          other.mime == this.mime &&
          other.sizeBytes == this.sizeBytes &&
          other.dateAdded == this.dateAdded &&
          other.dateModified == this.dateModified &&
          other.artworkKey == this.artworkKey &&
          other.replayGainTrackDb == this.replayGainTrackDb &&
          other.replayGainAlbumDb == this.replayGainAlbumDb &&
          other.hasLyrics == this.hasLyrics &&
          other.playCount == this.playCount &&
          other.skipCount == this.skipCount &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.isFavorite == this.isFavorite &&
          other.isHidden == this.isHidden &&
          other.isMissing == this.isMissing &&
          other.rating == this.rating);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<int> id;
  final Value<String> trackKey;
  final Value<int?> mediaStoreId;
  final Value<String> contentUri;
  final Value<String> path;
  final Value<String> relativeDir;
  final Value<String> title;
  final Value<String> titleSort;
  final Value<int?> artistId;
  final Value<int?> albumId;
  final Value<int?> albumArtistId;
  final Value<int?> trackNo;
  final Value<int?> discNo;
  final Value<int?> year;
  final Value<int> durationMs;
  final Value<int?> bitrate;
  final Value<int?> sampleRate;
  final Value<int?> bitDepth;
  final Value<int?> channels;
  final Value<String?> mime;
  final Value<int> sizeBytes;
  final Value<int?> dateAdded;
  final Value<int?> dateModified;
  final Value<String?> artworkKey;
  final Value<double?> replayGainTrackDb;
  final Value<double?> replayGainAlbumDb;
  final Value<bool> hasLyrics;
  final Value<int> playCount;
  final Value<int> skipCount;
  final Value<int?> lastPlayedAt;
  final Value<bool> isFavorite;
  final Value<bool> isHidden;
  final Value<bool> isMissing;
  final Value<int> rating;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.trackKey = const Value.absent(),
    this.mediaStoreId = const Value.absent(),
    this.contentUri = const Value.absent(),
    this.path = const Value.absent(),
    this.relativeDir = const Value.absent(),
    this.title = const Value.absent(),
    this.titleSort = const Value.absent(),
    this.artistId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumArtistId = const Value.absent(),
    this.trackNo = const Value.absent(),
    this.discNo = const Value.absent(),
    this.year = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.bitrate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.channels = const Value.absent(),
    this.mime = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.dateModified = const Value.absent(),
    this.artworkKey = const Value.absent(),
    this.replayGainTrackDb = const Value.absent(),
    this.replayGainAlbumDb = const Value.absent(),
    this.hasLyrics = const Value.absent(),
    this.playCount = const Value.absent(),
    this.skipCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isMissing = const Value.absent(),
    this.rating = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required String trackKey,
    this.mediaStoreId = const Value.absent(),
    required String contentUri,
    required String path,
    this.relativeDir = const Value.absent(),
    required String title,
    required String titleSort,
    this.artistId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumArtistId = const Value.absent(),
    this.trackNo = const Value.absent(),
    this.discNo = const Value.absent(),
    this.year = const Value.absent(),
    required int durationMs,
    this.bitrate = const Value.absent(),
    this.sampleRate = const Value.absent(),
    this.bitDepth = const Value.absent(),
    this.channels = const Value.absent(),
    this.mime = const Value.absent(),
    required int sizeBytes,
    this.dateAdded = const Value.absent(),
    this.dateModified = const Value.absent(),
    this.artworkKey = const Value.absent(),
    this.replayGainTrackDb = const Value.absent(),
    this.replayGainAlbumDb = const Value.absent(),
    this.hasLyrics = const Value.absent(),
    this.playCount = const Value.absent(),
    this.skipCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isMissing = const Value.absent(),
    this.rating = const Value.absent(),
  }) : trackKey = Value(trackKey),
       contentUri = Value(contentUri),
       path = Value(path),
       title = Value(title),
       titleSort = Value(titleSort),
       durationMs = Value(durationMs),
       sizeBytes = Value(sizeBytes);
  static Insertable<Track> custom({
    Expression<int>? id,
    Expression<String>? trackKey,
    Expression<int>? mediaStoreId,
    Expression<String>? contentUri,
    Expression<String>? path,
    Expression<String>? relativeDir,
    Expression<String>? title,
    Expression<String>? titleSort,
    Expression<int>? artistId,
    Expression<int>? albumId,
    Expression<int>? albumArtistId,
    Expression<int>? trackNo,
    Expression<int>? discNo,
    Expression<int>? year,
    Expression<int>? durationMs,
    Expression<int>? bitrate,
    Expression<int>? sampleRate,
    Expression<int>? bitDepth,
    Expression<int>? channels,
    Expression<String>? mime,
    Expression<int>? sizeBytes,
    Expression<int>? dateAdded,
    Expression<int>? dateModified,
    Expression<String>? artworkKey,
    Expression<double>? replayGainTrackDb,
    Expression<double>? replayGainAlbumDb,
    Expression<bool>? hasLyrics,
    Expression<int>? playCount,
    Expression<int>? skipCount,
    Expression<int>? lastPlayedAt,
    Expression<bool>? isFavorite,
    Expression<bool>? isHidden,
    Expression<bool>? isMissing,
    Expression<int>? rating,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackKey != null) 'track_key': trackKey,
      if (mediaStoreId != null) 'media_store_id': mediaStoreId,
      if (contentUri != null) 'content_uri': contentUri,
      if (path != null) 'path': path,
      if (relativeDir != null) 'relative_dir': relativeDir,
      if (title != null) 'title': title,
      if (titleSort != null) 'title_sort': titleSort,
      if (artistId != null) 'artist_id': artistId,
      if (albumId != null) 'album_id': albumId,
      if (albumArtistId != null) 'album_artist_id': albumArtistId,
      if (trackNo != null) 'track_no': trackNo,
      if (discNo != null) 'disc_no': discNo,
      if (year != null) 'year': year,
      if (durationMs != null) 'duration_ms': durationMs,
      if (bitrate != null) 'bitrate': bitrate,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (bitDepth != null) 'bit_depth': bitDepth,
      if (channels != null) 'channels': channels,
      if (mime != null) 'mime': mime,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (dateAdded != null) 'date_added': dateAdded,
      if (dateModified != null) 'date_modified': dateModified,
      if (artworkKey != null) 'artwork_key': artworkKey,
      if (replayGainTrackDb != null) 'replay_gain_track_db': replayGainTrackDb,
      if (replayGainAlbumDb != null) 'replay_gain_album_db': replayGainAlbumDb,
      if (hasLyrics != null) 'has_lyrics': hasLyrics,
      if (playCount != null) 'play_count': playCount,
      if (skipCount != null) 'skip_count': skipCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isMissing != null) 'is_missing': isMissing,
      if (rating != null) 'rating': rating,
    });
  }

  TracksCompanion copyWith({
    Value<int>? id,
    Value<String>? trackKey,
    Value<int?>? mediaStoreId,
    Value<String>? contentUri,
    Value<String>? path,
    Value<String>? relativeDir,
    Value<String>? title,
    Value<String>? titleSort,
    Value<int?>? artistId,
    Value<int?>? albumId,
    Value<int?>? albumArtistId,
    Value<int?>? trackNo,
    Value<int?>? discNo,
    Value<int?>? year,
    Value<int>? durationMs,
    Value<int?>? bitrate,
    Value<int?>? sampleRate,
    Value<int?>? bitDepth,
    Value<int?>? channels,
    Value<String?>? mime,
    Value<int>? sizeBytes,
    Value<int?>? dateAdded,
    Value<int?>? dateModified,
    Value<String?>? artworkKey,
    Value<double?>? replayGainTrackDb,
    Value<double?>? replayGainAlbumDb,
    Value<bool>? hasLyrics,
    Value<int>? playCount,
    Value<int>? skipCount,
    Value<int?>? lastPlayedAt,
    Value<bool>? isFavorite,
    Value<bool>? isHidden,
    Value<bool>? isMissing,
    Value<int>? rating,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      trackKey: trackKey ?? this.trackKey,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      contentUri: contentUri ?? this.contentUri,
      path: path ?? this.path,
      relativeDir: relativeDir ?? this.relativeDir,
      title: title ?? this.title,
      titleSort: titleSort ?? this.titleSort,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      albumArtistId: albumArtistId ?? this.albumArtistId,
      trackNo: trackNo ?? this.trackNo,
      discNo: discNo ?? this.discNo,
      year: year ?? this.year,
      durationMs: durationMs ?? this.durationMs,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      channels: channels ?? this.channels,
      mime: mime ?? this.mime,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      artworkKey: artworkKey ?? this.artworkKey,
      replayGainTrackDb: replayGainTrackDb ?? this.replayGainTrackDb,
      replayGainAlbumDb: replayGainAlbumDb ?? this.replayGainAlbumDb,
      hasLyrics: hasLyrics ?? this.hasLyrics,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isHidden: isHidden ?? this.isHidden,
      isMissing: isMissing ?? this.isMissing,
      rating: rating ?? this.rating,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackKey.present) {
      map['track_key'] = Variable<String>(trackKey.value);
    }
    if (mediaStoreId.present) {
      map['media_store_id'] = Variable<int>(mediaStoreId.value);
    }
    if (contentUri.present) {
      map['content_uri'] = Variable<String>(contentUri.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (relativeDir.present) {
      map['relative_dir'] = Variable<String>(relativeDir.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleSort.present) {
      map['title_sort'] = Variable<String>(titleSort.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<int>(artistId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (albumArtistId.present) {
      map['album_artist_id'] = Variable<int>(albumArtistId.value);
    }
    if (trackNo.present) {
      map['track_no'] = Variable<int>(trackNo.value);
    }
    if (discNo.present) {
      map['disc_no'] = Variable<int>(discNo.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (bitrate.present) {
      map['bitrate'] = Variable<int>(bitrate.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = Variable<int>(sampleRate.value);
    }
    if (bitDepth.present) {
      map['bit_depth'] = Variable<int>(bitDepth.value);
    }
    if (channels.present) {
      map['channels'] = Variable<int>(channels.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<int>(dateAdded.value);
    }
    if (dateModified.present) {
      map['date_modified'] = Variable<int>(dateModified.value);
    }
    if (artworkKey.present) {
      map['artwork_key'] = Variable<String>(artworkKey.value);
    }
    if (replayGainTrackDb.present) {
      map['replay_gain_track_db'] = Variable<double>(replayGainTrackDb.value);
    }
    if (replayGainAlbumDb.present) {
      map['replay_gain_album_db'] = Variable<double>(replayGainAlbumDb.value);
    }
    if (hasLyrics.present) {
      map['has_lyrics'] = Variable<bool>(hasLyrics.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (skipCount.present) {
      map['skip_count'] = Variable<int>(skipCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<int>(lastPlayedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isMissing.present) {
      map['is_missing'] = Variable<bool>(isMissing.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('trackKey: $trackKey, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('contentUri: $contentUri, ')
          ..write('path: $path, ')
          ..write('relativeDir: $relativeDir, ')
          ..write('title: $title, ')
          ..write('titleSort: $titleSort, ')
          ..write('artistId: $artistId, ')
          ..write('albumId: $albumId, ')
          ..write('albumArtistId: $albumArtistId, ')
          ..write('trackNo: $trackNo, ')
          ..write('discNo: $discNo, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('bitrate: $bitrate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('channels: $channels, ')
          ..write('mime: $mime, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('dateModified: $dateModified, ')
          ..write('artworkKey: $artworkKey, ')
          ..write('replayGainTrackDb: $replayGainTrackDb, ')
          ..write('replayGainAlbumDb: $replayGainAlbumDb, ')
          ..write('hasLyrics: $hasLyrics, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isHidden: $isHidden, ')
          ..write('isMissing: $isMissing, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }
}

class $ArtistsTable extends Artists with TableInfo<$ArtistsTable, Artist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameSortMeta = const VerificationMeta(
    'nameSort',
  );
  @override
  late final GeneratedColumn<String> nameSort = GeneratedColumn<String>(
    'name_sort',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artworkKeyMeta = const VerificationMeta(
    'artworkKey',
  );
  @override
  late final GeneratedColumn<String> artworkKey = GeneratedColumn<String>(
    'artwork_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, nameSort, artworkKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Artist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_sort')) {
      context.handle(
        _nameSortMeta,
        nameSort.isAcceptableOrUnknown(data['name_sort']!, _nameSortMeta),
      );
    } else if (isInserting) {
      context.missing(_nameSortMeta);
    }
    if (data.containsKey('artwork_key')) {
      context.handle(
        _artworkKeyMeta,
        artworkKey.isAcceptableOrUnknown(data['artwork_key']!, _artworkKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Artist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Artist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameSort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_sort'],
      )!,
      artworkKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_key'],
      ),
    );
  }

  @override
  $ArtistsTable createAlias(String alias) {
    return $ArtistsTable(attachedDatabase, alias);
  }
}

class Artist extends DataClass implements Insertable<Artist> {
  final int id;
  final String name;
  final String nameSort;
  final String? artworkKey;
  const Artist({
    required this.id,
    required this.name,
    required this.nameSort,
    this.artworkKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['name_sort'] = Variable<String>(nameSort);
    if (!nullToAbsent || artworkKey != null) {
      map['artwork_key'] = Variable<String>(artworkKey);
    }
    return map;
  }

  ArtistsCompanion toCompanion(bool nullToAbsent) {
    return ArtistsCompanion(
      id: Value(id),
      name: Value(name),
      nameSort: Value(nameSort),
      artworkKey: artworkKey == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkKey),
    );
  }

  factory Artist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Artist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameSort: serializer.fromJson<String>(json['nameSort']),
      artworkKey: serializer.fromJson<String?>(json['artworkKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'nameSort': serializer.toJson<String>(nameSort),
      'artworkKey': serializer.toJson<String?>(artworkKey),
    };
  }

  Artist copyWith({
    int? id,
    String? name,
    String? nameSort,
    Value<String?> artworkKey = const Value.absent(),
  }) => Artist(
    id: id ?? this.id,
    name: name ?? this.name,
    nameSort: nameSort ?? this.nameSort,
    artworkKey: artworkKey.present ? artworkKey.value : this.artworkKey,
  );
  Artist copyWithCompanion(ArtistsCompanion data) {
    return Artist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameSort: data.nameSort.present ? data.nameSort.value : this.nameSort,
      artworkKey: data.artworkKey.present
          ? data.artworkKey.value
          : this.artworkKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Artist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameSort: $nameSort, ')
          ..write('artworkKey: $artworkKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, nameSort, artworkKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artist &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameSort == this.nameSort &&
          other.artworkKey == this.artworkKey);
}

class ArtistsCompanion extends UpdateCompanion<Artist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> nameSort;
  final Value<String?> artworkKey;
  const ArtistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameSort = const Value.absent(),
    this.artworkKey = const Value.absent(),
  });
  ArtistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String nameSort,
    this.artworkKey = const Value.absent(),
  }) : name = Value(name),
       nameSort = Value(nameSort);
  static Insertable<Artist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? nameSort,
    Expression<String>? artworkKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameSort != null) 'name_sort': nameSort,
      if (artworkKey != null) 'artwork_key': artworkKey,
    });
  }

  ArtistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? nameSort,
    Value<String?>? artworkKey,
  }) {
    return ArtistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameSort: nameSort ?? this.nameSort,
      artworkKey: artworkKey ?? this.artworkKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameSort.present) {
      map['name_sort'] = Variable<String>(nameSort.value);
    }
    if (artworkKey.present) {
      map['artwork_key'] = Variable<String>(artworkKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameSort: $nameSort, ')
          ..write('artworkKey: $artworkKey')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleSortMeta = const VerificationMeta(
    'titleSort',
  );
  @override
  late final GeneratedColumn<String> titleSort = GeneratedColumn<String>(
    'title_sort',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumArtistIdMeta = const VerificationMeta(
    'albumArtistId',
  );
  @override
  late final GeneratedColumn<int> albumArtistId = GeneratedColumn<int>(
    'album_artist_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkKeyMeta = const VerificationMeta(
    'artworkKey',
  );
  @override
  late final GeneratedColumn<String> artworkKey = GeneratedColumn<String>(
    'artwork_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paletteJsonMeta = const VerificationMeta(
    'paletteJson',
  );
  @override
  late final GeneratedColumn<String> paletteJson = GeneratedColumn<String>(
    'palette_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    titleSort,
    albumArtistId,
    year,
    artworkKey,
    paletteJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<Album> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_sort')) {
      context.handle(
        _titleSortMeta,
        titleSort.isAcceptableOrUnknown(data['title_sort']!, _titleSortMeta),
      );
    } else if (isInserting) {
      context.missing(_titleSortMeta);
    }
    if (data.containsKey('album_artist_id')) {
      context.handle(
        _albumArtistIdMeta,
        albumArtistId.isAcceptableOrUnknown(
          data['album_artist_id']!,
          _albumArtistIdMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('artwork_key')) {
      context.handle(
        _artworkKeyMeta,
        artworkKey.isAcceptableOrUnknown(data['artwork_key']!, _artworkKeyMeta),
      );
    }
    if (data.containsKey('palette_json')) {
      context.handle(
        _paletteJsonMeta,
        paletteJson.isAcceptableOrUnknown(
          data['palette_json']!,
          _paletteJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Album(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleSort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_sort'],
      )!,
      albumArtistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_artist_id'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      artworkKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_key'],
      ),
      paletteJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}palette_json'],
      ),
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }
}

class Album extends DataClass implements Insertable<Album> {
  final int id;
  final String title;
  final String titleSort;
  final int? albumArtistId;
  final int? year;
  final String? artworkKey;
  final String? paletteJson;
  const Album({
    required this.id,
    required this.title,
    required this.titleSort,
    this.albumArtistId,
    this.year,
    this.artworkKey,
    this.paletteJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['title_sort'] = Variable<String>(titleSort);
    if (!nullToAbsent || albumArtistId != null) {
      map['album_artist_id'] = Variable<int>(albumArtistId);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || artworkKey != null) {
      map['artwork_key'] = Variable<String>(artworkKey);
    }
    if (!nullToAbsent || paletteJson != null) {
      map['palette_json'] = Variable<String>(paletteJson);
    }
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      title: Value(title),
      titleSort: Value(titleSort),
      albumArtistId: albumArtistId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtistId),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      artworkKey: artworkKey == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkKey),
      paletteJson: paletteJson == null && nullToAbsent
          ? const Value.absent()
          : Value(paletteJson),
    );
  }

  factory Album.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      titleSort: serializer.fromJson<String>(json['titleSort']),
      albumArtistId: serializer.fromJson<int?>(json['albumArtistId']),
      year: serializer.fromJson<int?>(json['year']),
      artworkKey: serializer.fromJson<String?>(json['artworkKey']),
      paletteJson: serializer.fromJson<String?>(json['paletteJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'titleSort': serializer.toJson<String>(titleSort),
      'albumArtistId': serializer.toJson<int?>(albumArtistId),
      'year': serializer.toJson<int?>(year),
      'artworkKey': serializer.toJson<String?>(artworkKey),
      'paletteJson': serializer.toJson<String?>(paletteJson),
    };
  }

  Album copyWith({
    int? id,
    String? title,
    String? titleSort,
    Value<int?> albumArtistId = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> artworkKey = const Value.absent(),
    Value<String?> paletteJson = const Value.absent(),
  }) => Album(
    id: id ?? this.id,
    title: title ?? this.title,
    titleSort: titleSort ?? this.titleSort,
    albumArtistId: albumArtistId.present
        ? albumArtistId.value
        : this.albumArtistId,
    year: year.present ? year.value : this.year,
    artworkKey: artworkKey.present ? artworkKey.value : this.artworkKey,
    paletteJson: paletteJson.present ? paletteJson.value : this.paletteJson,
  );
  Album copyWithCompanion(AlbumsCompanion data) {
    return Album(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      titleSort: data.titleSort.present ? data.titleSort.value : this.titleSort,
      albumArtistId: data.albumArtistId.present
          ? data.albumArtistId.value
          : this.albumArtistId,
      year: data.year.present ? data.year.value : this.year,
      artworkKey: data.artworkKey.present
          ? data.artworkKey.value
          : this.artworkKey,
      paletteJson: data.paletteJson.present
          ? data.paletteJson.value
          : this.paletteJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleSort: $titleSort, ')
          ..write('albumArtistId: $albumArtistId, ')
          ..write('year: $year, ')
          ..write('artworkKey: $artworkKey, ')
          ..write('paletteJson: $paletteJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    titleSort,
    albumArtistId,
    year,
    artworkKey,
    paletteJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == this.id &&
          other.title == this.title &&
          other.titleSort == this.titleSort &&
          other.albumArtistId == this.albumArtistId &&
          other.year == this.year &&
          other.artworkKey == this.artworkKey &&
          other.paletteJson == this.paletteJson);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> titleSort;
  final Value<int?> albumArtistId;
  final Value<int?> year;
  final Value<String?> artworkKey;
  final Value<String?> paletteJson;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.titleSort = const Value.absent(),
    this.albumArtistId = const Value.absent(),
    this.year = const Value.absent(),
    this.artworkKey = const Value.absent(),
    this.paletteJson = const Value.absent(),
  });
  AlbumsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String titleSort,
    this.albumArtistId = const Value.absent(),
    this.year = const Value.absent(),
    this.artworkKey = const Value.absent(),
    this.paletteJson = const Value.absent(),
  }) : title = Value(title),
       titleSort = Value(titleSort);
  static Insertable<Album> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? titleSort,
    Expression<int>? albumArtistId,
    Expression<int>? year,
    Expression<String>? artworkKey,
    Expression<String>? paletteJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (titleSort != null) 'title_sort': titleSort,
      if (albumArtistId != null) 'album_artist_id': albumArtistId,
      if (year != null) 'year': year,
      if (artworkKey != null) 'artwork_key': artworkKey,
      if (paletteJson != null) 'palette_json': paletteJson,
    });
  }

  AlbumsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? titleSort,
    Value<int?>? albumArtistId,
    Value<int?>? year,
    Value<String?>? artworkKey,
    Value<String?>? paletteJson,
  }) {
    return AlbumsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      titleSort: titleSort ?? this.titleSort,
      albumArtistId: albumArtistId ?? this.albumArtistId,
      year: year ?? this.year,
      artworkKey: artworkKey ?? this.artworkKey,
      paletteJson: paletteJson ?? this.paletteJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (titleSort.present) {
      map['title_sort'] = Variable<String>(titleSort.value);
    }
    if (albumArtistId.present) {
      map['album_artist_id'] = Variable<int>(albumArtistId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (artworkKey.present) {
      map['artwork_key'] = Variable<String>(artworkKey.value);
    }
    if (paletteJson.present) {
      map['palette_json'] = Variable<String>(paletteJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleSort: $titleSort, ')
          ..write('albumArtistId: $albumArtistId, ')
          ..write('year: $year, ')
          ..write('artworkKey: $artworkKey, ')
          ..write('paletteJson: $paletteJson')
          ..write(')'))
        .toString();
  }
}

class $GenresTable extends Genres with TableInfo<$GenresTable, Genre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genres';
  @override
  VerificationContext validateIntegrity(
    Insertable<Genre> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Genre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Genre(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $GenresTable createAlias(String alias) {
    return $GenresTable(attachedDatabase, alias);
  }
}

class Genre extends DataClass implements Insertable<Genre> {
  final int id;
  final String name;
  const Genre({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  GenresCompanion toCompanion(bool nullToAbsent) {
    return GenresCompanion(id: Value(id), name: Value(name));
  }

  factory Genre.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Genre(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Genre copyWith({int? id, String? name}) =>
      Genre(id: id ?? this.id, name: name ?? this.name);
  Genre copyWithCompanion(GenresCompanion data) {
    return Genre(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Genre(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Genre && other.id == this.id && other.name == this.name);
}

class GenresCompanion extends UpdateCompanion<Genre> {
  final Value<int> id;
  final Value<String> name;
  const GenresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  GenresCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Genre> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  GenresCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return GenresCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $TrackGenresTable extends TrackGenres
    with TableInfo<$TrackGenresTable, TrackGenre> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackGenresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreIdMeta = const VerificationMeta(
    'genreId',
  );
  @override
  late final GeneratedColumn<int> genreId = GeneratedColumn<int>(
    'genre_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, genreId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_genres';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackGenre> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('genre_id')) {
      context.handle(
        _genreIdMeta,
        genreId.isAcceptableOrUnknown(data['genre_id']!, _genreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_genreIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, genreId};
  @override
  TrackGenre map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackGenre(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      genreId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}genre_id'],
      )!,
    );
  }

  @override
  $TrackGenresTable createAlias(String alias) {
    return $TrackGenresTable(attachedDatabase, alias);
  }
}

class TrackGenre extends DataClass implements Insertable<TrackGenre> {
  final int trackId;
  final int genreId;
  const TrackGenre({required this.trackId, required this.genreId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<int>(trackId);
    map['genre_id'] = Variable<int>(genreId);
    return map;
  }

  TrackGenresCompanion toCompanion(bool nullToAbsent) {
    return TrackGenresCompanion(
      trackId: Value(trackId),
      genreId: Value(genreId),
    );
  }

  factory TrackGenre.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackGenre(
      trackId: serializer.fromJson<int>(json['trackId']),
      genreId: serializer.fromJson<int>(json['genreId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'genreId': serializer.toJson<int>(genreId),
    };
  }

  TrackGenre copyWith({int? trackId, int? genreId}) => TrackGenre(
    trackId: trackId ?? this.trackId,
    genreId: genreId ?? this.genreId,
  );
  TrackGenre copyWithCompanion(TrackGenresCompanion data) {
    return TrackGenre(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      genreId: data.genreId.present ? data.genreId.value : this.genreId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackGenre(')
          ..write('trackId: $trackId, ')
          ..write('genreId: $genreId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, genreId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackGenre &&
          other.trackId == this.trackId &&
          other.genreId == this.genreId);
}

class TrackGenresCompanion extends UpdateCompanion<TrackGenre> {
  final Value<int> trackId;
  final Value<int> genreId;
  final Value<int> rowid;
  const TrackGenresCompanion({
    this.trackId = const Value.absent(),
    this.genreId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackGenresCompanion.insert({
    required int trackId,
    required int genreId,
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       genreId = Value(genreId);
  static Insertable<TrackGenre> custom({
    Expression<int>? trackId,
    Expression<int>? genreId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (genreId != null) 'genre_id': genreId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackGenresCompanion copyWith({
    Value<int>? trackId,
    Value<int>? genreId,
    Value<int>? rowid,
  }) {
    return TrackGenresCompanion(
      trackId: trackId ?? this.trackId,
      genreId: genreId ?? this.genreId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (genreId.present) {
      map['genre_id'] = Variable<int>(genreId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackGenresCompanion(')
          ..write('trackId: $trackId, ')
          ..write('genreId: $genreId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUriMeta = const VerificationMeta(
    'coverUri',
  );
  @override
  late final GeneratedColumn<String> coverUri = GeneratedColumn<String>(
    'cover_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSmartMeta = const VerificationMeta(
    'isSmart',
  );
  @override
  late final GeneratedColumn<bool> isSmart = GeneratedColumn<bool>(
    'is_smart',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_smart" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rulesJsonMeta = const VerificationMeta(
    'rulesJson',
  );
  @override
  late final GeneratedColumn<String> rulesJson = GeneratedColumn<String>(
    'rules_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    coverUri,
    isSmart,
    rulesJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cover_uri')) {
      context.handle(
        _coverUriMeta,
        coverUri.isAcceptableOrUnknown(data['cover_uri']!, _coverUriMeta),
      );
    }
    if (data.containsKey('is_smart')) {
      context.handle(
        _isSmartMeta,
        isSmart.isAcceptableOrUnknown(data['is_smart']!, _isSmartMeta),
      );
    }
    if (data.containsKey('rules_json')) {
      context.handle(
        _rulesJsonMeta,
        rulesJson.isAcceptableOrUnknown(data['rules_json']!, _rulesJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      coverUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_uri'],
      ),
      isSmart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_smart'],
      )!,
      rulesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rules_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final int id;
  final String name;
  final String? description;
  final String? coverUri;
  final bool isSmart;
  final String? rulesJson;
  final int createdAt;
  final int updatedAt;
  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverUri,
    required this.isSmart,
    this.rulesJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverUri != null) {
      map['cover_uri'] = Variable<String>(coverUri);
    }
    map['is_smart'] = Variable<bool>(isSmart);
    if (!nullToAbsent || rulesJson != null) {
      map['rules_json'] = Variable<String>(rulesJson);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      coverUri: coverUri == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUri),
      isSmart: Value(isSmart),
      rulesJson: rulesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(rulesJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      coverUri: serializer.fromJson<String?>(json['coverUri']),
      isSmart: serializer.fromJson<bool>(json['isSmart']),
      rulesJson: serializer.fromJson<String?>(json['rulesJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'coverUri': serializer.toJson<String?>(coverUri),
      'isSmart': serializer.toJson<bool>(isSmart),
      'rulesJson': serializer.toJson<String?>(rulesJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> coverUri = const Value.absent(),
    bool? isSmart,
    Value<String?> rulesJson = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    coverUri: coverUri.present ? coverUri.value : this.coverUri,
    isSmart: isSmart ?? this.isSmart,
    rulesJson: rulesJson.present ? rulesJson.value : this.rulesJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      coverUri: data.coverUri.present ? data.coverUri.value : this.coverUri,
      isSmart: data.isSmart.present ? data.isSmart.value : this.isSmart,
      rulesJson: data.rulesJson.present ? data.rulesJson.value : this.rulesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUri: $coverUri, ')
          ..write('isSmart: $isSmart, ')
          ..write('rulesJson: $rulesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    coverUri,
    isSmart,
    rulesJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.coverUri == this.coverUri &&
          other.isSmart == this.isSmart &&
          other.rulesJson == this.rulesJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> coverUri;
  final Value<bool> isSmart;
  final Value<String?> rulesJson;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUri = const Value.absent(),
    this.isSmart = const Value.absent(),
    this.rulesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.coverUri = const Value.absent(),
    this.isSmart = const Value.absent(),
    this.rulesJson = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Playlist> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? coverUri,
    Expression<bool>? isSmart,
    Expression<String>? rulesJson,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (coverUri != null) 'cover_uri': coverUri,
      if (isSmart != null) 'is_smart': isSmart,
      if (rulesJson != null) 'rules_json': rulesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? coverUri,
    Value<bool>? isSmart,
    Value<String?>? rulesJson,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUri: coverUri ?? this.coverUri,
      isSmart: isSmart ?? this.isSmart,
      rulesJson: rulesJson ?? this.rulesJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverUri.present) {
      map['cover_uri'] = Variable<String>(coverUri.value);
    }
    if (isSmart.present) {
      map['is_smart'] = Variable<bool>(isSmart.value);
    }
    if (rulesJson.present) {
      map['rules_json'] = Variable<String>(rulesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('coverUri: $coverUri, ')
          ..write('isSmart: $isSmart, ')
          ..write('rulesJson: $rulesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTable extends PlaylistTracks
    with TableInfo<$PlaylistTracksTable, PlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<int> playlistId = GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackKeyMeta = const VerificationMeta(
    'trackKey',
  );
  @override
  late final GeneratedColumn<String> trackKey = GeneratedColumn<String>(
    'track_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistId,
    trackKey,
    position,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_key')) {
      context.handle(
        _trackKeyMeta,
        trackKey.isAcceptableOrUnknown(data['track_key']!, _trackKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_trackKeyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackKey};
  @override
  PlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrack(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_key'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $PlaylistTracksTable createAlias(String alias) {
    return $PlaylistTracksTable(attachedDatabase, alias);
  }
}

class PlaylistTrack extends DataClass implements Insertable<PlaylistTrack> {
  final int playlistId;
  final String trackKey;
  final int position;
  final int addedAt;
  const PlaylistTrack({
    required this.playlistId,
    required this.trackKey,
    required this.position,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<int>(playlistId);
    map['track_key'] = Variable<String>(trackKey);
    map['position'] = Variable<int>(position);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  PlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksCompanion(
      playlistId: Value(playlistId),
      trackKey: Value(trackKey),
      position: Value(position),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrack(
      playlistId: serializer.fromJson<int>(json['playlistId']),
      trackKey: serializer.fromJson<String>(json['trackKey']),
      position: serializer.fromJson<int>(json['position']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<int>(playlistId),
      'trackKey': serializer.toJson<String>(trackKey),
      'position': serializer.toJson<int>(position),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  PlaylistTrack copyWith({
    int? playlistId,
    String? trackKey,
    int? position,
    int? addedAt,
  }) => PlaylistTrack(
    playlistId: playlistId ?? this.playlistId,
    trackKey: trackKey ?? this.trackKey,
    position: position ?? this.position,
    addedAt: addedAt ?? this.addedAt,
  );
  PlaylistTrack copyWithCompanion(PlaylistTracksCompanion data) {
    return PlaylistTrack(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackKey: data.trackKey.present ? data.trackKey.value : this.trackKey,
      position: data.position.present ? data.position.value : this.position,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrack(')
          ..write('playlistId: $playlistId, ')
          ..write('trackKey: $trackKey, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, trackKey, position, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrack &&
          other.playlistId == this.playlistId &&
          other.trackKey == this.trackKey &&
          other.position == this.position &&
          other.addedAt == this.addedAt);
}

class PlaylistTracksCompanion extends UpdateCompanion<PlaylistTrack> {
  final Value<int> playlistId;
  final Value<String> trackKey;
  final Value<int> position;
  final Value<int> addedAt;
  final Value<int> rowid;
  const PlaylistTracksCompanion({
    this.playlistId = const Value.absent(),
    this.trackKey = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTracksCompanion.insert({
    required int playlistId,
    required String trackKey,
    required int position,
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackKey = Value(trackKey),
       position = Value(position),
       addedAt = Value(addedAt);
  static Insertable<PlaylistTrack> custom({
    Expression<int>? playlistId,
    Expression<String>? trackKey,
    Expression<int>? position,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackKey != null) 'track_key': trackKey,
      if (position != null) 'position': position,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTracksCompanion copyWith({
    Value<int>? playlistId,
    Value<String>? trackKey,
    Value<int>? position,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return PlaylistTracksCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackKey: trackKey ?? this.trackKey,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<int>(playlistId.value);
    }
    if (trackKey.present) {
      map['track_key'] = Variable<String>(trackKey.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackKey: $trackKey, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueStateTableTable extends QueueStateTable
    with TableInfo<$QueueStateTableTable, QueueStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _currentTrackKeyMeta = const VerificationMeta(
    'currentTrackKey',
  );
  @override
  late final GeneratedColumn<String> currentTrackKey = GeneratedColumn<String>(
    'current_track_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _shuffleMeta = const VerificationMeta(
    'shuffle',
  );
  @override
  late final GeneratedColumn<bool> shuffle = GeneratedColumn<bool>(
    'shuffle',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shuffle" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _repeatModeMeta = const VerificationMeta(
    'repeatMode',
  );
  @override
  late final GeneratedColumn<int> repeatMode = GeneratedColumn<int>(
    'repeat_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _queueJsonMeta = const VerificationMeta(
    'queueJson',
  );
  @override
  late final GeneratedColumn<String> queueJson = GeneratedColumn<String>(
    'queue_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentTrackKey,
    positionMs,
    shuffle,
    repeatMode,
    seed,
    queueJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_state_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueStateTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_track_key')) {
      context.handle(
        _currentTrackKeyMeta,
        currentTrackKey.isAcceptableOrUnknown(
          data['current_track_key']!,
          _currentTrackKeyMeta,
        ),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('shuffle')) {
      context.handle(
        _shuffleMeta,
        shuffle.isAcceptableOrUnknown(data['shuffle']!, _shuffleMeta),
      );
    }
    if (data.containsKey('repeat_mode')) {
      context.handle(
        _repeatModeMeta,
        repeatMode.isAcceptableOrUnknown(data['repeat_mode']!, _repeatModeMeta),
      );
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    }
    if (data.containsKey('queue_json')) {
      context.handle(
        _queueJsonMeta,
        queueJson.isAcceptableOrUnknown(data['queue_json']!, _queueJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueStateTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentTrackKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_track_key'],
      ),
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      shuffle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shuffle'],
      )!,
      repeatMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_mode'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
      queueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queue_json'],
      )!,
    );
  }

  @override
  $QueueStateTableTable createAlias(String alias) {
    return $QueueStateTableTable(attachedDatabase, alias);
  }
}

class QueueStateTableData extends DataClass
    implements Insertable<QueueStateTableData> {
  final int id;
  final String? currentTrackKey;
  final int positionMs;
  final bool shuffle;
  final int repeatMode;
  final int seed;
  final String queueJson;
  const QueueStateTableData({
    required this.id,
    this.currentTrackKey,
    required this.positionMs,
    required this.shuffle,
    required this.repeatMode,
    required this.seed,
    required this.queueJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || currentTrackKey != null) {
      map['current_track_key'] = Variable<String>(currentTrackKey);
    }
    map['position_ms'] = Variable<int>(positionMs);
    map['shuffle'] = Variable<bool>(shuffle);
    map['repeat_mode'] = Variable<int>(repeatMode);
    map['seed'] = Variable<int>(seed);
    map['queue_json'] = Variable<String>(queueJson);
    return map;
  }

  QueueStateTableCompanion toCompanion(bool nullToAbsent) {
    return QueueStateTableCompanion(
      id: Value(id),
      currentTrackKey: currentTrackKey == null && nullToAbsent
          ? const Value.absent()
          : Value(currentTrackKey),
      positionMs: Value(positionMs),
      shuffle: Value(shuffle),
      repeatMode: Value(repeatMode),
      seed: Value(seed),
      queueJson: Value(queueJson),
    );
  }

  factory QueueStateTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueStateTableData(
      id: serializer.fromJson<int>(json['id']),
      currentTrackKey: serializer.fromJson<String?>(json['currentTrackKey']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      shuffle: serializer.fromJson<bool>(json['shuffle']),
      repeatMode: serializer.fromJson<int>(json['repeatMode']),
      seed: serializer.fromJson<int>(json['seed']),
      queueJson: serializer.fromJson<String>(json['queueJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentTrackKey': serializer.toJson<String?>(currentTrackKey),
      'positionMs': serializer.toJson<int>(positionMs),
      'shuffle': serializer.toJson<bool>(shuffle),
      'repeatMode': serializer.toJson<int>(repeatMode),
      'seed': serializer.toJson<int>(seed),
      'queueJson': serializer.toJson<String>(queueJson),
    };
  }

  QueueStateTableData copyWith({
    int? id,
    Value<String?> currentTrackKey = const Value.absent(),
    int? positionMs,
    bool? shuffle,
    int? repeatMode,
    int? seed,
    String? queueJson,
  }) => QueueStateTableData(
    id: id ?? this.id,
    currentTrackKey: currentTrackKey.present
        ? currentTrackKey.value
        : this.currentTrackKey,
    positionMs: positionMs ?? this.positionMs,
    shuffle: shuffle ?? this.shuffle,
    repeatMode: repeatMode ?? this.repeatMode,
    seed: seed ?? this.seed,
    queueJson: queueJson ?? this.queueJson,
  );
  QueueStateTableData copyWithCompanion(QueueStateTableCompanion data) {
    return QueueStateTableData(
      id: data.id.present ? data.id.value : this.id,
      currentTrackKey: data.currentTrackKey.present
          ? data.currentTrackKey.value
          : this.currentTrackKey,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      shuffle: data.shuffle.present ? data.shuffle.value : this.shuffle,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
      seed: data.seed.present ? data.seed.value : this.seed,
      queueJson: data.queueJson.present ? data.queueJson.value : this.queueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateTableData(')
          ..write('id: $id, ')
          ..write('currentTrackKey: $currentTrackKey, ')
          ..write('positionMs: $positionMs, ')
          ..write('shuffle: $shuffle, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('seed: $seed, ')
          ..write('queueJson: $queueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currentTrackKey,
    positionMs,
    shuffle,
    repeatMode,
    seed,
    queueJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueStateTableData &&
          other.id == this.id &&
          other.currentTrackKey == this.currentTrackKey &&
          other.positionMs == this.positionMs &&
          other.shuffle == this.shuffle &&
          other.repeatMode == this.repeatMode &&
          other.seed == this.seed &&
          other.queueJson == this.queueJson);
}

class QueueStateTableCompanion extends UpdateCompanion<QueueStateTableData> {
  final Value<int> id;
  final Value<String?> currentTrackKey;
  final Value<int> positionMs;
  final Value<bool> shuffle;
  final Value<int> repeatMode;
  final Value<int> seed;
  final Value<String> queueJson;
  const QueueStateTableCompanion({
    this.id = const Value.absent(),
    this.currentTrackKey = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.shuffle = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.seed = const Value.absent(),
    this.queueJson = const Value.absent(),
  });
  QueueStateTableCompanion.insert({
    this.id = const Value.absent(),
    this.currentTrackKey = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.shuffle = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.seed = const Value.absent(),
    this.queueJson = const Value.absent(),
  });
  static Insertable<QueueStateTableData> custom({
    Expression<int>? id,
    Expression<String>? currentTrackKey,
    Expression<int>? positionMs,
    Expression<bool>? shuffle,
    Expression<int>? repeatMode,
    Expression<int>? seed,
    Expression<String>? queueJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentTrackKey != null) 'current_track_key': currentTrackKey,
      if (positionMs != null) 'position_ms': positionMs,
      if (shuffle != null) 'shuffle': shuffle,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (seed != null) 'seed': seed,
      if (queueJson != null) 'queue_json': queueJson,
    });
  }

  QueueStateTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? currentTrackKey,
    Value<int>? positionMs,
    Value<bool>? shuffle,
    Value<int>? repeatMode,
    Value<int>? seed,
    Value<String>? queueJson,
  }) {
    return QueueStateTableCompanion(
      id: id ?? this.id,
      currentTrackKey: currentTrackKey ?? this.currentTrackKey,
      positionMs: positionMs ?? this.positionMs,
      shuffle: shuffle ?? this.shuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      seed: seed ?? this.seed,
      queueJson: queueJson ?? this.queueJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentTrackKey.present) {
      map['current_track_key'] = Variable<String>(currentTrackKey.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (shuffle.present) {
      map['shuffle'] = Variable<bool>(shuffle.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<int>(repeatMode.value);
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (queueJson.present) {
      map['queue_json'] = Variable<String>(queueJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateTableCompanion(')
          ..write('id: $id, ')
          ..write('currentTrackKey: $currentTrackKey, ')
          ..write('positionMs: $positionMs, ')
          ..write('shuffle: $shuffle, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('seed: $seed, ')
          ..write('queueJson: $queueJson')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory
    with TableInfo<$PlayHistoryTable, PlayHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackKeyMeta = const VerificationMeta(
    'trackKey',
  );
  @override
  late final GeneratedColumn<String> trackKey = GeneratedColumn<String>(
    'track_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenedMsMeta = const VerificationMeta(
    'listenedMs',
  );
  @override
  late final GeneratedColumn<int> listenedMs = GeneratedColumn<int>(
    'listened_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackKey,
    startedAt,
    listenedMs,
    completed,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_key')) {
      context.handle(
        _trackKeyMeta,
        trackKey.isAcceptableOrUnknown(data['track_key']!, _trackKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_trackKeyMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('listened_ms')) {
      context.handle(
        _listenedMsMeta,
        listenedMs.isAcceptableOrUnknown(data['listened_ms']!, _listenedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_listenedMsMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_key'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      listenedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listened_ms'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }
}

class PlayHistoryData extends DataClass implements Insertable<PlayHistoryData> {
  final int id;
  final String trackKey;
  final int startedAt;
  final int listenedMs;
  final bool completed;
  final String? source;
  const PlayHistoryData({
    required this.id,
    required this.trackKey,
    required this.startedAt,
    required this.listenedMs,
    required this.completed,
    this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_key'] = Variable<String>(trackKey);
    map['started_at'] = Variable<int>(startedAt);
    map['listened_ms'] = Variable<int>(listenedMs);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(
      id: Value(id),
      trackKey: Value(trackKey),
      startedAt: Value(startedAt),
      listenedMs: Value(listenedMs),
      completed: Value(completed),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
    );
  }

  factory PlayHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryData(
      id: serializer.fromJson<int>(json['id']),
      trackKey: serializer.fromJson<String>(json['trackKey']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      listenedMs: serializer.fromJson<int>(json['listenedMs']),
      completed: serializer.fromJson<bool>(json['completed']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackKey': serializer.toJson<String>(trackKey),
      'startedAt': serializer.toJson<int>(startedAt),
      'listenedMs': serializer.toJson<int>(listenedMs),
      'completed': serializer.toJson<bool>(completed),
      'source': serializer.toJson<String?>(source),
    };
  }

  PlayHistoryData copyWith({
    int? id,
    String? trackKey,
    int? startedAt,
    int? listenedMs,
    bool? completed,
    Value<String?> source = const Value.absent(),
  }) => PlayHistoryData(
    id: id ?? this.id,
    trackKey: trackKey ?? this.trackKey,
    startedAt: startedAt ?? this.startedAt,
    listenedMs: listenedMs ?? this.listenedMs,
    completed: completed ?? this.completed,
    source: source.present ? source.value : this.source,
  );
  PlayHistoryData copyWithCompanion(PlayHistoryCompanion data) {
    return PlayHistoryData(
      id: data.id.present ? data.id.value : this.id,
      trackKey: data.trackKey.present ? data.trackKey.value : this.trackKey,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      listenedMs: data.listenedMs.present
          ? data.listenedMs.value
          : this.listenedMs,
      completed: data.completed.present ? data.completed.value : this.completed,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryData(')
          ..write('id: $id, ')
          ..write('trackKey: $trackKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('completed: $completed, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trackKey, startedAt, listenedMs, completed, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryData &&
          other.id == this.id &&
          other.trackKey == this.trackKey &&
          other.startedAt == this.startedAt &&
          other.listenedMs == this.listenedMs &&
          other.completed == this.completed &&
          other.source == this.source);
}

class PlayHistoryCompanion extends UpdateCompanion<PlayHistoryData> {
  final Value<int> id;
  final Value<String> trackKey;
  final Value<int> startedAt;
  final Value<int> listenedMs;
  final Value<bool> completed;
  final Value<String?> source;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.trackKey = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.listenedMs = const Value.absent(),
    this.completed = const Value.absent(),
    this.source = const Value.absent(),
  });
  PlayHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String trackKey,
    required int startedAt,
    required int listenedMs,
    this.completed = const Value.absent(),
    this.source = const Value.absent(),
  }) : trackKey = Value(trackKey),
       startedAt = Value(startedAt),
       listenedMs = Value(listenedMs);
  static Insertable<PlayHistoryData> custom({
    Expression<int>? id,
    Expression<String>? trackKey,
    Expression<int>? startedAt,
    Expression<int>? listenedMs,
    Expression<bool>? completed,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackKey != null) 'track_key': trackKey,
      if (startedAt != null) 'started_at': startedAt,
      if (listenedMs != null) 'listened_ms': listenedMs,
      if (completed != null) 'completed': completed,
      if (source != null) 'source': source,
    });
  }

  PlayHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? trackKey,
    Value<int>? startedAt,
    Value<int>? listenedMs,
    Value<bool>? completed,
    Value<String?>? source,
  }) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      trackKey: trackKey ?? this.trackKey,
      startedAt: startedAt ?? this.startedAt,
      listenedMs: listenedMs ?? this.listenedMs,
      completed: completed ?? this.completed,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackKey.present) {
      map['track_key'] = Variable<String>(trackKey.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (listenedMs.present) {
      map['listened_ms'] = Variable<int>(listenedMs.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('trackKey: $trackKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('completed: $completed, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $LibraryFoldersTable extends LibraryFolders
    with TableInfo<$LibraryFoldersTable, LibraryFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('include'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, path, mode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
    );
  }

  @override
  $LibraryFoldersTable createAlias(String alias) {
    return $LibraryFoldersTable(attachedDatabase, alias);
  }
}

class LibraryFolder extends DataClass implements Insertable<LibraryFolder> {
  final int id;
  final String path;
  final String mode;
  const LibraryFolder({
    required this.id,
    required this.path,
    required this.mode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['mode'] = Variable<String>(mode);
    return map;
  }

  LibraryFoldersCompanion toCompanion(bool nullToAbsent) {
    return LibraryFoldersCompanion(
      id: Value(id),
      path: Value(path),
      mode: Value(mode),
    );
  }

  factory LibraryFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryFolder(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      mode: serializer.fromJson<String>(json['mode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'mode': serializer.toJson<String>(mode),
    };
  }

  LibraryFolder copyWith({int? id, String? path, String? mode}) =>
      LibraryFolder(
        id: id ?? this.id,
        path: path ?? this.path,
        mode: mode ?? this.mode,
      );
  LibraryFolder copyWithCompanion(LibraryFoldersCompanion data) {
    return LibraryFolder(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      mode: data.mode.present ? data.mode.value : this.mode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryFolder(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('mode: $mode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, mode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryFolder &&
          other.id == this.id &&
          other.path == this.path &&
          other.mode == this.mode);
}

class LibraryFoldersCompanion extends UpdateCompanion<LibraryFolder> {
  final Value<int> id;
  final Value<String> path;
  final Value<String> mode;
  const LibraryFoldersCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.mode = const Value.absent(),
  });
  LibraryFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    this.mode = const Value.absent(),
  }) : path = Value(path);
  static Insertable<LibraryFolder> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<String>? mode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (mode != null) 'mode': mode,
    });
  }

  LibraryFoldersCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<String>? mode,
  }) {
    return LibraryFoldersCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      mode: mode ?? this.mode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryFoldersCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('mode: $mode')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String valueJson;
  const AppSetting({required this.key, required this.valueJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), valueJson: Value(valueJson));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
    };
  }

  AppSetting copyWith({String? key, String? valueJson}) =>
      AppSetting(key: key ?? this.key, valueJson: valueJson ?? this.valueJson);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $ArtistsTable artists = $ArtistsTable(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $GenresTable genres = $GenresTable(this);
  late final $TrackGenresTable trackGenres = $TrackGenresTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistTracksTable playlistTracks = $PlaylistTracksTable(this);
  late final $QueueStateTableTable queueStateTable = $QueueStateTableTable(
    this,
  );
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final $LibraryFoldersTable libraryFolders = $LibraryFoldersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index idxTracksArtistId = Index(
    'idx_tracks_artist_id',
    'CREATE INDEX idx_tracks_artist_id ON tracks (artist_id)',
  );
  late final Index idxTracksAlbumId = Index(
    'idx_tracks_album_id',
    'CREATE INDEX idx_tracks_album_id ON tracks (album_id)',
  );
  late final Index idxTracksTitleSort = Index(
    'idx_tracks_title_sort',
    'CREATE INDEX idx_tracks_title_sort ON tracks (title_sort)',
  );
  late final Index idxTracksDateAdded = Index(
    'idx_tracks_date_added',
    'CREATE INDEX idx_tracks_date_added ON tracks (date_added)',
  );
  late final Index idxTracksLastPlayed = Index(
    'idx_tracks_last_played',
    'CREATE INDEX idx_tracks_last_played ON tracks (last_played_at)',
  );
  late final Index idxTracksPlayCount = Index(
    'idx_tracks_play_count',
    'CREATE INDEX idx_tracks_play_count ON tracks (play_count)',
  );
  late final Index idxTracksIsFavorite = Index(
    'idx_tracks_is_favorite',
    'CREATE INDEX idx_tracks_is_favorite ON tracks (is_favorite)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    artists,
    albums,
    genres,
    trackGenres,
    playlists,
    playlistTracks,
    queueStateTable,
    playHistory,
    libraryFolders,
    appSettings,
    idxTracksArtistId,
    idxTracksAlbumId,
    idxTracksTitleSort,
    idxTracksDateAdded,
    idxTracksLastPlayed,
    idxTracksPlayCount,
    idxTracksIsFavorite,
  ];
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  required String trackKey,
  Value<int?> mediaStoreId,
  required String contentUri,
  required String path,
  Value<String> relativeDir,
  required String title,
  required String titleSort,
  Value<int?> artistId,
  Value<int?> albumId,
  Value<int?> albumArtistId,
  Value<int?> trackNo,
  Value<int?> discNo,
  Value<int?> year,
  required int durationMs,
  Value<int?> bitrate,
  Value<int?> sampleRate,
  Value<int?> bitDepth,
  Value<int?> channels,
  Value<String?> mime,
  required int sizeBytes,
  Value<int?> dateAdded,
  Value<int?> dateModified,
  Value<String?> artworkKey,
  Value<double?> replayGainTrackDb,
  Value<double?> replayGainAlbumDb,
  Value<bool> hasLyrics,
  Value<int> playCount,
  Value<int> skipCount,
  Value<int?> lastPlayedAt,
  Value<bool> isFavorite,
  Value<bool> isHidden,
  Value<bool> isMissing,
  Value<int> rating,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<int> id,
  Value<String> trackKey,
  Value<int?> mediaStoreId,
  Value<String> contentUri,
  Value<String> path,
  Value<String> relativeDir,
  Value<String> title,
  Value<String> titleSort,
  Value<int?> artistId,
  Value<int?> albumId,
  Value<int?> albumArtistId,
  Value<int?> trackNo,
  Value<int?> discNo,
  Value<int?> year,
  Value<int> durationMs,
  Value<int?> bitrate,
  Value<int?> sampleRate,
  Value<int?> bitDepth,
  Value<int?> channels,
  Value<String?> mime,
  Value<int> sizeBytes,
  Value<int?> dateAdded,
  Value<int?> dateModified,
  Value<String?> artworkKey,
  Value<double?> replayGainTrackDb,
  Value<double?> replayGainAlbumDb,
  Value<bool> hasLyrics,
  Value<int> playCount,
  Value<int> skipCount,
  Value<int?> lastPlayedAt,
  Value<bool> isFavorite,
  Value<bool> isHidden,
  Value<bool> isMissing,
  Value<int> rating,
});

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackKey => $composableBuilder(
    column: $table.trackKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativeDir => $composableBuilder(
    column: $table.relativeDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get albumArtistId => $composableBuilder(
    column: $table.albumArtistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNo => $composableBuilder(
    column: $table.trackNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNo => $composableBuilder(
    column: $table.discNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitrate => $composableBuilder(
    column: $table.bitrate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replayGainTrackDb => $composableBuilder(
    column: $table.replayGainTrackDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replayGainAlbumDb => $composableBuilder(
    column: $table.replayGainAlbumDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasLyrics => $composableBuilder(
    column: $table.hasLyrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipCount => $composableBuilder(
    column: $table.skipCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMissing => $composableBuilder(
    column: $table.isMissing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackKey => $composableBuilder(
    column: $table.trackKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativeDir => $composableBuilder(
    column: $table.relativeDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get albumArtistId => $composableBuilder(
    column: $table.albumArtistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNo => $composableBuilder(
    column: $table.trackNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNo => $composableBuilder(
    column: $table.discNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitrate => $composableBuilder(
    column: $table.bitrate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replayGainTrackDb => $composableBuilder(
    column: $table.replayGainTrackDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replayGainAlbumDb => $composableBuilder(
    column: $table.replayGainAlbumDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasLyrics => $composableBuilder(
    column: $table.hasLyrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipCount => $composableBuilder(
    column: $table.skipCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMissing => $composableBuilder(
    column: $table.isMissing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackKey =>
      $composableBuilder(column: $table.trackKey, builder: (column) => column);

  GeneratedColumn<int> get mediaStoreId => $composableBuilder(
    column: $table.mediaStoreId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get relativeDir => $composableBuilder(
    column: $table.relativeDir,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleSort =>
      $composableBuilder(column: $table.titleSort, builder: (column) => column);

  GeneratedColumn<int> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<int> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<int> get albumArtistId => $composableBuilder(
    column: $table.albumArtistId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trackNo =>
      $composableBuilder(column: $table.trackNo, builder: (column) => column);

  GeneratedColumn<int> get discNo =>
      $composableBuilder(column: $table.discNo, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bitrate =>
      $composableBuilder(column: $table.bitrate, builder: (column) => column);

  GeneratedColumn<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bitDepth =>
      $composableBuilder(column: $table.bitDepth, builder: (column) => column);

  GeneratedColumn<int> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<int> get dateModified => $composableBuilder(
    column: $table.dateModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => column,
  );

  GeneratedColumn<double> get replayGainTrackDb => $composableBuilder(
    column: $table.replayGainTrackDb,
    builder: (column) => column,
  );

  GeneratedColumn<double> get replayGainAlbumDb => $composableBuilder(
    column: $table.replayGainAlbumDb,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasLyrics =>
      $composableBuilder(column: $table.hasLyrics, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<int> get skipCount =>
      $composableBuilder(column: $table.skipCount, builder: (column) => column);

  GeneratedColumn<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isMissing =>
      $composableBuilder(column: $table.isMissing, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
          Track,
          PrefetchHooks Function()
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trackKey = const Value.absent(),
                Value<int?> mediaStoreId = const Value.absent(),
                Value<String> contentUri = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> relativeDir = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> titleSort = const Value.absent(),
                Value<int?> artistId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> albumArtistId = const Value.absent(),
                Value<int?> trackNo = const Value.absent(),
                Value<int?> discNo = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int?> bitrate = const Value.absent(),
                Value<int?> sampleRate = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int?> dateAdded = const Value.absent(),
                Value<int?> dateModified = const Value.absent(),
                Value<String?> artworkKey = const Value.absent(),
                Value<double?> replayGainTrackDb = const Value.absent(),
                Value<double?> replayGainAlbumDb = const Value.absent(),
                Value<bool> hasLyrics = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> skipCount = const Value.absent(),
                Value<int?> lastPlayedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isMissing = const Value.absent(),
                Value<int> rating = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                trackKey: trackKey,
                mediaStoreId: mediaStoreId,
                contentUri: contentUri,
                path: path,
                relativeDir: relativeDir,
                title: title,
                titleSort: titleSort,
                artistId: artistId,
                albumId: albumId,
                albumArtistId: albumArtistId,
                trackNo: trackNo,
                discNo: discNo,
                year: year,
                durationMs: durationMs,
                bitrate: bitrate,
                sampleRate: sampleRate,
                bitDepth: bitDepth,
                channels: channels,
                mime: mime,
                sizeBytes: sizeBytes,
                dateAdded: dateAdded,
                dateModified: dateModified,
                artworkKey: artworkKey,
                replayGainTrackDb: replayGainTrackDb,
                replayGainAlbumDb: replayGainAlbumDb,
                hasLyrics: hasLyrics,
                playCount: playCount,
                skipCount: skipCount,
                lastPlayedAt: lastPlayedAt,
                isFavorite: isFavorite,
                isHidden: isHidden,
                isMissing: isMissing,
                rating: rating,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trackKey,
                Value<int?> mediaStoreId = const Value.absent(),
                required String contentUri,
                required String path,
                Value<String> relativeDir = const Value.absent(),
                required String title,
                required String titleSort,
                Value<int?> artistId = const Value.absent(),
                Value<int?> albumId = const Value.absent(),
                Value<int?> albumArtistId = const Value.absent(),
                Value<int?> trackNo = const Value.absent(),
                Value<int?> discNo = const Value.absent(),
                Value<int?> year = const Value.absent(),
                required int durationMs,
                Value<int?> bitrate = const Value.absent(),
                Value<int?> sampleRate = const Value.absent(),
                Value<int?> bitDepth = const Value.absent(),
                Value<int?> channels = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                required int sizeBytes,
                Value<int?> dateAdded = const Value.absent(),
                Value<int?> dateModified = const Value.absent(),
                Value<String?> artworkKey = const Value.absent(),
                Value<double?> replayGainTrackDb = const Value.absent(),
                Value<double?> replayGainAlbumDb = const Value.absent(),
                Value<bool> hasLyrics = const Value.absent(),
                Value<int> playCount = const Value.absent(),
                Value<int> skipCount = const Value.absent(),
                Value<int?> lastPlayedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isMissing = const Value.absent(),
                Value<int> rating = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                trackKey: trackKey,
                mediaStoreId: mediaStoreId,
                contentUri: contentUri,
                path: path,
                relativeDir: relativeDir,
                title: title,
                titleSort: titleSort,
                artistId: artistId,
                albumId: albumId,
                albumArtistId: albumArtistId,
                trackNo: trackNo,
                discNo: discNo,
                year: year,
                durationMs: durationMs,
                bitrate: bitrate,
                sampleRate: sampleRate,
                bitDepth: bitDepth,
                channels: channels,
                mime: mime,
                sizeBytes: sizeBytes,
                dateAdded: dateAdded,
                dateModified: dateModified,
                artworkKey: artworkKey,
                replayGainTrackDb: replayGainTrackDb,
                replayGainAlbumDb: replayGainAlbumDb,
                hasLyrics: hasLyrics,
                playCount: playCount,
                skipCount: skipCount,
                lastPlayedAt: lastPlayedAt,
                isFavorite: isFavorite,
                isHidden: isHidden,
                isMissing: isMissing,
                rating: rating,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, Track>(table),
                  BaseReferences<_$AppDatabase, $TracksTable, Track>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, BaseReferences<_$AppDatabase, $TracksTable, Track>),
      Track,
      PrefetchHooks Function()
    >;
typedef $$ArtistsTableCreateCompanionBuilder = ArtistsCompanion Function({
  Value<int> id,
  required String name,
  required String nameSort,
  Value<String?> artworkKey,
});
typedef $$ArtistsTableUpdateCompanionBuilder = ArtistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> nameSort,
  Value<String?> artworkKey,
});

class $$ArtistsTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSort => $composableBuilder(
    column: $table.nameSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArtistsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSort => $composableBuilder(
    column: $table.nameSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistsTable> {
  $$ArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameSort =>
      $composableBuilder(column: $table.nameSort, builder: (column) => column);

  GeneratedColumn<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => column,
  );
}

class $$ArtistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistsTable,
          Artist,
          $$ArtistsTableFilterComposer,
          $$ArtistsTableOrderingComposer,
          $$ArtistsTableAnnotationComposer,
          $$ArtistsTableCreateCompanionBuilder,
          $$ArtistsTableUpdateCompanionBuilder,
          (Artist, BaseReferences<_$AppDatabase, $ArtistsTable, Artist>),
          Artist,
          PrefetchHooks Function()
        > {
  $$ArtistsTableTableManager(_$AppDatabase db, $ArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameSort = const Value.absent(),
                Value<String?> artworkKey = const Value.absent(),
              }) => ArtistsCompanion(
                id: id,
                name: name,
                nameSort: nameSort,
                artworkKey: artworkKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String nameSort,
                Value<String?> artworkKey = const Value.absent(),
              }) => ArtistsCompanion.insert(
                id: id,
                name: name,
                nameSort: nameSort,
                artworkKey: artworkKey,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArtistsTable, Artist>(table),
                  BaseReferences<_$AppDatabase, $ArtistsTable, Artist>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistsTable,
      Artist,
      $$ArtistsTableFilterComposer,
      $$ArtistsTableOrderingComposer,
      $$ArtistsTableAnnotationComposer,
      $$ArtistsTableCreateCompanionBuilder,
      $$ArtistsTableUpdateCompanionBuilder,
      (Artist, BaseReferences<_$AppDatabase, $ArtistsTable, Artist>),
      Artist,
      PrefetchHooks Function()
    >;
typedef $$AlbumsTableCreateCompanionBuilder = AlbumsCompanion Function({
  Value<int> id,
  required String title,
  required String titleSort,
  Value<int?> albumArtistId,
  Value<int?> year,
  Value<String?> artworkKey,
  Value<String?> paletteJson,
});
typedef $$AlbumsTableUpdateCompanionBuilder = AlbumsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> titleSort,
  Value<int?> albumArtistId,
  Value<int?> year,
  Value<String?> artworkKey,
  Value<String?> paletteJson,
});

class $$AlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get albumArtistId => $composableBuilder(
    column: $table.albumArtistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paletteJson => $composableBuilder(
    column: $table.paletteJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get albumArtistId => $composableBuilder(
    column: $table.albumArtistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paletteJson => $composableBuilder(
    column: $table.paletteJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get titleSort =>
      $composableBuilder(column: $table.titleSort, builder: (column) => column);

  GeneratedColumn<int> get albumArtistId => $composableBuilder(
    column: $table.albumArtistId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get artworkKey => $composableBuilder(
    column: $table.artworkKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paletteJson => $composableBuilder(
    column: $table.paletteJson,
    builder: (column) => column,
  );
}

class $$AlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTable,
          Album,
          $$AlbumsTableFilterComposer,
          $$AlbumsTableOrderingComposer,
          $$AlbumsTableAnnotationComposer,
          $$AlbumsTableCreateCompanionBuilder,
          $$AlbumsTableUpdateCompanionBuilder,
          (Album, BaseReferences<_$AppDatabase, $AlbumsTable, Album>),
          Album,
          PrefetchHooks Function()
        > {
  $$AlbumsTableTableManager(_$AppDatabase db, $AlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> titleSort = const Value.absent(),
                Value<int?> albumArtistId = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> artworkKey = const Value.absent(),
                Value<String?> paletteJson = const Value.absent(),
              }) => AlbumsCompanion(
                id: id,
                title: title,
                titleSort: titleSort,
                albumArtistId: albumArtistId,
                year: year,
                artworkKey: artworkKey,
                paletteJson: paletteJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String titleSort,
                Value<int?> albumArtistId = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> artworkKey = const Value.absent(),
                Value<String?> paletteJson = const Value.absent(),
              }) => AlbumsCompanion.insert(
                id: id,
                title: title,
                titleSort: titleSort,
                albumArtistId: albumArtistId,
                year: year,
                artworkKey: artworkKey,
                paletteJson: paletteJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlbumsTable, Album>(table),
                  BaseReferences<_$AppDatabase, $AlbumsTable, Album>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTable,
      Album,
      $$AlbumsTableFilterComposer,
      $$AlbumsTableOrderingComposer,
      $$AlbumsTableAnnotationComposer,
      $$AlbumsTableCreateCompanionBuilder,
      $$AlbumsTableUpdateCompanionBuilder,
      (Album, BaseReferences<_$AppDatabase, $AlbumsTable, Album>),
      Album,
      PrefetchHooks Function()
    >;
typedef $$GenresTableCreateCompanionBuilder = GenresCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$GenresTableUpdateCompanionBuilder = GenresCompanion Function({
  Value<int> id,
  Value<String> name,
});

class $$GenresTableFilterComposer
    extends Composer<_$AppDatabase, $GenresTable> {
  $$GenresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GenresTableOrderingComposer
    extends Composer<_$AppDatabase, $GenresTable> {
  $$GenresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GenresTableAnnotationComposer
    extends Composer<_$AppDatabase, $GenresTable> {
  $$GenresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$GenresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GenresTable,
          Genre,
          $$GenresTableFilterComposer,
          $$GenresTableOrderingComposer,
          $$GenresTableAnnotationComposer,
          $$GenresTableCreateCompanionBuilder,
          $$GenresTableUpdateCompanionBuilder,
          (Genre, BaseReferences<_$AppDatabase, $GenresTable, Genre>),
          Genre,
          PrefetchHooks Function()
        > {
  $$GenresTableTableManager(_$AppDatabase db, $GenresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) => GenresCompanion(id: id, name: name),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) => GenresCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GenresTable, Genre>(table),
                  BaseReferences<_$AppDatabase, $GenresTable, Genre>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GenresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GenresTable,
      Genre,
      $$GenresTableFilterComposer,
      $$GenresTableOrderingComposer,
      $$GenresTableAnnotationComposer,
      $$GenresTableCreateCompanionBuilder,
      $$GenresTableUpdateCompanionBuilder,
      (Genre, BaseReferences<_$AppDatabase, $GenresTable, Genre>),
      Genre,
      PrefetchHooks Function()
    >;
typedef $$TrackGenresTableCreateCompanionBuilder =
    TrackGenresCompanion Function({
      required int trackId,
      required int genreId,
      Value<int> rowid,
    });
typedef $$TrackGenresTableUpdateCompanionBuilder =
    TrackGenresCompanion Function({
      Value<int> trackId,
      Value<int> genreId,
      Value<int> rowid,
    });

class $$TrackGenresTableFilterComposer
    extends Composer<_$AppDatabase, $TrackGenresTable> {
  $$TrackGenresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrackGenresTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackGenresTable> {
  $$TrackGenresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get genreId => $composableBuilder(
    column: $table.genreId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrackGenresTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackGenresTable> {
  $$TrackGenresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<int> get genreId =>
      $composableBuilder(column: $table.genreId, builder: (column) => column);
}

class $$TrackGenresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackGenresTable,
          TrackGenre,
          $$TrackGenresTableFilterComposer,
          $$TrackGenresTableOrderingComposer,
          $$TrackGenresTableAnnotationComposer,
          $$TrackGenresTableCreateCompanionBuilder,
          $$TrackGenresTableUpdateCompanionBuilder,
          (
            TrackGenre,
            BaseReferences<_$AppDatabase, $TrackGenresTable, TrackGenre>,
          ),
          TrackGenre,
          PrefetchHooks Function()
        > {
  $$TrackGenresTableTableManager(_$AppDatabase db, $TrackGenresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackGenresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackGenresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackGenresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> trackId = const Value.absent(),
                Value<int> genreId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackGenresCompanion(
                trackId: trackId,
                genreId: genreId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int trackId,
                required int genreId,
                Value<int> rowid = const Value.absent(),
              }) => TrackGenresCompanion.insert(
                trackId: trackId,
                genreId: genreId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TrackGenresTable, TrackGenre>(table),
                  BaseReferences<_$AppDatabase, $TrackGenresTable, TrackGenre>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrackGenresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackGenresTable,
      TrackGenre,
      $$TrackGenresTableFilterComposer,
      $$TrackGenresTableOrderingComposer,
      $$TrackGenresTableAnnotationComposer,
      $$TrackGenresTableCreateCompanionBuilder,
      $$TrackGenresTableUpdateCompanionBuilder,
      (
        TrackGenre,
        BaseReferences<_$AppDatabase, $TrackGenresTable, TrackGenre>,
      ),
      TrackGenre,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  Value<String?> coverUri,
  Value<bool> isSmart,
  Value<String?> rulesJson,
  required int createdAt,
  required int updatedAt,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<String?> coverUri,
  Value<bool> isSmart,
  Value<String?> rulesJson,
  Value<int> createdAt,
  Value<int> updatedAt,
});

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUri => $composableBuilder(
    column: $table.coverUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSmart => $composableBuilder(
    column: $table.isSmart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rulesJson => $composableBuilder(
    column: $table.rulesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUri => $composableBuilder(
    column: $table.coverUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSmart => $composableBuilder(
    column: $table.isSmart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rulesJson => $composableBuilder(
    column: $table.rulesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUri =>
      $composableBuilder(column: $table.coverUri, builder: (column) => column);

  GeneratedColumn<bool> get isSmart =>
      $composableBuilder(column: $table.isSmart, builder: (column) => column);

  GeneratedColumn<String> get rulesJson =>
      $composableBuilder(column: $table.rulesJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist>),
          Playlist,
          PrefetchHooks Function()
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> coverUri = const Value.absent(),
                Value<bool> isSmart = const Value.absent(),
                Value<String?> rulesJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                description: description,
                coverUri: coverUri,
                isSmart: isSmart,
                rulesJson: rulesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> coverUri = const Value.absent(),
                Value<bool> isSmart = const Value.absent(),
                Value<String?> rulesJson = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                description: description,
                coverUri: coverUri,
                isSmart: isSmart,
                rulesJson: rulesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, Playlist>(table),
                  BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, BaseReferences<_$AppDatabase, $PlaylistsTable, Playlist>),
      Playlist,
      PrefetchHooks Function()
    >;
typedef $$PlaylistTracksTableCreateCompanionBuilder =
    PlaylistTracksCompanion Function({
      required int playlistId,
      required String trackKey,
      required int position,
      required int addedAt,
      Value<int> rowid,
    });
typedef $$PlaylistTracksTableUpdateCompanionBuilder =
    PlaylistTracksCompanion Function({
      Value<int> playlistId,
      Value<String> trackKey,
      Value<int> position,
      Value<int> addedAt,
      Value<int> rowid,
    });

class $$PlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackKey => $composableBuilder(
    column: $table.trackKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackKey => $composableBuilder(
    column: $table.trackKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTable> {
  $$PlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackKey =>
      $composableBuilder(column: $table.trackKey, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$PlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistTracksTable,
          PlaylistTrack,
          $$PlaylistTracksTableFilterComposer,
          $$PlaylistTracksTableOrderingComposer,
          $$PlaylistTracksTableAnnotationComposer,
          $$PlaylistTracksTableCreateCompanionBuilder,
          $$PlaylistTracksTableUpdateCompanionBuilder,
          (
            PlaylistTrack,
            BaseReferences<_$AppDatabase, $PlaylistTracksTable, PlaylistTrack>,
          ),
          PlaylistTrack,
          PrefetchHooks Function()
        > {
  $$PlaylistTracksTableTableManager(
    _$AppDatabase db,
    $PlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> playlistId = const Value.absent(),
                Value<String> trackKey = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion(
                playlistId: playlistId,
                trackKey: trackKey,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int playlistId,
                required String trackKey,
                required int position,
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksCompanion.insert(
                playlistId: playlistId,
                trackKey: trackKey,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistTracksTable, PlaylistTrack>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlaylistTracksTable,
                    PlaylistTrack
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistTracksTable,
      PlaylistTrack,
      $$PlaylistTracksTableFilterComposer,
      $$PlaylistTracksTableOrderingComposer,
      $$PlaylistTracksTableAnnotationComposer,
      $$PlaylistTracksTableCreateCompanionBuilder,
      $$PlaylistTracksTableUpdateCompanionBuilder,
      (
        PlaylistTrack,
        BaseReferences<_$AppDatabase, $PlaylistTracksTable, PlaylistTrack>,
      ),
      PlaylistTrack,
      PrefetchHooks Function()
    >;
typedef $$QueueStateTableTableCreateCompanionBuilder =
    QueueStateTableCompanion Function({
      Value<int> id,
      Value<String?> currentTrackKey,
      Value<int> positionMs,
      Value<bool> shuffle,
      Value<int> repeatMode,
      Value<int> seed,
      Value<String> queueJson,
    });
typedef $$QueueStateTableTableUpdateCompanionBuilder =
    QueueStateTableCompanion Function({
      Value<int> id,
      Value<String?> currentTrackKey,
      Value<int> positionMs,
      Value<bool> shuffle,
      Value<int> repeatMode,
      Value<int> seed,
      Value<String> queueJson,
    });

class $$QueueStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $QueueStateTableTable> {
  $$QueueStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentTrackKey => $composableBuilder(
    column: $table.currentTrackKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shuffle => $composableBuilder(
    column: $table.shuffle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get queueJson => $composableBuilder(
    column: $table.queueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueStateTableTable> {
  $$QueueStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentTrackKey => $composableBuilder(
    column: $table.currentTrackKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shuffle => $composableBuilder(
    column: $table.shuffle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queueJson => $composableBuilder(
    column: $table.queueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueStateTableTable> {
  $$QueueStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currentTrackKey => $composableBuilder(
    column: $table.currentTrackKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get shuffle =>
      $composableBuilder(column: $table.shuffle, builder: (column) => column);

  GeneratedColumn<int> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<String> get queueJson =>
      $composableBuilder(column: $table.queueJson, builder: (column) => column);
}

class $$QueueStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueStateTableTable,
          QueueStateTableData,
          $$QueueStateTableTableFilterComposer,
          $$QueueStateTableTableOrderingComposer,
          $$QueueStateTableTableAnnotationComposer,
          $$QueueStateTableTableCreateCompanionBuilder,
          $$QueueStateTableTableUpdateCompanionBuilder,
          (
            QueueStateTableData,
            BaseReferences<
              _$AppDatabase,
              $QueueStateTableTable,
              QueueStateTableData
            >,
          ),
          QueueStateTableData,
          PrefetchHooks Function()
        > {
  $$QueueStateTableTableTableManager(
    _$AppDatabase db,
    $QueueStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueStateTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentTrackKey = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<bool> shuffle = const Value.absent(),
                Value<int> repeatMode = const Value.absent(),
                Value<int> seed = const Value.absent(),
                Value<String> queueJson = const Value.absent(),
              }) => QueueStateTableCompanion(
                id: id,
                currentTrackKey: currentTrackKey,
                positionMs: positionMs,
                shuffle: shuffle,
                repeatMode: repeatMode,
                seed: seed,
                queueJson: queueJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentTrackKey = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<bool> shuffle = const Value.absent(),
                Value<int> repeatMode = const Value.absent(),
                Value<int> seed = const Value.absent(),
                Value<String> queueJson = const Value.absent(),
              }) => QueueStateTableCompanion.insert(
                id: id,
                currentTrackKey: currentTrackKey,
                positionMs: positionMs,
                shuffle: shuffle,
                repeatMode: repeatMode,
                seed: seed,
                queueJson: queueJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueueStateTableTable, QueueStateTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $QueueStateTableTable,
                    QueueStateTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueStateTableTable,
      QueueStateTableData,
      $$QueueStateTableTableFilterComposer,
      $$QueueStateTableTableOrderingComposer,
      $$QueueStateTableTableAnnotationComposer,
      $$QueueStateTableTableCreateCompanionBuilder,
      $$QueueStateTableTableUpdateCompanionBuilder,
      (
        QueueStateTableData,
        BaseReferences<
          _$AppDatabase,
          $QueueStateTableTable,
          QueueStateTableData
        >,
      ),
      QueueStateTableData,
      PrefetchHooks Function()
    >;
typedef $$PlayHistoryTableCreateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      required String trackKey,
      required int startedAt,
      required int listenedMs,
      Value<bool> completed,
      Value<String?> source,
    });
typedef $$PlayHistoryTableUpdateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      Value<String> trackKey,
      Value<int> startedAt,
      Value<int> listenedMs,
      Value<bool> completed,
      Value<String?> source,
    });

class $$PlayHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackKey => $composableBuilder(
    column: $table.trackKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackKey => $composableBuilder(
    column: $table.trackKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackKey =>
      $composableBuilder(column: $table.trackKey, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$PlayHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayHistoryTable,
          PlayHistoryData,
          $$PlayHistoryTableFilterComposer,
          $$PlayHistoryTableOrderingComposer,
          $$PlayHistoryTableAnnotationComposer,
          $$PlayHistoryTableCreateCompanionBuilder,
          $$PlayHistoryTableUpdateCompanionBuilder,
          (
            PlayHistoryData,
            BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData>,
          ),
          PlayHistoryData,
          PrefetchHooks Function()
        > {
  $$PlayHistoryTableTableManager(_$AppDatabase db, $PlayHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trackKey = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int> listenedMs = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String?> source = const Value.absent(),
              }) => PlayHistoryCompanion(
                id: id,
                trackKey: trackKey,
                startedAt: startedAt,
                listenedMs: listenedMs,
                completed: completed,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trackKey,
                required int startedAt,
                required int listenedMs,
                Value<bool> completed = const Value.absent(),
                Value<String?> source = const Value.absent(),
              }) => PlayHistoryCompanion.insert(
                id: id,
                trackKey: trackKey,
                startedAt: startedAt,
                listenedMs: listenedMs,
                completed: completed,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayHistoryTable, PlayHistoryData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PlayHistoryTable,
                    PlayHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayHistoryTable,
      PlayHistoryData,
      $$PlayHistoryTableFilterComposer,
      $$PlayHistoryTableOrderingComposer,
      $$PlayHistoryTableAnnotationComposer,
      $$PlayHistoryTableCreateCompanionBuilder,
      $$PlayHistoryTableUpdateCompanionBuilder,
      (
        PlayHistoryData,
        BaseReferences<_$AppDatabase, $PlayHistoryTable, PlayHistoryData>,
      ),
      PlayHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LibraryFoldersTableCreateCompanionBuilder =
    LibraryFoldersCompanion Function({
      Value<int> id,
      required String path,
      Value<String> mode,
    });
typedef $$LibraryFoldersTableUpdateCompanionBuilder =
    LibraryFoldersCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<String> mode,
    });

class $$LibraryFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryFoldersTable> {
  $$LibraryFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryFoldersTable> {
  $$LibraryFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryFoldersTable> {
  $$LibraryFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);
}

class $$LibraryFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryFoldersTable,
          LibraryFolder,
          $$LibraryFoldersTableFilterComposer,
          $$LibraryFoldersTableOrderingComposer,
          $$LibraryFoldersTableAnnotationComposer,
          $$LibraryFoldersTableCreateCompanionBuilder,
          $$LibraryFoldersTableUpdateCompanionBuilder,
          (
            LibraryFolder,
            BaseReferences<_$AppDatabase, $LibraryFoldersTable, LibraryFolder>,
          ),
          LibraryFolder,
          PrefetchHooks Function()
        > {
  $$LibraryFoldersTableTableManager(
    _$AppDatabase db,
    $LibraryFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> mode = const Value.absent(),
          }) => LibraryFoldersCompanion(id: id, path: path, mode: mode),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String path,
            Value<String> mode = const Value.absent(),
          }) => LibraryFoldersCompanion.insert(id: id, path: path, mode: mode),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryFoldersTable, LibraryFolder>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LibraryFoldersTable,
                    LibraryFolder
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryFoldersTable,
      LibraryFolder,
      $$LibraryFoldersTableFilterComposer,
      $$LibraryFoldersTableOrderingComposer,
      $$LibraryFoldersTableAnnotationComposer,
      $$LibraryFoldersTableCreateCompanionBuilder,
      $$LibraryFoldersTableUpdateCompanionBuilder,
      (
        LibraryFolder,
        BaseReferences<_$AppDatabase, $LibraryFoldersTable, LibraryFolder>,
      ),
      LibraryFolder,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String valueJson,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$ArtistsTableTableManager get artists =>
      $$ArtistsTableTableManager(_db, _db.artists);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
  $$GenresTableTableManager get genres =>
      $$GenresTableTableManager(_db, _db.genres);
  $$TrackGenresTableTableManager get trackGenres =>
      $$TrackGenresTableTableManager(_db, _db.trackGenres);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(_db, _db.playlistTracks);
  $$QueueStateTableTableTableManager get queueStateTable =>
      $$QueueStateTableTableTableManager(_db, _db.queueStateTable);
  $$PlayHistoryTableTableManager get playHistory =>
      $$PlayHistoryTableTableManager(_db, _db.playHistory);
  $$LibraryFoldersTableTableManager get libraryFolders =>
      $$LibraryFoldersTableTableManager(_db, _db.libraryFolders);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
