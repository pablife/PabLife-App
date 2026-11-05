import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../infra/repositories/calendar_feed_repository.dart';
import 'wide_agenda_views.dart';

/// Conecta o planner e a trilha de Saúde da mulher ao calendário do celular ou
/// do computador. A ligação é só de ida: o que muda no PabLife aparece lá.
class CalendarConnectDialog extends StatefulWidget {
  /// Nome da trilha ativa. Sem trilha, essa parte não aparece.
  final String? womenTrailTitle;
  final CalendarFeedRepository? repository;

  const CalendarConnectDialog({
    super.key,
    this.womenTrailTitle,
    this.repository,
  });

  static Future<void> show(BuildContext context, {String? womenTrailTitle}) {
    return showDialog<void>(
      context: context,
      builder: (_) => CalendarConnectDialog(womenTrailTitle: womenTrailTitle),
    );
  }

  @override
  State<CalendarConnectDialog> createState() => _CalendarConnectDialogState();
}

class _CalendarConnectDialogState extends State<CalendarConnectDialog> {
  late final CalendarFeedRepository _repository =
      widget.repository ?? CalendarFeedRepository();

  Map<String, Map<String, dynamic>> _feeds = {};

  /// Links recém-gerados. Depois de fechar, só gerando outro.
  final Map<String, String> _links = {};

  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final feeds = await _repository.getFeeds();
      if (!mounted) return;
      setState(() {
        _feeds = feeds;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar calendários: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar. Tente novamente.';
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      final feeds = await _repository.getFeeds();
      if (!mounted) return;
      setState(() => _feeds = feeds);
    } catch (e) {
      debugPrint('Erro ao atualizar calendário: $e');
      if (!mounted) return;
      setState(() => _error = 'Não foi possível concluir. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect(String kind) {
    return _run(() async {
      _links[kind] = await _repository.connect(kind);
    });
  }

  Future<void> _regenerate(String kind) async {
    final confirmed = await _confirm(
      title: 'Gerar novo link?',
      message:
          'O link atual para de funcionar. Depois, será preciso assinar o '
          'calendário de novo.',
      action: 'Gerar novo link',
    );
    if (confirmed) await _connect(kind);
  }

  Future<void> _disconnect(String kind, String id) async {
    final confirmed = await _confirm(
      title: 'Desconectar?',
      message:
          'O link para de funcionar e o calendário deixa de atualizar. Para '
          'tirá-lo da tela, apague também a assinatura no seu calendário.',
      action: 'Desconectar',
    );
    if (!confirmed) return;
    await _run(() async {
      await _repository.disconnect(id);
      _links.remove(kind);
    });
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// `webcal` abre direto a pergunta "Assinar" no Calendário da Apple.
  Future<void> _addToCalendar(String link) async {
    final uri = Uri.parse(link.replaceFirst(RegExp('^https'), 'webcal'));
    final opened = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );
    if (!opened && mounted) {
      setState(() => _error = 'Copie o link e cole no seu calendário.');
    }
  }

  Future<void> _copy(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Link copiado')));
  }

  Widget _section({
    required String kind,
    required String title,
    required String description,
    required List<Widget> Function(Map<String, dynamic> feed) options,
  }) {
    final feed = _feeds[kind];
    final link = _links[kind];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: WideAgendaColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: WideAgendaColors.text,
          ),
        ),
        const SizedBox(height: 8),
        if (feed == null)
          FilledButton(
            onPressed: _busy ? null : () => _connect(kind),
            style: FilledButton.styleFrom(
              backgroundColor: WideAgendaColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Conectar'),
          )
        else ...[
          Text(
            _status(feed),
            style: const TextStyle(fontSize: 12, color: WideAgendaColors.text),
          ),
          ...options(feed),
          const SizedBox(height: 8),
          if (link != null) ...[
            FilledButton.icon(
              onPressed: () => _addToCalendar(link),
              style: FilledButton.styleFrom(
                backgroundColor: WideAgendaColors.accent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.event_available, size: 18),
              label: const Text('Adicionar ao calendário'),
            ),
            TextButton.icon(
              onPressed: () => _copy(link),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar link'),
            ),
            const Text(
              'Este link é pessoal e só aparece agora: quem tiver acesso a '
              'ele vê este calendário.',
              style: TextStyle(fontSize: 12, color: WideAgendaColors.text),
            ),
          ] else
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _regenerate(kind),
                  child: const Text('Gerar novo link'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _disconnect(kind, feed['id'] as String),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Desconectar'),
                ),
              ],
            ),
        ],
      ],
    );
  }

  String _status(Map<String, dynamic> feed) {
    final fetched = feed['last_fetched_at'] as String?;
    if (fetched == null) return 'Conectado. Aguardando a primeira atualização.';
    final local = DateTime.parse(fetched).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'Conectado. Última atualização em ${two(local.day)}/'
        '${two(local.month)} às ${two(local.hour)}:${two(local.minute)}.';
  }

  Widget _option(Map<String, dynamic> feed, String column, String label) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeTrackColor: WideAgendaColors.accent,
      title: Text(label, style: const TextStyle(color: WideAgendaColors.text)),
      value: feed[column] as bool? ?? false,
      onChanged: _busy
          ? null
          : (value) => _run(
              () => _repository.setOption(feed['id'] as String, column, value),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final womenTrail = widget.womenTrailTitle;

    return AlertDialog(
      scrollable: true,
      backgroundColor: WideAgendaColors.panel,
      title: const Text(
        'Conectar ao calendário',
        style: TextStyle(color: WideAgendaColors.text),
      ),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Veja o PabLife no Calendário da Apple, Google ou Outlook. '
                    'Você continua criando e editando aqui, e o calendário '
                    'atualiza sozinho de tempos em tempos.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: WideAgendaColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    kind: CalendarFeedKind.planner,
                    title: 'Planner',
                    description: 'Tarefas, metas e consultas.',
                    options: (feed) => [
                      _option(feed, 'include_tasks', 'Tarefas'),
                      _option(feed, 'include_goals', 'Metas'),
                      _option(feed, 'include_appointments', 'Consultas'),
                    ],
                  ),
                  if (womenTrail != null) ...[
                    const Divider(height: 32),
                    _section(
                      kind: CalendarFeedKind.womenHealth,
                      title: womenTrail,
                      description:
                          'Opcional e em um calendário separado. Esses dados '
                          'são íntimos: ao conectar, eles ficam visíveis no '
                          'seu calendário e para quem você o compartilha. '
                          'As datas são estimativas e não servem como método '
                          'contraceptivo.',
                      options: (feed) => [
                        _option(
                          feed,
                          'discreet_titles',
                          'Usar nomes discretos',
                        ),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
