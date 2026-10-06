// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Sonara';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navLibrary => '媒体库';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get noTrackPlaying => '暂无播放曲目';

  @override
  String get settingsTitle => '设置';

  @override
  String get themeMode => '主题模式';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeAmoled => '纯黑 AMOLED';

  @override
  String get themeSystem => '跟随系统';
}
