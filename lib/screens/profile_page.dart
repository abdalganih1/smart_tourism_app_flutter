// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // لاستيراد الصور
import 'dart:io'; // لتمثيل الملف File

import 'package:smart_tourism_app/repositories/user_repository.dart';
import 'package:smart_tourism_app/repositories/auth_repository.dart'; // For logout
import 'package:smart_tourism_app/models/user.dart'; // User model
import 'package:smart_tourism_app/models/user_profile.dart'; // UserProfile model
import 'package:smart_tourism_app/utils/api_exceptions.dart'; // For error handling
import 'package:smart_tourism_app/screens/edit_profile_page.dart'; // الصفحة لتعديل البيانات النصية
import 'package:smart_tourism_app/screens/change_password_page.dart'; // الصفحة لتغيير كلمة المرور

// تأكد من أن هذه الألوان معرفة ومتاحة، يفضل أن تكون في ملف ثوابت مشترك
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker(); // لـ ImagePicker

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // This method will be called when returning from EditProfilePage to refresh data
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Use UserRepository to get the full profile, as it calls /api/profile
      final userRepo = Provider.of<UserRepository>(context, listen: false);
      final user = await userRepo.getMyFullProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } on ApiException catch (e) {
      print('API Error fetching profile: ${e.statusCode} - ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on NetworkException catch (e) {
      print('Network Error fetching profile: ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      print('Unexpected Error fetching profile: ${e.toString()}');
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل معلومات الملف الشخصي.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      await authRepo.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الخروج بنجاح'), backgroundColor: kSuccessColor),
        );
        // PushReplacementNamed لمنع العودة لصفحة الملف الشخصي بعد تسجيل الخروج
        Navigator.pushReplacementNamed(context, '/login'); 
      }
    } on ApiException catch (e) {
      print('API Error during logout: ${e.statusCode} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تسجيل الخروج: ${e.message}'), backgroundColor: kErrorColor),
        );
      }
    } catch (e) {
      print('Unexpected Error during logout: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع أثناء تسجيل الخروج.'), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // دالة لاختيار صورة الملف الشخصي ورفعها
  Future<void> _pickAndUploadProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return; // المستخدم ألغى الاختيار

    setState(() {
      _isLoading = true; // يمكن أن نستخدم مؤشر تحميل خاص لرفع الصورة
    });

    try {
      final userRepo = Provider.of<UserRepository>(context, listen: false);
      
      // FIX: استدعاء الدالة المخصصة لتحديث الصورة فقط
      final response = await userRepo.updateProfilePicture(File(image.path));
      
      // بعد الرفع الناجح، قم بتحديث واجهة المستخدم برابط الصورة الجديد
      if (mounted) {
        setState(() {
          // الـ API يرجع رابط الصورة الجديد، لذلك نقوم بتحديث المودل المحلي
          if (_currentUser != null && _currentUser!.profile != null) {
            // إعادة بناء الكائن User لتحديث رابط الصورة
            _currentUser = User(
              id: _currentUser!.id,
              username: _currentUser!.username,
              email: _currentUser!.email,
              userType: _currentUser!.userType,
              isActive: _currentUser!.isActive,
              createdAt: _currentUser!.createdAt,
              updatedAt: DateTime.now(), // أو استخدام updatedAt من الـ API إذا أرسلها
              profile: UserProfile(
                id: _currentUser!.profile!.id,
                userId: _currentUser!.profile!.userId,
                firstName: _currentUser!.profile!.firstName,
                lastName: _currentUser!.profile!.lastName,
                bio: _currentUser!.profile!.bio,
                // تحديث رابط الصورة من استجابة الـ API
                profilePictureUrl: response['profile_picture_url'] as String?,
                createdAt: _currentUser!.profile!.createdAt,
                updatedAt: DateTime.now(),
              ),
              phoneNumbers: _currentUser!.phoneNumbers,
            );
          } else {
            // إذا لم يكن هناك ملف شخصي، أعد جلب كل البيانات من الخادم
            _fetchUserProfile();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث صورة الملف الشخصي بنجاح!'), backgroundColor: kSuccessColor),
        );
      }
    } on ApiException catch (e) {
      print('API Error uploading profile picture: ${e.statusCode} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الصورة: ${e.message}'), backgroundColor: kErrorColor),
        );
      }
    } catch (e) {
      print('Unexpected Error uploading profile picture: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع أثناء رفع الصورة.'), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _navigateToEditProfile() async {
    if (_currentUser == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: _currentUser!),
      ),
    );
    // إذا عادت صفحة التعديل بنتيجة (عادة true بعد الحفظ الناجح)، نقوم بتحديث الملف الشخصي
    if (result == true) {
      _fetchUserProfile();
    }
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordPage(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: _isLoading && _currentUser == null 
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: kErrorColor),
                          const SizedBox(height: 15),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(color: kErrorColor),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchUserProfile,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _currentUser == null // إذا كان التحميل قد انتهى و_currentUser لا يزال null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                              const SizedBox(height: 20),
                              Text(
                                'تعذر تحميل بيانات المستخدم.',
                                style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'الرجاء التأكد من تسجيل الدخول أو المحاولة لاحقاً.',
                                style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView( // Use SingleChildScrollView for scrollable content
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // User Image
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: kSurfaceColor,
                                  backgroundImage: (_currentUser!.profile?.imageUrl != null && _currentUser!.profile!.imageUrl!.isNotEmpty)
                                      ? NetworkImage(_currentUser!.profile!.imageUrl!) as ImageProvider
                                      : const AssetImage('assets/user.png'), // Default asset image
                                  onBackgroundImageError: (exception, stackTrace) {
                                    print('Error loading profile picture: $exception');
                                    // يمكنك عرض صورة بديلة هنا إذا فشل تحميل الصورة
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                                      onPressed: _pickAndUploadProfilePicture, // ربط الزر بدالة اختيار ورفع الصورة
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // User Name
                            Text(
                              _currentUser!.profile?.fullName ?? _currentUser!.username,
                              style: textTheme.headlineMedium?.copyWith(color: kTextColor, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // User Email
                            Text(
                              _currentUser!.email,
                              style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                            if (_currentUser!.profile?.bio != null && _currentUser!.profile!.bio!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                  _currentUser!.profile!.bio!,
                                  style: textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 32),

                            // Edit Profile Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _navigateToEditProfile, // ربط الزر بدالة الانتقال
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('تعديل الملف الشخصي'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Change Password Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _navigateToChangePassword, // ربط الزر بدالة الانتقال
                                icon: const Icon(Icons.lock_reset_outlined),
                                label: const Text('تغيير كلمة المرور'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _logout, // ربط الزر بدالة تسجيل الخروج
                                icon: const Icon(Icons.logout_outlined),
                                label: const Text('تسجيل الخروج'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kErrorColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}