import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/data/models/card_model.dart';
import 'package:networking/data/models/tested_card_model.dart';
import 'package:networking/presentation/providers/cards_provider.dart';
import 'package:networking/presentation/providers/engine_provider.dart';
import 'package:networking/presentation/providers/logs_provider.dart';
import 'package:networking/presentation/providers/settings_provider.dart';

class CardsTab extends StatefulWidget {
  const CardsTab({super.key});

  @override
  State<CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<CardsTab> {
  int _rowsPerPage = 25;
  final TextEditingController _testedSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _testedSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsProv = context.watch<CardsProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final engineProv = context.watch<EngineProvider>();
    final showAutoLoginTab = settingsProv.settings.autoLoginWithHuntedCards;

    return DefaultTabController(
      key: ValueKey<bool>(showAutoLoginTab),
      length: showAutoLoginTab ? 3 : 2,
      child: Column(
        children: [
          // شريط التبويب العلوي الأنيق (يظهر التبويب الثالث فقط عند تفعيل ميزة الاتصال التلقائي في الإعدادات)
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.card_membership_rounded, size: 20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('الكروت المصطادة'),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${cardsProv.totalCount}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  icon: const Icon(Icons.fact_check_outlined, size: 20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('سجل الكروت المختبرة'),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${cardsProv.totalTestedCount}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showAutoLoginTab)
                  Tab(
                    icon: const Icon(Icons.autorenew_rounded, size: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('أولوية الاتصال التلقائي'),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cardsProv.unusedCount}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              children: [
                // التبويب 1: الكروت المصطادة
                _buildHuntedCardsView(context, cardsProv, settingsProv),

                // التبويب 2: سجل الكروت المختبرة (DataTable)
                _buildTestedCardsView(context, cardsProv),

                // التبويب 3 (يظهر فقط عند التفعيل في الإعدادات): أولوية الاتصال التلقائي
                if (showAutoLoginTab)
                  _buildAutoLoginQueueView(
                    context,
                    cardsProv,
                    settingsProv,
                    engineProv,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // التبويب الأول: الكروت المصطادة بنجاح
  // ===========================================================================
  Widget _buildHuntedCardsView(
    BuildContext context,
    CardsProvider cardsProv,
    SettingsProvider settingsProv,
  ) {
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
                          backgroundColor:
                              AppColors.purple.withValues(alpha: 0.15),
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
                            : 'مسح كافة الكروت المصطادة',
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

        // 2. قائمة الكروت المصطادة
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
                            'لا توجد كروت مصطادة حتى الآن',
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
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
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

  // ===========================================================================
  // التبويب الثاني: سجل الكروت المختبرة (PaginatedDataTable)
  // ===========================================================================
  Widget _buildTestedCardsView(
    BuildContext context,
    CardsProvider cardsProv,
  ) {
    final testedCards = cardsProv.testedCards;

    return Column(
      children: [
        // شريط البحث والأدوات لسجل الكروت المختبرة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              TextField(
                controller: _testedSearchCtrl,
                onChanged: (q) => cardsProv.setTestedSearchQuery(q),
                decoration: InputDecoration(
                  hintText: 'البحث في الكروت المختبرة أو رسائل الرد...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _testedSearchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _testedSearchCtrl.clear();
                            cardsProv.setTestedSearchQuery('');
                          },
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.list_alt, size: 16),
                    label: Text(
                      'إجمالي المختبر: ${cardsProv.totalTestedCount}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.primaryLight,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text(
                      'مسح سجل المختبر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _confirmClearAllTested(context, cardsProv),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // جدول البيانات المبوب
        Expanded(
          child: cardsProv.isLoadingTested
              ? const Center(child: CircularProgressIndicator())
              : testedCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_outlined,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'سجل الكروت المختبرة فارغ حتى الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 36),
                      child: PaginatedDataTable(
                        header: const Text(
                          'سجل الفحص والاختبار الشامل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        rowsPerPage: _rowsPerPage,
                        availableRowsPerPage: const [25, 50, 100],
                        onRowsPerPageChanged: (val) {
                          if (val != null) {
                            setState(() => _rowsPerPage = val);
                          }
                        },
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'رقم الكرت',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'وقت وتاريخ الفحص',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'النتيجة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'رسالة صفحة الدخول / البوابة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        source: TestedCardsTableSource(context, testedCards),
                      ),
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
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                14,
                12,
                14,
                (bottomInset > 0 ? bottomInset : 20) + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'إجراءات الكرت: ${card.cardNumber}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
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
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'فحص توفر وصلاحية الكرت',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
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
  },
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
          'تأكيد مسح كافة الكروت المصطادة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد بالتأكيد حذف كافة الكروت المصطادة نهائياً من قاعدة البيانات؟ لا يمكن التراجع عن هذا الإجراء.',
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

  void _confirmClearAllTested(BuildContext context, CardsProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تأكيد مسح سجل الكروت المختبرة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد بالتأكيد مسح كافة سجلات الكروت التي تم فحصها واختبارها؟\n\nملاحظة: هذا الإجراء لن يحذف الكروت المصطادة بنجاح المحفوظة في التبويب الأول.',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
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
              prov.clearAllTestedCards();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم مسح سجل الكروت المختبرة بنجاح 🗑️',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              );
            },
            child: const Text('مسح السجل', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // التبويب الثالث: أولوية الاتصال التلقائي (إدارة وترتيب الكروت غير المستخدمة)
  // ===========================================================================
  Widget _buildAutoLoginQueueView(
    BuildContext context,
    CardsProvider cardsProv,
    SettingsProvider settingsProv,
    EngineProvider engineProv,
  ) {
    final queue = cardsProv.unusedQueue;
    final isHunting = engineProv.isRunning;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String statusBannerText;
    Color statusBannerColor;
    IconData statusBannerIcon;

    if (isHunting) {
      statusBannerText =
          'متوقف مؤقتاً لأن محرك الفحص والاصطياد قيد التشغيل حالياً';
      statusBannerColor = AppColors.warning;
      statusBannerIcon = Icons.shield_outlined;
    } else if (queue.isEmpty) {
      statusBannerText =
          'لا توجد كروت مصطادة غير مستخدمة جاهزة للاتصال التلقائي حالياً';
      statusBannerColor = AppColors.danger;
      statusBannerIcon = Icons.info_outline_rounded;
    } else {
      statusBannerText =
          'نشط ومستعد 🟢 — الكرت القادم للاتصال التلقائي (#1): ${queue.first.cardNumber}';
      statusBannerColor = AppColors.success;
      statusBannerIcon = Icons.bolt_rounded;
    }

    return Column(
      children: [
        // 1. بطاقة حالة وتحكم الاتصال التلقائي
        Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statusBannerColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusBannerColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      statusBannerIcon,
                      color: statusBannerColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ترتيب أولوية الاتصال التلقائي بالشبكة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusBannerText,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusBannerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (cardsProv.isAutoLoggingIn ||
                  cardsProv.autoLoginStatus.isNotEmpty) ...[
                const Divider(height: 14),
                Row(
                  children: [
                    if (cardsProv.isAutoLoggingIn) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        cardsProv.autoLoginStatus,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (queue.isNotEmpty && !isHunting) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'اسحب الكرت للأعلى أو الأسفل لتحديد ترتيب الاتصال عند انتهاء الرصيد، أو ارفعه للمركز #1.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.wifi_rounded, size: 15),
                      label: const Text(
                        'اتصال تلقائي الآن',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      onPressed: cardsProv.isAutoLoggingIn
                          ? null
                          : () async {
                              final logsProv = context.read<LogsProvider>();
                              final effectiveSettings = settingsProv.settings
                                  .copyWith(autoLoginWithHuntedCards: true);
                              final connectedNum = await cardsProv
                                  .triggerAutoLoginIfNeeded(
                                    config: effectiveSettings,
                                    isEngineRunning: engineProv.isRunning,
                                    forceAttempt: true,
                                    onLog: (m) => logsProv.addLog(m),
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    connectedNum != null
                                        ? '🎉 تم الاتصال بنجاح عبر الكرت: $connectedNum وتحويله إلى مستخدم!'
                                        : '❌ تعذر الاتصال بأي كرت من القائمة حالياً',
                                    style: const TextStyle(fontFamily: 'Cairo'),
                                  ),
                                  backgroundColor: connectedNum != null
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // 2. قائمة السحب والإفلات لترتيب الكروت غير المستخدمة
        Expanded(
          child: queue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.playlist_add_check_circle_outlined,
                        size: 58,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'لا توجد كروت جاهزة للاتصال التلقائي حالياً',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'الكروت المصطادة غير المستخدمة ستظهر هنا تلقائياً لترتيب أولوية الاتصال بها.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: queue.length,
                  onReorderItem: (oldIndex, newIndex) {
                    cardsProv.reorderUnusedCards(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final card = queue[index];
                    final isFirst = index == 0;

                    return Card(
                      key: ValueKey('queue_card_${card.id ?? card.cardNumber}'),
                      elevation: isFirst ? 2.5 : 1,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isFirst
                              ? AppColors.success.withValues(alpha: 0.65)
                              : Colors.grey.withValues(alpha: 0.2),
                          width: isFirst ? 1.6 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isFirst
                                ? AppColors.success
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isFirst
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                              if (isFirst)
                                const Text(
                                  'القادم',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 8.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                card.cardNumber,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isFirst)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'الأولوية الأولى ⭐',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'تاريخ الاصطياد: ${card.foundAt}'
                            '${card.notes.isNotEmpty ? ' • ${card.notes}' : ''}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isFirst && card.id != null)
                              IconButton(
                                tooltip: 'رفع للأولوية الأولى (#1)',
                                icon: const Icon(
                                  Icons.vertical_align_top_rounded,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  cardsProv.moveCardToTopPriority(card.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'تم رفع الكرت ${card.cardNumber} إلى الأولوية الأولى (#1) ⭐',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            IconButton(
                              tooltip: 'الاتصال بهذا الكرت فوراً',
                              icon: const Icon(
                                Icons.wifi_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                              onPressed: () async {
                                final ok =
                                    await cardsProv.loginAndConnectWithCard(
                                      card,
                                      settingsProv.settings,
                                      isAutoLogin: true,
                                    );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? '🎉 تم الاتصال بالكرت ${card.cardNumber} وتحويله إلى مستخدم!'
                                          : '❌ تعذر الاتصال بالكرت ${card.cardNumber}',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    backgroundColor: ok
                                        ? AppColors.success
                                        : AppColors.danger,
                                  ),
                                );
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// =============================================================================
// DataTableSource المخصص لسجل الكروت المختبرة بتنسيق احترافي وتمييز لوني
// =============================================================================
class TestedCardsTableSource extends DataTableSource {
  final BuildContext context;
  final List<TestedCardModel> items;

  TestedCardsTableSource(this.context, this.items);

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final item = items[index];
    final isSuccess = item.status == 'success';
    final isLast = item.isLastTested;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // تلوين خلفية الصف: أخضر خفيف للناجح، أحمر خفيف للفاشل، وأزرق مميز لآخر رقم مفحوص
    Color rowBgColor;
    if (isLast) {
      rowBgColor = isDark
          ? AppColors.primary.withValues(alpha: 0.28)
          : AppColors.primaryLight.withValues(alpha: 0.75);
    } else if (isSuccess) {
      rowBgColor = isDark
          ? AppColors.success.withValues(alpha: 0.15)
          : AppColors.successLight.withValues(alpha: 0.6);
    } else {
      rowBgColor = isDark
          ? AppColors.danger.withValues(alpha: 0.12)
          : AppColors.dangerLight.withValues(alpha: 0.5);
    }

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.all(rowBgColor),
      cells: [
        // 1. رقم الكرت مع شارة "آخر مفحوص"
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                item.cardNumber,
                style: TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLast
                      ? AppColors.primary
                      : (isSuccess ? AppColors.success : AppColors.danger),
                ),
              ),
              if (isLast) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🎯 آخر مفحوص',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. الوقت والتاريخ
        DataCell(
          Text(
            item.testedAt,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ),

        // 3. النتيجة (ناجح / فاشل)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSuccess
                  ? (isDark
                      ? AppColors.success.withValues(alpha: 0.25)
                      : AppColors.successLight)
                  : (isDark
                      ? AppColors.danger.withValues(alpha: 0.25)
                      : AppColors.dangerLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isSuccess ? '✅ ناجح' : '❌ فاشل',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSuccess ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
        ),

        // 4. رسالة البوابة / صفحة تسجيل الدخول
        DataCell(
          Tooltip(
            message: item.portalMessage,
            child: SizedBox(
              width: 180,
              child: Text(
                item.portalMessage.isEmpty ? '-' : item.portalMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade300 : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => 0;
}
