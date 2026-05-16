import 'package:flutter/material.dart';

class TopicData {
  final String title;
  final String youtubeUrl;
  final String notes;
  final String knowledgeMapImage;
  final double? posX;
  final double? posY;

  const TopicData({
    required this.title,
    required this.youtubeUrl,
    required this.notes,
    this.knowledgeMapImage = '',
    this.posX,
    this.posY,
  });
}

class BookData {
  final String id;
  final String title;
  final String author;
  final String category;
  final double rating;
  final String summary;
  final Color coverColor;
  final IconData icon;
  final List<TopicData> topics;

  const BookData({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.rating,
    required this.summary,
    required this.coverColor,
    required this.icon,
    required this.topics,
  });
}

class CategoryData {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const CategoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

CategoryData categoryDataFromName(String name, {String? id, String? subtitle}) {
  final normalized = name.trim();
  final index = normalized.isEmpty ? 0 : normalized.hashCode.abs();
  final presets = <CategoryData>[
    const CategoryData(
      id: 'programming',
      title: 'Programming',
      subtitle: 'Build apps and code smarter',
      icon: Icons.code_rounded,
      color: Color(0xFFE5EDFF),
    ),
    const CategoryData(
      id: 'design',
      title: 'Design',
      subtitle: 'Create clean user experiences',
      icon: Icons.palette_rounded,
      color: Color(0xFFFFE6EF),
    ),
    const CategoryData(
      id: 'business',
      title: 'Business',
      subtitle: 'Grow projects and teams',
      icon: Icons.work_rounded,
      color: Color(0xFFFFF1D9),
    ),
    const CategoryData(
      id: 'science',
      title: 'Science',
      subtitle: 'Learn with curiosity',
      icon: Icons.science_rounded,
      color: Color(0xFFE4F8EE),
    ),
    const CategoryData(
      id: 'general',
      title: 'General',
      subtitle: 'Browse all learning content',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFEDEBFF),
    ),
  ];

  final preset = presets.firstWhere(
    (category) => category.title.toLowerCase() == normalized.toLowerCase(),
    orElse: () => presets[index % presets.length],
  );

  return CategoryData(
    id: id ?? normalized.toLowerCase(),
    title: normalized,
    subtitle: subtitle ?? preset.subtitle,
    icon: preset.icon,
    color: preset.color,
  );
}

class LibraryCatalog {
  static const categories = <CategoryData>[
    CategoryData(
      id: 'programming',
      title: 'Programming',
      subtitle: 'Build apps and code smarter',
      icon: Icons.code_rounded,
      color: Color(0xFFE5EDFF),
    ),
    CategoryData(
      id: 'design',
      title: 'Design',
      subtitle: 'Create clean user experiences',
      icon: Icons.palette_rounded,
      color: Color(0xFFFFE6EF),
    ),
    CategoryData(
      id: 'business',
      title: 'Business',
      subtitle: 'Grow projects and teams',
      icon: Icons.work_rounded,
      color: Color(0xFFFFF1D9),
    ),
    CategoryData(
      id: 'science',
      title: 'Science',
      subtitle: 'Learn with curiosity',
      icon: Icons.science_rounded,
      color: Color(0xFFE4F8EE),
    ),
  ];

