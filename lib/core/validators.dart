class AppValidators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле $fieldName обязательно для заполнения';
    }
    return null;
  }

  static String? validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный адрес почты';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }
    return null;
  }
}