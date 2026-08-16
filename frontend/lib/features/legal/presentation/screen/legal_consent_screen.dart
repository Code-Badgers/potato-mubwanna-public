import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
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
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.94),
                            borderRadius:
                                BorderRadius.circular(AppDimens.cardRadius),
                            boxShadow: AppShadows.softCard,
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '시작 전 확인할게요',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1.18,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '필수 항목만 동의해도 지도와 여행 정보를 둘러볼 수 있어요. 위치와 걸음 정보는 인증·성장 기록에만 사용됩니다.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AllAgreementTile(
                          value: _allAccepted,
                          onChanged: _setAll,
                        ),
                        const SizedBox(height: 12),
                        _AgreementTile(
                          label: '만 14세 이상입니다',
                          badge: '필수',
                          description: '서비스 이용 가능 연령 확인',
                          value: _minimumAgeConfirmed,
                          onChanged: (value) => setState(
                            () => _minimumAgeConfirmed = value ?? false,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _AgreementTile(
                          label: '서비스 이용약관',
                          badge: '필수',
                          description: '계정과 서비스 이용 조건',
                          value: _serviceTermsAccepted,
                          onChanged: (value) => setState(
                            () => _serviceTermsAccepted = value ?? false,
                          ),
                          onOpen: () => context.push('/legal/service-terms'),
                        ),
                        const SizedBox(height: 9),
                        _AgreementTile(
                          label: '개인위치정보 이용 동의',
                          badge: '선택',
                          description: '주변 탐색과 방문 인증에 현재 위치 사용',
                          value: _personalLocationAccepted,
                          onChanged: (value) => setState(
                            () => _personalLocationAccepted = value ?? false,
                          ),
                          onOpen: () => context.push('/legal/location-terms'),
                        ),
                        const SizedBox(height: 9),
                        _AgreementTile(
                          label: '걸음 정보 수집·이용 동의',
                          badge: '선택',
                          description:
                              '감자 성장에 HealthKit·Health Connect 걸음 수 사용',
                          value: _healthDataAccepted,
                          onChanged: (value) => setState(
                            () => _healthDataAccepted = value ?? false,
                          ),
                          onOpen: () =>
                              context.push('/legal/health-data-consent'),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                context.push('/legal/privacy-policy'),
                            icon: const Icon(Icons.shield_outlined, size: 18),
                            label: const Text('개인정보처리방침 보기'),
                          ),
                        ),
                        const Spacer(),
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
                              disabledBackgroundColor:
                                  AppColors.line.withValues(alpha: 0.78),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
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
                                : const Text('계속하기'),
                          ),
                        ),
                      ],
                    ),
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

class _AllAgreementTile extends StatelessWidget {
  const _AllAgreementTile({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryTint.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        controlAffinity: ListTileControlAffinity.leading,
        checkboxShape: const CircleBorder(),
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '전체 동의',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        subtitle: const Text(
          '필수와 선택 항목을 한 번에 선택합니다',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  const _AgreementTile({
    required this.label,
    required this.badge,
    required this.description,
    required this.value,
    required this.onChanged,
    this.onOpen,
  });

  final String label;
  final String badge;
  final String description;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.95),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: const CircleBorder(),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badge == '필수'
                                ? AppColors.primaryTint
                                : AppColors.cream,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badge == '필수'
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
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
