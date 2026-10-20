import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';

/// Only externally navigable web links and plain phone numbers are allowed.
Uri? placeWebsiteUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null ||
      !const ['https', 'http'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

Uri? placePhoneUri(String? value) {
  final number = value?.trim().replaceAll(RegExp(r'[\s()\-]'), '') ?? '';
  return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(number)
      ? Uri(scheme: 'tel', path: number)
      : null;
}

Future<void> openPlaceLink(BuildContext context, Uri uri) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Launch failures must not interrupt the place sheet.
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('연결할 수 없어요. 잠시 후 다시 시도해주세요.')),
    );
  }
}

class PlaceVisitActions extends StatelessWidget {
  const PlaceVisitActions({this.phone, this.website, super.key});

  final String? phone;
  final String? website;

  @override
  Widget build(BuildContext context) {
    final phoneUri = placePhoneUri(phone);
    final websiteUri = placeWebsiteUri(website);
    return Wrap(
      spacing: 12,
      children: [
        if (phoneUri != null)
          TextButton.icon(
            onPressed: () => openPlaceLink(context, phoneUri),
            icon: const Icon(Icons.call_outlined, size: 18),
            label: const Text('전화 문의'),
          ),
        if (websiteUri != null)
          TextButton.icon(
            onPressed: () => openPlaceLink(context, websiteUri),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('홈페이지'),
          ),
      ],
    );
  }
}

class PlaceSourceCaption extends StatelessWidget {
  const PlaceSourceCaption({this.sourceUrl, this.verifiedOn = '', super.key});

  final String? sourceUrl;
  final String verifiedOn;

  @override
  Widget build(BuildContext context) {
    final uri = placeWebsiteUri(sourceUrl);
    final isTourApi = uri?.host == 'apis.data.go.kr';
    final source = isTourApi ? '한국관광공사' : uri?.host;
    final date = DateTime.tryParse(verifiedOn);
    final caption = [
      if (source != null) '출처: $source',
      if (date != null) '${verifiedOn.replaceAll('-', '.')} 확인',
    ].join(' · ');
    if (caption.isEmpty) return const SizedBox.shrink();
    final text = Text(caption,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary));
    // A key-protected API endpoint is not a usable public source page.
    return uri == null || isTourApi
        ? text
        : InkWell(
            onTap: () => openPlaceLink(context, uri),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(alignment: Alignment.centerLeft, child: text),
              ),
            ));
  }
}
