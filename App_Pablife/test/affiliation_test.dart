import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pablife/infra/models/affiliation.dart';
import 'package:pablife/infra/repositories/affiliation_repository.dart';
import 'package:pablife/modules/auth/affiliation_draft.dart';
import 'package:pablife/modules/auth/controllers/sign_up_controller.dart';
import 'package:pablife/modules/auth/pages/affiliation_page.dart';
import 'package:pablife/modules/auth/pages/student_proof_page.dart';
import 'package:pablife/modules/profile/widgets/affiliation_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _fortaleza = Organization(
  id: 'pmfor',
  name: 'Prefeitura de Fortaleza',
  kind: 'prefeitura',
  city: 'Fortaleza',
  state: 'CE',
);
const _caucaia = Organization(
  id: 'pmcau',
  name: 'Prefeitura de Caucaia',
  kind: 'prefeitura',
  city: 'Caucaia',
  state: 'CE',
);

/// Banco de mentira: guarda o que foi pedido para conferir depois.
class _FakeRepo extends AffiliationRepository {
  final calls = <String>[];
  Map<String, Object?>? saved;
  InviteRedeem redeem = const InviteRedeem(
    valid: true,
    planGranted: true,
    planName: 'Lite',
  );

  @override
  Future<List<Organization>> searchOrganizations({
    required List<String> kinds,
    String search = '',
  }) async {
    calls.add('search:${kinds.join(',')}:$search');
    final all = [_fortaleza, _caucaia];
    final q = search.toLowerCase();
    return all
        .where((o) => kinds.contains(o.kind))
        .where((o) => q.isEmpty || o.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<InviteCheck> validateInvite(String code) async {
    calls.add('validate:$code');
    if (code.trim().toUpperCase() == 'PMFORTALEZA-7K2') {
      return const InviteCheck(
        valid: true,
        organization: _fortaleza,
        kind: AffiliationKind.publicServant,
        planName: 'Lite',
      );
    }
    if (code == 'BLOQ-1') {
      return const InviteCheck.invalid('too_many_attempts');
    }
    return const InviteCheck.invalid('not_found');
  }

  @override
  Future<InviteRedeem?> redeemInvite(String code, {String? roleTitle}) async {
    calls.add('redeem:$code:$roleTitle');
    return redeem;
  }

  @override
  Future<String?> saveMine({
    required AffiliationKind kind,
    String? organizationId,
    String? suggestedOrganization,
    String? roleTitle,
  }) async {
    calls.add('save');
    saved = {
      'kind': kind,
      'organizationId': organizationId,
      'suggestion': suggestedOrganization,
      'role': roleTitle,
    };
    return null;
  }
}

void main() {
  late _FakeRepo repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://exemplo.supabase.co', anonKey: 'x');
  });

  setUp(() {
    Get.testMode = true;
    repo = _FakeRepo();
    AffiliationRepository.instance = repo;
  });

  tearDown(() {
    Get.reset();
    AffiliationRepository.instance = AffiliationRepository();
  });

  group('cadastro', () {
    test('"vínculo" é obrigatório para usuário, não para profissional', () {
      final c = SignUpController();
      expect(c.missing, contains('vínculo'));
      c.updateAffiliationKind(AffiliationKind.private);
      expect(c.missing, isNot(contains('vínculo')));

      final pro = SignUpController()..accountType = 'profissional';
      expect(pro.missing, isNot(contains('vínculo')));
    });

    test('passos e botão mudam com o vínculo e o estudante', () {
      final c = SignUpController()
        ..updateAffiliationKind(AffiliationKind.private);
      expect(c.firstStep, 'Seus dados');
      expect(c.firstStepButton, 'Criar minha conta');

      c.updateAffiliationKind(AffiliationKind.publicServant);
      expect(c.firstStep, 'Passo 1 de 2 · seus dados');
      expect(c.firstStepButton, 'Continuar para o vínculo');
      expect(c.affiliationStep, 'Passo 2 de 2');

      c.toggleStudent();
      expect(c.firstStep, 'Passo 1 de 3 · seus dados');
      expect(c.affiliationStep, 'Passo 2 de 3');
      expect(c.studentStep, 'Passo 3 de 3');
    });
  });

