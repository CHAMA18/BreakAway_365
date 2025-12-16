import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines a single step in a walkthrough
class WalkthroughStep {
  final String id;
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final Alignment tooltipAlignment;
  final IconData? icon;

  const WalkthroughStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetKey,
    this.tooltipAlignment = Alignment.bottomCenter,
    this.icon,
  });
}

/// Defines a complete walkthrough for a page
class PageWalkthrough {
  final String pageId;
  final String pageName;
  final String pageDescription;
  final IconData pageIcon;
  final List<WalkthroughStep> steps;

  const PageWalkthrough({
    required this.pageId,
    required this.pageName,
    required this.pageDescription,
    required this.pageIcon,
    required this.steps,
  });
}

/// Service to manage walkthrough state and definitions
class WalkthroughService extends ChangeNotifier {
  static final WalkthroughService _instance = WalkthroughService._internal();
  factory WalkthroughService() => _instance;
  WalkthroughService._internal();

  bool _isWalkthroughActive = false;
  String? _currentPageId;
  int _currentStepIndex = 0;
  List<WalkthroughStep> _currentSteps = [];
  VoidCallback? _onWalkthroughComplete;

  bool get isWalkthroughActive => _isWalkthroughActive;
  String? get currentPageId => _currentPageId;
  int get currentStepIndex => _currentStepIndex;
  WalkthroughStep? get currentStep =>
      _currentSteps.isNotEmpty && _currentStepIndex < _currentSteps.length
          ? _currentSteps[_currentStepIndex]
          : null;
  int get totalSteps => _currentSteps.length;
  bool get isLastStep => _currentStepIndex >= _currentSteps.length - 1;

