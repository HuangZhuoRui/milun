/// 命盘档案实体模型
class UserProfile {
  /// 唯一标识 ID
  final String id;

  /// 姓名 / 测算对象称谓
  final String name;

  /// 性别：'乾 (男)' 或 '坤 (女)'
  final String gender;

  /// 公历出生日期
  final DateTime solarDate;

  /// 是否为农历输入
  final bool isLunar;

  /// 时辰序号：0..11 对应 十二地支时辰，-1 表示时辰不详
  final int hourIndex;

  /// 是否已知确切时辰
  final bool isHourKnown;

  /// 出生地域/城市
  final String? birthCity;

  /// 档案备注说明
  final String notes;

  /// 档案创建时间
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.solarDate,
    required this.isLunar,
    required this.hourIndex,
    required this.isHourKnown,
    this.birthCity,
    required this.notes,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      gender: json['gender'] as String? ?? '乾 (男)',
      solarDate: DateTime.parse(json['solarDate'] as String),
      isLunar: json['isLunar'] as bool? ?? false,
      hourIndex: json['hourIndex'] as int? ?? 0,
      isHourKnown: json['isHourKnown'] as bool? ?? true,
      birthCity: json['birthCity'] as String?,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender,
        'solarDate': solarDate.toIso8601String(),
        'isLunar': isLunar,
        'hourIndex': hourIndex,
        'isHourKnown': isHourKnown,
        'birthCity': birthCity,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}
