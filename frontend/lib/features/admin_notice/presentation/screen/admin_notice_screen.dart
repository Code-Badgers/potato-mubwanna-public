import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_design_tokens.dart';
import '../../../../core/network/api_exception.dart';
import '../../application/admin_notice_controller.dart';
import '../../domain/admin_notice.dart';

class AdminNoticeScreen extends ConsumerStatefulWidget {
  const AdminNoticeScreen({super.key});

  @override
  ConsumerState<AdminNoticeScreen> createState() => _AdminNoticeScreenState();
}

class _AdminNoticeScreenState extends ConsumerState<AdminNoticeScreen> {
  int? _changingPublicationNoticeId;

  @override
  Widget build(BuildContext context) {
    final noticesState = ref.watch(adminNoticesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: const Row(
          children: [
            Text(
              '공지 관리',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(width: 9),
            _AdminBadge(),
          ],
        ),
      ),
      body: noticesState.when(
        loading: () => const _AdminNoticeLoading(),
        error: (error, _) => _AdminNoticeError(
          error: error,
          onRetry: () => ref.invalidate(adminNoticesProvider),
        ),
        data: (notices) => RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: () => ref.refresh(adminNoticesProvider.future),
          child: _AdminNoticeContent(
            notices: notices,
            changingPublicationNoticeId: _changingPublicationNoticeId,
            onCreate: () => _openEditor(),
            onEdit: _openEditor,
            onPublicationChanged: _changePublication,
          ),
        ),
      ),
      floatingActionButton: noticesState.hasValue
          ? FloatingActionButton.extended(
              key: const ValueKey('admin-notice-create-button'),
              onPressed: _openEditor,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                '새 공지',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
    );
  }

