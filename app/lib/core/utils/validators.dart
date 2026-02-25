/// Utility class for input validation
class Validators {
  /// Validates if a string is not empty
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName é obrigatório'
          : 'Campo obrigatório';
    }
    return null;
  }

  /// Validates if a value is a valid positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName é obrigatório'
          : 'Campo obrigatório';
    }

    // Parse BRL format
    String cleaned = value.replaceAll('R\$', '').trim();
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');

    final number = double.tryParse(cleaned);
    if (number == null) {
      return 'Valor inválido';
    }

    if (number <= 0) {
      return 'O valor deve ser maior que zero';
    }

    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.length < min) {
      return fieldName != null
          ? '$fieldName deve ter pelo menos $min caracteres'
          : 'Mínimo de $min caracteres';
    }
    return null;
  }

  /// Validates maximum length
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return fieldName != null
          ? '$fieldName deve ter no máximo $max caracteres'
          : 'Máximo de $max caracteres';
    }
    return null;
  }

  /// Validates if a date is not in the future
  static String? notFutureDate(DateTime? date) {
    if (date == null) {
      return 'Data é obrigatória';
    }

    if (date.isAfter(DateTime.now())) {
      return 'A data não pode ser no futuro';
    }

    return null;
  }

  /// Validates if a category is selected
  static String? categoryRequired(String? category) {
    if (category == null || category.isEmpty) {
      return 'Selecione uma categoria';
    }
    return null;
  }

  /// Combines multiple validators
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