  /// All available page walkthroughs
  static final List<PageWalkthrough> availableWalkthroughs = [
    PageWalkthrough(
      pageId: 'dashboard',
      pageName: 'Dashboard',
      pageDescription: 'Learn about your personal dashboard and progress tracking',
      pageIcon: Icons.dashboard_outlined,
      steps: [
        WalkthroughStep(
          id: 'dashboard_welcome',
          title: 'Welcome to Your Dashboard',
          description: 'This is your personal learning hub. Here you can track your progress, view recent activity, and access all platform features.',
          icon: Icons.home_outlined,
        ),
        WalkthroughStep(
          id: 'dashboard_tabs',
          title: 'Dashboard Tabs',
          description: 'Switch between Overview, Learning Activity, and Skills & Competencies tabs to see different aspects of your progress.',
          icon: Icons.tab_outlined,
        ),
        WalkthroughStep(
          id: 'dashboard_progress',
          title: 'Progress Cards',
          description: 'View your learning level, time spent, current streak, and achievements at a glance.',
          icon: Icons.trending_up_outlined,
        ),
        WalkthroughStep(
          id: 'dashboard_categories',
          title: 'Progress by Category',
          description: 'Track your learning across different topics with the category breakdown chart.',
          icon: Icons.pie_chart_outline,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'content_library',
      pageName: 'Content Library',
      pageDescription: 'Discover courses, videos, and learning materials',
      pageIcon: Icons.video_library_outlined,
      steps: [
        WalkthroughStep(
          id: 'library_overview',
          title: 'Content Library',
          description: 'Browse all available courses, videos, and learning materials. Filter by topic or search for specific content.',
          icon: Icons.video_library_outlined,
        ),
        WalkthroughStep(
          id: 'library_tabs',
          title: 'Topic Categories',
          description: 'Use the topic tabs (Think, Keep, Accelerate, Transform, Abundance) to filter content by category.',
          icon: Icons.filter_list_outlined,
        ),
        WalkthroughStep(
          id: 'library_search',
          title: 'Search Content',
          description: 'Use the search bar to find specific courses or videos by title, description, or keywords.',
          icon: Icons.search_outlined,
        ),
        WalkthroughStep(
          id: 'library_favorites',
          title: 'Favorites',
          description: 'Click the heart icon on any content to add it to your favorites for quick access later.',
          icon: Icons.favorite_outline,
        ),
        WalkthroughStep(
          id: 'library_breakaway_tools',
          title: 'Breakaway Tools',
          description: 'Access specialized learning tools and immersive footage in the dedicated tools section.',
          icon: Icons.build_outlined,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'profile',
      pageName: 'Profile',
      pageDescription: 'View and manage your profile and achievements',
      pageIcon: Icons.person_outline,
      steps: [
        WalkthroughStep(
          id: 'profile_overview',
          title: 'Your Profile',
          description: 'View your profile information, learning statistics, and achievements.',
          icon: Icons.person_outline,
        ),
        WalkthroughStep(
          id: 'profile_stats',
          title: 'Learning Statistics',
          description: 'See your level, total learning time, streak days, and achievement badges.',
          icon: Icons.bar_chart_outlined,
        ),
        WalkthroughStep(
          id: 'profile_notifications',
          title: 'Notification Preferences',
          description: 'Switch to the Notifications tab to customize which alerts and updates you receive.',
          icon: Icons.notifications_outlined,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'assessments',
      pageName: 'Assessments',
      pageDescription: 'Complete and view your assessment results',
      pageIcon: Icons.assignment_outlined,
      steps: [
        WalkthroughStep(
          id: 'assessments_overview',
          title: 'Assessments Hub',
          description: 'Complete personality and skills assessments to better understand your strengths and areas for growth.',
          icon: Icons.assignment_outlined,
        ),
        WalkthroughStep(
          id: 'assessments_kolbe',
          title: 'Kolbe Assessment',
          description: 'The Kolbe A Index measures your instinctive way of doing things - your natural strengths when you take action.',
          icon: Icons.psychology_outlined,
        ),
        WalkthroughStep(
          id: 'assessments_print',
          title: 'PRINT Survey',
          description: 'Discover your unconscious motivators and how they influence your behavior and decisions.',
          icon: Icons.fingerprint_outlined,
        ),
        WalkthroughStep(
          id: 'assessments_results',
          title: 'View Results',
          description: 'Once completed, your assessment results will appear here with detailed insights.',
          icon: Icons.insights_outlined,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'scorecard',
      pageName: 'Scorecard',
      pageDescription: 'Track your coaching metrics and goals',
      pageIcon: Icons.score_outlined,
      steps: [
        WalkthroughStep(
          id: 'scorecard_overview',
          title: 'Scorecard Overview',
          description: 'Track and update your coaching metrics, goals, and commitments in one place.',
          icon: Icons.score_outlined,
        ),
        WalkthroughStep(
          id: 'scorecard_metrics',
          title: 'Metric Cards',
          description: 'Each card represents a different metric you\'re tracking. Click on a card to update its value or view history.',
          icon: Icons.assessment_outlined,
        ),
        WalkthroughStep(
          id: 'scorecard_custom',
          title: 'Custom Metrics',
          description: 'Add your own custom metrics to track specific goals that matter to you.',
          icon: Icons.add_chart_outlined,
        ),
        WalkthroughStep(
          id: 'scorecard_history',
          title: 'Previous Scorecards',
          description: 'View your scorecard history to see how your metrics have changed over time.',
          icon: Icons.history_outlined,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'documents',
      pageName: 'My Documents',
      pageDescription: 'Access and manage your uploaded documents',
      pageIcon: Icons.folder_outlined,
      steps: [
        WalkthroughStep(
          id: 'documents_overview',
          title: 'My Documents',
          description: 'Access all your uploaded documents, resources, and files in one organized location.',
          icon: Icons.folder_outlined,
        ),
        WalkthroughStep(
          id: 'documents_stats',
          title: 'Document Statistics',
          description: 'See a quick overview of your document library including total count and storage used.',
          icon: Icons.pie_chart_outline,
        ),
        WalkthroughStep(
          id: 'documents_list',
          title: 'Document List',
          description: 'Browse your documents with details like file name, date uploaded, and quick actions.',
          icon: Icons.list_outlined,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'ai_coach',
      pageName: 'AI Coach',
      pageDescription: 'Get personalized coaching from your AI assistant',
      pageIcon: Icons.smart_toy_outlined,
      steps: [
        WalkthroughStep(
          id: 'aicoach_overview',
          title: 'AI Coach',
          description: 'Your personal AI coaching assistant is here to answer questions, provide guidance, and support your learning journey.',
          icon: Icons.smart_toy_outlined,
        ),
        WalkthroughStep(
          id: 'aicoach_chat',
          title: 'Chat Interface',
          description: 'Type your questions or topics you want to discuss. The AI Coach will respond with personalized insights.',
          icon: Icons.chat_outlined,
        ),
        WalkthroughStep(
          id: 'aicoach_suggestions',
          title: 'Suggested Topics',
          description: 'Not sure what to ask? Use the suggested topics to get started with common coaching conversations.',
          icon: Icons.lightbulb_outline,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'forums',
      pageName: 'Discussion Forums',
      pageDescription: 'Connect with the community and share ideas',
      pageIcon: Icons.forum_outlined,
      steps: [
        WalkthroughStep(
          id: 'forums_overview',
          title: 'Discussion Forums',
          description: 'Connect with other members, share insights, and participate in community discussions.',
          icon: Icons.forum_outlined,
        ),
        WalkthroughStep(
          id: 'forums_tabs',
          title: 'Forum Tabs',
          description: 'Switch between Forums, Friends, and Coaches tabs to access different community features.',
          icon: Icons.tab_outlined,
        ),
        WalkthroughStep(
          id: 'forums_featured',
          title: 'Featured Forums',
          description: 'Browse featured discussions curated by the community and coaching team.',
          icon: Icons.star_outline,
        ),
        WalkthroughStep(
          id: 'forums_create',
          title: 'Create Discussion',
          description: 'Start a new discussion by clicking the "Create Forum" button to share your thoughts.',
          icon: Icons.add_comment_outlined,
        ),
        WalkthroughStep(
          id: 'forums_friends',
          title: 'Friends & Connections',
          description: 'Build your network by connecting with other members who share your interests.',
          icon: Icons.people_outline,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'messages',
      pageName: 'Messages',
      pageDescription: 'Send and receive messages with coaches and members',
      pageIcon: Icons.message_outlined,
      steps: [
        WalkthroughStep(
          id: 'messages_overview',
          title: 'Messages',
          description: 'Send private messages to coaches, members, and groups. Stay connected with your learning community.',
          icon: Icons.message_outlined,
        ),
        WalkthroughStep(
          id: 'messages_conversations',
          title: 'Conversations',
          description: 'View your recent conversations and unread messages at a glance.',
          icon: Icons.chat_bubble_outline,
        ),
        WalkthroughStep(
          id: 'messages_groups',
          title: 'Group Chats',
          description: 'Create or join group conversations to collaborate with multiple members.',
          icon: Icons.groups_outlined,
        ),
        WalkthroughStep(
          id: 'messages_new',
          title: 'New Conversation',
          description: 'Start a new conversation by clicking the compose button and selecting recipients.',
          icon: Icons.edit_outlined,
        ),
      ],
    ),
    PageWalkthrough(
      pageId: 'settings',
      pageName: 'Settings',
      pageDescription: 'Customize your account and preferences',
      pageIcon: Icons.settings_outlined,
      steps: [
        WalkthroughStep(
          id: 'settings_overview',
          title: 'Settings',
          description: 'Customize your account settings, notification preferences, privacy controls, and security options.',
          icon: Icons.settings_outlined,
        ),
        WalkthroughStep(
          id: 'settings_accounts',
          title: 'Account Settings',
          description: 'Update your language, date format, timezone, and time display preferences.',
          icon: Icons.person_outline,
        ),
        WalkthroughStep(
          id: 'settings_notifications',
          title: 'Notifications',
          description: 'Control which notifications you receive via email, push, and in-app alerts.',
          icon: Icons.notifications_outlined,
        ),
        WalkthroughStep(
          id: 'settings_privacy',
          title: 'Privacy',
          description: 'Manage who can see your profile, activity, and control your data preferences.',
          icon: Icons.lock_outline,
        ),
        WalkthroughStep(
          id: 'settings_security',
          title: 'Security',
          description: 'Update your password, enable two-factor authentication, and manage active sessions.',
          icon: Icons.security_outlined,
        ),
        WalkthroughStep(
          id: 'settings_tutorial',
          title: 'Help & Tutorial',
          description: 'Access page-specific walkthroughs to learn how to use each feature of the platform.',
          icon: Icons.help_outline,
        ),
      ],
    ),
  ];

  /// Start a walkthrough for a specific page
  void startWalkthrough(String pageId, {VoidCallback? onComplete}) {
    final walkthrough = availableWalkthroughs.firstWhere(
      (w) => w.pageId == pageId,
      orElse: () => availableWalkthroughs.first,
    );

    _currentPageId = pageId;
    _currentSteps = walkthrough.steps;
    _currentStepIndex = 0;
    _isWalkthroughActive = true;
    _onWalkthroughComplete = onComplete;
    notifyListeners();
  }

  /// Move to the next step
  void nextStep() {
    if (_currentStepIndex < _currentSteps.length - 1) {
      _currentStepIndex++;
      notifyListeners();
    } else {
      endWalkthrough();
    }
  }

  /// Move to the previous step
  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  /// Skip to a specific step
  void goToStep(int index) {
    if (index >= 0 && index < _currentSteps.length) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }

  /// End the current walkthrough
  void endWalkthrough() {
    _isWalkthroughActive = false;
    _currentPageId = null;
    _currentStepIndex = 0;
    _currentSteps = [];
    _onWalkthroughComplete?.call();
    _onWalkthroughComplete = null;
    notifyListeners();
  }

  /// Mark a walkthrough as completed
  Future<void> markWalkthroughCompleted(String pageId) async {
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList('completed_walkthroughs') ?? [];
    if (!completedList.contains(pageId)) {
      completedList.add(pageId);
      await prefs.setStringList('completed_walkthroughs', completedList);
    }
  }

  /// Check if a walkthrough has been completed
  Future<bool> isWalkthroughCompleted(String pageId) async {
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList('completed_walkthroughs') ?? [];
    return completedList.contains(pageId);
  }

  /// Reset all walkthrough completion status
  Future<void> resetAllWalkthroughs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('completed_walkthroughs');
  }

  /// Get PageWalkthrough by pageId
  PageWalkthrough? getWalkthrough(String pageId) {
    try {
      return availableWalkthroughs.firstWhere((w) => w.pageId == pageId);
    } catch (_) {
      return null;
    }
  }
}
