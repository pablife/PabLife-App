import 'package:flutter/material.dart';
import '../../shared/themes/app_colors.dart';

/// Widget de avatar personalizado que suporta imagens, SVG ou iniciais
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textColor = AppColors.white,
    this.fontSize,
  });

  /// URL da imagem (network)
  final String? imageUrl;

  /// Caminho do asset local
  final String? assetPath;

  /// Nome para exibir iniciais caso não tenha imagem
  final String? name;

  /// Raio do avatar
  final double radius;

  /// Cor de fundo do avatar
  final Color? backgroundColor;

  /// Cor do texto das iniciais
  final Color textColor;

  /// Tamanho da fonte das iniciais
  final double? fontSize;

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';

    final parts = name!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;

    // Gerar cor baseada no nome para consistência
    if (name != null && name!.isNotEmpty) {
      final hash = name!.hashCode;
      final hue = (hash % 360).toDouble();
      return HSLColor.fromAHSL(1.0, hue, 0.5, 0.4).toColor();
    }

    return AppColors.primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    // Se tiver URL de imagem
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _getBackgroundColor(),
        backgroundImage: NetworkImage(imageUrl!),
        onBackgroundImageError: (_, __) {
          // Fallback para iniciais em caso de erro
        },
        child: imageUrl!.isEmpty ? _buildInitials() : null,
      );
    }

    // Se tiver asset local
    if (assetPath != null && assetPath!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _getBackgroundColor(),
        backgroundImage: AssetImage(assetPath!),
      );
    }

    // Fallback para iniciais
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getBackgroundColor(),
      child: _buildInitials(),
    );
  }

  Widget _buildInitials() {
    return Text(
      _getInitials(),
      style: TextStyle(
        color: textColor,
        fontSize: fontSize ?? radius * 0.6,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
