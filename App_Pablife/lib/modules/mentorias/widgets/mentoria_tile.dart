import 'package:flutter/material.dart';

import '../../../infra/models/mentoria_model.dart';
import '../../../shared/themes/pab_colors.dart';
import '../../../widgets/design_system/app_image.dart';

/// Cartão da mentoria (canvas "Mentorias — mobile"): foto com o botão de
/// salvar, duração e autor, título, descrição e "Começar".
class MentoriaTile extends StatelessWidget {
  final MentoriaModel mentoria;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  const MentoriaTile({
    super.key,
    required this.mentoria,
    required this.onTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final saved = mentoria.isSaved;
    final locked = mentoria.isLocked;
    final placeholder = Container(
      color: PabColors.lilac,
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_outlined,
        size: 40,
        color: PabColors.lilacText,
      ),
    );

    Widget tag(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );

    return Material(
      color: PabColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: PabColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    imageUrl: mentoria.bannerUrl,
                    fit: BoxFit.cover,
                    errorWidget: placeholder,
                  ),
                  if (locked)
                    Container(
                      color: PabColors.ink.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock_outline,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Tooltip(
                      message: saved ? 'Remover dos salvos' : 'Salvar mentoria',
                      child: Material(
                        color: saved ? PabColors.ink : PabColors.card,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: onBookmarkTap,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              saved ? Icons.bookmark : Icons.bookmark_outline,
                              size: 20,
                              color: saved ? PabColors.accent : PabColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (mentoria.durationMinutes > 0)
                        tag(
                          mentoria.durationLabel,
                          PabColors.soft,
                          PabColors.softText,
                        ),
                      if (mentoria.author.trim().isNotEmpty)
                        tag(
                          'Com ${mentoria.author.trim()}',
                          PabColors.lilac,
                          PabColors.lilacText,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mentoria.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: PabColors.ink,
                    ),
                  ),
                  if (mentoria.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      mentoria.description.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: PabColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onTap,
                    icon: Icon(
                      locked ? Icons.lock_outline : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      locked ? 'Desbloquear' : 'Começar',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: PabColors.accent,
                      foregroundColor: PabColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
