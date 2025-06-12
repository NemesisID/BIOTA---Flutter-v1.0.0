import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:biota_2/constants/colors.dart';

class ImageCropWidget extends StatefulWidget {
  final File imageFile;
  final Function(Uint8List) onCropped;

  const ImageCropWidget({
    Key? key,
    required this.imageFile,
    required this.onCropped,
  }) : super(key: key);

  @override
  State<ImageCropWidget> createState() => _ImageCropWidgetState();
}

class _ImageCropWidgetState extends State<ImageCropWidget> {
  final GlobalKey _cropKey = GlobalKey();
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late Size _imageSize;
  late ui.Image _image;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _imageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      _imageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_imageLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Potong Gambar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _cropImage,
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Background gambar
              Center(
                child: Transform.scale(
                  scale: _scale,
                  child: Transform.translate(
                    offset: _offset,
                    child: RepaintBoundary(
                      key: _cropKey,
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // Overlay dengan crop area
              _buildCropOverlay(),
              // Gesture detector untuk pan dan zoom
              _buildGestureDetector(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale - 0.1).clamp(0.5, 3.0);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() {
                      _scale = 1.0;
                      _offset = Offset.zero;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale + 0.1).clamp(0.5, 3.0);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cropSize = constraints.maxWidth * 0.8;
        final left = (constraints.maxWidth - cropSize) / 2;
        final top = (constraints.maxHeight - cropSize) / 2;

        return Stack(
          children: [
            // Dark overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.5),
            ),
            // Clear crop area
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: cropSize,
                height: cropSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(cropSize / 2),
                ),
                child: ClipOval(
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            // Corner indicators
            Positioned(
              left: left - 10,
              top: top - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              right: constraints.maxWidth - left - cropSize - 10,
              top: top - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              left: left - 10,
              bottom: constraints.maxHeight - top - cropSize - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              right: constraints.maxWidth - left - cropSize - 10,
              bottom: constraints.maxHeight - top - cropSize - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGestureDetector() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _offset += details.delta;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.5, 3.0);
        });
      },
    );
  }

  Future<void> _cropImage() async {
    try {
      // Untuk simplifikasi, kita akan menggunakan InteractiveViewer approach
      final bytes = await widget.imageFile.readAsBytes();
      
      // Crop ke ukuran square (1:1)
      final originalImage = await _decodeImageFromList(bytes);
      final croppedImage = await _cropToSquare(originalImage);
      final croppedBytes = await _imageToBytes(croppedImage);
      
      widget.onCropped(croppedBytes);
    } catch (e) {
      print('Error cropping image: $e');
      // Fallback: gunakan gambar original
      final bytes = await widget.imageFile.readAsBytes();
      widget.onCropped(bytes);
    }
  }

  Future<ui.Image> _decodeImageFromList(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _cropToSquare(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Tentukan ukuran crop (square)
    final size = image.width < image.height ? image.width : image.height;
    final srcRect = Rect.fromLTWH(
      (image.width - size) / 2,
      (image.height - size) / 2,
      size.toDouble(),
      size.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    
    final picture = recorder.endRecording();
    return await picture.toImage(size, size);
  }

  Future<Uint8List> _imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}