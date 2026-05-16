import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../screens/app_theme.dart';
import '../models/admin_models.dart';
import '../services/admin_repository.dart';

class BookFormPage extends StatefulWidget {
  final AdminBook? existingBook;
  final AdminRepository repository;

  const BookFormPage({this.existingBook, required this.repository, super.key});

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final Future<List<AdminCategory>> _categoriesFuture;

  String? _selectedCategoryId;
  Uint8List? _thumbnailBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingBook?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingBook?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.existingBook?.category ?? '',
    );
    _selectedCategoryId = widget.existingBook?.categoryId;
    _categoriesFuture = widget.repository.fetchCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingBook = widget.existingBook;

    return Scaffold(
      appBar: AppBar(
        title: Text(existingBook == null ? 'Add Book' : 'Edit Book'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: authInputDecoration(
                hint: 'Book title',
                icon: Icons.title_rounded,
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: authInputDecoration(
                hint: 'Book description',
                icon: Icons.short_text_rounded,
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a description' : null,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AdminCategory>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const <AdminCategory>[];
                if (categories.isNotEmpty) {
                  final selected =
                      categories.any((c) => c.id == _selectedCategoryId)
                      ? _selectedCategoryId
                      : null;

                  return DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: authInputDecoration(
                      hint: 'Category',
                      icon: Icons.category_rounded,
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                      final categoryName = categories
                          .firstWhere((c) => c.id == value)
                          .name;
                      _categoryController.text = categoryName;
                    },
                    validator: (value) =>
                        (value ?? '').isEmpty ? 'Select a category' : null,
                  );
                }

                return TextFormField(
                  controller: _categoryController,
                  decoration: authInputDecoration(
                    hint: 'Category',
                    icon: Icons.category_rounded,
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter a category' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            _ThumbnailPicker(
              thumbnailUrl: existingBook?.thumbnailUrl,
              thumbnailBytes: _thumbnailBytes,
              onPick: _pickThumbnail,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        existingBook == null ? 'Create Book' : 'Save Changes',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) {
      return;
    }

    setState(() {
      _thumbnailBytes = file!.bytes;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);
    try {
      print('Starting book save: title=${_titleController.text}');
      await widget.repository.saveBook(
        bookId: widget.existingBook?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        categoryId: _selectedCategoryId,
        thumbnailBytes: _thumbnailBytes,
        existingThumbnailUrl: widget.existingBook?.thumbnailUrl,
      );

      if (!mounted) {
        return;
      }

      print('Book saved successfully');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book saved successfully')));
      Navigator.pop(context, true);
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Book saved without thumbnail (image upload skipped)',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      print('Timeout error: $e');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Book save error: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ThumbnailPicker extends StatelessWidget {
  final String? thumbnailUrl;
  final Uint8List? thumbnailBytes;
  final VoidCallback onPick;

  const _ThumbnailPicker({
    required this.thumbnailUrl,
    required this.thumbnailBytes,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (thumbnailBytes != null) {
      preview = Image.memory(thumbnailBytes!, fit: BoxFit.cover);
    } else if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      preview = Image.network(thumbnailUrl!, fit: BoxFit.cover);
    } else {
      preview = Container(
        color: const Color(0xFFE8ECFF),
        child: const Icon(
          Icons.image_rounded,
          size: 40,
          color: Color(0xFF3B53D6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thumbnail (Optional)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(aspectRatio: 16 / 9, child: preview),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Choose image'),
        ),
      ],
    );
  }
}
