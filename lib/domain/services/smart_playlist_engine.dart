import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';

final smartPlaylistEngineProvider = Provider<SmartPlaylistEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return SmartPlaylistEngine(db);
});

enum SmartField {
  title,
  artist,
  album,
  genre,
  year,
  playCount,
  skipCount,
  lastPlayed,
  dateAdded,
  duration,
  isFavorite,
}

enum SmartOperator { equals, contains, greaterThan, lessThan, isTrue, isFalse }

class SmartRule {
  final SmartField field;
  final SmartOperator operator;
  final dynamic value;

  const SmartRule({required this.field, required this.operator, this.value});

  Map<String, dynamic> toJson() => {
    'field': field.name,
    'operator': operator.name,
    'value': value,
  };

  factory SmartRule.fromJson(Map<String, dynamic> json) {
    return SmartRule(
      field: SmartField.values.byName(json['field'] as String),
      operator: SmartOperator.values.byName(json['operator'] as String),
      value: json['value'],
    );
  }

  bool evaluate(
    Track track, {
    String? artistName,
    String? albumTitle,
    List<String> genres = const [],
  }) {
    switch (field) {
      case SmartField.title:
        return _evaluateString(track.title, operator, value?.toString() ?? '');
      case SmartField.artist:
        return _evaluateString(
          artistName ?? '',
          operator,
          value?.toString() ?? '',
        );
      case SmartField.album:
        return _evaluateString(
          albumTitle ?? '',
          operator,
          value?.toString() ?? '',
        );
      case SmartField.genre:
        final target = value?.toString() ?? '';
        return genres.any((g) => _evaluateString(g, operator, target));
      case SmartField.year:
        final y = track.year ?? 0;
        final target = int.tryParse(value?.toString() ?? '') ?? 0;
        return _evaluateNumber(y, operator, target);
      case SmartField.playCount:
        final target = int.tryParse(value?.toString() ?? '') ?? 0;
        return _evaluateNumber(track.playCount, operator, target);
      case SmartField.skipCount:
        final target = int.tryParse(value?.toString() ?? '') ?? 0;
        return _evaluateNumber(track.skipCount, operator, target);
      case SmartField.lastPlayed:
        final last = track.lastPlayedAt ?? 0;
        final target = int.tryParse(value?.toString() ?? '') ?? 0;
        return _evaluateNumber(last, operator, target);
      case SmartField.dateAdded:
        final added = track.dateAdded ?? 0;
        final target = int.tryParse(value?.toString() ?? '') ?? 0;
        return _evaluateNumber(added, operator, target);
      case SmartField.duration:
        final durSec = track.durationMs ~/ 1000;
        final target = int.tryParse(value?.toString() ?? '') ?? 0;
        return _evaluateNumber(durSec, operator, target);
      case SmartField.isFavorite:
        return operator == SmartOperator.isTrue
            ? track.isFavorite
            : !track.isFavorite;
    }
  }

  bool _evaluateString(String fieldVal, SmartOperator op, String target) {
    final lowerField = fieldVal.trim().toLowerCase();
    final lowerTarget = target.trim().toLowerCase();
    switch (op) {
      case SmartOperator.equals:
        return lowerField == lowerTarget;
      case SmartOperator.contains:
        return lowerField.contains(lowerTarget);
      default:
        return false;
    }
  }

  bool _evaluateNumber(int fieldVal, SmartOperator op, int target) {
    switch (op) {
      case SmartOperator.equals:
        return fieldVal == target;
      case SmartOperator.greaterThan:
        return fieldVal > target;
      case SmartOperator.lessThan:
        return fieldVal < target;
      default:
        return false;
    }
  }
}

class SmartRuleGroup {
  final bool matchAll;
  final List<SmartRule> rules;
  final int limit;
  final SmartField? sortBy;
  final bool sortAscending;

  const SmartRuleGroup({
    this.matchAll = true,
    required this.rules,
    this.limit = 50,
    this.sortBy,
    this.sortAscending = true,
  });

  Map<String, dynamic> toJson() => {
    'matchAll': matchAll,
    'rules': rules.map((r) => r.toJson()).toList(),
    'limit': limit,
    'sortBy': sortBy?.name,
    'sortAscending': sortAscending,
  };

