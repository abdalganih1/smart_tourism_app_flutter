// lib/screens/tourist_site_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl; // لتنسيق التاريخ والوقت
import 'package:url_launcher/url_launcher.dart'; // لفتح الخرائط
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // للتقييمات
import 'package:image_picker/image_picker.dart'; // <<--- لاستيراد الصور
import 'dart:io'; // <<--- لتمثيل الملف File

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/repositories/interaction_repository.dart';
import 'package:smart_tourism_app/repositories/auth_repository.dart'; // For current user info
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/tourist_site.dart';
import 'package:smart_tourism_app/models/rating.dart';
import 'package:smart_tourism_app/models/comment.dart';
import 'package:smart_tourism_app/models/site_experience.dart'; // <<--- استيراد مودل التجربة السياحية
import 'package:smart_tourism_app/models/user.dart'; // To display user info in ratings/comments
import 'package:smart_tourism_app/models/pagination.dart';
import 'package:smart_tourism_app/utils/constants.dart'; // For TargetTypes

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

class TouristSiteDetailsPage extends StatefulWidget {
  final int siteId;

  const TouristSiteDetailsPage({super.key, required this.siteId});

  @override
  State<TouristSiteDetailsPage> createState() => _TouristSiteDetailsPageState();
}

class _TouristSiteDetailsPageState extends State<TouristSiteDetailsPage> {
  // Main page state
  TouristSite? _site;
  bool _isLoading = true; // Start with loading true for initial fetch
  String? _errorMessage;
  bool _isFavorited = false;

  // Ratings section state
  final List<Rating> _ratings = [];
  int _ratingsCurrentPage = 1;
  bool _canLoadMoreRatings = true;
  final ScrollController _ratingsScrollController = ScrollController();
  double _overallRating = 0.0;
  int _totalReviews = 0;

  // Comments section state
  final List<Comment> _comments = [];
  int _commentsCurrentPage = 1;
  bool _canLoadMoreComments = true;
  final ScrollController _commentsScrollController = ScrollController();

  // Site Experiences section state <<<< NEW
  final List<SiteExperience> _experiences = [];
  int _experiencesCurrentPage = 1;
  bool _canLoadMoreExperiences = true;
  final ScrollController _experiencesScrollController = ScrollController();

  // New review/comment/experience state
  final TextEditingController _reviewTitleController = TextEditingController();
  final TextEditingController _reviewTextController = TextEditingController();
  final TextEditingController _commentTextController = TextEditingController();
  final TextEditingController _experienceTitleController = TextEditingController(); // <<<< NEW
  final TextEditingController _experienceContentController = TextEditingController(); // <<<< NEW
  File? _pickedExperiencePhoto; // <<<< NEW
  final ImagePicker _picker = ImagePicker(); // <<<< NEW
  double _newRatingValue = 0;
  int? _replyToCommentId;

  // Submission loading states for review and comment forms
  bool _isSubmittingReview = false;
  bool _isSubmittingComment = false;
  bool _isSubmittingExperience = false; // <<<< NEW

