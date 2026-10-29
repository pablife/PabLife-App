enum UserStatus {
  active('active', 'Ativo'),
  inactive('inactive', 'Inativo'),
  pending('pending', 'Pendente'),
  suspended('suspended', 'Suspenso');

  const UserStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.active,
    );
  }
}
