import 'package:get/get.dart';
import '../../../shared/mixins/loader_manager.dart';

class GoalSuggestionsController extends GetxController with LoaderManagerMixin {
  List<Map<String, dynamic>> suggestions = [];

  @override
  void onInit() {
    super.onInit();
    loadSuggestions();
  }

  void loadSuggestions() {
    changeLoading(true);

    suggestions = [
      {
        'title': 'Fundo de Emergência',
        'category': 'Financeira',
        'description':
            'Criar um fundo de emergência equivalente a 6 meses do que você ganha, garantindo segurança financeira e estabilidade em imprevistos.',
        'duration': '6 meses',
        'priority': 'high',
        'color': 0xFFCDDC39,
        'steps': [
          'Calcular seus gastos mensais reais',
          'Definir o total da reserva (6x seus gastos)',
          'Abrir ou separar uma conta específica para esse fundo',
          'Determinar quanto poderá guardar por mês',
          'Ajustar gastos para liberar mais poupança',
          'Programar transferência automática',
          'Conferir mensalmente o avanço',
        ],
      },
      {
        'title': 'Poupar para Viagem',
        'category': 'Financeira',
        'description':
            'Guardar dinheiro para realizar uma viagem dos sonhos com tranquilidade e sem dívidas.',
        'duration': '12 meses',
        'priority': 'high',
        'color': 0xFF92CA4F,
        'steps': [
          'Escolher destino e duração',
          'Estimar gastos (passagem, hospedagem, alimentação, passeios)',
          'Calcular o valor total necessário',
          'Dividir o total pelos meses disponíveis',
          'Criar um cofrinho digital ou conta separada',
          'Anotar mensalmente quanto conseguiu guardar',
          'Pesquisar promoções durante o processo',
        ],
      },
      {
        'title': 'Perder Peso',
        'category': 'Saúde',
        'description':
            'Emagrecer de forma saudável, melhorando a qualidade de vida, disposição e autoestima.',
        'duration': '6 meses',
        'priority': 'high',
        'color': 0xFFFF9999,
        'steps': [
          'Avaliação com nutricionista',
          'Definir meta de kg ou % de gordura a perder',
          'Criar cardápio ajustado',
          'Estabelecer rotina de exercícios',
          'Aumentar ingestão de água',
          'Registrar evolução semanal',
          'Ajustar o plano conforme necessidade',
        ],
      },
      {
        'title': 'Aprender Inglês',
        'category': 'Educação',
        'description':
            'Dominar o inglês para ampliar oportunidades profissionais e pessoais.',
        'duration': '12 meses',
        'priority': 'medium',
        'color': 0xFF00C2A8,
        'steps': [
          'Definir nível atual (iniciante/intermediário)',
          'Escolher plataforma ou curso',
          'Estabelecer rotina fixa de estudo',
          'Assistir 1 conteúdo por dia em inglês',
          'Praticar conversação semanalmente',
          'Construir lista de vocabulário',
          'Fazer simulado mensal para medir evolução',
        ],
      },
      {
        'title': 'Quitar Dívidas',
        'category': 'Financeira',
        'description':
            'Sair do ciclo de dívidas, organizando finanças e eliminando juros desnecessários.',
        'duration': '8 meses',
        'priority': 'high',
        'color': 0xFFE57373,
        'steps': [
          'Levantar todas as dívidas e juros',
          'Classificar por urgência',
          'Negociar com credores',
          'Montar calendário de pagamentos',
          'Cortar gastos não essenciais',
          'Acompanhar semanalmente o progresso',
          'Reinvestir o valor quitado em reserva',
        ],
      },
      {
        'title': 'Investir Primeiros R\$ 1.000',
        'category': 'Financeira',
        'description':
            'Construir hábito de investir e criar o primeiro patrimônio.',
        'duration': '4 meses',
        'priority': 'medium',
        'color': 0xFF64B5F6,
        'steps': [
          'Escolher corretora',
          'Criar conta e validar dados',
          'Aprender sobre renda fixa',
          'Programar aporte mensal',
          'Automatizar transferências',
          'Acompanhar rendimento',
          'Revisar carteira mensalmente',
        ],
      },
      {
        'title': 'Criar Rotina de Sono',
        'category': 'Saúde',
        'description':
            'Regular o sono para melhorar energia, foco e bem-estar.',
        'duration': '3 meses',
        'priority': 'high',
        'color': 0xFF9575CD,
        'steps': [
          'Estabelecer hora de dormir e acordar',
          'Criar rotina de relaxamento',
          'Evitar telas antes de dormir',
          'Ajustar temperatura/luz do quarto',
          'Registrar horas de sono',
          'Acompanhar qualidade',
          'Ajustar hábitos semanalmente',
        ],
      },
      {
        'title': 'Criar Rotina de Exercícios',
        'category': 'Saúde',
        'description': 'Aumentar disposição e saúde com exercícios regulares.',
        'duration': '3 meses',
        'priority': 'high',
        'color': 0xFF4DB6AC,
        'steps': [
          'Definir dias fixos',
          'Escolher treino (academia/casa)',
          'Fazer treino leve na primeira semana',
          'Aumentar intensidade',
          'Registrar treinos',
          'Acompanhar medidas',
          'Ajustar semanalmente',
        ],
      },
      {
        'title': 'Ler 12 Livros por Ano',
        'category': 'Educação',
        'description':
            'Criar hábito de leitura contínua para crescer profissionalmente e mentalmente.',
        'duration': '12 meses',
        'priority': 'medium',
        'color': 0xFFFFB74D,
        'steps': [
          'Escolher lista de 12 livros',
          'Ler 15 minutos por dia',
          'Registrar páginas lidas',
          'Finalizar 1 livro por mês',
          'Fazer resumo após leitura',
          'Aplicar aprendizados',
          'Avaliar evolução trimestral',
        ],
      },
      {
        'title': 'Reduzir Uso de Celular',
        'category': 'Produtividade',
        'description': 'Diminuir distrações e aumentar foco no dia a dia.',
        'duration': '1 mês',
        'priority': 'high',
        'color': 0xFF90A4AE,
        'steps': [
          'Ver tempo de uso atual',
          'Definir limite diário',
          'Desinstalar apps desnecessários',
          'Colocar celular longe de manhã',
          'Criar horários fixos de uso',
          'Ativar tempo de tela',
          'Revisar progresso semanalmente',
        ],
      },
    ];

    changeLoading(false);
    update();
  }

  void selectSuggestion(Map<String, dynamic> suggestion) {
    Get.back(result: suggestion);
  }

  void goBack() {
    Get.back();
  }
}
