import 'package:flutter/material.dart';
// provider not required here; repository is passed via constructor

import '../../screens/youtube_video_page.dart';
import '../models/admin_models.dart';
import '../services/admin_repository.dart';
import 'topic_form_page.dart';

class BookTopicsPage extends StatefulWidget {
  final AdminBook book;
  final AdminRepository repository;

  const BookTopicsPage({
    required this.book,
    required this.repository,
    super.key,
  });

  @override
  State<BookTopicsPage> createState() => _BookTopicsPageState();
}

class _BookTopicsPageState extends State<BookTopicsPage> {
  Future<List<AdminTopic>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.fetchTopics(widget.book.id);
  }

  Future<void> _refresh() async {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Notes'),
              Tab(text: 'Knowledge Map'),
              Tab(text: 'Videos'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _openTopicForm,
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add topic',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: FutureBuilder<List<AdminTopic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final topics = snapshot.data ?? const <AdminTopic>[];
            if (topics.isEmpty) {
              return _EmptyTopicsView(onAddTopic: _openTopicForm);
            }

            return TabBarView(
              children: [
                _TopicSectionList(
                  topics: topics,
                  emptyLabel: 'No notes topics yet.',
                  sectionBuilder: (topic) => _TopicNotesCard(topic: topic),
                  onEdit: _editTopic,
                  onDelete: _deleteTopic,
                ),
                _TopicSectionList(
                  topics: topics,
                  emptyLabel: 'No knowledge map topics yet.',
                  sectionBuilder: (topic) => _TopicMapCard(topic: topic),
                  onEdit: _editTopic,
                  onDelete: _deleteTopic,
                ),
                _TopicSectionList(
                  topics: topics,
                  emptyLabel: 'No video topics yet.',
                  sectionBuilder: (topic) => _TopicVideoCard(topic: topic),
                  onEdit: _editTopic,
                  onDelete: _deleteTopic,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openTopicForm({AdminTopic? topic}) async {
    final repository = widget.repository;
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TopicFormPage(
          bookId: widget.book.id,
          existingTopic: topic,
          repository: repository,
        ),
      ),
    );

    if (shouldRefresh == true) {
      await _refresh();
    }
  }

  Future<void> _editTopic(AdminTopic topic) => _openTopicForm(topic: topic);

  Future<void> _deleteTopic(AdminTopic topic) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete topic?'),
        content: Text('This will remove "${topic.title}" from the book.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await widget.repository.deleteTopic(
      bookId: widget.book.id,
      topicId: topic.id,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Topic deleted')));
    await _refresh();
  }
}

class _EmptyTopicsView extends StatelessWidget {
  final VoidCallback onAddTopic;

  const _EmptyTopicsView({required this.onAddTopic});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.topic_outlined,
              size: 52,
              color: Color(0xFF98A2B3),
            ),
            const SizedBox(height: 10),
            const Text(
              'No topics yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add topics with notes, knowledge maps, and video links.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onAddTopic, child: const Text('Add Topic')),
          ],
        ),
      ),
    );
  }
}

class _TopicSectionList extends StatelessWidget {
  final List<AdminTopic> topics;
  final String emptyLabel;
  final Widget Function(AdminTopic topic) sectionBuilder;
  final Future<void> Function(AdminTopic topic) onEdit;
  final Future<void> Function(AdminTopic topic) onDelete;

  const _TopicSectionList({
    required this.topics,
    required this.emptyLabel,
    required this.sectionBuilder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return Center(child: Text(emptyLabel));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final topic = topics[index];
        return sectionBuilder(topic);
      },
    );
  }
}

class _TopicNotesCard extends StatelessWidget {
  final AdminTopic topic;

  const _TopicNotesCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return _TopicCardShell(
      title: topic.title,
      subtitle: topic.notes,
      onEdit: () => _actions(context, topic, editOnly: true),
      onDelete: () => _actions(context, topic, deleteOnly: true),
    );
  }
}

class _TopicMapCard extends StatelessWidget {
  final AdminTopic topic;

  const _TopicMapCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final preview = topic.knowledgeMapImage.isEmpty
        ? Container(
            color: const Color(0xFFF0F3FF),
            child: const Icon(
              Icons.map_rounded,
              color: Color(0xFF3B53D6),
              size: 40,
            ),
          )
        : Image.network(topic.knowledgeMapImage, fit: BoxFit.cover);

    return _TopicCardShell(
      title: topic.title,
      subtitle: 'Knowledge map image',
      preview: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(aspectRatio: 16 / 9, child: preview),
      ),
      onEdit: () => _actions(context, topic, editOnly: true),
      onDelete: () => _actions(context, topic, deleteOnly: true),
    );
  }
}

class _TopicVideoCard extends StatelessWidget {
  final AdminTopic topic;

  const _TopicVideoCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return _TopicCardShell(
      title: topic.title,
      subtitle: topic.videoUrl,
      trailingLabel: 'Preview video',
      onPreview: topic.videoUrl.isEmpty
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => YoutubeVideoPage(
                    title: topic.title,
                    youtubeUrl: topic.videoUrl,
                  ),
                ),
              );
            },
      onEdit: () => _actions(context, topic, editOnly: true),
      onDelete: () => _actions(context, topic, deleteOnly: true),
    );
  }
}

class _TopicCardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? preview;
  final VoidCallback? onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? trailingLabel;

  const _TopicCardShell({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.preview,
    this.onPreview,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Color(0xFF667085))),
            if (preview != null) ...[const SizedBox(height: 12), preview!],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
                if (onPreview != null)
                  FilledButton.tonalIcon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(trailingLabel ?? 'Preview'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _actions(
  BuildContext context,
  AdminTopic topic, {
  bool editOnly = false,
  bool deleteOnly = false,
}) async {
  final state = context.findAncestorStateOfType<_BookTopicsPageState>();
  if (state == null) {
    return;
  }

  if (editOnly) {
    await state._editTopic(topic);
  }

  if (deleteOnly) {
    await state._deleteTopic(topic);
  }
}
