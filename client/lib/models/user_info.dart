class UserInfo {
  const UserInfo({
    required this.sessionId,
    this.platUserId,
    this.email,
    this.displayName,
  });

  final String sessionId;
  final int? platUserId;
  final String? email;
  final String? displayName;

  String get nickname => (displayName != null && displayName!.isNotEmpty)
      ? displayName!
      : (email ?? sessionId.substring(0, 6));

  String get avatarLetter {
    final src = (displayName != null && displayName!.isNotEmpty)
        ? displayName!
        : (email ?? '?');
    return src.isEmpty ? '?' : src.substring(0, 1).toUpperCase();
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        sessionId: json['sessionId'] as String? ?? '',
        platUserId: (json['platUserId'] as num?)?.toInt(),
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
      );
}
