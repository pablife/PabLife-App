/// Gênero informado pela pessoa (opcional).
enum Gender {
  female('feminino', 'Feminino'),
  male('masculino', 'Masculino'),
  nonBinary('nao_binario', 'Não binário'),
  other('outro', 'Outro'),
  undisclosed('prefiro_nao_informar', 'Prefiro não informar');

  const Gender(this.value, this.label);

  /// Como fica no banco.
  final String value;

  /// Como aparece na tela.
  final String label;

  static Gender? fromValue(String? value) {
    for (final g in values) {
      if (g.value == value) return g;
    }
    return null;
  }
}
