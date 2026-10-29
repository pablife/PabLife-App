enum ProfessionalType {
  nutritionist('nutritionist', 'Nutricionista'),
  psychologist('psychologist', 'Psicólogo');

  const ProfessionalType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ProfessionalType fromString(String value) {
    return ProfessionalType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProfessionalType.nutritionist,
    );
  }
}
