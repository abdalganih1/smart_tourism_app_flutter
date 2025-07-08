// lib/screens/Questions.dart
import 'package:flutter/material.dart';

// تأكد من أن هذه الألوان معرفة ومتاحة
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);


class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<Map<String, String>> faqs = [
    {"question": "كيف يمكنني إجراء حجز؟", "answer": "يمكنك إجراء حجز عبر الصفحة الرئيسية أو قائمة الفنادق من خلال قسم الحجوزات، أو مباشرة من صفحة تفاصيل الفندق/المنتج الذي ترغب به."},
    {"question": "ما هي طرق الدفع المتاحة؟", "answer": "ندعم الدفع باستخدام البطاقات الائتمانية الرئيسية (فيزا، ماستركارد)، أو الدفع عند الوصول لبعض الخدمات والمنتجات، أو عبر بوابات دفع محلية متوفرة في سوريا."},
    {"question": "كيف أحصل على خصومات وعروض على الحجوزات والمنتجات؟", "answer": "يمكنك متابعة قسم 'العروض الحصرية' في الصفحة الرئيسية، أو الاشتراك في قائمتنا البريدية لتصلك أحدث الخصومات والعروض الخاصة أولاً بأول."},
    {"question": "هل يمكنني إلغاء أو تعديل الحجز؟", "answer": "نعم، يمكنك إلغاء حجز الفندق من صفحة 'الفواتير والحجوزات' ضمن حسابك، عادةً قبل موعد الوصول بـ 24 أو 48 ساعة حسب سياسة الفندق. تعديل الحجز يتطلب التواصل مع الدعم الفني."},
    {"question": "ما هي الوجهات السياحية المتوفرة في التطبيق؟", "answer": "يتوفر لدينا دليل شامل للعديد من الوجهات السياحية في سوريا، بما في ذلك المواقع التاريخية، الطبيعية، الثقافية، والترفيهية في مختلف المحافظات. يمكنك استكشافها من قسم 'استكشف'."},
    {"question": "كيف يمكنني التواصل مع الدعم الفني؟", "answer": "يمكنك التواصل مع فريق الدعم الفني عبر البريد الإلكتروني الموضح في صفحة 'حول التطبيق' أو من خلال خيار 'اتصل بنا' إذا كان متوفراً ضمن حسابك."},
    {"question": "هل يوفر التطبيق معلومات عن الأحوال الجوية في الوجهات؟", "answer": "نعم، يوفر التطبيق قسم خاص 'الطقس' يمكنك من خلاله الاطلاع على توقعات الطقس في المدن السورية الرئيسية لمساعدتك في التخطيط لرحلتك."},
  ];

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    List<Map<String, String>> filteredFAQs = faqs
        .where((faq) =>
            (faq["question"]?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (faq["answer"]?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false))
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأسئلة الشائعة'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: "ابحث في الأسئلة...",
                  hintText: "مثال: حجز، دفع، إلغاء...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                  filled: true,
                  fillColor: kSurfaceColor,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredFAQs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                            const SizedBox(height: 20),
                            Text(
                              "لا توجد نتائج مطابقة لبحثك.",
                              style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "حاول البحث بكلمات مفتاحية أخرى.",
                              style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredFAQs.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                filteredFAQs[index]["question"]!,
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
                                textAlign: TextAlign.right,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                                  child: Text(
                                    filteredFAQs[index]["answer"]!,
                                    style: textTheme.bodyLarge,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}