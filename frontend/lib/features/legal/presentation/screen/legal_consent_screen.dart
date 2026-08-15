import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/legal_consent_store.dart';

class LegalConsentScreen extends StatefulWidget {
  const LegalConsentScreen({
    required this.onAccepted,
    this.consentStore = const SharedPreferencesLegalConsentStore(),
    super.key,
  });

  final LegalConsentStore consentStore;
  final Future<void> Function() onAccepted;

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _minimumAgeConfirmed = false;
  bool _serviceTermsAccepted = false;
  bool _personalLocationAccepted = false;
  bool _healthDataAccepted = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _canContinue =>
      _minimumAgeConfirmed && _serviceTermsAccepted && !_isSaving;

  bool get _allAccepted =>
      _minimumAgeConfirmed &&
      _serviceTermsAccepted &&
      _personalLocationAccepted &&
      _healthDataAccepted;

  void _setAll(bool? accepted) {
    final value = accepted ?? false;
    setState(() {
      _minimumAgeConfirmed = value;
      _serviceTermsAccepted = value;
      _personalLocationAccepted = value;
      _healthDataAccepted = value;
      _errorMessage = null;
    });
  }

  Future<void> _continue() async {
    if (!_canContinue) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.consentStore.acceptRequiredDocuments();
      await widget.consentStore.setPersonalLocationConsent(
        _personalLocationAccepted,
      );
      await widget.consentStore.setHealthDataConsent(_healthDataAccepted);
      await widget.onAccepted();
      if (mounted) {
        setState(() => _isSaving = false);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = '동의 상태를 저장하지 못했습니다. 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '감자여행을 시작하기 전에\n이용 연령과 약관을 확인해주세요',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '선택 동의를 거부해도 기본 관광 정보는 이용할 수 있어요.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AllAgreementTile(
                    value: _allAccepted,
                    onChanged: _setAll,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      children: [
                        _AgreementTile(
                          label: '[필수] 만 14세 이상입니다',
                          description: '만 14세 미만은 서비스를 이용할 수 없어요',
                          value: _minimumAgeConfirmed,
                          onChanged: (value) => setState(
                            () => _minimumAgeConfirmed = value ?? false,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AgreementTile(
                          label: '[필수] 서비스 이용약관',
                          description: '계정과 서비스 이용 조건',
                          value: _serviceTermsAccepted,
                          onChanged: (value) => setState(
                            () => _serviceTermsAccepted = value ?? false,
                          ),
                          onOpen: () => context.push('/legal/service-terms'),
                        ),
                        const SizedBox(height: 10),
                        _AgreementTile(
                          label: '[선택] 개인위치정보 이용 동의',
                          description: '주변 탐색과 방문 인증에 현재 위치 사용',
                          value: _personalLocationAccepted,
                          onChanged: (value) => setState(
                            () => _personalLocationAccepted = value ?? false,
                          ),
                          onOpen: () => context.push('/legal/location-terms'),
                        ),
                        const SizedBox(height: 10),
                        _AgreementTile(
                          label: '[선택] 걸음 정보 수집·이용 동의',
                          description: 'HealthKit·Health Connect 걸음 수로 감자 성장',
                          value: _healthDataAccepted,
                          onChanged: (value) => setState(
                            () => _healthDataAccepted = value ?? false,
                          ),
                          onOpen: () =>
                              context.push('/legal/health-data-consent'),
                        ),
                        const SizedBox(height: 18),
                        TextButton.icon(
                          onPressed: () =>
                              context.push('/legal/privacy-policy'),
                          icon: const Icon(Icons.shield_outlined),
                          label: const Text('개인정보처리방침 보기'),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _canContinue ? _continue : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.line,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('동의하고 계속하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllAgreementTile extends StatelessWidget {
  const _AllAgreementTile({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(14),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          '전체 동의',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: const Text(
          '필수 및 선택 항목을 모두 선택합니다.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  const _AgreementTile({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.onOpen,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onOpen != null)
            IconButton(
              tooltip: '내용 보기',
              onPressed: onOpen,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    );
  }
}
