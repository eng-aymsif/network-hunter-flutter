import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:networking/core/constants/app_colors.dart';
import 'package:networking/presentation/providers/cards_provider.dart';

class CardsTab extends StatelessWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cardsProv = context.watch<CardsProvider>();
    final cards = cardsProv.cards;

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
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => cardsProv.setSearchQuery(''),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    children: [
                      Chip(
                        label: Text(
                          'الإجمالي: ${cardsProv.totalCount}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: Theme.of(context).brightness ==
                                Brightness.dark
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 6),
                      Chip(
                        label: Text(
                          'غير مستخدم: ${cardsProv.unusedCount}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.success,
                          ),
                        ),
                        backgroundColor: Theme.of(context).brightness ==
                                Brightness.dark
                            ? AppColors.success.withValues(alpha: 0.18)
                            : AppColors.successLight,
                      ),
                    ],
                  ),
                  Wrap(
                    children: [
                      IconButton(
                        tooltip: 'تصدير كـ CSV',
                        icon: const Icon(Icons.file_download, color: AppColors.primary),
                        onPressed: () => cardsProv.exportCards(asCsv: true),
                      ),
                      IconButton(
                        tooltip: 'مشاركة كـ TXT',
                        icon: const Icon(Icons.share, color: AppColors.accent),
                        onPressed: () => cardsProv.exportCards(asCsv: false),
                      ),
                      IconButton(
                        tooltip: 'مسح كافة الكروت',
                        icon: const Icon(Icons.delete_sweep, color: AppColors.danger),
                        onPressed: () => _confirmClearAll(context, cardsProv),
                      ),
                    ],
                  ),
                ],
              ),
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
                          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد كروت مكتشفة حتى الآن',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: cards.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final card = cards[index];

                        return Card(
                          elevation: 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onDoubleTap: () {
                              if (card.id != null) {
                                cardsProv.toggleUsed(card.id!);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            card.isUsed ? Icons.check_circle : Icons.radio_button_unchecked,
                                            color: card.isUsed ? Colors.grey : AppColors.success,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          SelectableText(
                                            card.cardNumber,
                                            style: TextStyle(
                                              fontFamily: 'Consolas',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: card.isUsed ? Colors.grey : AppColors.primary,
                                              decoration: card.isUsed ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: card.isUsed ? Colors.grey.shade200 : AppColors.successLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          card.isUsed ? '✅ مستخدم' : '⭕ غير مستخدم',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: card.isUsed ? Colors.grey.shade700 : AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'التاريخ: ${card.foundAt}',
                                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'تبديل حالة الاستخدام',
                                            icon: Icon(card.isUsed ? Icons.undo : Icons.check, size: 18, color: AppColors.primary),
                                            onPressed: () {
                                              if (card.id != null) cardsProv.toggleUsed(card.id!);
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'نسخ الرقم',
                                            icon: const Icon(Icons.copy, size: 18, color: AppColors.accent),
                                            onPressed: () {
                                              cardsProv.copyCardNumber(card.cardNumber);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('تم نسخ الرقم: ${card.cardNumber}', style: const TextStyle(fontFamily: 'Cairo')),
                                                  duration: const Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'حذف',
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                            onPressed: () {
                                              if (card.id != null) {
                                                _confirmDeleteCard(context, cardsProv, card.id!, card.cardNumber);
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

  void _confirmDeleteCard(BuildContext context, CardsProvider prov, int cardId, String cardNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف الكرت رقم "$cardNum" من قاعدة البيانات؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
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

  void _confirmClearAll(BuildContext context, CardsProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد مسح كافة الكروت', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: const Text('هل تريد بالتأكيد حذف كافة الكروت المكتشفة نهائياً من قاعدة البيانات؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
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