  Future<void> _openEditor([AdminNotice? notice]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AdminNoticeEditorSheet(
        notice: notice,
        onSubmit: ({required title, required content, required published}) {
          final repository = ref.read(adminNoticeRepositoryProvider);
          if (notice == null) {
            return repository.createNotice(
              title: title,
              content: content,
              published: published,
            );
          }
          return repository.updateNotice(
            noticeId: notice.id,
            title: title,
            content: content,
          );
        },
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    ref.invalidate(adminNoticesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notice == null ? '공지를 등록했습니다.' : '공지를 수정했습니다.')),
    );
  }

  Future<void> _changePublication(AdminNotice notice, bool published) async {
    if (_changingPublicationNoticeId != null) {
      return;
    }
    setState(() => _changingPublicationNoticeId = notice.id);
    try {
      await ref.read(adminNoticeRepositoryProvider).changePublication(
            noticeId: notice.id,
            published: published,
          );
      ref.invalidate(adminNoticesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(published ? '공지를 게시했습니다.' : '공지를 숨겼습니다.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageOf(error, '게시 상태를 변경하지 못했습니다.'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _changingPublicationNoticeId = null);
      }
    }
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.22),
        ),
      ),
      child: const Text(
        'ADMIN',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AdminNoticeContent extends StatelessWidget {
  const _AdminNoticeContent({
    required this.notices,
    required this.changingPublicationNoticeId,
    required this.onCreate,
    required this.onEdit,
    required this.onPublicationChanged,
  });

  final List<AdminNotice> notices;
  final int? changingPublicationNoticeId;
  final VoidCallback onCreate;
  final ValueChanged<AdminNotice> onEdit;
  final void Function(AdminNotice notice, bool published) onPublicationChanged;

  @override
  Widget build(BuildContext context) {
    final publishedCount = notices.where((notice) => notice.published).length;

    return CustomScrollView(
      key: const ValueKey('admin-notice-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAF9F0), Color(0xFFFFF8EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppDimens.cardRadius),
                        border: Border.all(
                          color: AppColors.line.withValues(alpha: 0.82),
                        ),
                        boxShadow: AppShadows.softCard,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '서비스 소식을 관리해요',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  '게시한 공지는 사용자의 공지사항에 바로 반영됩니다.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.42,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: AppColors.primaryDark,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: '전체 공지',
                            value: notices.length,
                            icon: Icons.article_outlined,
                            color: AppColors.brown,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryCard(
                            label: '게시 중',
                            value: publishedCount,
                            icon: Icons.visibility_outlined,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryCard(
                            label: '숨김',
                            value: notices.length - publishedCount,
                            icon: Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      '공지 목록',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '스위치를 눌러 사용자에게 보이는 상태를 바꿀 수 있어요.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (notices.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _AdminNoticeEmpty(onCreate: onCreate),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList.separated(
              itemCount: notices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _AdminNoticeCard(
                    notice: notices[index],
                    changingPublication:
                        changingPublicationNoticeId == notices[index].id,
                    onEdit: () => onEdit(notices[index]),
                    onPublicationChanged: (published) =>
                        onPublicationChanged(notices[index], published),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 10, 12),
      decoration: AppDecorations.card(radius: AppDimens.compactCardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 9),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNoticeCard extends StatelessWidget {
  const _AdminNoticeCard({
    required this.notice,
    required this.changingPublication,
    required this.onEdit,
    required this.onPublicationChanged,
  });

  final AdminNotice notice;
  final bool changingPublication;
  final VoidCallback onEdit;
  final ValueChanged<bool> onPublicationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('admin-notice-${notice.id}'),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PublicationBadge(published: notice.published),
              const Spacer(),
              Text(
                '수정 ${_formatDate(notice.updatedAt)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                key: ValueKey('admin-notice-edit-${notice.id}'),
                tooltip: '공지 수정',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
          Text(
            notice.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            notice.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.line),
          Row(
            children: [
              Expanded(
                child: Text(
                  notice.published ? '사용자 공지사항에 노출 중' : '관리자에게만 보이는 초안',
                  style: TextStyle(
                    color: notice.published
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (changingPublication)
                const Padding(
                  padding: EdgeInsets.all(11),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                )
              else
                Switch.adaptive(
                  key: ValueKey('admin-notice-publication-${notice.id}'),
                  value: notice.published,
                  activeThumbColor: AppColors.primaryDark,
                  onChanged: onPublicationChanged,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublicationBadge extends StatelessWidget {
  const _PublicationBadge({required this.published});

  final bool published;

  @override
  Widget build(BuildContext context) {
    final color = published ? AppColors.primaryDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
      ),
      child: Text(
        published ? '게시 중' : '숨김',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdminNoticeEditorSheet extends StatefulWidget {
  const _AdminNoticeEditorSheet({
    required this.notice,
    required this.onSubmit,
  });

  final AdminNotice? notice;
  final Future<AdminNotice> Function({
    required String title,
    required String content,
    required bool published,
  }) onSubmit;

  @override
  State<_AdminNoticeEditorSheet> createState() =>
      _AdminNoticeEditorSheetState();
}

class _AdminNoticeEditorSheetState extends State<_AdminNoticeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _published;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.notice?.title);
    _contentController = TextEditingController(text: widget.notice?.content);
    _published = widget.notice?.published ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.notice != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.sheetRadius),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        isEditing ? '공지 수정' : '새 공지 작성',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEditing
                            ? '제목과 내용을 수정합니다. 게시 상태는 목록에서 바꿀 수 있어요.'
                            : '저장 후 바로 게시하거나 숨김 상태로 준비할 수 있어요.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        key: const ValueKey('admin-notice-title-field'),
                        controller: _titleController,
                        maxLength: 160,
                        textInputAction: TextInputAction.next,
                        decoration:
                            _inputDecoration('제목', '사용자에게 보일 제목을 입력하세요'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? '제목을 입력해주세요.'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const ValueKey('admin-notice-content-field'),
                        controller: _contentController,
                        maxLength: 2000,
                        minLines: 5,
                        maxLines: 8,
                        decoration: _inputDecoration('내용', '공지 내용을 입력하세요'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? '내용을 입력해주세요.'
                                : null,
                      ),
                      if (!isEditing) ...[
                        const SizedBox(height: 4),
                        SwitchListTile.adaptive(
                          key: const ValueKey('admin-notice-create-published'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            '저장 후 바로 게시',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text('끄면 관리자에게만 보이는 숨김 상태로 저장됩니다.'),
                          value: _published,
                          activeThumbColor: AppColors.primaryDark,
                          onChanged: _submitting
                              ? null
                              : (value) => setState(() => _published = value),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.buttonRadius,
                                  ),
                                ),
                              ),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              key: const ValueKey('admin-notice-save-button'),
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimens.buttonRadius,
                                  ),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEditing ? '수정 저장' : '공지 저장',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        published: _published,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = _messageOf(error, '공지를 저장하지 못했습니다.');
        });
      }
    }
  }
}

class _AdminNoticeEmpty extends StatelessWidget {
  const _AdminNoticeEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 10, 28, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.article_outlined,
              color: AppColors.primaryDark,
              size: 50,
            ),
            const SizedBox(height: 13),
            const Text(
              '아직 등록한 공지가 없어요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            const Text(
              '첫 공지를 작성해 사용자에게 서비스 소식을 알려주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('첫 공지 작성'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNoticeLoading extends StatelessWidget {
  const _AdminNoticeLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryDark),
    );
  }
}

class _AdminNoticeError extends StatelessWidget {
  const _AdminNoticeError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final statusCode =
        error is ApiException ? (error as ApiException).statusCode : null;
    final isForbidden = statusCode == 401 || statusCode == 403;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isForbidden
                    ? Icons.admin_panel_settings_outlined
                    : Icons.cloud_off_outlined,
                color: isForbidden ? AppColors.brown : AppColors.error,
                size: 54,
              ),
              const SizedBox(height: 15),
              Text(
                isForbidden ? '관리자 전용 화면입니다' : '공지 관리를 불러오지 못했습니다',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                isForbidden
                    ? '서버에서 관리자 권한이 확인된 계정만 사용할 수 있어요.'
                    : _messageOf(error, '잠시 후 다시 시도해주세요.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isForbidden) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('다시 시도'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
}

String _messageOf(Object error, String fallback) {
  if (error is ApiException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return fallback;
}
