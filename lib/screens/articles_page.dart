// lib/screens/articles_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import 'package:smart_tourism_app/models/article.dart';
import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/screens/article_details_page.dart'; // سنقوم بإنشاء هذه الصفحة لاحقاً
import 'package:smart_tourism_app/utils/api_exceptions.dart';

// Use your app's constant colors
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kErrorColor = Color(0xFFE74C3C);

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  final List<Article> _articles = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchArticles(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        _canLoadMore && !_isLoading) {
      _currentPage++;
      _fetchArticles();
    }
  }

  Future<void> _fetchArticles({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _articles.clear();
      _canLoadMore = true;
    }

    if (!_canLoadMore && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final response = await tourismRepo.getArticles(page: _currentPage);

      setState(() {
        _articles.addAll(response.data);
        _canLoadMore = response.meta.currentPage < response.meta.lastPage;
      });
    } on ApiException catch (e) {
      setState(() { _errorMessage = e.message; });
    } on NetworkException catch (e) {
      setState(() { _errorMessage = e.message; });
    } catch (e) {
      setState(() { _errorMessage = 'فشل في تحميل المقالات.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المدونة السياحية'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchArticles(isRefresh: true),
          child: _isLoading && _articles.isEmpty
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : _articles.isEmpty
                      ? _buildEmptyStateWidget()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _articles.length + (_canLoadMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _articles.length) {
                              final article = _articles[index];
                              return _buildArticleCard(article);
                            } else {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                              );
                            }
                          },
                        ),
        ),
      ),
    );
  }
  
  Widget _buildArticleCard(Article article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailsPage(articleId: article.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              Image.network(
                article.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: kSurfaceColor,
                  child: const Icon(Icons.article_outlined, size: 60, color: kSecondaryTextColor),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.excerpt ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: kSecondaryTextColor),
                      const SizedBox(width: 4),
                      Text(
                        article.author?.username ?? 'فريق سمارت توريزم',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: kSecondaryTextColor),
                      const SizedBox(width: 4),
                      Text(
                        intl.DateFormat('yyyy/MM/dd').format(article.publishedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: kErrorColor),
            const SizedBox(height: 15),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kErrorColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => _fetchArticles(isRefresh: true), child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: kSecondaryTextColor.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            'لا توجد مقالات متاحة حالياً',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'ترقبوا نصائح ومقالات جديدة حول السياحة في سوريا!',
            textAlign: TextAlign.center,
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ],
      ),
    );
  }
}