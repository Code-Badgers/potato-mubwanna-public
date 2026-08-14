import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/legal_consent_store.dart';
import '../../domain/legal_document.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    required this.document,
    this.manageConsent = false,
    this.returnOnAccept = false,
    this.consentStore = const SharedPreferencesLegalConsentStore(),
    super.key,
  });

  final LegalDocument document;
  final bool manageConsent;
  final bool returnOnAccept;
  final LegalConsentStore consentStore;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  bool? _isAccepted;
  bool _isSaving = false;

  bool get _canManage =>
      widget.manageConsent &&
      (widget.document.type == LegalDocumentType.locationServiceTerms ||
          widget.document.type == LegalDocumentType.healthDataConsent);

  @override
  void initState() {
    super.initState();
    if (_canManage) {
      _loadConsent();
    }
  }

  Future<void> _loadConsent() async {
    final accepted = switch (widget.document.type) {
      LegalDocumentType.locationServiceTerms =>
        await widget.consentStore.hasAcceptedPersonalLocation(),
      LegalDocumentType.healthDataConsent =>
        await widget.consentStore.hasAcceptedHealthData(),
      _ => false,
    };
    if (mounted) {
      setState(() => _isAccepted = accepted);
    }
  }

  Future<void> _changeConsent() async {
    if (_isAccepted == null || _isSaving) {
      return;
    }
    final nextValue = !_isAccepted!;
    if (!nextValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('동의를 철회할까요?'),
          content: Text(_withdrawalMessage()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('철회하기'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      switch (widget.document.type) {
        case LegalDocumentType.locationServiceTerms:
          await widget.consentStore.setPersonalLocationConsent(nextValue);
          break;
        case LegalDocumentType.healthDataConsent:
          await widget.consentStore.setHealthDataConsent(nextValue);
          break;
        case LegalDocumentType.serviceTerms:
        case LegalDocumentType.privacyPolicy:
          break;
      }
      if (!mounted) {
        return;
      }
      if (nextValue && widget.returnOnAccept) {
        context.pop(true);
        return;
      }
      setState(() {
        _isAccepted = nextValue;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동의 상태를 변경하지 못했습니다.')),
      );
    }
  }

  String _withdrawalMessage() {
    return switch (widget.document.type) {
      LegalDocumentType.locationServiceTerms =>
        '철회하면 현재 위치 탐색과 방문 인증을 이용할 수 없습니다. 기기 위치 권한은 시스템 설정에서 별도로 해제할 수 있습니다.',
      LegalDocumentType.healthDataConsent =>
        '철회하면 걸음 통계, 감자 성장과 걸음 미션이 중단됩니다. 기기의 건강정보 권한은 시스템 설정에서 별도로 해제할 수 있습니다.',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.document.title),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    Text(
                      widget.document.summary,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '시행일 ${widget.document.effectiveDate}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 26),
                    for (final section in widget.document.sections)
                      _DocumentSection(section: section),
                  ],
                ),
              ),
            ),
            if (_canManage)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isAccepted == null || _isSaving
                        ? null
                        : _changeConsent,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isAccepted == true
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isAccepted == true ? '동의 철회하기' : '동의하기',
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({required this.section});

  final LegalDocumentSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          if (section.paragraphs.isNotEmpty) const SizedBox(height: 10),
          for (final paragraph in section.paragraphs) ...[
            Text(
              paragraph,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (section.items.isNotEmpty) const SizedBox(height: 6),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
