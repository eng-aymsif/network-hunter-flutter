import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/presentation/providers/cards_provider.dart';
import 'package:networking/presentation/providers/settings_provider.dart';

class CardsTab extends StatelessWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cardsProv = context.watch<CardsProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final cards = cardsProv.cards;
    final isSelectionMode = cardsProv.isSelectionMode;

    return Column(
      children: [
        // 1. شريط الأدوات العلوي والبحث
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              TextField(
                onChanged: (q) => cardsProv.setSearchQuery(q),
                decoration: InputDecoration(
                  hintText: 'البحث عن رقم كرت...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: cardsProv.cards.length != cardsProv.totalCount
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => cardsProv.setSearchQuery(''),
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        label: Text(
                          'الإجمالي: ${cardsProv.totalCount}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : AppColors.primaryLight,
                      ),
                      Chip(
                        label: Text(
                          'غير مستخدم: ${cardsProv.unusedCount}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.success.withValues(alpha: 0.18)
                                : AppColors.successLight,
                      ),
                      if (isSelectionMode)
                        Chip(
                          label: Text(
                            'المحدد: ${cardsProv.selectedCount}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.purple.withValues(alpha: 0.15),
                        ),
                    ],
                  ),
                  Wrap(
                    children: [
                      IconButton(
                        tooltip: 'تنزيل كملف Excel (.xlsx)',
                        icon: const Icon(
                          Icons.file_download,
                          color: AppColors.primary,
                        ),
                        onPressed: () async {
                          final ok = await cardsProv.exportCardsToExcel();
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'لا توجد كروت للتصدير أو حدث خطأ',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'مشاركة البيانات كـ نص منسق',
                        icon: const Icon(Icons.share, color: AppColors.accent),
                        onPressed: () => cardsProv.shareFormattedCards(),
                      ),
                      IconButton(
                        tooltip: isSelectionMode
                            ? 'حذف الكروت المحددة'
                            : 'مسح كافة الكروت',
                        icon: Icon(
                          isSelectionMode
                              ? Icons.delete
                              : Icons.delete_sweep,
                          color: AppColors.danger,
                        ),
                        onPressed: () {
                          if (isSelectionMode) {
                            _confirmDeleteSelected(context, cardsProv);
                          } else {
                            _confirmClearAll(context, cardsProv);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // أدوات التحديد المتعدد وفحص التوفر
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.select_all, size: 16),
                      label: const Text(
                        'تحديد الكل',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                      ),
                      onPressed: () => cardsProv.selectAll(),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.filter_alt_outlined, size: 16),
                      label: const Text(
                        'تحديد غير المستخدمة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                      ),
                      onPressed: () => cardsProv.selectUnused(),
                    ),
                    if (isSelectionMode) ...[
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.close, size: 16),
                        label: const Text(
                          'إلغاء التحديد',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                        ),
                        onPressed: () => cardsProv.clearSelection(),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.wifi_tethering, size: 16),
                        label: Text(
                          'فحص توفر وصلاحية (${cardsProv.selectedCount})',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: cardsProv.isCheckingBatch
                            ? null
                            : () {
                                final selected = cardsProv.cards
                                    .where((c) =>
                                        cardsProv.selectedIds.contains(c.id))
                                    .toList();
                                cardsProv.checkBatchAvailability(
                                  selected,
                                  settingsProv.settings,
                                );
                              },
                      ),
                    ],
                  ],
                ),
              ),

              // شريط تقدم الفحص التتابعي للدفعة
              if (cardsProv.isCheckingBatch) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cardsProv.batchCheckStatus,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const Divider(height: 1),

        // 2. قائمة الكروت
        Expanded(
          child: cardsProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد كروت مكتشفة حتى الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: cards.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        final isSelected =
                            cardsProv.selectedIds.contains(card.id);

                        return Card(
                          elevation: isSelected ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (isSelectionMode && card.id != null) {
                                cardsProv.toggleSelectCard(card.id!);
                              }
                            },
                            onLongPress: () {
                              _showCardOptionsDialog(
                                context,
                                card,
                                cardsProv,
                                settingsProv,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (isSelectionMode)
                                            Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .only(end: 8),
                                              child: Checkbox(
                                                value: isSelected,
                                                onChanged: (_) {
                                                  if (card.id != null) {
                                                    cardsProv.toggleSelectCard(
                                                      card.id!,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          Icon(
                                            card.isUsed
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: card.isUsed
                                                ? Colors.grey
                                                : AppColors.success,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          SelectableText(
                                            card.cardNumber,
                                            style: TextStyle(
                                              fontFamily: 'Consolas',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: card.isUsed
                                                  ? Colors.grey
                                                  : AppColors.primary,
                                              decoration: card.isUsed
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          // شارة حالة الاستخدام
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: card.isUsed
                                                  ? Colors.grey.shade200
                                                  : AppColors.successLight,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              card.isUsed
                                                  ? '✅ مستخدم'
                                                  : '⭕ غير مستخدم',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: card.isUsed
                                                    ? Colors.grey.shade700
                                                    : AppColors.success,
                                              ),
                                            ),
                                          ),
                                          // شارة الملاحظات / حالة التوفر
                                          if (card.notes.isNotEmpty)
                                            _buildNotesBadge(card.notes),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'التاريخ: ${card.foundAt}',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'تبديل حالة الاستخدام',
                                            icon: Icon(
                                              card.isUsed
                                                  ? Icons.undo
                                                  : Icons.check,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                            onPressed: () {
                                              if (card.id != null) {
                                                cardsProv.toggleUsed(card.id!);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'نسخ الرقم',
                                            icon: const Icon(
                                              Icons.copy,
                                              size: 18,
                                              color: AppColors.accent,
                                            ),
                                            onPressed: () {
                                              cardsProv.copyCardNumber(
                                                card.cardNumber,
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'تم نسخ الرقم: ${card.cardNumber}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'حذف',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.danger,
                                            ),
                                            onPressed: () {
                                              if (card.id != null) {
                                                _confirmDeleteCard(
                                                  context,
                                                  cardsProv,
                                                  card.id!,
                                                  card.cardNumber,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildNotesBadge(String notes) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade700;

    if (notes.contains('متاح') || notes.contains('صالح')) {
      bg = AppColors.successLight;
      fg = AppColors.success;
    } else if (notes.contains('غير متاح') || notes.contains('❌')) {
      bg = AppColors.dangerLight;
      fg = AppColors.danger;
    } else if (notes.contains('متصل')) {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        notes,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // ==================== حوار الخيارات الاحترافي عند النقر المطول ====================

  void _showCardOptionsDialog(
    BuildContext context,
    CardModel card,
    CardsProvider cardsProv,
    SettingsProvider settingsProv,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ترويسة الحوار
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'إجراءات الكرت: ${card.cardNumber}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),

              // 1. الاتصال وتسجيل الدخول بالكرت الآن
              ListTile(
                leading: const Icon(Icons.wifi, color: AppColors.success),
                title: const Text(
                  'الاتصال وتسجيل الدخول بالكرت الآن',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'تسجيل الدخول في بوابة الشبكة وإبقاء الجلسة نشطة لتصفح الإنترنت.',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'جاري الاتصال وتسجيل الدخول بالكرت: ${card.cardNumber}...',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                  final ok = await cardsProv.loginAndConnectWithCard(
                    card,
                    settingsProv.settings,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '🎉 تم الاتصال وتسجيل الدخول بنجاح! أنت الآن متصل بالإنترنت.'
                              : '❌ تعذر تسجيل الدخول بالكرت (الكرت غير صالح أو البوابة رفضت الطلب)',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.danger,
                      ),
                    );
                  }
                },
              ),

              // 2. فحص توفر وصلاحية الكرت
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                title: const Text(
                  'فحص توفر وصلاحية الكرت',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'التحقق من عمل الكرت دون حجز الجلسة (تسجيل دخول ثم خروج فوري).',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'جاري فحص توفر الكرت: ${card.cardNumber}...',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                  final ok = await cardsProv.checkSingleCardAvailability(
                    card,
                    settingsProv.settings,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '✓ الكرت ${card.cardNumber} متاح وصالح للاستخدام!'
                              : '❌ الكرت ${card.cardNumber} غير متاح أو منتهي الصلاحية',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.danger,
                      ),
                    );
                  }
                },
              ),

              // 3. نسخ الرقم
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.accent),
                title: const Text(
                  'نسخ رقم الكرت',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  cardsProv.copyCardNumber(card.cardNumber);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم نسخ الرقم: ${card.cardNumber}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  );
                },
              ),

              // 4. مشاركة منسقة
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.accent),
                title: const Text(
                  'مشاركة بيانات الكرت',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  cardsProv.shareFormattedCards(targetList: [card]);
                },
              ),

              // 5. تبديل حالة الاستخدام
              ListTile(
                leading: Icon(
                  card.isUsed ? Icons.undo : Icons.check,
                  color: AppColors.purple,
                ),
                title: Text(
                  card.isUsed
                      ? 'تعيين كـ غير مستخدم'
                      : 'تعيين كـ مستخدم',
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (card.id != null) cardsProv.toggleUsed(card.id!);
                },
              ),

              // 6. حذف الكرت
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text(
                  'حذف الكرت',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (card.id != null) {
                    _confirmDeleteCard(
                      context,
                      cardsProv,
                      card.id!,
                      card.cardNumber,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== حوارات تأكيد الحذف ====================

  void _confirmDeleteCard(
    BuildContext context,
    CardsProvider prov,
    int cardId,
    String cardNum,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد حذف الكرت رقم "$cardNum" من قاعدة البيانات نهائياً؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              prov.deleteCard(cardId);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context, CardsProvider prov) {
    final count = prov.selectedCount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد حذف الكروت المحددة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد بالتأكيد حذف الكروت المحددة ($count كرت) نهائياً من قاعدة البيانات؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              prov.deleteSelectedCards();
              Navigator.pop(ctx);
            },
            child: const Text('حذف المحدد', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, CardsProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد مسح كافة الكروت',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد بالتأكيد حذف كافة الكروت المكتشفة نهائياً من قاعدة البيانات؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              prov.clearAllCards();
              Navigator.pop(ctx);
            },
            child: const Text('مسح الكل', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
