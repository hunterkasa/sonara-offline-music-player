// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سونارا';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSearch => 'البحث';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get nowPlaying => 'قيد التشغيل الآن';

  @override
  String get noTrackPlaying => 'لا يوجد مسار قيد التشغيل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get themeMode => 'وضع المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeAmoled => 'داكن AMOLED';

  @override
  String get themeSystem => 'افتراضي النظام';
}
