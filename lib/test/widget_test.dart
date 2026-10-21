import 'package:flutter_test/flutter_test.dart';
import 'package:duo_match/models/user_model.dart';

void main() {
  test('Тестирование расчета совместимости пар', () {
    final user = UserProfile(
      userId: 'u1',
      fullName: 'Тест',
      birthDate: DateTime(2003, 1, 1),
      gender: 'Мужской',
      interests: ['Музыка', 'Кофе', 'Спорт'],
    );
    final myInterests = ['Музыка', 'Кофе'];
    final score = user.calculateCompatibility(myInterests);
    expect(score, greaterThanOrEqualTo(55));
  });
}