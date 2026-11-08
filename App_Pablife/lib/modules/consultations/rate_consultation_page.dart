import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../infra/models/professional_appointment_model.dart';
import '../../infra/repositories/consultation_repository.dart';
import '../../shared/themes/pab_colors.dart';
import '../../shared/utils/app_snackbar.dart';
import '../auth/pages/widgets/registration_layout.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_page.dart';
import 'consultation_info.dart';

/// "Como foi sua consulta?" (canvas Q5): nota de 1 a 5 com carinhas, o que se
/// destacou e um comentário que só a equipe vê. Devolve true se enviou.
class RateConsultationPage extends StatefulWidget {
  final ProfessionalAppointmentModel appointment;

  const RateConsultationPage({super.key, required this.appointment});

  static Future<bool> open(ProfessionalAppointmentModel appointment) async {
    final sent = await Get.to<bool>(
      () => RateConsultationPage(appointment: appointment),
    );
    return sent ?? false;
  }

  @override
  State<RateConsultationPage> createState() => _RateConsultationPageState();
}

const _faceColors = ['B9B3FF', '8FD3F4', 'F5E94C', 'C6F45A', 'FF8ECF'];
const _mouths = [
  'M14 31 Q22 23 30 31',
  'M15 29 Q22 26 29 29',
  'M15 28 L29 28',
  'M14 26 Q22 32 30 26',
  'M13 25 Q22 35 31 25 Z',
];
const _labels = ['Muito ruim', 'Ruim', 'Ok', 'Boa', 'Excelente'];
const _highlights = [
  'Acolhimento',
  'Pontualidade',
  'Clareza',
  'Qualidade do vídeo',
];

/// Carinha do canvas (SVG): cor e boca de cada nota.
String _faceSvg(int index) {
  final mouthFill = index == 4 ? '#052F33' : 'none';
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">'
      '<circle cx="22" cy="22" r="20" fill="#${_faceColors[index]}" '
      'stroke="#052F33" stroke-width="2"/>'
      '<circle cx="16" cy="18" r="2.4" fill="#052F33"/>'
      '<circle cx="28" cy="18" r="2.4" fill="#052F33"/>'
      '<path d="${_mouths[index]}" stroke="#052F33" stroke-width="2.4" '
      'fill="$mouthFill" stroke-linecap="round"/></svg>';
}

class _RateConsultationPageState extends State<RateConsultationPage> {
  int _score = 0;
  final Set<String> _picked = {};
  final _comment = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_score == 0) {
      setState(() => _error = 'Toque numa carinha para dar sua nota.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await ConsultationRepository().submitRating(
      appointmentId: widget.appointment.id,
      professionalId: widget.appointment.professionalId,
      score: _score,
      highlights: _picked.toList(),
      comment: _comment.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    AppSnackbar.to.show('Obrigado pela avaliação!');
    Get.back(result: true);
  }

  void _bookAgain() {
    Get.offAllNamed(DashboardPage.route);
    if (Get.isRegistered<DashboardController>()) {
      DashboardController.to.changeTab(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final big = _score == 0 ? 3 : _score - 1;

    return RegistrationLayout(
      title: 'Avaliar consulta',
      onBack: () => Get.back(result: false),
      fields: [
        Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: SvgPicture.string(
                _faceSvg(big),
                key: ValueKey(big),
                width: 128,
                height: 128,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Como foi sua consulta?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Com ${a.professionalName} · ${a.shortWhen}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: PabColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 5; i++)
                  Semantics(
                    button: true,
                    selected: _score == i + 1,
                    label: '${i + 1} de 5, ${_labels[i].toLowerCase()}',
                    excludeSemantics: true,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        _score = i + 1;
                        _error = null;
                      }),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: _score == i + 1 ? 1.22 : 1,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _score == 0 || _score == i + 1 ? 1 : .5,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: SvgPicture.string(
                              _faceSvg(i),
                              width: 48,
                              height: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _score == 0 ? 'Toque numa carinha' : _labels[_score - 1],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: PabColors.accentText,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O que se destacou?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in _highlights)
                  FilterChip(
                    label: Text(h),
                    selected: _picked.contains(h),
                    showCheckmark: false,
                    onSelected: (on) => setState(() {
                      if (on) {
                        _picked.add(h);
                      } else {
                        _picked.remove(h);
                      }
                    }),
                    selectedColor: PabColors.ink,
                    backgroundColor: PabColors.card,
                    side: BorderSide(
                      color: _picked.contains(h)
                          ? PabColors.ink
                          : PabColors.line,
                    ),
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _picked.contains(h) ? Colors.white : PabColors.ink,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quer deixar um comentário?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: PabColors.ink,
              ),
            ),
            const Text(
              'Só a equipe Pablife vê.',
              style: TextStyle(fontSize: 12, color: PabColors.muted),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _comment,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Opcional',
                filled: true,
                fillColor: PabColors.card,
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: PabColors.lineStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: PabColors.accent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
      footer: [
        RegPrimaryButton(
          label: 'Enviar avaliação',
          loading: _sending,
          onTap: _send,
        ),
        const SizedBox(height: 4),
        RegTextButton(label: 'Agendar retorno', onTap: _bookAgain),
        if (_error != null) RegError(_error!),
      ],
    );
  }
}
