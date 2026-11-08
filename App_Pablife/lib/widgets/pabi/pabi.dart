import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Humores da Pabi, a personagem do "Como estou hoje".
enum PabiMood {
  feliz('feliz'),
  tranquila('tranquila'),
  cansada('cansada'),
  triste('triste'),
  ansiosa('ansiosa'),
  irritada('irritada'),
  colica('com cólica'),
  sensivel('sensível');

  final String label;
  const PabiMood(this.label);

  /// Humor da Pabi para o registro do dia (opções do app).
  static PabiMood fromCheckIn(String? checkIn) => switch (checkIn) {
    'Feliz' || 'Energética' => PabiMood.feliz,
    'Com cólica' => PabiMood.colica,
    'Sensível' => PabiMood.sensivel,
    'Cansada' || 'Sono ruim' => PabiMood.cansada,
    'Triste' || 'Desanimada' => PabiMood.triste,
    'Ansiosa' || 'Confusa' => PabiMood.ansiosa,
    'Raiva' || 'Irritada' || 'Calorão' => PabiMood.irritada,
    _ => PabiMood.tranquila,
  };
}

/// A Pabi: sementinha com folha, desenhada em vetor. No visual Saúde da
/// Mulher ([women]) ganha rosa e lilás.
class Pabi extends StatelessWidget {
  final PabiMood mood;
  final bool women;
  final double size;

  const Pabi({
    super.key,
    this.mood = PabiMood.tranquila,
    this.women = false,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Pabi ${mood.label}',
      child: SvgPicture.string(
        pabiSvg(mood: mood, women: women),
        width: size,
        height: size,
      ),
    );
  }
}

