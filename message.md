لقد قمت بإجراء تعديل قد يحل مشكلة الخطأ `500` عند إضافة منتج إلى السلة.

**سبب المشكلة المحتمل:**
أحياناً، تتوقع الخوادم استلام البيانات بتنسيق `form-urlencoded` بدلاً من `JSON`. الخطأ `500` قد يكون ناتجاً عن عدم قدرة الخادم على معالجة تنسيق JSON الذي كان يرسله التطبيق.

**الإصلاح الذي قمت به:**
1.  **تغيير تنسيق الإرسال:** قمت بتعديل الكود في `api_service.dart` و `shopping_cart_repository.dart` لإرسال بيانات "إضافة إلى السلة" بتنسيق `application/x-www-form-urlencoded`.

**ماذا يعني هذا؟**
هذا التغيير هو محاولة لمطابقة التنسيق الذي قد يتوقعه الخادم. إذا نجح هذا الإصلاح، فهذا يعني أن المشكلة كانت في طريقة إرسال البيانات. إذا استمر الخطأ، فهذا يؤكد أن المشكلة على الأرجح في كود الخادم نفسه وتحتاج إلى مراجعة هناك.

يرجى إعادة تشغيل التطبيق وتجربة إضافة منتج إلى السلة مرة أخرى.