import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

class VersionInfo {
  final String minSupported;
  final String latest;
  final String? changelog;
  final String? storeUrl;
  VersionInfo({
    required this.minSupported,
    required this.latest,
    this.changelog,
    this.storeUrl,
  });
  factory VersionInfo.fromJson(Map<String, dynamic> j) => VersionInfo(
        minSupported: (j['min_supported'] ?? '0.0.0') as String,
        latest: (j['latest'] ?? '0.0.0') as String,
        changelog: j['latest_changelog'] as String?,
        storeUrl: j['play_store_url'] as String?,
      );
}

int _cmp(String a, String b) {
  final ap = a.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
  final bp = b.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
  while (ap.length < bp.length) {
    ap.add(0);
  }
  while (bp.length < ap.length) {
    bp.add(0);
  }
  for (var i = 0; i < ap.length; i++) {
    if (ap[i] != bp[i]) return ap[i].compareTo(bp[i]);
  }
  return 0;
}

/// 'force' | 'optional' | null
Future<({String mode, VersionInfo info})?> checkVersion(Dio dio) async {
  try {
    final r = await dio.get('/version',
        options: Options(receiveTimeout: const Duration(seconds: 5)));
    final info =
        VersionInfo.fromJson(Map<String, dynamic>.from(r.data as Map));
    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version;
    if (_cmp(current, info.minSupported) < 0) {
      return (mode: 'force', info: info);
    }
    if (_cmp(current, info.latest) < 0) {
      return (mode: 'optional', info: info);
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> showUpdateDialog(
  BuildContext context,
  VersionInfo info, {
  bool force = false,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !force,
    builder: (ctx) => PopScope(
      canPop: !force,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(force ? 'Yangilash majburiy' : 'Yangi versiya bor 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versiya ${info.latest} mavjud.',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
            if (info.changelog != null) ...[
              const SizedBox(height: 8),
              Text(
                info.changelog!,
                style: const TextStyle(
                  color: AppColors.inkLight,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keyinroq'),
            ),
          FilledButton(
            onPressed: () async {
              final url = info.storeUrl;
              if (url != null && url.isNotEmpty) {
                try {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } catch (_) {}
              }
              if (!force && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Yangilash'),
          ),
        ],
      ),
    ),
  );
}
