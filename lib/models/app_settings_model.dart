import 'package:hive/hive.dart';

part 'app_settings_model.g.dart';

@HiveType(typeId: 3)
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  final String themeMode;

  @HiveField(1)
  final String languageCode;

  AppSettingsModel({
    this.themeMode = 'light',
    this.languageCode = 'bn',
  });

  AppSettingsModel copyWith({
    String? themeMode,
    String? languageCode,
  }) {
    return AppSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode,
      'language_code': languageCode,
    };
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      themeMode: json['theme_mode'] as String? ?? json['themeMode'] as String? ?? 'light',
      languageCode: json['language_code'] as String? ?? json['languageCode'] as String? ?? 'bn',
    );
  }
}
