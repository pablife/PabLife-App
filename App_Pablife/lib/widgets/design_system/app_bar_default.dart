import 'package:flutter/material.dart';
import '../app_text_vector.dart';
import 'outlined_icon_button.dart';
import 'text_default.dart';

class AppBarDefault extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? trailing;
  final String? title;

  const AppBarDefault({super.key, this.leading, this.trailing, this.title});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            leading ??
                (canPop
                    ? OutlinedIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      )
                    : const SizedBox(width: 66)),
            title != null
                ? TextDefault(
                    title!,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )
                : const AppTextVector(width: 148, height: 45),
            trailing ?? const SizedBox(width: 66),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(85);
}
