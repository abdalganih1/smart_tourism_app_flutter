// lib/screens/change_password_page.dart
import 'package:flutter/material.dart';
// import 'package:provider/provider';
import 'package:provider/provider.dart';
// import 'package:smart_tourism_app/repositories/auth_repository.dart'; // لم تعد بحاجة لهذا الاستيراد هنا
import 'package:smart_tourism_app/repositories/user_repository.dart'; // <<--- استخدم UserRepository
import 'package:smart_tourism_app/utils/api_exceptions.dart'; // تأكد من هذا الاستيراد

const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kTextColor = Color(0xFF2D3436);
const Color kErrorColor = Color(0xFFE74C3C);
const Color kSuccessColor = Color(0xFF2ECC71);

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isChangingPassword = true; });

    try {
      // FIX: استخدم UserRepository لتغيير كلمة المرور
      final userRepo = Provider.of<UserRepository>(context, listen: false); 
      await userRepo.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmNewPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح!'), backgroundColor: kSuccessColor),
        );
        Navigator.pop(context); // العودة للخلف بعد التغيير الناجح
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'خطأ في التحقق من البيانات المدخلة.'), backgroundColor: kErrorColor),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تغيير كلمة المرور: ${e.message}'), backgroundColor: kErrorColor),
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
        setState(() { _isChangingPassword = false; });
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
          title: const Text('تغيير كلمة المرور'),
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
                  'تغيير كلمة المرور الخاصة بك',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                    ),
                  ),
                  obscureText: _obscureCurrentPassword,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور الحالية';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_open_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                  ),
                  obscureText: _obscureNewPassword,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة مرور جديدة';
                    }
                    if (value.length < 8) {
                      return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmNewPasswordController,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmNewPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmNewPassword = !_obscureConfirmNewPassword),
                    ),
                  ),
                  obscureText: _obscureConfirmNewPassword,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور الجديدة';
                    }
                    if (value != _newPasswordController.text) {
                      return 'كلمة المرور الجديدة غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _isChangingPassword
                      ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                      : ElevatedButton.icon(
                          onPressed: _changePassword,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('تغيير كلمة المرور'),
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