import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../design_system/edge_button_rounded.dart';
import '../design_system/text_default.dart';
import '../../modules/profile/pages/subscription_page.dart';

class PremiumLockDialog extends StatelessWidget {
  final String message;
  final String? contentType;
  final String? contentTitle;

  const PremiumLockDialog({
    super.key,
    required this.message,
    this.contentType,
    this.contentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        width: 362,
        height: 474,
        decoration: BoxDecoration(
          color: const Color(0xFFC1CDFF),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            // Illustration
            Positioned(
              left: 22, // 37 - 15
              top: 16, // 201 - 185
              child: SizedBox(
                width: 143,
                height: 173,
                child: Image.asset(
                  'assets/pages/premium/premium_required.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Text Content Group
            Positioned(
              left: 175, // 190 - 15
              top: 78, // 263 - 185
              right: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (contentType != null)
                    TextDefault(
                      contentType!,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF00343C),
                      height: 17 / 14,
                    ),
                  if (contentType != null) const SizedBox(height: 4),
                  if (contentTitle != null)
                    TextDefault(
                      contentTitle!,
                      fontWeight: FontWeight.w400,
                      fontSize: 24,
                      color: const Color(0xFF00343C),
                      height: 29 / 24,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (contentTitle != null) const SizedBox(height: 4),
                  const TextDefault(
                    'Conteúdo Bloqueado',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF00343C),
                    height: 20 / 16,
                  ),
                ],
              ),
            ),

            // Description Title
            Positioned(
              top: 204, // 389 - 185
              left: 0,
              right: 0,
              child: const Center(
                child: SizedBox(
                  width: 302,
                  child: TextDefault(
                    'Faça o upgrade e aproveite todos os recursos sem limitações.',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF000000),
                    height: 20 / 16,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Description Message
            Positioned(
              top: 257, // 442 - 185
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 326,
                  child: TextDefault(
                    message,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: const Color(0xFF000000),
                    height: 17 / 14,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                  ),
                ),
              ),
            ),

            // Buttons
            Positioned(
              top: 373, // 558 - 185
              left: 0,
              right: 0,
              child: SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    // Voltar Button (Left)
                    Positioned(
                      left: 0, // 15 - 15
                      child: EdgeButtonRounded(
                        text: 'Voltar',
                        width: 120,
                        backgroundColor: const Color(0xFF082C32),
                        textColor: Colors.white,
                        side: EdgeSide.right,
                        // The design has radius 30px 0px 0px 30px (Left rounded)
                        // But it is on the left side of the screen.
                        // EdgeButtonRounded side=left means rounded on left.
                        // Let's check the implementation of EdgeButtonRounded.
                        // side == EdgeSide.left ? Radius.circular(100) : inverseRadius...
                        // So yes, side=left means left corners are rounded.
                        onTap: () => Get.back(),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Premium Button (Right)
                    Positioned(
                      right: 0, // Calculated from width
                      // In CSS: left 145px (relative to 362px container?)
                      // 145 - 15 = 130px relative left.
                      // Width 232px.
                      // 130 + 232 = 362px.
                      // So it touches the right edge.
                      child: EdgeButtonRounded(
                        text: 'Quero ser Premium',
                        width: 200,
                        backgroundColor: const Color(0xFF0C8DA1),
                        textColor: Colors.white,
                        side: EdgeSide
                            .left, // CSS: radius 30px 0px 0px 30px (Left rounded)
                        // Wait, if it's on the right, usually we round the left side to "attach" it?
                        // Or round the right side?
                        // CSS: border-radius: 30px 0px 0px 30px; -> TopLeft, TopRight, BottomRight, BottomLeft?
                        // No, standard is TL, TR, BR, BL.
                        // 30px (TL), 0px (TR), 0px (BR), 30px (BL).
                        // So it is rounded on the LEFT.
                        // So side = EdgeSide.left is correct.
                        onTap: () {
                          Get.back();
                          Get.toNamed(SubscriptionPage.route);
                        },
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
