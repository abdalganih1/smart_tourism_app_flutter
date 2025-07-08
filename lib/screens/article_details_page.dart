// lib/screens/article_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart'; // ستحتاج لإضافة هذا الباكج

import 'package:smart_tourism_app/models/article.dart';
import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';

// Use your app's constant colors
const Color kPrimaryColor = Color.fromARGB(255, 192, 227, 250);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kErrorColor = Color(0xFFE74C3C);

class ArticleDetailsPage extends StatefulWidget {
  final int articleId;
  const ArticleDetailsPage({super.key, required this.articleId});

  @override
  State<ArticleDetailsPage> createState() => _ArticleDetailsPageState();
}

class _ArticleDetailsPageState extends State<ArticleDetailsPage> {
  Article? _article;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchArticleDetails();
  }

  Future<void> _fetchArticleDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      _article = await tourismRepo.getArticleDetails(widget.articleId);
    } on ApiException catch (e) {
      setState(() { _errorMessage = e.message; });
    } on NetworkException catch (e) {
      setState(() { _errorMessage = e.message; });
    } catch (e) {
      setState(() { _errorMessage = 'فشل في تحميل تفاصيل المقالة.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _isLoading && _article == null
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _errorMessage != null
                ? _buildErrorWidget()
                : _article == null
                    ? _buildErrorWidget(message: 'لم يتم العثور على المقالة.')
                    : CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 250.0,
                            pinned: true,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(
                                _article!.title,
                                style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 8)]),
                              ),
                              background: _article!.imageUrl != null
                                  ? Image.network(
                                      _article!.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                    )
                                  : Container(color: kPrimaryColor),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Meta info: author and date
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 16, color: kSecondaryTextColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _article!.author?.username ?? 'فريق سمارت توريزم',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.calendar_today_outlined, size: 16, color: kSecondaryTextColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        intl.DateFormat('yyyy/MM/dd').format(_article!.publishedAt),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 32),
                                  // Article Content using flutter_html for rich text
                                  Html(
                                    data: _article!.content,
                                    style: {
                                      "body": Style(
                                        fontSize: FontSize(16.0),
                                        lineHeight: LineHeight.em(1.5),
                                        textAlign: TextAlign.justify,
                                      ),
                                      "p": Style(
                                        margin: Margins.only(bottom: 12),
                                      ),
                                      "h2": Style(
                                        fontSize: FontSize(22.0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      "h3": Style(
                                        fontSize: FontSize(18.0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  // Tags
                                  if (_article!.tags != null && _article!.tags!.isNotEmpty)
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: _article!.tags!.map((tag) => Chip(
                                        label: Text(tag),
                                        backgroundColor: kPrimaryColor.withOpacity(0.1),
                                        labelStyle: const TextStyle(color: kPrimaryColor),
                                      )).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildErrorWidget({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: kErrorColor),
            const SizedBox(height: 15),
            Text(
              message ?? _errorMessage ?? 'حدث خطأ غير متوقع.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kErrorColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchArticleDetails, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}