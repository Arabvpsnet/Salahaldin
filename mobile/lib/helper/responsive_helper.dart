import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveHelper {
  static const double tabletBreakpoint = 650;
  static const double desktopBreakpoint = 1300;

  // Legacy platform predicate; use isMobile(context) for layout decisions.
  static bool isMobilePhone() => !kIsWeb;
  static bool isWeb() => kIsWeb;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  static bool isTab(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}
