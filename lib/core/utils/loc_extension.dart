import 'package:flutter/material.dart';
import 'package:admin_motareb/l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
