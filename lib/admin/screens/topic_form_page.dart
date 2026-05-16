import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../screens/app_theme.dart';
import '../models/admin_models.dart';
import '../services/admin_repository.dart';

class TopicFormPage extends StatefulWidget {
  final String bookId;
  final AdminTopic? existingTopic;
  final AdminRepository repository;

  const TopicFormPage({
    required this.bookId,
    this.existingTopic,
    required this.repository,
    super.key,
  });

  @override
  State<TopicFormPage> createState() => _TopicFormPageState();
}

class _TopicFormPageState extends State<TopicFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _videoUrlController;

  Uint8List? _knowledgeMapBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingTopic?.title ?? '',
    );
    _notesController = TextEditingController(
      text: widget.existingTopic?.notes ?? '',
    );
    _videoUrlController = TextEditingController(
      text: widget.existingTopic?.videoUrl ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingTopic = widget.existingTopic;

    return Scaffold(
      appBar: AppBar(
        title: Text(existingTopic == null ? 'Add Topic' : 'Edit Topic'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: authInputDecoration(
                hint: 'Topic title',
                icon: Icons.title_rounded,
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a topic title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 5,
              decoration: authInputDecoration(
                hint: 'Notes',
                icon: Icons.notes_rounded,
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter topic notes' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _videoUrlController,
              decoration: authInputDecoration(
                hint: 'YouTube URL',
                icon: Icons.play_circle_outline_rounded,
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a YouTube URL' : null,
            ),
            const SizedBox(height: 16),
            _KnowledgeMapPicker(
              imageUrl: existingTopic?.knowledgeMapImage,
              imageBytes: _knowledgeMapBytes,
              onPick: _pickKnowledgeMap,
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
                        existingTopic == null ? 'Create Topic' : 'Save Changes',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickKnowledgeMap() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) {
      return;
    }

    setState(() {
      _knowledgeMapBytes = file!.bytes;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.saveTopic(
        bookId: widget.bookId,
        topicId: widget.existingTopic?.id,
        title: _titleController.text,
        notes: _notesController.text,
        videoUrl: _videoUrlController.text,
        knowledgeMapBytes: _knowledgeMapBytes,
        existingKnowledgeMapImage: widget.existingTopic?.knowledgeMapImage,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Topic saved successfully')));
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Topic save error: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _KnowledgeMapPicker extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback onPick;

  const _KnowledgeMapPicker({
    required this.imageUrl,
    required this.imageBytes,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    Widget preview;
    final hasImage =
        (imageBytes != null) || (imageUrl != null && imageUrl!.isNotEmpty);

    if (imageBytes != null) {
      preview = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      preview = Image.network(imageUrl!, fit: BoxFit.cover);
    } else {
      preview = Container(
        color: const Color(0xFFF0F3FF),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map_rounded, size: 44, color: Color(0xFF3B53D6)),
            SizedBox(height: 10),
            Text(
              'No knowledge map image selected',
              style: TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Choose an image to use as the topic knowledge map.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF98A2B3), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Knowledge map image (optional)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  preview,
                  if (hasImage)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Tap to replace',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(hasImage ? 'Replace image' : 'Choose image'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
