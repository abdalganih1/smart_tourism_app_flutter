// lib/screens/advice.dart
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


class TravelTipsPage extends StatelessWidget {
   TravelTipsPage({super.key});

  final List<Map<String, String>> travelTips = [
    {
      "title": "أفضل الأوقات لزيارة سوريا",
      "content":
          "تتمتع سوريا بمناخ متنوع، ولكن أفضل وقت لزيارة معظم المناطق يكون بين مارس ومايو (الربيع) أو سبتمبر وأكتوبر (الخريف) حيث تكون الأجواء معتدلة ومناسبة للاستكشاف. الصيف حار في المناطق الداخلية، والشتاء بارد ومثلج في الجبال."
    },
    {
      "title": "نصائح لتجهيز حقيبتك",
      "content":
          "احرص على أخذ ملابس مريحة ومناسبة للموسم، أحذية مريحة للمشي واستكشاف المواقع التاريخية. لا تنس واقي الشمس وقبعة في الصيف، ومعطفاً دافئاً في الشتاء. الأدوية الأساسية الخاصة بك ووثائق السفر (جواز السفر، التأشيرة، التذاكر) يجب أن تكون في متناول اليد."
    },
    {
      "title": "كيف تتعامل مع الثقافة المحلية",
      "content":
          "تعد الثقافة السورية غنية ودافئة. تعلم بعض الكلمات الأساسية باللغة العربية (مثل شكراً، من فضلك، صباح الخير) سيترك انطباعاً جيداً. احترم التقاليد المحلية، وارتدِ ملابس محتشمة عند زيارة الأماكن الدينية. تقبل الضيافة السورية المعروفة وكرم أهلها."
    },
    {
      "title": "النصائح الصحية والسلامة أثناء السفر",
      "content":
          "اشرب الماء المعبأ فقط، وتجنب الأطعمة غير المطهية جيداً أو التي تباع في أماكن غير نظيفة. احرص على غسل يديك بانتظام واستخدام معقم اليدين. احمل معك مجموعة إسعافات أولية صغيرة. كن على دراية بمحيطك وتجنب المناطق النائية ليلاً."
    },
    {
      "title": "كيفية الوصول إلى الأماكن السياحية والتنقل",
      "content":
          "يمكنك استخدام وسائل النقل المحلية مثل الحافلات العامة أو سيارات الأجرة (التكاسي) للتنقل داخل المدن. للتنقل بين المدن، تتوفر حافلات نقل داخلية مريحة. يمكن أيضاً الاستفسار عن خدمات النقل الخاصة أو تنظيم الجولات مع شركات سياحية محلية."
    },
    {
      "title": "العملة المحلية وطرق الدفع",
      "content":
          "العملة المحلية هي الليرة السورية. يُنصح بحمل بعض النقود المحلية معك، خاصة في الأسواق التقليدية والأماكن الصغيرة. بطاقات الائتمان قد لا تكون مقبولة في جميع الأماكن، لذا استفسر دائماً مسبقاً."
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نصائح وإرشادات السفر'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: travelTips.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                      const SizedBox(height: 20),
                      Text(
                        'لا توجد نصائح سفر متاحة حالياً.',
                        style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تابعنا للحصول على أحدث الإرشادات قبل رحلتك القادمة.',
                        style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: travelTips.length,
                itemBuilder: (context, index) {
                  final tip = travelTips[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(Icons.info_outline, color: kPrimaryColor, size: 28),
                      title: Text(
                        tip["title"]!,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.right,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                          child: Text(
                            tip["content"]!,
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
    );
  }
}