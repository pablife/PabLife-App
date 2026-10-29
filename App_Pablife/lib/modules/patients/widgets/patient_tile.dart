import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../infra/models/professional_appointment_model.dart';
import '../../../widgets/design_system/app_image.dart';
import '../../../widgets/design_system/text_default.dart';

class PatientTile extends StatelessWidget {
  final ProfessionalAppointmentModel patient;
  final VoidCallback? onMarkAsCompleted;
  final VoidCallback? onCancelAppointment;
  final int? pageIndex;
  final int? currentPageIndex;
  final int? totalPages;
  final bool filledHour;
  final Color? customBackgroundColor;
  final Color? customButtonColor;
  final Color? customTextColor;
  final Color? customTimeColor;
  final IconData? customTrailingIcon;
  final Color? customTrailingIconColor;
  final VoidCallback? onTrailingTap;
  final VoidCallback? onTap;
  final bool showStatusIndicator;
  final bool forceShowTrailing;
  final bool isProfessional;

  const PatientTile({
    super.key,
    required this.patient,
    this.onMarkAsCompleted,
    this.onCancelAppointment,
    this.pageIndex,
    this.currentPageIndex,
    this.totalPages,
    this.filledHour = false,
    this.customBackgroundColor,
    this.customButtonColor,
    this.customTextColor,
    this.customTimeColor,
    this.customTrailingIcon,
    this.customTrailingIconColor,
    this.onTrailingTap,
    this.onTap,
    this.showStatusIndicator = false,
    this.forceShowTrailing = false,
    this.isProfessional = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNow = patient.isOngoing;
    final isCompleted = patient.isCompleted;
    final now = DateTime.now();
    final appointmentDateTime = patient.startAt;
    final canCancel =
        appointmentDateTime.isAfter(now) &&
        appointmentDateTime.difference(now).inHours >= 24;

    final isCancelled = patient.status == AppointmentStatus.cancelled;
    final isNoShow = patient.status == AppointmentStatus.noShow;
    final isLateStatus = patient.isLate;
    final isInProgress =
        patient.status != AppointmentStatus.noShow &&
        patient.status != AppointmentStatus.cancelled &&
        patient.startedAt != null;

    Color statusBgColor;
    if (isCancelled) {
      statusBgColor = Color(0xffda879a);
    } else if (isNoShow || isLateStatus) {
      statusBgColor = Color(0xffd3cab5);
    } else if (isCompleted || isInProgress) {
      statusBgColor = Color(0xffafcddb);
    } else {
      statusBgColor = const Color(0xFF95B0FF);
    }

    final bgColor =
        customBackgroundColor ??
        (showStatusIndicator
            ? statusBgColor
            : (isCompleted
                  ? const Color(0xFF9BD3CC)
                  : (isNow
                        ? const Color(0xFF9BD3CC)
                        : const Color(0xFF95B0FF))));

    final buttonColor =
        customButtonColor ??
        (isCompleted
            ? const Color(0xFF00C2A8)
            : (isNow ? const Color(0xFF00C2A8) : const Color(0xFF3065FF)));

    final trailingIcon =
        customTrailingIcon ??
        (isCompleted ? Icons.arrow_forward : Icons.calendar_month);
    final trailingIconColor = customTrailingIconColor ?? Colors.white;
    final showTrailingBase =
        customTrailingIcon != null || onTrailingTap != null || onTap != null;
    final showTrailingButton =
        (forceShowTrailing && showTrailingBase) ||
        (!forceShowTrailing && canCancel && showTrailingBase);

    final textColor = customTextColor ?? const Color(0xFF00343C);
    final timeColor =
        customTimeColor ?? (filledHour ? Colors.white : buttonColor);

    final showSwipeActions =
        onMarkAsCompleted != null || (onCancelAppointment != null && canCancel);
    final showPageIndicators =
        pageIndex != null && currentPageIndex != null && totalPages != null;

    String? statusLabel;
    IconData? statusIcon;
    if (showStatusIndicator) {
      if (isCompleted) {
        statusLabel = 'Concluída';
        statusIcon = Icons.check_circle_outline;
      } else if (isCancelled) {
        statusLabel = 'Cancelada';
        statusIcon = Icons.cancel_outlined;
      } else if (isNoShow) {
        statusLabel = 'Não compareceu';
        statusIcon = Icons.person_off_outlined;
      } else if (isLateStatus) {
        statusLabel = 'Atrasada';
        statusIcon = Symbols.warning;
      } else if (isInProgress) {
        statusLabel = 'Em andamento';
        statusIcon = Icons.play_circle_outline;
      }
    }

    Widget tileContent = Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (statusLabel != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusIcon != null) ...[
                  Icon(statusIcon, size: 18, color: const Color(0xFF00343C)),
                  const SizedBox(width: 6),
                ],
                TextDefault(
                  statusLabel,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00343C),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              ClipOval(
                child: AppImage(
                  imageUrl: isProfessional
                      ? patient.patientImageUrl
                      : patient.professionalData?['user']?['image_url'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFF00343C).withAlpha(51),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: const Color(0xFF00343C).withAlpha(128),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 17),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextDefault(
                      isProfessional
                          ? patient.professionalType != null
                                ? (patient.professionalType == 'psychologist'
                                      ? 'Psicólogo'
                                      : patient.professionalType ==
                                            'nutritionist'
                                      ? 'Nutricionista'
                                      : 'Profissional')
                                : 'Paciente'
                          : (patient.professionalData?['type'] == 'psychologist'
                                ? 'Psicólogo'
                                : patient.professionalData?['type'] ==
                                      'nutritionist'
                                ? 'Nutricionista'
                                : 'Profissional'),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    TextDefault(
                      isProfessional
                          ? patient.patientName
                          : patient.professionalData?['user']?['full_name'] ??
                                '',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    filledHour
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: buttonColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextDefault(
                              isCompleted ? 'Realizada' : patient.formattedTime,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: timeColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : TextDefault(
                            isCompleted ? 'Realizada' : patient.formattedTime,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: timeColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (showTrailingButton)
                GestureDetector(
                  onTap: onTrailingTap ?? onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 49.24,
                    height: 48.5,
                    decoration: BoxDecoration(
                      color:
                          forceShowTrailing && customTrailingIcon == Icons.check
                          ? Colors.green
                          : buttonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      trailingIcon,
                      color: customTrailingIcon == Icons.check
                          ? Colors.white
                          : trailingIconColor,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          if (showPageIndicators) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalPages!,
                (index) => Container(
                  width: 11.5,
                  height: 11.5,
                  margin: const EdgeInsets.symmetric(horizontal: 5.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPageIndex == index
                        ? buttonColor
                        : const Color(0xFFD9D9D9),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    Widget mainContainer = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        constraints: BoxConstraints(minHeight: showPageIndicators ? 180 : 110),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: tileContent,
      ),
    );

    if (showSwipeActions) {
      return Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(left: 50),
              decoration: BoxDecoration(
                color: const Color(0xFF3065FF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isCompleted && onMarkAsCompleted != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (onCancelAppointment != null)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Slidable(
            key: ValueKey(patient.id),
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.4,
              children: [
                if (!isCompleted && onMarkAsCompleted != null) ...[
                  CustomSlidableAction(
                    onPressed: (_) => onMarkAsCompleted!(),
                    backgroundColor: Colors.transparent,
                    child: const SizedBox.shrink(),
                  ),
                ],
                if (onCancelAppointment != null)
                  CustomSlidableAction(
                    onPressed: (_) => onCancelAppointment!(),
                    backgroundColor: Colors.transparent,
                    child: const SizedBox.shrink(),
                  ),
              ],
            ),
            child: mainContainer,
          ),
        ],
      );
    }

    return mainContainer;
  }
}