  static const books = <BookData>[
    BookData(
      id: 'flutter-in-action',
      title: 'Flutter in Action',
      author: 'Eric Windmill',
      category: 'Programming',
      rating: 4.8,
      summary:
          'A practical book for building beautiful cross-platform apps with Flutter.',
      coverColor: Color(0xFF3B53D6),
      icon: Icons.phone_android_rounded,
      topics: [
        TopicData(
          title: 'Dart basics',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=dart+basics',
          notes:
              'Understand variables, functions, classes, and null safety before moving deeper into Flutter.',
        ),
        TopicData(
          title: 'Widgets and layout',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=flutter+widgets+layout',
          notes:
              'Widgets are the building blocks of Flutter. Learn Container, Row, Column, and ListView well.',
        ),
        TopicData(
          title: 'Navigation',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=flutter+navigation+navigator+push',
          notes:
              'Use Navigator.push to move between screens and keep the app flow simple.',
        ),
      ],
    ),
    BookData(
      id: 'clean-code',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      rating: 4.9,
      summary:
          'Learn how to write readable, maintainable, and professional code.',
      coverColor: Color(0xFF1F2937),
      icon: Icons.terminal_rounded,
      topics: [
        TopicData(
          title: 'Meaningful names',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=clean+code+meaningful+names',
          notes:
              'Use names that explain what the code does instead of hiding intent behind short labels.',
        ),
        TopicData(
          title: 'Functions',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=clean+code+functions',
          notes:
              'Keep functions small and focused on one thing. That makes them easier to read and reuse.',
        ),
        TopicData(
          title: 'Comments and refactoring',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=clean+code+refactoring',
          notes:
              'Refactor code so the intent becomes obvious, and only keep comments that add real value.',
        ),
      ],
    ),
    BookData(
      id: 'design-systems',
      title: 'Design Systems',
      author: 'Alla Kholmatova',
      category: 'Design',
      rating: 4.7,
      summary:
          'Build consistent interfaces with reusable patterns and shared visuals.',
      coverColor: Color(0xFFEF6B93),
      icon: Icons.design_services_rounded,
      topics: [
        TopicData(
          title: 'Consistency',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=design+systems+consistency',
          notes:
              'A design system keeps colors, spacing, and components uniform across the app.',
        ),
        TopicData(
          title: 'Components',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=design+system+components',
          notes:
              'Reusable buttons, cards, and forms save time and improve the user experience.',
        ),
        TopicData(
          title: 'Accessibility',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=design+system+accessibility',
          notes:
              'Good contrast, readable type, and clear interaction states help every user.',
        ),
      ],
    ),
    BookData(
      id: 'deep-work',
      title: 'Deep Work',
      author: 'Cal Newport',
      category: 'Business',
      rating: 4.8,
      summary:
          'Focus on meaningful work and reduce distractions in your learning routine.',
      coverColor: Color(0xFFF2C319),
      icon: Icons.work_history_rounded,
      topics: [
        TopicData(
          title: 'Focus rituals',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=deep+work+focus+rituals',
          notes:
              'Set a clear routine that tells your brain it is time to focus and create.',
        ),
        TopicData(
          title: 'Eliminate distractions',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=deep+work+distractions',
          notes:
              'Turn off notifications and keep your work sessions short but intense.',
        ),
        TopicData(
          title: 'Plan the day',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=deep+work+planning',
          notes:
              'A simple schedule helps you protect your attention and finish important tasks.',
        ),
      ],
    ),
    BookData(
      id: 'atomic-habits',
      title: 'Atomic Habits',
      author: 'James Clear',
      category: 'Business',
      rating: 5.0,
      summary: 'Small changes compound into noticeable improvement over time.',
      coverColor: Color(0xFFB7C1C2),
      icon: Icons.track_changes_rounded,
      topics: [
        TopicData(
          title: '1% better every day',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=atomic+habits+1%25+better+every+day',
          notes:
              'Tiny improvements become powerful when repeated consistently.',
        ),
        TopicData(
          title: 'Habit loop',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=atomic+habits+habit+loop',
          notes:
              'Cue, craving, response, and reward make habits easier to understand and change.',
        ),
        TopicData(
          title: 'Environment design',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=atomic+habits+environment+design',
          notes:
              'Make good habits easy and bad habits harder by shaping your environment.',
        ),
      ],
    ),
    BookData(
      id: 'brief-history-of-time',
      title: 'A Brief History of Time',
      author: 'Stephen Hawking',
      category: 'Science',
      rating: 4.6,
      summary:
          'A beginner-friendly introduction to the universe and modern physics.',
      coverColor: Color(0xFF2E476D),
      icon: Icons.public_rounded,
      topics: [
        TopicData(
          title: 'The universe',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=universe+explained+science',
          notes:
              'The book introduces large-scale ideas about space, time, and how the universe works.',
        ),
        TopicData(
          title: 'Black holes',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=black+holes+explained',
          notes:
              'Black holes show how gravity becomes extremely strong in a very small space.',
        ),
        TopicData(
          title: 'Time and gravity',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=time+and+gravity+explained',
          notes:
              'Physics links time, space, and gravity in ways that challenge everyday intuition.',
        ),
      ],
    ),
    BookData(
      id: 'scientific-thinking',
      title: 'Scientific Thinking',
      author: 'Neil deGrasse Tyson',
      category: 'Science',
      rating: 4.5,
      summary:
          'Learn how science helps us ask better questions and test ideas clearly.',
      coverColor: Color(0xFF4EA38A),
      icon: Icons.lightbulb_rounded,
      topics: [
        TopicData(
          title: 'Observation',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=scientific+thinking+observation',
          notes:
              'Good science starts by noticing patterns and asking what they might mean.',
        ),
        TopicData(
          title: 'Hypothesis',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=scientific+thinking+hypothesis',
          notes:
              'A hypothesis is a testable explanation that can be checked with evidence.',
        ),
        TopicData(
          title: 'Evidence',
          youtubeUrl:
              'https://www.youtube.com/results?search_query=scientific+thinking+evidence',
          notes:
              'Useful conclusions come from evidence, not from assumptions alone.',
        ),
      ],
    ),
  ];

  static final ValueNotifier<Set<String>> savedBookIds =
      ValueNotifier<Set<String>>(<String>{});

  static List<BookData> booksForCategory(String categoryTitle) {
    return books.where((book) => book.category == categoryTitle).toList();
  }

  static BookData bookById(String id) {
    return books.firstWhere((book) => book.id == id);
  }

  static List<BookData> savedBooks() {
    final savedIds = savedBookIds.value;
    return books.where((book) => savedIds.contains(book.id)).toList();
  }
}
