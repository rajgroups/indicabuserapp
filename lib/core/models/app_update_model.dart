class AppUpdateModel {
  final bool updateAvailable;
  final bool forceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String minVersion;
  final String updateUrl;
  final String title;
  final String message;

  const AppUpdateModel({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.minVersion,
    required this.updateUrl,
    required this.title,
    required this.message,
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      updateAvailable: json['update_available'] as bool? ?? false,
      forceUpdate: json['force_update'] as bool? ?? false,
      currentVersion: json['current_version']?.toString() ?? '1.0.0',
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      minVersion: json['min_version']?.toString() ?? '1.0.0',
      updateUrl: json['update_url']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Update Available',
      message: json['message']?.toString() ?? 'A new version of the app is available. Please update.',
    );
  }

  Map<String, dynamic> toJson() => {
        'update_available': updateAvailable,
        'force_update': forceUpdate,
        'current_version': currentVersion,
        'latest_version': latestVersion,
        'min_version': minVersion,
        'update_url': updateUrl,
        'title': title,
        'message': message,
      };
}
