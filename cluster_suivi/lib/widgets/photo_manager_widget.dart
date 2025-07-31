import 'dart:io';
import 'package:flutter/material.dart';
import '../core/services/photo_service.dart';
import '../core/services/upload_service.dart'; // à ajouter si pas encore

class PhotoManagerWidget extends StatefulWidget {
  final List<String> photos;
  final Function(List<String>) onPhotosChanged;
  final int maxPhotos;

  const PhotoManagerWidget({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 5,
  });

  @override
  State<PhotoManagerWidget> createState() => _PhotoManagerWidgetState();
}

class _PhotoManagerWidgetState extends State<PhotoManagerWidget> {
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_camera, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Photos (${_photos.length}/${widget.maxPhotos})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Affichage des photos existantes
        if (_photos.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoItem(_photos[index], index);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Boutons d'ajout de photos
        if (_photos.length < widget.maxPhotos) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Prendre une photo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galerie'),
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            'Nombre maximum de photos atteint',
            style: TextStyle(color: Colors.orange),
          ),
        ],

        // ✅ Bouton de test d'upload (corrigé)
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _testUpload,
            icon: const Icon(Icons.upload, color: Colors.blue),
            label: const Text('🧪 Tester upload'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoItem(String fileName, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<String>(
              future: PhotoService.getPhotoPath(fileName),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.file(
                    File(snapshot.data!),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  );
                } else {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade300,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deletePhoto(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final String? photoFileName = await PhotoService.takePhoto();
    if (photoFileName != null) {
      setState(() {
        _photos.add(photoFileName);
      });
      widget.onPhotosChanged(_photos);
    }
  }

  Future<void> _pickFromGallery() async {
    final String? photoFileName = await PhotoService.pickFromGallery();
    if (photoFileName != null) {
      setState(() {
        _photos.add(photoFileName);
      });
      widget.onPhotosChanged(_photos);
    }
  }

  Future<void> _deletePhoto(int index) async {
    final String fileName = _photos[index];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PhotoService.deletePhoto(fileName);
      setState(() {
        _photos.removeAt(index);
      });
      widget.onPhotosChanged(_photos);
    }
  }

  Future<void> _testUpload() async {
    if (_photos.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Test upload...'),
          ],
        ),
      ),
    );

    try {
      final photoName = _photos.first;
      final fullPath = await PhotoService.getPhotoPath(photoName);

      await PhotoUploadService.testImageUpload(fullPath);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test upload terminé - Voir les logs'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