  group('tela Seu vínculo', () {
    late SignUpController c;

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      c = Get.put(SignUpController())
        ..updateAffiliationKind(AffiliationKind.publicServant);
      await tester.pumpWidget(
        GetMaterialApp(
          home: const AffiliationPage(),
          getPages: [
            GetPage(
              name: StudentProofPage.route,
              page: () => const StudentProofPage(),
            ),
          ],
        ),
      );
      await tester.pump();
    }

    Finder field(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)),
      matching: find.byType(TextFormField),
    );

    testWidgets('código válido preenche a organização e mostra o plano', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(
        field('Código de convite (opcional)').first,
        'pmfortaleza-7k2',
      );
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Código válido. Plano Lite liberado pelo convênio.'),
        findsOneWidget,
      );
      expect(find.text('Prefeitura de Fortaleza'), findsWidgets);
      expect(c.affiliation.organization?.id, 'pmfor');
      expect(c.affiliation.usesCode, isTrue);
    });

    testWidgets('código inválido avisa e não escolhe organização', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(
        field('Código de convite (opcional)').first,
        'ERRADO-1',
      );
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Código não encontrado. Confira com o RH ou escolha na lista '
          'abaixo.',
        ),
        findsOneWidget,
      );
      expect(c.affiliation.organization, isNull);
    });

    testWidgets('muitas tentativas pede para esperar', (tester) async {
      await open(tester);
      await tester.enterText(
        field('Código de convite (opcional)').first,
        'BLOQ-1',
      );
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Muitas tentativas. Tente de novo em alguns minutos.'),
        findsOneWidget,
      );
      expect(find.textContaining('Código não encontrado'), findsNothing);
      expect(c.affiliation.organization, isNull);
    });

    testWidgets('busca na lista, só do tipo certo, e escolhe', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField).at(1), 'cauc');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(repo.calls.last, 'search:prefeitura,camara,outro:cauc');
      expect(find.text('Prefeitura de Caucaia'), findsOneWidget);
      expect(find.text('Prefeitura de Fortaleza'), findsNothing);

      await tester.tap(find.text('Prefeitura de Caucaia'));
      await tester.pumpAndSettle();
      expect(c.affiliation.organization?.id, 'pmcau');
      expect(find.byTooltip('Trocar'), findsOneWidget);
    });

    testWidgets('"Não encontrei" vira sugestão e dá para voltar', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Não encontrei minha organização'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nome da prefeitura, câmara ou empresa'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Câmara de Maranguape',
      );
      expect(c.affiliation.suggesting, isTrue);
      expect(c.affiliation.suggestion, 'Câmara de Maranguape');

      await tester.tap(find.text('Voltar para a lista'));
      await tester.pumpAndSettle();
      expect(c.affiliation.suggesting, isFalse);
      expect(find.text('Não encontrei minha organização'), findsOneWidget);
    });

    testWidgets('"Preencher depois" limpa os detalhes e segue', (tester) async {
      await open(tester);
      c.toggleStudent();
      c.affiliation
        ..organization = _caucaia
        ..role = 'Agente';
      await tester.pump();
      await tester.tap(find.text('Preencher depois'));
      await tester.pumpAndSettle();

      expect(c.affiliation.kind, AffiliationKind.publicServant);
      expect(c.affiliation.organization, isNull);
      expect(c.affiliation.role, isEmpty);
      expect(Get.currentRoute, StudentProofPage.route);
    });
  });

  group('gravação', () {
    test('código válido usa o convite', () async {
      final d = AffiliationDraft()
        ..kind = AffiliationKind.publicServant
        ..code = 'PMFORTALEZA-7K2'
        ..role = 'Agente';
      d.applyCheck(await repo.validateInvite(d.code));
      final saved = await saveAffiliation(d);
      expect(repo.calls.last, 'redeem:PMFORTALEZA-7K2:Agente');
      expect(saved.outcome, 'convenio');
      expect(saved.planName, 'Lite');
    });

    test(
      'organização da lista, sugestão e particular gravam o vínculo',
      () async {
        final lista = await saveAffiliation(
          AffiliationDraft()
            ..kind = AffiliationKind.publicServant
            ..organization = _caucaia,
        );
        expect(lista.outcome, 'lista');
        expect(repo.saved!['organizationId'], 'pmcau');

        final analise = await saveAffiliation(
          AffiliationDraft()
            ..kind = AffiliationKind.partnerCompany
            ..suggesting = true
            ..suggestion = ' JAPEDIU ',
        );
        expect(analise.outcome, 'analise');
        expect(repo.saved!['suggestion'], ' JAPEDIU ');

        final particular = await saveAffiliation(
          AffiliationDraft()..kind = AffiliationKind.private,
        );
        expect(particular.outcome, isNull);
        expect(repo.saved!['kind'], AffiliationKind.private);
      },
    );
  });

  group('cartão Meu vínculo', () {
    Future<void> show(WidgetTester tester, MyAffiliation? a) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AffiliationCardView(
                affiliation: a,
                onEdit: () {},
                onResume: () {},
              ),
            ),
          ),
        );

    testWidgets('mostra cada situação', (tester) async {
      await show(tester, null);
      expect(find.text('Informar'), findsOneWidget);

      await show(
        tester,
        const MyAffiliation(
          kind: AffiliationKind.publicServant,
          organizationId: 'pmfor',
          organizationName: 'Prefeitura de Fortaleza',
          roleTitle: 'Agente administrativo',
          planName: 'Lite',
        ),
      );
      expect(find.text('Prefeitura de Fortaleza'), findsOneWidget);
      expect(
        find.text(
          'Servidor(a) público(a) · Agente administrativo. Plano Lite pelo '
          'convênio.',
        ),
        findsOneWidget,
      );

      await show(
        tester,
        const MyAffiliation(
          kind: AffiliationKind.publicServant,
          suggestedOrganization: 'Câmara de Maranguape',
          suggestionStatus: 'pendente',
        ),
      );
      expect(find.text('Organização em análise'), findsOneWidget);

      await show(tester, const MyAffiliation(kind: AffiliationKind.private));
      expect(find.text('Particular.'), findsOneWidget);

      for (final (reason, text) in [
        ('sem_uso', 'Você não teve consultas nos últimos 60 dias.'),
        ('faltas', 'Você faltou às duas últimas consultas.'),
      ]) {
        await show(
          tester,
          MyAffiliation(
            kind: AffiliationKind.publicServant,
            organizationId: 'pmfor',
            planPausedAt: DateTime(2026, 11, 1),
            planPauseReason: reason,
          ),
        );
        expect(find.text('Plano do convênio pausado'), findsOneWidget);
        expect(find.text(text), findsOneWidget);
        expect(find.text('Reativar plano'), findsOneWidget);
      }
    });
  });
}
