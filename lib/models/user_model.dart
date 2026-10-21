class UserProfile {
  String userId;
  String fullName;
  DateTime birthDate;
  String gender;
  String university;
  String bio;
  String status;
  List<String> photos;
  List<String> interests;
  double latitude;
  double longitude;
  String? lastMessage;
  bool isIncognito;
  bool isPremium;
  double avatarScale;
  String? videoPath;
  String relationship;
  String email;

  UserProfile({
    required this.userId,
    required this.fullName,
    required this.birthDate,
    required this.gender,
    this.university = '',
    this.bio = '',
    this.status = 'Учусь в ВУЗе',
    this.photos = const [],
    this.interests = const [],
    this.latitude = 0,
    this.longitude = 0,
    this.lastMessage,
    this.isIncognito = false,
    this.isPremium = false,
    this.avatarScale = 1.0,
    this.videoPath,
    this.relationship = 'Свободен',
    this.email = '',
  });

  int get age {
    final today = DateTime.now();
    int a = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      a -= 1;
    }
    return a;
  }

  int calculateCompatibility(List<String> myInterests) {
    if (myInterests.isEmpty || interests.isEmpty) return 78;
    final setA = myInterests.map((e) => e.toLowerCase()).toSet();
    final setB = interests.map((e) => e.toLowerCase()).toSet();
    final common = setA.intersection(setB).length;
    final total = setA.union(setB).length;
    if (total == 0) return 75;
    int score = 55 + ((common / total) * 45).round();
    return score.clamp(55, 98);
  }
}