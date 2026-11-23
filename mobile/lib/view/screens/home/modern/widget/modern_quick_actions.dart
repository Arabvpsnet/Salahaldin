// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:salatime/helper/route_helper.dart';
import 'package:salatime/theme/modern_light_theme.dart';
import 'package:salatime/util/dimensions.dart';
import 'package:salatime/util/images.dart';
import 'package:salatime/util/styles.dart';
import 'package:salatime/view/screens/category/category_screen.dart';

class ModernQuickActions extends StatelessWidget {
  const ModernQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAction(
        Images.ModernIcon_ReadQuran,
        'quran'.tr,
        RouteHelper.suraList,
      ),
      _QuickAction(
        Images.ModernIcon_AudioQuran,
        'audio_quran'.tr,
        RouteHelper.recters,
      ),
      _QuickAction(Images.ModernIcon_Duas, 'dua'.tr, RouteHelper.dua),
      _QuickAction(Images.ModernIcon_Dhikr, 'dikir'.tr, RouteHelper.dhikr),
      _QuickAction(
        Images.ModernIcon_QiblaKaaba,
        'compass'.tr,
        RouteHelper.compass,
        tint: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.RADIUS_EXTRA_LARGE),
        border: Border.all(
          color: Get.isDarkMode
              ? AppColorModern.emerald.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
        ),
        boxShadow: Get.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Get.isDarkMode
                      ? Colors.black.withOpacity(0.25)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                'quick_actions'.tr,
                style: robotoMedium.copyWith(
                  color: Get.isDarkMode
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColorModern.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Get.to(
                  () => CategoryScreen(appBackButton: true),
                  routeName: '/more',
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'view_all'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.FONT_SIZE_SMALL,
                        color: AppColorModern.emerald,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppColorModern.emerald,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final minWidth = 96.0 * scale.clamp(1.0, 2.0);
              final columns = ((constraints.maxWidth + gap) /
                      (minWidth + gap))
                  .floor()
                  .clamp(1, items.length);
              final tileWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: tileWidth,
                      child: _QuickActionTile(
                        icon: item.icon,
                        label: item.label,
                        route: item.route,
                        tint: item.tint,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String icon;
  final String label;
  final String route;
  final bool tint;
  _QuickAction(this.icon, this.label, this.route, {this.tint = true});
}

class _QuickActionTile extends StatelessWidget {
  final String icon;
  final String label;
  final String route;
  final bool tint;
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE),
      onTap: () => Get.toNamed(route),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: Get.isDarkMode
                    ? Colors.grey.withValues(alpha: 0.05)
                    : AppColorModern.emerald.withOpacity(0.07),
                borderRadius: BorderRadius.circular(Dimensions.RADIUS_LARGE),
                border: Border.all(color: AppColorModern.emerald, width: 0.08),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      icon,
                      width: 32,
                      height: 32,
                      color: tint ? AppColorModern.emerald : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.FONT_SIZE_SMALL,
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
