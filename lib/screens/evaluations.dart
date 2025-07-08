// lib/screens/evaluations.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/repositories/interaction_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/rating.dart'; // Rating model
import 'package:smart_tourism_app/models/pagination.dart'; // Pagination model
import 'package:smart_tourism_app/utils/constants.dart'; // For TargetTypes

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

class ReviewsPage extends StatefulWidget {
  // يمكن لهذه الصفحة أن تعرض التقييمات لأي عنصر (موقع، منتج، فندق، مقالة)
  // لذلك يمكنها استقبال targetType و targetId
  final String? targetType; // e.g., 'TouristSite', 'Product', 'Hotel', 'Article', 'SiteExperience'
  final int? targetId;

  const ReviewsPage({super.key, this.targetType, this.targetId});

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<Rating> _ratings = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  // For adding a new review (if this page allows adding reviews)
  double _newRatingValue = 0;
  final TextEditingController _reviewTitleController = TextEditingController();
  final TextEditingController _reviewTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRatings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _reviewTitleController.dispose();
    _reviewTextController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _canLoadMore && !_isLoading) {
      _currentPage++;
      _fetchRatings(page: _currentPage);
    }
  }

  Future<void> _fetchRatings({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _ratings.clear(); // Clear existing data on refresh
    }

    if (!_canLoadMore && !isRefresh) return; // No more data to load

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      PaginatedResponse<Rating> response;

      // Determine if fetching all ratings or ratings for a specific target
      if (widget.targetType != null && widget.targetId != null) {
        response = await interactionRepo.getRatingsForTarget(widget.targetType!, widget.targetId!, page: _currentPage);
      } else {
        // Fallback or a dedicated endpoint for 'my reviews' or 'all reviews' if available
        // For simplicity, if no target, fetch all ratings for TouristSites (or just show empty)
        // You might need a /my-ratings endpoint in your API for user's own reviews
        // For now, let's just make sure there's data to display if target is null
        _errorMessage = "الرجاء تحديد عنصر لعرض تقييماته (مثلاً: موقع سياحي، فندق).";
        _canLoadMore = false;
        return;
      }

      setState(() {
        _ratings.addAll(response.data);
        _canLoadMore = response.meta.currentPage < response.meta.lastPage;
      });
    } on ApiException catch (e) {
      print('API Error fetching ratings: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching ratings: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching ratings: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل التقييمات.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addReview() async {
    if (_newRatingValue == 0 || _reviewTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال تقييم ونص المراجعة.'), backgroundColor: kAccentColor),
      );
      return;
    }
    if (widget.targetType == null || widget.targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إضافة تقييم بدون تحديد العنصر.'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final newRating = await interactionRepo.addRating({
        'target_type': widget.targetType!,
        'target_id': widget.targetId!,
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
        setState(() {
          _newRatingValue = 0;
        });
        _fetchRatings(isRefresh: true); // Re-fetch to show new review
      }
    } on ValidationException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'خطأ في التحقق من البيانات.'), backgroundColor: kErrorColor),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'فشل إضافة المراجعة.'), backgroundColor: kErrorColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع: ${e.toString()}.'), backgroundColor: kErrorColor),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقييمات والمراجعات'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchRatings(isRefresh: true),
          color: kPrimaryColor,
          backgroundColor: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: _isLoading && _ratings.isEmpty && _errorMessage == null
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
                                  Text(_errorMessage!, textAlign: TextAlign.center, style: textTheme.titleMedium?.copyWith(color: kErrorColor)),
                                  const SizedBox(height: 20),
                                  ElevatedButton(onPressed: () => _fetchRatings(isRefresh: true), child: const Text('إعادة المحاولة')),
                                ],
                              ),
                            ),
                          )
                        : _ratings.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(30.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.reviews_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                      const SizedBox(height: 20),
                                      Text(
                                        'لا توجد تقييمات حتى الآن.',
                                        style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'كن أول من يقيّم هذا العنصر!',
                                        style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _ratings.length + (_canLoadMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index < _ratings.length) {
                                    final rating = _ratings[index];
                                    return _buildReviewCard(context, rating);
                                  } else {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                                    );
                                  }
                                },
                              ),
              ),
              const Divider(height: 20, thickness: 0.5),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "إضافة مراجعة جديدة",
                      style: textTheme.headlineSmall,
                    ),
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
                          color: kAccentColor, // Use theme color for stars
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
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: "عنوان المراجعة (اختياري)",
                        hintText: "مثال: تجربة رائعة، مكان جميل...",
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewTextController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: "نص المراجعة",
                        hintText: "شاركنا تجربتك بالتفصيل...",
                        prefixIcon: Icon(Icons.rate_review_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                          : ElevatedButton.icon(
                              onPressed: _addReview,
                              icon: const Icon(Icons.send_outlined),
                              label: Text("إرسال المراجعة", style: textTheme.labelLarge),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Review Card Widget ---
  Widget _buildReviewCard(BuildContext context, Rating review) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
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
                    review.user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: textTheme.titleMedium?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.user?.username ?? 'مستخدم مجهول',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      const SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: review.ratingValue.toDouble(),
                        itemBuilder: (context, index) => Icon(
                          Icons.star_rounded,
                          color: kAccentColor,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
                // Optional: Edit/Delete button if it's the current user's review
                // IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
            if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: Text(
                  review.reviewTitle!,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            if (review.reviewText != null && review.reviewText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  review.reviewText!,
                  style: textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '${review.createdAt != null ? intl.DateFormat('yyyy/MM/dd').format(review.createdAt!) : ''}',
                style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}