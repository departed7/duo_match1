class UserProfile {
  final String userId;
  String fullName;
  DateTime birthDate;
  String gender;
  String university;
  String bio;
  List<String> photos;
  List<String> interests;
  final double latitude;
  final double longitude;
  bool isPremium;
  bool isIncognito;
  String lastMessage;
  double avatarScale;
  String? videoPath;

  UserProfile({
    required this.userId,
    required this.fullName,
    required this.birthDate,
    required this.gender,
    required this.university,
    required this.bio,
    required this.photos,
    required this.interests,
    required this.latitude,
    required this.longitude,
    this.isPremium = false,
    this.isIncognito = false,
    this.lastMessage = "",
    this.avatarScale = 1.0,
    this.videoPath,
  });

  int get age {
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}