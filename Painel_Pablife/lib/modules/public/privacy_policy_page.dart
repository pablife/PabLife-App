import 'package:flutter/material.dart';

/// Política de Privacidade do PabLife (endereço informado ao Google Play e à
/// App Store). Texto revisado pelo encarregado de dados em 18/11/2026.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String route = '/politica-de-privacidade';

  static const _azul = Color(0xFF1E3A5F);
  static const _email = 'pablifeapp@pablife.com.br';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _azul,
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Política de Privacidade do PabLife',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _azul,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Última atualização: 26 de novembro de 2026',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  _p(
                    'Esta política explica quais dados o PabLife coleta, para que usa, com quem compartilha e como você pode exercer seus direitos pela Lei Geral de Proteção de Dados (Lei nº 13.709/2018, LGPD). Vale para o app PabLife no Android e no iPhone e para o site app.pablife.com.br.',
                  ),
                  _h('1. Quem somos e como falar conosco'),
                  _p(
                    'O PabLife é o controlador dos seus dados pessoais: decide como e para que eles são usados.',
                  ),
                  _item('Empresa: PAB DESENVOLVIMENTO LTDA (nome fantasia: PAB LIFE)'),
                  _item('CNPJ: 62.990.545/0001-40'),
                  _item('Endereço: Rua Abdon Galdino, 2069, Letra B, Centro, Cascavel - CE, CEP 62850-000'),
                  _item('Encarregado de dados (DPO): Rafael Paulino Bulhões Alves'),
                  _item('Contato para privacidade: $_email'),
                  _p('Respondemos pedidos sobre seus dados em até 15 dias.'),
                  _h('2. Quais dados coletamos'),
                  _p(
                    'Coletamos só o necessário para o app funcionar. Dados de saúde são dados pessoais sensíveis pela LGPD e recebem cuidado redobrado.',
                  ),
                  _item('Cadastro: nome, apelido, e-mail, telefone, CPF, data de nascimento, gênero (opcional) e foto de perfil, ao criar e editar a conta. A data de nascimento confirma a idade mínima de 18 anos; data e gênero não são mostrados às profissionais nem a outros usuários.'),
                  _item('Saúde da Mulher (dado sensível): ciclo menstrual, sintomas, humor, energia, sono, diário, tentativas e testes, gestação e seus registros. Só se você usar essa área e der seu consentimento.'),
                  _item('Consultas: profissional escolhida, datas, remarcações, cancelamentos e motivo, avaliações.'),
                  _item('Registros feitos pela profissional (dado sensível): anotações sobre o atendimento.'),
                  _item('Agenda pessoal: tarefas, metas diárias e lembretes que você cria.'),
                  _item('Profissionais: registro no conselho, documentos de validação, especialização e descrição.'),
                  _item('Estudantes: instituição, curso e comprovante, ao pedir o plano estudante.'),
                  _item('Vínculo de trabalho: se você é servidor(a) público(a), colaborador(a) de empresa parceira ou particular; a organização (prefeitura, câmara ou empresa) e o cargo, que é opcional. Se usar um código de convite, registramos que o plano veio do convênio.'),
                  _item('Pagamentos: plano, valor, datas, situação do pagamento e cupom usado.'),
                  _item('Aparelho e uso do app: identificador para notificações e relatórios de falha (modelo do aparelho, versão do sistema).'),
                  _p(
                    'Os dados do cartão (número, validade, código de segurança, nome e CPF do titular) são digitados no app e enviados por conexão segura ao Mercado Pago para a cobrança. O PabLife não guarda esses dados.',
                  ),
                  _p(
                    'Não coletamos localização, contatos do celular, calendário do celular nem áudio. O PabLife não exibe anúncios.',
                  ),
                  _h('3. Para que usamos e com qual base legal'),
                  _p(
                    'Cada uso tem uma base legal da LGPD. Não vendemos seus dados e não usamos dados de saúde para publicidade.',
                  ),
                  _item('Criar e manter sua conta; agendar, remarcar e cancelar consultas; lembretes e avisos do app: execução de contrato (art. 7º, V).'),
                  _item('Acompanhar ciclo, humor, diário e gestação: consentimento específico e destacado (art. 11, I), registrado no app.'),
                  _item('Registros de saúde feitos pela profissional: tutela da saúde, em procedimento realizado por profissional de saúde (art. 11, II, f).'),
                  _item('Validar profissionais e estudantes e evitar fraudes: cumprimento de obrigação legal e legítimo interesse (art. 7º, II e IX).'),
                  _item('Liberar o plano do convênio da sua organização: execução de contrato (art. 7º, V).'),
                  _item('Relatórios para a sua organização, só com números somados e sem identificar ninguém: legítimo interesse (art. 7º, IX).'),
                  _item('Cobrar planos e guardar comprovantes: execução de contrato e obrigação legal fiscal (art. 7º, V e II).'),
                  _item('E-mails sobre novidades e benefícios: legítimo interesse (art. 7º, IX), com opção de sair em todo e-mail.'),
                  _item('Corrigir falhas do app: legítimo interesse (art. 7º, IX).'),
                  _p(
                    'Você pode retirar o consentimento da Saúde da Mulher a qualquer momento. Isso não afeta o que foi feito antes da retirada.',
                  ),
                  _h('4. Com quem compartilhamos'),
                  _p(
                    'Profissionais que você escolhe: ao agendar, a profissional vê seu nome, telefone, CPF e os dados da consulta. Diário e registros da gestação só chegam a ela se você escolher compartilhar.',
                  ),
                  _p(
                    'Sua organização (prefeitura, câmara ou empresa parceira): recebe só números somados, como quantas pessoas usam o PabLife. Nunca recebe seu nome, seus dados de saúde, suas consultas nem qualquer dado que identifique você.',
                  ),
                  _p(
                    'Empresas que operam o serviço para nós, que só podem usar os dados para prestar o serviço ao PabLife:',
                  ),
                  _item('Supabase: banco de dados, login e arquivos.'),
                  _item('Google Firebase: site e relatórios de falha.'),
                  _item('OneSignal: notificações no celular.'),
                  _item('Mercado Pago: cobrança dos planos.'),
                  _item('Customer.io: e-mails do PabLife.'),
                  _p('Autoridades: quando a lei ou uma ordem judicial exigir.'),
                  _h('5. Onde os dados ficam, segurança e por quanto tempo'),
                  _p(
                    'O banco de dados fica nos Estados Unidos (Supabase). Firebase, OneSignal e Customer.io também podem tratar dados fora do Brasil. Essas transferências seguem o art. 33 da LGPD, com garantias contratuais de proteção.',
                  ),
                  _item('Todo envio de dados usa conexão criptografada (HTTPS).'),
                  _item('Regras no banco garantem que cada pessoa só acesse os próprios dados; a profissional só vê pacientes que agendaram com ela.'),
                  _item('Senhas não ficam guardadas em texto aberto.'),
                  _item('O acesso da equipe aos dados é restrito.'),
                  _p('Por quanto tempo guardamos:'),
                  _item('Conta, vínculo de trabalho, Saúde da Mulher e agenda: enquanto a conta existir; apagados ao excluir a conta.'),
                  _item('Códigos de convite digitados errado: até 1 dia, de forma embaralhada, só para bloquear tentativas em massa.'),
                  _item('Registros de pagamento, sem nome nem e-mail: pelo prazo da lei fiscal (em geral, 5 anos).'),
                  _item('Datas de consultas já realizadas, sem dados pessoais: pelo tempo necessário à prestação de contas e ao exercício regular de direitos.'),
                  _item('Registros feitos pela profissional: anonimizados ao excluir a conta, respeitadas as regras de guarda do conselho profissional.'),
                  _item('Relatórios de falha: até 90 dias.'),
                  _h('6. Seus direitos'),
                  _p('Pela LGPD (art. 18), você pode pedir a qualquer momento:'),
                  _item('confirmação de que tratamos seus dados e acesso a eles;'),
                  _item('correção de dados errados ou desatualizados;'),
                  _item('anonimização, bloqueio ou eliminação de dados desnecessários;'),
                  _item('portabilidade para outro serviço;'),
                  _item('informação sobre com quem compartilhamos;'),
                  _item('retirada do consentimento e eliminação dos dados tratados com ele.'),
                  _p(
                    'Muitos dados você mesmo corrige em Perfil. Para o resto, escreva para $_email. Você também pode reclamar à Autoridade Nacional de Proteção de Dados (ANPD).',
                  ),
                  _p(
                    'Excluir a conta: no app ou no site, vá em Perfil → Excluir conta. O passo a passo e o que é apagado estão em app.pablife.com.br/excluir-conta.',
                  ),
                  _p(
                    'Menores de idade: o PabLife é para maiores de 18 anos. Não coletamos dados de crianças de propósito; se isso acontecer, apagamos.',
                  ),
                  _p(
                    'Mudanças nesta política: avisamos no app antes de mudanças importantes. A data da última atualização fica no topo desta página.',
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} PAB DESENVOLVIMENTO LTDA. Todos os direitos reservados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _h(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _azul,
        ),
      ),
    );
  }

  static Widget _p(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        content,
        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
      ),
    );
  }

  static Widget _item(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 16, height: 1.6)),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
