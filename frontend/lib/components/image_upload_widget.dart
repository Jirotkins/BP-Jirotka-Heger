import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';
import 'dart:convert';

class ImageUploadWidget extends StatefulWidget {
  final void Function(String? base64DataUrl) onImageSelected;
  final String title;
  final String? initialImageUrl;

  const ImageUploadWidget({
    super.key,
    required this.onImageSelected,
    this.title = 'Přidat obrázek (volitelné)',
    this.initialImageUrl,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isHovering = false;
  String? _currentImageUrl;
  Uint8List? _currentImageBytes;
  
  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
    if (_currentImageUrl != null && _currentImageUrl!.startsWith('data:image')) {
      try {
        final b64 = _currentImageUrl!.split(',').last;
        _currentImageBytes = base64Decode(b64);
      } catch (e) {
        // Fallback
      }
    }
  }

  Future<void> _processFile(XFile file, Uint8List bytes) async {
    final ext = file.name.split('.').last.toLowerCase();
    String mimeType = 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';
    if (ext == 'svg') mimeType = 'image/svg+xml';
    if (ext == 'webp') mimeType = 'image/webp';
    
    final base64Str = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$base64Str';
    
    setState(() {
      _currentImageUrl = dataUrl;
      _currentImageBytes = bytes;
    });
    
    widget.onImageSelected(dataUrl);
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final file = result.files.first;
      if (file.bytes != null) {
        await _processFile(XFile(file.path ?? file.name), file.bytes!);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _currentImageUrl = null;
      _currentImageBytes = null;
    });
    widget.onImageSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImageUrl != null) {
      return Container(
        height: 140.0,
        width: 200.0,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _currentImageBytes != null
                ? Image.memory(_currentImageBytes!, fit: BoxFit.cover)
                : Image.network(_currentImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image))),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: _removeImage,
                  tooltip: 'Odebrat obrázek',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            )
          ],
        ),
      );
    }

    return DropTarget(
      onDragDone: (detail) async {
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          final bytes = await file.readAsBytes();
          await _processFile(file, bytes);
        }
      },
      onDragEntered: (_) => setState(() => _isHovering = true),
      onDragExited: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: _isHovering 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _isHovering 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.outline, 
              width: 1.0,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined, 
                color: Theme.of(context).colorScheme.primary, 
                size: 20.0
              ),
              const SizedBox(width: 8.0),
              Text(
                widget.title, 
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.primary, 
                  fontWeight: FontWeight.w600,
                  fontSize: 14.0
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
