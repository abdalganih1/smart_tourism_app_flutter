// lib/screens/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/repositories/user_repository.dart';
import 'package:smart_tourism_app/models/user.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart'; // تأكد من هذا الاستيراد

const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kTextColor = Color(0xFF2D3436);
const Color kErrorColor = Color(0xFFE74C3C);
const Color kSuccessColor = Color(0xFF2ECC71);

class EditProfilePage extends StatefulWidget {
  final User user; // المستخدم الحالي لتعبئة الحقول

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>(); // مفتاح التحقق من صحة النموذج
  // لا نحتاج لمتحكمات لـ username و email إذا لم يتم تعديلهما هنا
  // late TextEditingController _usernameController;
  // late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _bioController;

  bool _isSaving = false; // حالة حفظ البيانات

  @override
  void initState() {
    super.initState();
    // تهيئة المتحكمات بالبيانات الحالية للمستخدم
    // _usernameController = TextEditingController(text: widget.user.username);
    // _emailController = TextEditingController(text: widget.user.email);
    _firstNameController = TextEditingController(text: widget.user.profile?.firstName);
    _lastNameController = TextEditingController(text: widget.user.profile?.lastName);
    _bioController = TextEditingController(text: widget.user.profile?.bio);
  }

  @override
  void dispose() {
    // _usernameController.dispose();
    // _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // إذا كان النموذج غير صالح، لا تفعل شيئاً
    }

    setState(() { _isSaving = true; });

    try {
      final userRepo = Provider.of<UserRepository>(context, listen: false);
      
      // بناء بيانات الملف الشخصي المراد تحديثها
      // نرسل فقط الحقول التي يتعامل معها PUT /api/profile في Backend
      final Map<String, dynamic> updatedData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        // أرسل bio كـ null إذا كان فارغاً ليتطابق مع قاعدة البيانات إذا كانت تقبل null
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        
        // father_name و mother_name يمكن إضافتهما هنا إذا كانت لديك حقول إدخال لهما
      };

      await userRepo.updateMyProfile(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح!'), backgroundColor: kSuccessColor),
        );
        // إرجاع 'true' لصفحة الملف الشخصي للإشارة إلى ضرورة تحديث البيانات
        Navigator.pop(context, true); 
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'خطأ في التحقق من البيانات.'), backgroundColor: kErrorColor),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الملف الشخصي: ${e.message}'), backgroundColor: kErrorColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}.'), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الملف الشخصي'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المعلومات الشخصية',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الأول',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                   validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم الأول';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الأخير',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم الأخير';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'السيرة الذاتية (اختياري)',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _isSaving
                      ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                      : ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('حفظ التغييرات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}