  // User state
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Add listeners here, after the widget is built (addPostFrameCallback) or in initState
    _ratingsScrollController.addListener(_onRatingsScroll);
    _commentsScrollController.addListener(_onCommentsScroll);
    _experiencesScrollController.addListener(_onExperiencesScroll); // <<<< NEW
  }

  @override
  void dispose() {
    _ratingsScrollController.dispose();
    _commentsScrollController.dispose();
    _experiencesScrollController.dispose(); // <<<< NEW
    _reviewTitleController.dispose();
    _reviewTextController.dispose();
    _commentTextController.dispose();
    _experienceTitleController.dispose(); // <<<< NEW
    _experienceContentController.dispose(); // <<<< NEW
    super.dispose();
  }

  void _onRatingsScroll() {
    // Load more ratings if scrolled to the end, more are available, and not already loading
    if (_ratingsScrollController.position.pixels == _ratingsScrollController.position.maxScrollExtent && _canLoadMoreRatings && !_isLoading) {
      _fetchRatings(page: ++_ratingsCurrentPage);
    }
  }

  void _onCommentsScroll() {
    // Load more comments if scrolled to the end, more are available, and not already loading
    if (_commentsScrollController.position.pixels == _commentsScrollController.position.maxScrollExtent && _canLoadMoreComments && !_isLoading) {
      _fetchComments(page: ++_commentsCurrentPage);
    }
  }

  void _onExperiencesScroll() { // <<<< NEW
    // Load more experiences if scrolled to the end, more are available, and not already loading
    if (_experiencesScrollController.position.pixels == _experiencesScrollController.position.maxScrollExtent && _canLoadMoreExperiences && !_isLoading) {
      _fetchExperiences(page: ++_experiencesCurrentPage);
    }
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch current user and site details first, as they are prerequisites
      await _fetchCurrentUser();
      await _fetchSiteDetails();

      // If site details are successfully fetched, proceed with other data
      if (_site != null) {
        await Future.wait([
          _fetchFavoriteStatus(),
          _fetchRatings(isRefresh: true), // Always refresh ratings on initial load
          _fetchComments(isRefresh: true), // Always refresh comments on initial load
          _fetchExperiences(isRefresh: true), // <<<< NEW: Fetch experiences on initial load
        ]);
      } else {
        // If _site is still null, throw a specific exception
        throw Exception('تعذر العثور على تفاصيل هذا الموقع.');
      }
    } on ApiException catch (e) {
      // Catch specific API errors
      _errorMessage = 'خطأ من الخادم: ${e.message}';
      print('API Error during initialization: ${e.statusCode} - ${e.message}');
    } on NetworkException catch (e) {
      // Catch network errors
      _errorMessage = 'خطأ في الشبكة: ${e.message}';
      print('Network Error during initialization: ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors
      _errorMessage = 'خطأ غير متوقع أثناء التهيئة: ${e.toString()}';
      print('Unexpected Error during initialization: ${e.toString()}');
    } finally {
      // Ensure loading state is reset regardless of success or failure
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      _currentUser = await authRepo.getAuthenticatedUser();
    } catch (e) {
      print('Could not fetch current user: $e');
      // No need to set error message here, main _initializeData will handle it.
    }
  }

  Future<void> _fetchSiteDetails() async {
    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final site = await tourismRepo.getTouristSiteDetails(widget.siteId);
      if (mounted) {
        setState(() {
          _site = site;
        });
      }
    } on ApiException catch (e) {
      // Re-throw to be caught by _initializeData's catch block
      throw e;
    } on NetworkException catch (e) {
      throw e;
    } catch (e) {
      throw e;
    }
  }

  Future<void> _fetchFavoriteStatus() async {
    // Only check favorite status if a user is logged in and site ID is available
    if (_currentUser == null || _site?.id == null) return;
    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final status = await interactionRepo.checkFavoriteStatus(TargetTypes.touristSite, _site!.id!);
      if (mounted) {
        setState(() {
          _isFavorited = status['is_favorited'];
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      // Fail silently for favorite status, as it's not critical for page display
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول لإضافة للمفضلة.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (_site?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد الموقع لإضافته للمفضلة.'), backgroundColor: kErrorColor),
      );
      return;
    }

    // Optimistic update for immediate UI feedback
    final originalFavoritedState = _isFavorited;
    setState(() { _isFavorited = !_isFavorited; });

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final result = await interactionRepo.toggleFavorite(TargetTypes.touristSite, _site!.id!);
      if (mounted) {
        setState(() {
          _isFavorited = result['is_favorited']; // Update with actual state from server
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorited ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة'),
            backgroundColor: _isFavorited ? kSuccessColor : kPrimaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isFavorited = originalFavoritedState; }); // Revert UI on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إضافة/إزالة من المفضلة: ${e.toString()}'), backgroundColor: kErrorColor),
        );
      }
      print('Error toggling favorite: $e');
    }
  }

  Future<void> _fetchRatings({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _ratingsCurrentPage = 1;
      _ratings.clear();
      _canLoadMoreRatings = true; // Reset for new fetch
      _overallRating = 0.0; // Reset overall rating
      _totalReviews = 0; // Reset total reviews
    }
    // Prevent loading if no more pages or if it's not a refresh and we can't load more
    if (!_canLoadMoreRatings && !isRefresh) return;
    if (_site?.id == null) return; // Site must be loaded

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final response = await interactionRepo.getRatingsForTarget(TargetTypes.touristSite, _site!.id!, page: page);
      if (mounted) {
        setState(() {
          // Add new data to the list
          _ratings.addAll(response.data.where((r) => r != null).toList().cast<Rating>());
          // Update pagination status
          _canLoadMoreRatings = response.meta.currentPage < response.meta.lastPage;
          // Update overall rating and total reviews from the meta/extra data
          _totalReviews = response.meta.total;
          _overallRating = response.extra?['average_rating']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print('Error fetching ratings: $e');
      // Could show a snackbar or small error message within the ratings section
    }
  }

  Future<void> _addOrUpdateReview() async {
    if (_newRatingValue == 0 || _reviewTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال تقييم ونص المراجعة.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول لإضافة تقييم.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (_site?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد الموقع لإضافة تقييم.'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() { _isSubmittingReview = true; }); // Activate specific loading indicator

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      // The addRating method should return the newly created rating object or confirmation
      final newRatingData = await interactionRepo.addRating({
        'target_type': TargetTypes.touristSite,
        'target_id': _site!.id!,
        'rating_value': _newRatingValue.round(),
        'review_title': _reviewTitleController.text.trim().isNotEmpty ? _reviewTitleController.text.trim() : null,
        'review_text': _reviewTextController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة مراجعتك بنجاح!'), backgroundColor: kSuccessColor),
        );
        _reviewTitleController.clear();
        _reviewTextController.clear();
        setState(() { _newRatingValue = 0; }); // Reset rating value

        // Refresh ratings list to show the new review and update overall average
        await _fetchRatings(isRefresh: true);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'خطأ في التحقق من البيانات.'), backgroundColor: kErrorColor));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'فشل إضافة المراجعة.'), backgroundColor: kErrorColor));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}.'), backgroundColor: kErrorColor));
      }
    } finally {
      // Always deactivate loading indicator
      if (mounted) {
        setState(() { _isSubmittingReview = false; });
      }
    }
  }

  Future<void> _fetchComments({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _commentsCurrentPage = 1;
      _comments.clear();
      _canLoadMoreComments = true; // Reset for new fetch
    }
    // Prevent loading if no more pages or if it's not a refresh and we can't load more
    if (!_canLoadMoreComments && !isRefresh) return;
    if (_site?.id == null) return; // Site must be loaded

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final response = await interactionRepo.getCommentsForTarget(TargetTypes.touristSite, _site!.id!, page: page);
      if (mounted) {
        setState(() {
          // Add new data to the list
          _comments.addAll(response.data.where((c) => c != null).toList().cast<Comment>());
          // Update pagination status
          _canLoadMoreComments = response.meta.currentPage < response.meta.lastPage;
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
      // Could show a snackbar or small error message within the comments section
    }
  }

  Future<void> _addComment() async {
    if (_commentTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال نص التعليق.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول لإضافة تعليق.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (_site?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد الموقع لإضافة تعليق.'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() { _isSubmittingComment = true; }); // Activate specific loading indicator

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      // The addComment method should return the newly created comment object or confirmation
      final newCommentData = await interactionRepo.addComment({
        'target_type': TargetTypes.touristSite,
        'target_id': _site!.id!,
        'content': _commentTextController.text.trim(),
        'parent_comment_id': _replyToCommentId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة التعليق بنجاح!'), backgroundColor: kSuccessColor),
        );
        
        _commentTextController.clear();
        setState(() {
          _replyToCommentId = null; // Reset reply state
          // Optimistic update: Add the new comment directly to the list
          if (newCommentData is Map<String, dynamic> && newCommentData.containsKey('data')) {
            final comment = Comment.fromJson(newCommentData['data']);
            _comments.insert(0, comment); // Add to the top of the list
          }
        });

        // Add a small delay (e.g., 500ms) to give the API/database time to process
        // before fetching the updated list, especially if optimistic update failed.
        await Future.delayed(const Duration(milliseconds: 500)); 
        
        // Refresh comments list to ensure full synchronization with server
        await _fetchComments(isRefresh: true);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'خطأ في التحقق من البيانات.'), backgroundColor: kErrorColor));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'فشل إضافة التعليق.'), backgroundColor: kErrorColor));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}.'), backgroundColor: kErrorColor));
      }
    } finally {
      // Always deactivate loading indicator
      if (mounted) {
        setState(() { _isSubmittingComment = false; });
      }
    }
  }

  // --- Site Experiences Methods <<<< NEW
  Future<void> _fetchExperiences({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _experiencesCurrentPage = 1;
      _experiences.clear();
      _canLoadMoreExperiences = true;
    }
    if (!_canLoadMoreExperiences && !isRefresh) return;
    if (_site?.id == null) return;

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final response = await interactionRepo.getExperiencesForTarget(TargetTypes.touristSite, _site!.id!, page: page);
      if (mounted) {
        setState(() {
          _experiences.addAll(response.data.where((e) => e != null).toList().cast<SiteExperience>());
          _canLoadMoreExperiences = response.meta.currentPage < response.meta.lastPage;
        });
      }
    } catch (e) {
      print('Error fetching experiences: $e');
      // Handle error display if necessary
    }
  }

  Future<void> _addExperience() async {
    if (_experienceTitleController.text.trim().isEmpty || _experienceContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان ومحتوى التجربة.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تسجيل الدخول لإضافة تجربة.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (_site?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد الموقع لإضافة تجربة.'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() { _isSubmittingExperience = true; });

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final newExperienceData = await interactionRepo.addExperience(
        {
          'site_id': _site!.id!, // Assuming backend takes site_id directly
          'title': _experienceTitleController.text.trim(),
          'content': _experienceContentController.text.trim(),
          // 'visit_date': intl.DateFormat('yyyy-MM-dd').format(DateTime.now()), // Optional: add current date
        },
        photoFile: _pickedExperiencePhoto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة تجربتك بنجاح!'), backgroundColor: kSuccessColor),
        );
        _experienceTitleController.clear();
        _experienceContentController.clear();
        setState(() { _pickedExperiencePhoto = null; }); // Clear picked photo

        // Optimistic update
        if (newExperienceData is Map<String, dynamic> && newExperienceData.containsKey('data')) {
          final experience = SiteExperience.fromJson(newExperienceData['data']);
          _experiences.insert(0, experience);
        }
        await _fetchExperiences(isRefresh: true); // Full refresh to ensure consistency
      }
    } on ValidationException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'خطأ في التحقق من البيانات.'), backgroundColor: kErrorColor));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'فشل إضافة التجربة.'), backgroundColor: kErrorColor));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}.'), backgroundColor: kErrorColor));
    } finally {
      if (mounted) setState(() { _isSubmittingExperience = false; });
    }
  }

  Future<void> _pickImageForExperience() async { // <<<< NEW
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedExperiencePhoto = File(image.path);
      });
    }
  }

  // Function to launch Google Maps or other navigation apps
  Future<void> _launchMapsUrl(double lat, double lon, String label) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon&query_place_id=$label';
    final Uri launchUri = Uri.parse(googleMapsUrl); // Parse to Uri for canLaunchUrl/launchUrl
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح خرائط جوجل أو تطبيق الخرائط الافتراضي.'), backgroundColor: kErrorColor),
        );
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
          title: Text(_site?.name ?? 'تفاصيل الموقع'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        // Centralized body building based on loading/error/data states
        body: _buildBody(textTheme),
      ),
    );
  }

  // Helper method to decide what to show in the body
  Widget _buildBody(TextTheme textTheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }
    if (_errorMessage != null) {
      return _buildErrorWidget(textTheme); // General error
    }
    if (_site == null || _site!.id == null || _site!.name == null) {
      // Specific error if site data is missing after loading
      return _buildErrorWidget(
        textTheme,
        message: 'تعذر العثور على تفاصيل هذا الموقع أو بياناته غير مكتملة.',
        additionalMessage: 'قد يكون الموقع غير موجود، تم حذفه، أو تضررت بياناته.',
      );
    }
    // If all checks pass, show the actual content
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Site Image / Video Section
          _buildSiteImage(textTheme, _site!.mainImageUrl, _site!.videoUrl),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site Name
                Text(
                  _site!.name!, // Safe due to previous null check
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                ),
                const SizedBox(height: 8),
                // Location and Overall Rating Row
                _buildLocationAndRatingRow(textTheme),
                const SizedBox(height: 16),
                // Action Buttons (Favorite, Directions)
                _buildActionButtons(),
                const SizedBox(height: 24),

                // Description Section
                _buildSectionTitle(textTheme, 'الوصف'),
                Text(
                  _site?.description ?? 'لا يوجد وصف متاح لهذا الموقع.', // Default text
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 32),

                // Ratings Section
                _buildRatingsSection(textTheme),
                const SizedBox(height: 32),

                // Comments Section
                _buildCommentsSection(textTheme),
                const SizedBox(height: 32),

                // Site Experiences Section <<<< NEW
                _buildExperiencesSection(textTheme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Generic error widget builder
  Widget _buildErrorWidget(TextTheme textTheme, {String? message, String? additionalMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: kErrorColor),
            const SizedBox(height: 15),
            Text(
              message ?? _errorMessage!,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: kErrorColor),
            ),
            if (additionalMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                additionalMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeData, // Retry all data fetching
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for consistent section titles
  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  // Widget for location and overall rating display
  Widget _buildLocationAndRatingRow(TextTheme textTheme) {
    return Row(
      children: [
        Icon(Icons.location_on, color: kSecondaryTextColor, size: 20),
        const SizedBox(width: 8),
        Text(
          _site!.locationText ?? (_site!.city != null ? '${_site!.city!}, سوريا' : 'سوريا'),
          style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
        ),
        const Spacer(),
        Icon(Icons.star_rounded, color: kAccentColor, size: 20),
        const SizedBox(width: 4),
        Text(
          '${_overallRating.toStringAsFixed(1)}',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          ' ($_totalReviews تقييم)',
          style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor),
        ),
      ],
    );
  }

  // Widget for action buttons (Favorite, Directions)
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            label: Text(_isFavorited ? 'بالمفضلة' : 'أضف للمفضلة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFavorited ? kPrimaryColor : kSurfaceColor,
              foregroundColor: _isFavorited ? Colors.white : kPrimaryColor,
              side: _isFavorited ? null : const BorderSide(color: kPrimaryColor, width: 1),
              elevation: _isFavorited ? 2 : 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (_site!.latitude != null && _site!.longitude != null && _site!.name != null) // Check name for launchMapsUrl
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _launchMapsUrl(_site!.latitude!, _site!.longitude!, _site!.name!),
              icon: const Icon(Icons.directions_outlined),
              label: const Text('الاتجاهات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        // TODO: Add "Book Activity" button if activities are linked
      ],
    );
  }

  // Widget for Site Image / Video
  Widget _buildSiteImage(TextTheme textTheme, String? imageUrl, String? videoUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 250,
          width: double.infinity,
          color: kSurfaceColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 60, color: kSecondaryTextColor),
                Text('صورة غير متوفرة', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
              ],
            ),
          ),
        ),
      );
    } else if (videoUrl != null && videoUrl.isNotEmpty) {
      // TODO: Implement video player for videoUrl
      return Container(
        height: 250,
        width: double.infinity,
        color: kSurfaceColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 60, color: kSecondaryTextColor),
              Text('فيديو غير متوفر (يجب إضافة مشغل)', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
            ],
          ),
        ),
      );
    } else {
      return Container(
        height: 250,
        width: double.infinity,
        color: kSurfaceColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.landscape_outlined, size: 60, color: kSecondaryTextColor),
              Text('لا توجد صورة أو فيديو', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
            ],
          ),
        ),
      );
    }
  }

  // Ratings Section Widget
  Widget _buildRatingsSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(textTheme, 'التقييمات والمراجعات'),
            if (_totalReviews > 0)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full reviews page if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('عرض كل التقييمات.'), backgroundColor: kAccentColor),
                  );
                },
                child: const Text('عرض الكل'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_totalReviews > 0) // Only show overall rating if there are reviews
          Row(
            children: [
              Text(
                '${_overallRating.toStringAsFixed(1)}',
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
              ),
              const SizedBox(width: 8),
              RatingBarIndicator(
                rating: _overallRating,
                itemBuilder: (context, index) => Icon(
                  Icons.star_rounded,
                  color: kAccentColor,
                ),
                itemCount: 5,
                itemSize: 25.0,
                direction: Axis.horizontal,
              ),
              const SizedBox(width: 8),
              Text(
                '($_totalReviews مراجعة)',
                style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Display ratings list or loading/empty state
        _ratings.isEmpty && _isLoading // Show loading indicator specifically for ratings if empty
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _ratings.isEmpty
                ? Center(
                    child: Text('لا توجد تقييمات لهذا الموقع بعد.', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
                  )
                : ListView.builder(
                    controller: _ratingsScrollController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Important when nested in SingleChildScrollView
                    itemCount: _ratings.length + (_canLoadMoreRatings ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _ratings.length) {
                        return _buildRatingCard(textTheme, _ratings[index]);
                      } else {
                        // Show loading indicator if more ratings are available
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                        );
                      }
                    },
                  ),
        const SizedBox(height: 24),
        // Add Review Section Form
        _buildSectionTitle(textTheme, 'أضف تقييمك ومراجعتك'),
        const SizedBox(height: 12),
        Center(
          child: RatingBar.builder(
            initialRating: _newRatingValue,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(
              Icons.star_rounded,
              color: kAccentColor,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _newRatingValue = rating;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reviewTitleController,
          decoration: const InputDecoration(
            labelText: 'عنوان المراجعة (اختياري)',
            prefixIcon: Icon(Icons.title_outlined),
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reviewTextController,
          decoration: const InputDecoration(
            labelText: 'نص المراجعة',
            prefixIcon: Icon(Icons.rate_review_outlined),
          ),
          maxLines: 3,
          minLines: 1,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _isSubmittingReview // Use specific loading indicator for review submission
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : ElevatedButton.icon(
                  onPressed: _addOrUpdateReview,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('إرسال المراجعة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  // Rating Card Widget (no changes needed here)
  Widget _buildRatingCard(TextTheme textTheme, Rating rating) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  child: Text(
                    rating.user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: textTheme.titleSmall?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.user?.username ?? 'مستخدم مجهول',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      RatingBarIndicator(
                        rating: rating.ratingValue.toDouble(),
                        itemBuilder: (context, index) => Icon(
                          Icons.star_rounded,
                          color: kAccentColor,
                        ),
                        itemCount: 5,
                        itemSize: 18.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rating.reviewTitle != null && rating.reviewTitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: Text(
                  rating.reviewTitle!,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            if (rating.reviewText != null && rating.reviewText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  rating.reviewText!,
                  style: textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '${rating.createdAt != null ? intl.DateFormat('yyyy/MM/dd').format(rating.createdAt!) : ''}',
                style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Comments Section Widget
  Widget _buildCommentsSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(textTheme, 'التعليقات'),
            if (_comments.isNotEmpty)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full comments page if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('عرض كل التعليقات.'), backgroundColor: kAccentColor),
                  );
                },
                child: const Text('عرض الكل'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Display comments list or loading/empty state
        _comments.isEmpty && _isLoading // Show loading indicator specifically for comments if empty
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _comments.isEmpty
                ? Center(
                    child: Text('لا توجد تعليقات لهذا الموقع بعد.', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
                  )
                : ListView.builder(
                    controller: _commentsScrollController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Important when nested
                    itemCount: _comments.length + (_canLoadMoreComments ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _comments.length) {
                        return _buildCommentCard(textTheme, _comments[index]);
                      } else {
                        // Show loading indicator if more comments are available
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                        );
                      }
                    },
                  ),
        const SizedBox(height: 24),
        // Add Comment Section Form
        _buildSectionTitle(textTheme, 'أضف تعليقك'),
        const SizedBox(height: 12),
        TextField(
          controller: _commentTextController,
          decoration: InputDecoration(
            labelText: _replyToCommentId != null ? 'الرد على التعليق...' : 'اكتب تعليقك هنا...',
            prefixIcon: const Icon(Icons.comment_outlined),
            suffixIcon: _replyToCommentId != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _replyToCommentId = null;
                        _commentTextController.clear();
                      });
                    },
                  )
                : null,
          ),
          maxLines: 3,
          minLines: 1,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _isSubmittingComment // Use specific loading indicator for comment submission
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : ElevatedButton.icon(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(_replyToCommentId != null ? 'إرسال الرد' : 'إرسال التعليق'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  // Comment Card Widget (no changes needed here)
  Widget _buildCommentCard(TextTheme textTheme, Comment comment, {bool isReply = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8, left: isReply ? 24 : 0, right: 0), // Indent replies
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  child: Text(
                    comment.user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: textTheme.titleSmall?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    comment.user?.username ?? 'مستخدم مجهول',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                  ),
                ),
                Text(
                  '${comment.createdAt != null ? intl.DateFormat('yyyy/MM/dd').format(comment.createdAt!) : ''}',
                  style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor.withOpacity(0.7)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              comment.content,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _replyToCommentId = comment.id;
                    _commentTextController.text = '@${comment.user?.username ?? 'مستخدم'}: ';
                  });
                  // Scroll to the end to make the comment input visible
                  _commentsScrollController.animateTo(
                    _commentsScrollController.position.maxScrollExtent + 100, // Add some offset
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                icon: const Icon(Icons.reply_outlined, size: 18),
                label: const Text('رد'),
                style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
              ),
            ),
            // Display replies recursively (can be simplified if API provides flat list)
            if (comment.replies != null && comment.replies!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comment.replies!.length,
                  itemBuilder: (context, index) {
                    final reply = comment.replies![index];
                    if (reply == null) return const SizedBox.shrink();
                    return _buildCommentCard(textTheme, reply, isReply: true);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Site Experiences Section Widget <<<< NEW
  Widget _buildExperiencesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(textTheme, 'تجارب الزوار'),
            if (_experiences.isNotEmpty)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to a dedicated page for all experiences if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('عرض كل التجارب.'), backgroundColor: kAccentColor),
                  );
                },
                child: const Text('عرض الكل'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Display experiences list or loading/empty state
        _experiences.isEmpty && _isLoading // Show loading indicator specifically for experiences
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _experiences.isEmpty
                ? Center(
                    child: Text('لا توجد تجارب لهذا الموقع بعد.', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
                  )
                : ListView.builder(
                    controller: _experiencesScrollController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _experiences.length + (_canLoadMoreExperiences ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _experiences.length) {
                        return _buildExperienceCard(textTheme, _experiences[index]);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                        );
                      }
                    },
                  ),
        const SizedBox(height: 24),
        // Add Experience Form
        _buildSectionTitle(textTheme, 'أضف تجربتك'),
        const SizedBox(height: 12),
        TextField(
          controller: _experienceTitleController,
          decoration: const InputDecoration(
            labelText: 'عنوان التجربة',
            prefixIcon: Icon(Icons.title_outlined),
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _experienceContentController,
          decoration: const InputDecoration(
            labelText: 'محتوى التجربة',
            prefixIcon: Icon(Icons.article_outlined),
          ),
          maxLines: 3,
          minLines: 1,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _pickedExperiencePhoto != null
                  ? Image.file(_pickedExperiencePhoto!, height: 80, fit: BoxFit.cover)
                  : Container(
                      height: 80,
                      color: kSurfaceColor,
                      child: Center(
                        child: Text(
                          'لا توجد صورة مختارة',
                          style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _pickImageForExperience,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('اختيار صورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kSurfaceColor,
                foregroundColor: kPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _isSubmittingExperience
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : ElevatedButton.icon(
                  onPressed: _addExperience,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('إرسال التجربة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  // --- Experience Card Widget <<<< NEW
  Widget _buildExperienceCard(TextTheme textTheme, SiteExperience experience) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  child: Text(
                    experience.user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: textTheme.titleSmall?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        experience.user?.username ?? 'مستخدم مجهول',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      Text(
                        experience.formattedVisitDate ?? '',
                        style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
                if (experience.site?.name != null)
                  Chip(
                    label: Text(experience.site!.name!), // Display site name in a chip
                    backgroundColor: kAccentColor.withOpacity(0.1),
                    labelStyle: const TextStyle(color: kAccentColor),
                  ),
              ],
            ),
            if (experience.title != null && experience.title!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: Text(
                  experience.title!,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                experience.content,
                style: textTheme.bodyLarge,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (experience.imageUrl != null && experience.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    experience.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: kSurfaceColor,
                      child: const Center(child: Icon(Icons.image_not_supported, color: kSecondaryTextColor)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'تم النشر: ${intl.DateFormat('yyyy/MM/dd').format(experience.createdAt)}',
                style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}