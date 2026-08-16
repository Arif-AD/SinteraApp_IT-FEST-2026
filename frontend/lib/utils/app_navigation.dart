import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';

void safePopOrGoHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

void safePopOrGo(BuildContext context, String route) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(route);
  }
}
