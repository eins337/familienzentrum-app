import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/n_card.dart';

/// A grid of thumbnails pulled from the group's foto-posts (the caller
/// already has that data from `groupPostsProvider`, so this takes the
/// flattened photo URL list directly rather than re-fetching).
class GruppeGallery extends StatelessWidget {
  const GruppeGallery({super.key, required this.photoUrls});
  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    return NCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FOTOS', style: TextStyle(fontFamily: 'Outfit', fontSize: 10, letterSpacing: 1.3, color: AppColors.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photoUrls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _openFullscreen(context, photoUrls, i),
                child: CachedNetworkImage(imageUrl: photoUrls[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context, List<String> urls, int startIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.transparent,
        child: PageView.builder(
          controller: PageController(initialPage: startIndex),
          itemCount: urls.length,
          itemBuilder: (context, i) => InteractiveViewer(
            child: CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
