import '../models/user_model.dart';

class AuthService {
  static final List<UserProfile> testUsers = [
    UserProfile(
      userId: 'admin_1',
      fullName: 'Администратор',
      birthDate: DateTime(2000, 1, 1),
      gender: 'Мужской',
      university: 'РЭУ им. Плеханова • Модератор',
      bio: 'Системный аккаунт модератора DuoMatch.',
      status: 'Техподдержка',
      photos: ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500'],
      interests: const ['Безопасность', 'IT', 'Учеба'],
      isPremium: true,
      email: 'admin@duomatch.ru',
      relationship: 'Модератор',
    ),
    UserProfile(
      userId: 'u_volkov',
      fullName: 'Александр Волков',
      birthDate: DateTime(2003, 5, 20),
      gender: 'Мужской',
      university: 'МГТУ им. Баумана • 4 курс',
      bio: 'Инженер и гитарист. Ищу ту, с кем можно сходить на рок-концерт.',
      status: 'На парах',
      photos: ['https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500'],
      interests: const ['Рок', 'Гитара', 'Космос', 'Спорт'],
      isPremium: true,
      email: 'volkov@mail.ru',
      relationship: 'Свободен',
    ),
    UserProfile(
      userId: 'u_belova',
      fullName: 'Дарья Белова',
      birthDate: DateTime(2004, 4, 14),
      gender: 'Женский',
      university: 'РЭУ им. Плеханова • 3 курс',
      bio: 'Обожаю винил, кофе и долгие вечерние прогулки.',
      status: 'Слушаю музыку',
      photos: ['assets/images/profile_1.jpg'],
      interests: const ['Музыка', 'Кофе', 'Дизайн'],
      isPremium: false,
      email: 'belova@mail.ru',
      relationship: 'Свободна',
    ),
    UserProfile(
      userId: 'u_osipyan',
      fullName: 'Лусине Осипян',
      birthDate: DateTime(2004, 11, 17),
      gender: 'Женский',
      university: 'РЭУ им. Плеханова • 3 курс',
      bio: 'Люблю душевные разговоры до утра и зеленый чай.',
      status: 'Пью чай',
      photos: ['assets/images/profile_2.jpg'],
      interests: const ['Фотография', 'Чай', 'Психология'],
      isPremium: true,
      email: 'osipyan@mail.ru',
      relationship: 'Свободна',
    ),
  ];

  static UserProfile? getTestUser(String email, String password) {
    final clean = email.trim().toLowerCase();
    if (clean == 'admin@duomatch.ru' && password == 'Admin123!') return testUsers[0];
    if (clean == 'volkov@mail.ru' && password == 'Volkov123!') return testUsers[1];
    if (clean == 'belova@mail.ru' && password == 'Belova123!') return testUsers[2];
    if (clean == 'osipyan@mail.ru' && password == 'Osipyan123!') return testUsers[3];
    return null;
  }
}