  factory SmartRuleGroup.fromJson(Map<String, dynamic> json) {
    final rulesList = (json['rules'] as List<dynamic>? ?? [])
        .map((r) => SmartRule.fromJson(r as Map<String, dynamic>))
        .toList();
    return SmartRuleGroup(
      matchAll: json['matchAll'] as bool? ?? true,
      rules: rulesList,
      limit: json['limit'] as int? ?? 50,
      sortBy: json['sortBy'] != null
          ? SmartField.values.byName(json['sortBy'] as String)
          : null,
      sortAscending: json['sortAscending'] as bool? ?? true,
    );
  }
}

class SmartPlaylistEngine {
  final AppDatabase _db;

  SmartPlaylistEngine(this._db);

  /// Evaluate rule group against all tracks and return matched tracks
  Future<List<Track>> evaluate(SmartRuleGroup group) async {
    final allTracks = await _db.getAllTracks(includeHidden: false);
    final allGenresMap = await _db.getAllTrackGenresMap();
    final allArtists = await _db.getAllArtists();
    final allAlbums = await _db.getAllAlbums();
    final artistMap = {for (final a in allArtists) a.id: a.name};
    final albumMap = {for (final a in allAlbums) a.id: a.title};
    final matched = <Track>[];

    for (final track in allTracks) {
      final artistName = artistMap[track.artistId];
      final albumTitle = albumMap[track.albumId];
      final trackGenres = allGenresMap[track.id] ?? const [];

      if (group.rules.isEmpty) {
        matched.add(track);
        continue;
      }

      var matches = group.matchAll;
      for (final rule in group.rules) {
        final result = rule.evaluate(
          track,
          artistName: artistName,
          albumTitle: albumTitle,
          genres: trackGenres,
        );
        if (group.matchAll) {
          if (!result) {
            matches = false;
            break;
          }
        } else {
          if (result) {
            matches = true;
            break;
          }
        }
      }

      if (matches) {
        matched.add(track);
      }
    }

    // Sort
    if (group.sortBy != null) {
      matched.sort((a, b) {
        int comp;
        switch (group.sortBy!) {
          case SmartField.title:
            comp = a.title.compareTo(b.title);
            break;
          case SmartField.playCount:
            comp = a.playCount.compareTo(b.playCount);
            break;
          case SmartField.skipCount:
            comp = a.skipCount.compareTo(b.skipCount);
            break;
          case SmartField.dateAdded:
            comp = (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
            break;
          case SmartField.lastPlayed:
            comp = (a.lastPlayedAt ?? 0).compareTo(b.lastPlayedAt ?? 0);
            break;
          case SmartField.year:
            comp = (a.year ?? 0).compareTo(b.year ?? 0);
            break;
          case SmartField.duration:
            comp = a.durationMs.compareTo(b.durationMs);
            break;
          default:
            comp = a.title.compareTo(b.title);
        }
        return group.sortAscending ? comp : -comp;
      });
    }

    if (group.limit > 0 && matched.length > group.limit) {
      return matched.sublist(0, group.limit);
    }

    return matched;
  }

  /// Preset: Most Played Tracks
  static SmartRuleGroup mostPlayedPreset() => const SmartRuleGroup(
    rules: [
      SmartRule(
        field: SmartField.playCount,
        operator: SmartOperator.greaterThan,
        value: 1,
      ),
    ],
    sortBy: SmartField.playCount,
    sortAscending: false,
    limit: 30,
  );

  /// Preset: Recently Added
  static SmartRuleGroup recentlyAddedPreset() => const SmartRuleGroup(
    rules: [],
    sortBy: SmartField.dateAdded,
    sortAscending: false,
    limit: 30,
  );

  /// Preset: Never Played
  static SmartRuleGroup neverPlayedPreset() => const SmartRuleGroup(
    rules: [
      SmartRule(
        field: SmartField.playCount,
        operator: SmartOperator.equals,
        value: 0,
      ),
    ],
    sortBy: SmartField.dateAdded,
    sortAscending: false,
    limit: 50,
  );

  /// Preset: Forgotten Favorites
  static SmartRuleGroup forgottenFavoritesPreset() => const SmartRuleGroup(
    rules: [
      SmartRule(field: SmartField.isFavorite, operator: SmartOperator.isTrue),
    ],
    sortBy: SmartField.lastPlayed,
    sortAscending: true,
    limit: 25,
  );
}
