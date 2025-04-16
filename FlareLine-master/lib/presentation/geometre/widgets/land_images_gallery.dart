import 'package:flareline/presentation/geometre/widgets/land_widget.dart';
import 'package:flutter/material.dart';
import 'package:flareline/domain/entities/land_entity.dart';
import 'package:flareline_uikit/components/card/common_card.dart';

class LandImagesGallery extends StatelessWidget {
  final Land land;

  const LandImagesGallery({
    Key? key,
    required this.land,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si nous n'avons pas d'URLs d'images mais avons des CIDs, afficher un message
    if (land.imageUrls.isEmpty && land.imageCIDs.isNotEmpty) {
      return CommonCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Images du terrain',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      '${land.imageCIDs.length} images disponibles, mais elles doivent être chargées via IPFS',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si nous n'avons ni URLs ni CIDs, afficher un message
    if (land.imageUrls.isEmpty && land.imageCIDs.isEmpty) {
      return CommonCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Images du terrain',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Aucune image disponible pour ce terrain',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si nous avons des URLs d'images, les afficher
    return CommonCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Images du terrain',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: land.imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = land.imageUrls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => _showImageFullScreen(context, land.imageUrls, index),
                      child: LandImage(
                        imageUrl: imageUrl,
                        width: 200,
                        height: 200,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 800,
            maxHeight: 600,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Image ${initialIndex + 1}/${images.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: LandImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}