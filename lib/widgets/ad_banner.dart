import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../prayer_times_page.dart';
import '../dalma_ai_page.dart';
import '../services_page.dart';
import '../realty_page.dart';

class AdBanner extends StatefulWidget {
  final String pageLocation;
  final String position;
  
  const AdBanner({
    Key? key,
    required this.pageLocation,
    this.position = 'top',
  }) : super(key: key);
  
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  List<dynamic> _ads = [];
  bool _loading = true;
  final Set<int> _trackedImpressions = {};
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadAds();
  }
  
  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  void _startAutoPlay() {
    if (_ads.length <= 1) return;
    
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _ads.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  Future<void> _loadAds() async {
    try {
      print('📢 [ADS] Loading ads for ${widget.pageLocation}...');
      
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/ads/${widget.pageLocation}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> ads = jsonDecode(response.body);
        setState(() {
          _ads = ads.where((ad) => ad['position'] == widget.position).toList();
          _loading = false;
        });
        print('✅ [ADS] Loaded ${_ads.length} ads');
        
        // Track impression ONLY for the first visible ad (index 0)
        // This is the only ad that is immediately visible when the page loads
        // Other ads in the carousel will be tracked ONLY when they become visible:
        // - When user manually swipes to them
        // - When auto-play moves to them
        // This ensures accurate impression tracking - only count what user actually sees
        if (_ads.isNotEmpty) {
          _trackImpression(_ads[0]['id']);
          _currentPage = 0; // Set initial page
          print('👁️ [ADS] Initial impression tracked for first ad (index 0, Ad #${_ads[0]['id']})');
        }
        
        // Start auto-play if multiple ads
        if (_ads.length > 1) {
          _startAutoPlay();
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ [ADS] Error: $e');
      setState(() => _loading = false);
    }
  }
  
  Future<void> _trackImpression(int adId) async {
    // Prevent duplicate tracking - each ad should be counted only once per session
    if (_trackedImpressions.contains(adId)) {
      print('⏭️ [ADS] Ad #$adId already tracked, skipping');
      return;
    }
    
    try {
      print('👁️ [ADS] Tracking impression for ad #$adId (now visible on screen)');
      await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/ads/$adId/impression'),
      );
      _trackedImpressions.add(adId);
      print('✅ [ADS] Impression successfully tracked for ad #$adId');
    } catch (e) {
      print('❌ [ADS] Impression tracking error for ad #$adId: $e');
    }
  }
  
  Future<void> _trackClick(int adId) async {
    try {
      await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/ads/$adId/click'),
      );
      print('👆 [ADS] Click tracked for ad #$adId');
    } catch (e) {
      print('❌ [ADS] Click tracking error: $e');
    }
  }
  
  void _handleAdTap(Map<String, dynamic> ad) async {
    final adId = ad['id'];
    final linkType = ad['link_type'] ?? 'external';
    
    // Track click
    await _trackClick(adId);
    
    if (linkType == 'internal') {
      // Internal navigation
      final route = ad['internal_route'];
      if (route != null && route.isNotEmpty) {
        _navigateToInternalRoute(route);
      }
    } else {
      // External URL
      final linkUrl = ad['link_url'];
      if (linkUrl != null && linkUrl.toString().isNotEmpty) {
        try {
          final url = Uri.parse(linkUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('❌ [ADS] Error launching URL: $e');
        }
      }
    }
  }
  
  void _navigateToInternalRoute(String route) {
    Widget? page;
    
    switch (route) {
      case '/prayer':
      case '/prayer-times':
        page = const PrayerTimesPage();
        break;
      case '/dalma-ai':
      case '/ai':
        page = const DalmaAIPage();
        break;
      case '/services':
        page = const ServicesPage(showAppBar: true);
        break;
      case '/realty':
        page = const RealtyPage();
        break;
      // Add more routes as needed
      default:
        print('⚠️ [ADS] Unknown internal route: $route');
        return;
    }
    
    if (page != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page!),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Container(
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _ads.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              // Track impression ONLY when ad becomes visible
              // This is called when:
              // 1. User manually swipes to a new ad
              // 2. Auto-play moves to the next ad
              // 3. Any page change in the carousel
              final ad = _ads[index];
              _trackImpression(ad['id']);
              print('📊 [ADS] Page changed to index $index (Ad #${ad['id']})');
            },
            itemBuilder: (context, index) {
          final ad = _ads[index];
          return GestureDetector(
            onTap: () => _handleAdTap(ad),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: ad['image_url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image, size: 50, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              ad['title'] ?? 'إعلان',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Description overlay (if exists)
                  if (ad['description'] != null && ad['description'].toString().isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          ad['description'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    // Page indicators (dots) - only show if multiple ads
    if (_ads.length > 1)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _ads.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? const Color(0xFF10b981)
                    : Colors.grey.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
      ],
    );
  }
}



