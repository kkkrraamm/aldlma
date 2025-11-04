import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

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
  
  @override
  void initState() {
    super.initState();
    _loadAds();
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
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ [ADS] Error: $e');
      setState(() => _loading = false);
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
    
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: PageView.builder(
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return GestureDetector(
            onTap: () async {
              if (ad['link_url'] != null && ad['link_url'].toString().isNotEmpty) {
                try {
                  final url = Uri.parse(ad['link_url']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  print('❌ [ADS] Error launching URL: $e');
                }
              }
            },
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: ad['image_url'],
                  fit: BoxFit.cover,
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
            ),
          );
        },
      ),
    );
  }
}



