import 'package:flutter/material.dart';
import '../../../design/design.dart';

class VirtualMuthawifScreenPremium extends StatefulWidget {
  const VirtualMuthawifScreenPremium({super.key});

  @override
  State<VirtualMuthawifScreenPremium> createState() => _VirtualMuthawifScreenPremiumState();
}

class _VirtualMuthawifScreenPremiumState extends State<VirtualMuthawifScreenPremium> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'Assalamu\'alaikum! Saya Muthawif virtual Anda. Ada yang bisa saya bantu hari ini?',
    },
  ];
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
      });
      _messageController.clear();
      _isTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': _getAutoResponse(text),
          });
          _isTyping = false;
        });
      }
    });
  }

  String _getAutoResponse(String input) {
    final lowerInput = input.toLowerCase();
    if (lowerInput.contains('haji') || lowerInput.contains('umrah')) {
      return 'Umrah adalah ibadah mengunjungi Masjidil Haram dengan niat. Pastikan Anda sudah berniat ihram dari miqat dan membaca talbiyah saat memulai.';
    } else if (lowerInput.contains('sa\'i') || lowerInput.contains('sai')) {
      return 'Sa\'i adalah berlari-lari kecil antara bukit Shafa dan Marwa sebanyak 7 kali. Mulailah dari Shafa dan akhiri di Marwa.';
    } else if (lowerInput.contains('thawaf')) {
      return 'Thawaf adalah mengelilingi Ka\'bah sebanyak 7 kali dengan arah berlawanan jarum jam. Lakukan dengan bahu kiri menghadap Ka\'bah.';
    }
    return 'Terima kasih atas pertanyaannya. Saya akan membantu menjelaskan lebih detail. Silakan bertanya lebih spesifik.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildQuickActions(isDark),
            Expanded(
              child: _buildMessageList(isDark),
            ),
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
              color: AppColors.gold.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muthawif Virtual',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _buildQuickActionChip('Thawaf', isDark),
          _buildQuickActionChip('Sa\'i', isDark),
          _buildQuickActionChip('Ihram', isDark),
          _buildQuickActionChip('Miqat', isDark),
          _buildQuickActionChip('Doa', isDark),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: ActionChip(
        label: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.gold,
          ),
        ),
        backgroundColor: AppColors.gold.withValues(alpha: 0.1),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        onPressed: () {
          _messageController.text = 'Jelaskan tentang $label';
          _sendMessage();
        },
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return _buildTypingIndicator(isDark);
        }
        final message = _messages[index];
        final isUser = message['role'] == 'user';
        return _buildMessageBubble(message['content']!, isUser, isDark);
      },
    );
  }

  Widget _buildMessageBubble(String content, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.gold
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(isUser ? AppSpacing.radiusMd : 0),
            bottomRight: Radius.circular(isUser ? 0 : AppSpacing.radiusMd),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Muthawif',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              content,
              style: AppTypography.bodyMedium.copyWith(
                color: isUser
                    ? AppColors.primaryDark
                    : (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(1),
            const SizedBox(width: 4),
            _buildTypingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tanyakan tentang ibadah...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                        .withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
