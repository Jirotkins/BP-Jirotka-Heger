import 'dart:convert';
import 'package:flutter/material.dart';

/// Widget pro zobrazení obrázku (Base64 nebo URL) s možností přizpůsobení velikosti
/// a rozkliknutí do celoobrazovkového zobrazení s možností zoomování.
class ZoomableImageWidget extends StatelessWidget {
  final String imageUrl;
  final double maxHeight;
  
  const ZoomableImageWidget({
    super.key,
    required this.imageUrl,
    this.maxHeight = 300.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const SizedBox();

    Widget imageWidget;
    
    if (imageUrl.startsWith('data:image')) {
      try {
        String b64 = imageUrl.split(',').last.trim();
        imageWidget = Image.memory(
          base64Decode(base64.normalize(b64)),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      } catch (e) {
        debugPrint('Chyba vykreslení obrázku (ZoomableImageWidget): $e');
        return const SizedBox();
      }
    } else {
      imageWidget = Image.network(
        imageUrl, 
        fit: BoxFit.contain, 
        errorBuilder: (c, e, s) => const SizedBox(),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: imageWidget,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}
