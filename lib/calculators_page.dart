import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'mortgage_calculator_page.dart';
import 'roi_calculator_page.dart';
import 'purchase_costs_calculator_page.dart';
import 'affordability_calculator_page.dart';
import 'rent_calculator_page.dart';
import 'unit_converter_page.dart';
import 'savings_calculator_page.dart';
import 'loan_calculator_page.dart';
import 'salary_calculator_page.dart';
import 'construction_cost_calculator_page.dart';
import 'finishing_cost_calculator_page.dart';

class CalculatorsPage extends StatelessWidget {
  const CalculatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    final calculators = [
      {
        'title': 'حاسبة التمويل العقاري',
        'subtitle': 'احسب القسط الشهري والفوائد',
        'icon': Icons.calculate,
        'color': const Color(0xFF10b981),
        'page': const MortgageCalculatorPage(),
      },
      {
        'title': 'حاسبة العائد على الاستثمار',
        'subtitle': 'احسب ربحية الاستثمار العقاري',
        'icon': Icons.trending_up,
        'color': const Color(0xFF3b82f6),
        'page': const ROICalculatorPage(),
      },
      {
        'title': 'حاسبة تكاليف الشراء',
        'subtitle': 'احسب جميع رسوم شراء العقار',
        'icon': Icons.receipt_long,
        'color': const Color(0xFFf59e0b),
        'page': const PurchaseCostsCalculatorPage(),
      },
      {
        'title': 'حاسبة القدرة الشرائية',
        'subtitle': 'اعرف أقصى سعر عقار يمكنك شراؤه',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFFef4444),
        'page': const AffordabilityCalculatorPage(),
      },
      {
        'title': 'حاسبة الإيجار المثالي',
        'subtitle': 'احسب الإيجار المناسب لعقارك',
        'icon': Icons.home_work,
        'color': const Color(0xFF8b5cf6),
        'page': const RentCalculatorPage(),
      },
      {
        'title': 'محول الوحدات',
        'subtitle': 'حول بين وحدات المساحة المختلفة',
        'icon': Icons.straighten,
        'color': const Color(0xFF06b6d4),
        'page': const UnitConverterPage(),
      },
      {
        'title': 'حاسبة الادخار',
        'subtitle': 'خطط لمستقبلك المالي',
        'icon': Icons.savings,
        'color': const Color(0xFF10b981),
        'page': const SavingsCalculatorPage(),
      },
      {
        'title': 'حاسبة القرض الشخصي',
        'subtitle': 'احسب قسط القرض الشخصي',
        'icon': Icons.credit_card,
        'color': const Color(0xFFec4899),
        'page': const LoanCalculatorPage(),
      },
      {
        'title': 'حاسبة الراتب الصافي',
        'subtitle': 'احسب راتبك بعد الخصومات',
        'icon': Icons.payments,
        'color': const Color(0xFF6366f1),
        'page': const SalaryCalculatorPage(),
      },
      {
        'title': 'حاسبة تكلفة البناء',
        'subtitle': 'قدّر تكلفة بناء عقارك',
        'icon': Icons.construction,
        'color': const Color(0xFFf97316),
        'page': const ConstructionCostCalculatorPage(),
      },
      {
        'title': 'حاسبة تكلفة التشطيب',
        'subtitle': 'احسب تكلفة تشطيب العقار',
        'icon': Icons.brush,
        'color': const Color(0xFFa855f7),
        'page': const FinishingCostCalculatorPage(),
      },
    ];

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calculate, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'الحاسبات والأدوات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: calculators.length,
        itemBuilder: (context, index) {
          final calc = calculators[index];
          return _buildCalculatorCard(
            context,
            theme,
            calc['title'] as String,
            calc['subtitle'] as String,
            calc['icon'] as IconData,
            calc['color'] as Color,
            calc['page'] as Widget,
          );
        },
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context,
    ThemeConfig theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: theme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