/// SVG da Pabi (mesmo desenho do canvas "Personagem").
String pabiSvg({required PabiMood mood, required bool women}) {
  const none = 'M0 0';
  final bodies = women
      ? {
          PabiMood.feliz: '#FF8ECF',
          PabiMood.tranquila: '#FFC2E6',
          PabiMood.cansada: '#D5C3DC',
          PabiMood.triste: '#B3AEEA',
          PabiMood.ansiosa: '#B9B3FF',
          PabiMood.irritada: '#FF9C7A',
          PabiMood.colica: '#F7A1C4',
          PabiMood.sensivel: '#E7B8F2',
        }
      : {
          PabiMood.feliz: '#13B8B2',
          PabiMood.tranquila: '#7FD6D2',
          PabiMood.cansada: '#A9C4C5',
          PabiMood.triste: '#9FB4D6',
          PabiMood.ansiosa: '#B9B3FF',
          PabiMood.irritada: '#FF9C7A',
          PabiMood.colica: '#F7A1C4',
          PabiMood.sensivel: '#E7B8F2',
        };
  final eyes = {
    PabiMood.feliz: ['M66 118 Q78 104 90 118', 'M110 118 Q122 104 134 118'],
    PabiMood.tranquila: ['M68 112 Q78 122 88 112', 'M112 112 Q122 122 132 112'],
    PabiMood.cansada: ['M68 116 L88 116', 'M112 116 L132 116'],
    PabiMood.colica: ['M70 106 L86 114 L70 122', 'M130 106 L114 114 L130 122'],
  };
  final dots = {
    PabiMood.triste: 7,
    PabiMood.ansiosa: 6,
    PabiMood.irritada: 6,
    PabiMood.sensivel: 8,
  };
  final brows = {
    PabiMood.triste: 'M64 102 L88 94 M136 102 L112 94',
    PabiMood.ansiosa: 'M66 96 Q78 88 90 96 M110 96 Q122 88 134 96',
    PabiMood.irritada: 'M64 96 L88 104 M136 96 L112 104',
    PabiMood.cansada: 'M66 104 L90 106 M110 106 L134 104',
  };
  final mouths = {
    PabiMood.feliz: 'M80 142 Q100 168 120 142 Z',
    PabiMood.tranquila: 'M86 146 Q100 156 114 146',
    PabiMood.cansada: 'M88 152 Q100 148 112 152',
    PabiMood.triste: 'M84 158 Q100 142 116 158',
    PabiMood.ansiosa:
        'M82 152 Q88 146 94 152 Q100 158 106 152 Q112 146 118 152',
    PabiMood.irritada: 'M84 156 Q100 146 116 156',
    PabiMood.colica: 'M86 156 Q100 148 114 156',
    PabiMood.sensivel: 'M90 150 Q100 156 110 150',
  };

  final ink = women ? '#3A1D4F' : '#052F33';
  final leaf = women ? '#A8336F' : '#0E7C78';
  final eye = eyes[mood] ?? [none, none];
  final dot = dots[mood] ?? 0;
  final shine = dot > 0 ? 2.5 : 0;
  int on(List<PabiMood> moods) => moods.contains(mood) ? 1 : 0;
  final blush = on([
    PabiMood.feliz,
    PabiMood.tranquila,
    PabiMood.sensivel,
    PabiMood.irritada,
    PabiMood.colica,
  ]);
  final blushColor = mood == PabiMood.irritada ? '#E2554F' : '#FF6FAE';
  final mouthFill = mood == PabiMood.feliz ? ink : 'none';

  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
<ellipse cx="100" cy="192" rx="52" ry="6" fill="#000000" fill-opacity="0.08"/>
<path d="M100 46 Q100 32 110 26" stroke="$ink" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M110 26 Q124 18 128 30 Q116 36 110 26 Z" fill="$leaf"/>
<path d="M100 44 C142 44 168 80 168 118 C168 156 140 184 100 184 C60 184 32 156 32 118 C32 80 58 44 100 44 Z" fill="${bodies[mood]}"/>
<g opacity="${on([PabiMood.triste])}">
<circle cx="78" cy="30" r="13" fill="#C9D3DD"/>
<circle cx="98" cy="22" r="17" fill="#C9D3DD"/>
<circle cx="120" cy="30" r="13" fill="#C9D3DD"/>
<rect x="66" y="28" width="66" height="15" rx="7" fill="#C9D3DD"/>
</g>
<g opacity="${on([PabiMood.feliz])}" fill="#FFC94D">
<path d="M164 42 L168 54 L180 58 L168 62 L164 74 L160 62 L148 58 L160 54 Z"/>
<path d="M36 56 L38.5 63 L46 65.5 L38.5 68 L36 75 L33.5 68 L26 65.5 L33.5 63 Z"/>
</g>
<g opacity="${on([PabiMood.ansiosa])}" stroke="$ink" stroke-width="4" stroke-linecap="round">
<path d="M22 96 L12 90 M20 114 L8 114 M22 132 L12 138 M178 96 L188 90 M180 114 L192 114 M178 132 L188 138"/>
</g>
<path opacity="${on([PabiMood.irritada])}" d="M148 52 Q154 58 160 52 M148 64 Q154 58 160 64" stroke="#E2554F" stroke-width="4" fill="none" stroke-linecap="round"/>
<g opacity="${on([PabiMood.cansada])}" stroke="$ink" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round">
<path d="M146 44 L156 44 L146 56 L156 56"/>
<path d="M162 34 L170 34 L162 44 L170 44"/>
</g>
<path opacity="${on([PabiMood.sensivel])}" d="M156 52 C156 45 165 43 167 50 C169 43 178 45 178 52 C178 61 167 68 167 68 C167 68 156 61 156 52 Z" fill="#FF6FAE"/>
<circle cx="64" cy="134" r="10" fill="$blushColor" opacity="$blush"/>
<circle cx="136" cy="134" r="10" fill="$blushColor" opacity="$blush"/>
<path d="${brows[mood] ?? none}" stroke="$ink" stroke-width="5" fill="none" stroke-linecap="round"/>
<path d="${eye[0]}" stroke="$ink" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<path d="${eye[1]}" stroke="$ink" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="78" cy="114" r="$dot" fill="$ink"/>
<circle cx="122" cy="114" r="$dot" fill="$ink"/>
<circle cx="81" cy="111" r="$shine" fill="#FFFFFF"/>
<circle cx="125" cy="111" r="$shine" fill="#FFFFFF"/>
<ellipse opacity="${on([PabiMood.triste, PabiMood.sensivel])}" cx="130" cy="132" rx="4.5" ry="7" fill="#6FC3F0"/>
<path d="${mouths[mood]}" stroke="$ink" stroke-width="5" fill="$mouthFill" stroke-linecap="round" stroke-linejoin="round"/>
<g opacity="${on([PabiMood.cansada])}">
<path d="M158 146 q4 -6 0 -12 M166 146 q4 -6 0 -12" stroke="$ink" stroke-width="2.5" fill="none" stroke-linecap="round"/>
<rect x="150" y="150" width="24" height="26" rx="5" fill="#FFFFFF" stroke="$ink" stroke-width="3"/>
<path d="M174 156 q9 0 9 8 q0 8 -9 8" stroke="$ink" stroke-width="3" fill="none"/>
</g>
<g opacity="${on([PabiMood.colica])}">
<rect x="93" y="152" width="14" height="9" rx="3" fill="$ink"/>
<rect x="76" y="158" width="48" height="32" rx="12" fill="#FF6FAE" stroke="$ink" stroke-width="3"/>
<path d="M86 170 L114 170 M86 178 L114 178" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round"/>
</g>
</svg>''';
}
