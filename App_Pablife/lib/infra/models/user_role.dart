enum UserRole {
  user('user', 'Usuário'),
  professional('professional', 'Profissional'),
  admin('admin', 'Administrador');

  const UserRole(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }
}
