import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';

class ImageUploadWidget extends StatefulWidget {
  final Function(XFile? file, Uint8List? bytes) onImageSelected;
  final String title;

  const ImageUploadWidget({
    super.key,
    required this.onImageSelected,
    this.title = 'Přetáhněte obrázek nebo schéma (volitelné)',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isHovering = false;
  XFile? _selectedFile;
  Uint8List? _fileBytes;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      final file = result.files.first;
      setState(() {
        _selectedFile = XFile(file.path ?? file.name);
        _fileBytes = file.bytes;
      });
      widget.onImageSelected(_selectedFile, _fileBytes);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedFile = null;
      _fileBytes = null;
    });
    widget.onImageSelected(null, null);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedFile != null) {
      return Container(
        height: 120.0,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              clipBehavior: Clip.hardEdge,
              child: _fileBytes != null
                  ? Image.memory(_fileBytes!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.image)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedFile!.name,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: _removeImage,
              tooltip: 'Odebrat obrázek',
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
          setState(() {
            _selectedFile = file;
            _fileBytes = bytes;
          });
          widget.onImageSelected(_selectedFile, _fileBytes);
        }
      },
      onDragEntered: (detail) {
        setState(() {
          _isHovering = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _isHovering = false;
        });
      },
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 120.0,
          decoration: BoxDecoration(
            color: _isHovering 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _isHovering 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.outline, 
              width: 1.5
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined, 
                color: _isHovering 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.secondary, 
                size: 36.0
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.title, 
                style: GoogleFonts.inter(
                  color: _isHovering 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.secondary, 
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
