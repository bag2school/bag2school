import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'bagi_identity_settings_page.dart';
import 'services/bagi_app_bootstrap.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'services/bagi_identity_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.publishableKey,
  );

  await BagiAppBootstrap.initialize();

  runApp(const Bag2SchoolApp());
}

class Bag2SchoolApp extends StatelessWidget {
  const Bag2SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bag2School',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFCF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A21),
        ),

        // Give interactive controls a consistent tactile response.
        // This keeps the UI friendly without changing the existing layout.
        splashFactory: InkRipple.splashFactory,
        splashColor: const Color(0x26FF7A21),
        highlightColor: const Color(0x14FF7A21),
        hoverColor: const Color(0x0DFF7A21),
        focusColor: const Color(0x14FF7A21),

        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0x2EFF7A21);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0x14FF7A21);
                }
                return null;
              },
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0x22FF7A21);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0x0FFF7A21);
                }
                return null;
              },
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0x22FF7A21);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0x0FFF7A21);
                }
                return null;
              },
            ),
          ),
        ),

        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            animationDuration: const Duration(milliseconds: 120),
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0x24FF7A21);
                }
                if (states.contains(WidgetState.hovered)) {
                  return const Color(0x12FF7A21);
                }
                return null;
              },
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  static const Color _orange = Color(0xFFFF7A21);
  static const Color _orangeSoft = Color(0xFFFFE8D5);
  static const Color _peach = Color(0xFFFFF1E6);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _purple = Color(0xFF7661D8);
  static const Color _purpleSoft = Color(0xFFF0EDFF);
  static const Color _teal = Color(0xFF2A9D8F);

  List<String> _bagiHomeMessagesForHour(int hour) {
  final parentTitle = BagiIdentityController.parentTitle;
  final childName = Bag2SchoolStore.childName;

  if (hour >= 5 && hour < 12) {
    return [
      "Good morning, $parentTitle! Let's get $childName ready for a great day. 😊",
      "Morning, $parentTitle! Let's make sure $childName starts the day feeling ready. 🎒",
      "Good morning! I'll keep an eye on the little school things with you. ✨",
    ];
  }

  if (hour >= 12 && hour < 18) {
    return [
      "Good afternoon, $parentTitle! Let's see how $childName is doing today. 😊",
      "Afternoon check-in! We can get tomorrow ready little by little. 🎒",
      "Hi $parentTitle! Let's keep today's school things nice and easy. ✨",
    ];
  }

  if (hour >= 18 && hour < 21) {
    return [
      "Good evening, $parentTitle! Let's get tomorrow ready without the rush. 🌙",
      "Evening check-in! We can finish the important little things together. 🎒",
      "Good evening! Let's make sure $childName is ready for tomorrow. ✨",
    ];
  }

  if (hour >= 21 && hour < 24) {
    return [
      "Good night, $parentTitle! Let's keep things calm and get tomorrow ready. 🌙",
      "It's a quiet night. We can finish the important school things together. 🎒",
      "Good night! $childName can rest once tomorrow is ready. ✨",
    ];
  }

  return [
    "It's late, $parentTitle. Let's keep tonight calm and get ready for tomorrow. 🌙",
    "A quiet night is a good time for a quick school check. 🎒",
    "I'm here for the little things, even late at night. ✨",
  ];
}

  Timer? _bagiHomeTimer;
  int _bagiHomeMessageIndex = 0;
  int _bagiHomeVersion = 0;
  String get _bagiHomeVisibleMessageInitial =>
      _bagiHomeMessagesForHour(DateTime.now().hour).first;

  late String _bagiHomeVisibleMessage;


  @override
  void initState() {
    super.initState();
    _bagiHomeVisibleMessage = _bagiHomeVisibleMessageInitial;
    _startBagiHomeConversation();
  }

  @override
  void dispose() {
    _bagiHomeTimer?.cancel();
    super.dispose();
  }

  void _startBagiHomeConversation() {
    _bagiHomeTimer?.cancel();
    _bagiHomeTimer = Timer.periodic(
      const Duration(seconds: 13),
      (_) => _nextBagiHomeMessage(),
    );
  }

  void _nextBagiHomeMessage() {
    if (!mounted) return;
    final messages = _bagiHomeMessagesForHour(DateTime.now().hour);
    _bagiHomeMessageIndex =
        (_bagiHomeMessageIndex + 1) % messages.length;
    final message = messages[_bagiHomeMessageIndex];
    final version = ++_bagiHomeVersion;
    final words = message.split(' ');

    setState(() => _bagiHomeVisibleMessage = '');

    for (var i = 1; i <= words.length; i++) {
      Future.delayed(Duration(milliseconds: 70 * i), () {
        if (!mounted || version != _bagiHomeVersion) return;
        setState(() {
          _bagiHomeVisibleMessage = words.take(i).join(' ');
        });
      });
    }
  }

  DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<BagActivity> _activitiesForDate(DateTime date) {
    final clean = _dayOnly(date);
    final activities = Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(clean))
        .where(
          (activity) =>
              !Bag2SchoolStore.isOccurrenceCancelled(clean, activity.id),
        )
        .toList()
      ..sort((a, b) => a.startMinutes().compareTo(b.startMinutes()));
    return activities;
  }

  List<PreparationItem> _preparationsForDate(DateTime date) {
    final clean = _dayOnly(date);
    final result = <PreparationItem>[];
    final added = <String>{};

    for (final activity in _activitiesForDate(clean)) {
      final items = Bag2SchoolStore.preparationsForOccurrence(
        clean,
        activity.id,
      );
      for (final item in items) {
        if (_isHomeworkPreparationHome(item)) continue;
        if (added.add('${activity.id}|${item.id}')) {
          result.add(item.copyWith(preparationDate: clean));
        }
      }
    }

    // A PreparationItem can exist in the base list even when the occurrence
    // helper returned an overridden/filtered list. Add the date-matching
    // source item for each target activity as a safe fallback.
    for (final item in Bag2SchoolStore.preparations) {
      if (_isHomeworkPreparationHome(item) || !item.occursOn(clean)) continue;
      if (!_activitiesForDate(clean).any((a) => a.id == item.activityId)) {
        continue;
      }
      if (added.add('${item.activityId}|${item.id}')) {
        result.add(item.copyWith(preparationDate: clean));
      }
    }

    return result;
  }

  HomeworkItem? _homeworkForPreparationHome(PreparationItem item) {
    for (final homework in Bag2SchoolStore.homeworks) {
      if (item.id == 'prep-${homework.id}') return homework;
    }
    return null;
  }

  bool _isHomeworkPreparationHome(PreparationItem item) =>
      _homeworkForPreparationHome(item) != null;

  bool _isPreparationChecked(PreparationItem item, DateTime date) {
    final linkedHomework = _homeworkForPreparationHome(item);
    if (linkedHomework != null) {
      final key =
          '${_dayOnly(date).toIso8601String()}|${linkedHomework.id}';
      return Bag2SchoolStore.homeworkPreparationCompletion[key] ?? false;
    }

    final clean = _dayOnly(date);
    final overrideItems = Bag2SchoolStore
        .preparationOccurrenceOverrides[
            Bag2SchoolStore.preparationOccurrenceKey(
          clean,
          item.activityId,
        )];

    if (overrideItems != null) {
      final overrideItem = overrideItems
          .where((entry) => entry.id == item.id)
          .cast<PreparationItem?>()
          .firstWhere((entry) => entry != null, orElse: () => null);
      if (overrideItem != null) return overrideItem.completed;
    }

    return Bag2SchoolStore.preparationOccurrenceCompletion[
          '${clean.toIso8601String()}|${item.id}'
        ] ??
        item.completed;
  }

  bool _isHomeHomeworkChecked(HomeworkItem homework) =>
      homework.completed;

  double _readinessProgress(
    DateTime date,
    List<PreparationItem> preparations,
    List<HomeworkItem> homeworks,
  ) {
    final total = preparations.length + homeworks.length;
    if (total == 0) return 0;

    final prepDone = preparations
        .where((item) => _isPreparationChecked(item, date))
        .length;
    final homeworkDone =
        homeworks.where(_isHomeHomeworkChecked).length;

    return (prepDone + homeworkDone) / total;
  }

  void _toggleHomePreparation(PreparationItem item, DateTime date) {
    final clean = _dayOnly(date);
    final occurrenceKey = Bag2SchoolStore.preparationOccurrenceKey(
      clean,
      item.activityId,
    );
    final current = _isPreparationChecked(item, clean);

    setState(() {
      final overrides =
          Bag2SchoolStore.preparationOccurrenceOverrides[occurrenceKey];

      if (overrides != null) {
        final index = overrides.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          overrides[index] = overrides[index].copyWith(
            completed: !current,
            preparationDate: clean,
          );
          return;
        }
      }

      // Recurring activity: completion is occurrence-local.
      final activity = Bag2SchoolStore.activities.cast<BagActivity?>().firstWhere(
            (entry) => entry?.id == item.activityId,
            orElse: () => null,
          );

      if (activity != null && activity.occursOn(clean)) {
        Bag2SchoolStore.preparationOccurrenceCompletion[
            '${clean.toIso8601String()}|${item.id}'] = !current;
        return;
      }

      // One-time/standalone preparation: update the base item.
      final index = Bag2SchoolStore.preparations.indexWhere(
        (entry) => entry.id == item.id,
      );
      if (index >= 0) {
        Bag2SchoolStore.preparations[index] =
            Bag2SchoolStore.preparations[index].copyWith(
          completed: !current,
          preparationDate: clean,
        );
      }
    });
  }

  void _toggleHomeHomework(HomeworkItem homework) {
    final key =
        '${_dayOnly(homework.dueDate).toIso8601String()}|${homework.id}';
    final current =
        Bag2SchoolStore.homeworkPreparationCompletion[key] ?? false;

    setState(() {
      Bag2SchoolStore.homeworkPreparationCompletion[key] = !current;
    });
  }

  String _formatDateLong(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDayData time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _activityColor(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return _orange;
      case ActivityType.lesson:
        return _purple;
      case ActivityType.extracurricular:
        return const Color(0xFFFF9B3D);
      case ActivityType.exam:
        return _teal;
      case ActivityType.event:
        return const Color(0xFF4C8FD9);
    }
  }

  Color _activityBackground(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFFFFEEE2);
      case ActivityType.lesson:
        return _purpleSoft;
      case ActivityType.extracurricular:
        return const Color(0xFFFFF0E3);
      case ActivityType.exam:
        return const Color(0xFFE5F7F5);
      case ActivityType.event:
        return const Color(0xFFEAF3FF);
    }
  }

  IconData _activityIcon(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return Icons.school_outlined;
      case ActivityType.lesson:
        return Icons.menu_book_outlined;
      case ActivityType.extracurricular:
        return Icons.sports_basketball_outlined;
      case ActivityType.exam:
        return Icons.assignment_outlined;
      case ActivityType.event:
        return Icons.event_outlined;
    }
  }

  bool get _showTodayPreparation {
    final hour = TimeOfDay.now().hour;
    // Early morning is about getting through today's urgent preparation.
    // From 08:00 onwards the home focus shifts to tomorrow.
    return hour < 8;
  }

  Future<void> _chooseActiveChild() async {
    var selectedId = Bag2SchoolStore.activeChildId;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Switch Child',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),
                ...Bag2SchoolStore.childProfiles.map(
                  (child) => RadioListTile<String>(
                    value: child.id,
                    groupValue: selectedId,
                    activeColor: _orange,
                    title: Text(
                      child.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(child.grade),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedId = value);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, selectedId),
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Use this profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted || selected == null) return;
    setState(() {
      Bag2SchoolStore.switchActiveChild(selected);
    });
  }

  Future<void> _pickChildPhoto() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Photo upload will be enabled after the image picker package is added.',
        ),
      ),
    );
  }

  Future<void> _editChildProfile() async {
    final nameController = TextEditingController(text: Bag2SchoolStore.childName);
    final gradeController = TextEditingController(text: Bag2SchoolStore.childGrade);

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cream,
          title: const Text(
            'Child Profile',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickChildPhoto(),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildChildAvatar(size: 92),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: _orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gradeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Grade',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final grade = gradeController.text.trim();
                if (name.isEmpty || grade.isEmpty) return;
                Navigator.pop(
                  dialogContext,
                  {
                    'name': name,
                    'grade': grade,
                  },
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameController.dispose();
        gradeController.dispose();
      });
      return;
    }

    setState(() {
      Bag2SchoolStore.updateActiveChild(
        name: result['name'],
        grade: result['grade'],
      );
    });

    // Let the dialog's TextFields detach before disposing their controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      gradeController.dispose();
    });
  }


  Widget _buildChildAvatar({double size = 68}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE7D2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '👦🏻',
          style: TextStyle(fontSize: size * .58),
        ),
      ),
    );
  }

  Widget _buildHomeBagiCompanion() {
    return IgnorePointer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: const BagiCharacter(),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _purpleSoft,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: const Color(0xFFE0D9FF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      _bagiHomeVisibleMessage.isEmpty
                          ? '...'
                          : _bagiHomeVisibleMessage,
                      key: ValueKey(_bagiHomeVisibleMessage),
                      maxLines: 3,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4D445B),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -6,
                  bottom: 10,
                  child: CustomPaint(
                    size: const Size(10, 16),
                    painter: _BagiHomeBubbleTailPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowSection(DateTime tomorrow) {
    final activities = _activitiesForDate(tomorrow);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: activities.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nothing scheduled for tomorrow yet.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < activities.length; i++) ...[
                  _homeScheduleItem(activities[i]),
                  if (i != activities.length - 1)
                    const Divider(height: 18),
                ],
              ],
            ),
    );
  }

  Widget _homeScheduleItem(BagActivity activity) {
    final color = _activityColor(activity);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _activityBackground(activity),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            _activityIcon(activity),
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_formatTime(activity.startTime)} – ${_formatTime(activity.endTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (activity.type == ActivityType.exam)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'EXAM',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: .7,
                fontWeight: FontWeight.w900,
                color: _teal,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreparationSummary(DateTime targetDate) {
    final preparations = _preparationsForDate(targetDate);
    final targetHomeworks = _homeworksForDate(targetDate);
    final totalItems = preparations.length + targetHomeworks.length;
    final progress = _readinessProgress(
      targetDate,
      preparations,
      targetHomeworks,
    );
    final done = (progress * totalItems).round();
    final isTodayFocus = _showTodayPreparation;
    final title = isTodayFocus ? 'GET READY FOR TODAY' : 'READY FOR TOMORROW';
    final emptyText = isTodayFocus
        ? 'No preparation or homework for today.'
        : 'No preparation or homework for tomorrow yet.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF641C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDateLong(targetDate),
            style: const TextStyle(
              fontSize: 12,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (totalItems == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                SizedBox(
                  width: 105,
                  height: 105,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 11,
                        backgroundColor: Colors.white,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_orange),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'ready',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF655B55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$done of $totalItems ready',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalItems - done} left',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Real Preparation items.
            ...preparations.map((item) {
              final checked = _isPreparationChecked(item, targetDate);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _toggleHomePreparation(item, targetDate),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          checked
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 21,
                          color:
                              checked ? const Color(0xFF55A56B) : _orange,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Builder(
                            builder: (_) {
                              BagActivity? related;
                              for (final activity in _activitiesForDate(targetDate)) {
                                if (activity.id == item.activityId) {
                                  related = activity;
                                  break;
                                }
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                      decoration: checked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (related != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      related!.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: _muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Homework uses the same readiness checklist, but its completion
            // is linked to the Homework page so the state stays in sync.
            ...targetHomeworks.map((homework) {
              final key =
                  '${_dayOnly(targetDate).toIso8601String()}|${homework.id}';
              final checked =
                  Bag2SchoolStore.homeworkPreparationCompletion[key] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _toggleHomeHomework(homework),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _purpleSoft,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFE0D9FF),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          checked
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 21,
                          color:
                              checked ? const Color(0xFF55A56B) : _purple,
                        ),
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E1FF),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'HOMEWORK',
                            style: TextStyle(
                              fontSize: 8.5,
                              letterSpacing: .6,
                              fontWeight: FontWeight.w900,
                              color: _purple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            homework.task,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              decoration: checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PreparationPage(),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Check Preparation →',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  List<HomeworkItem> _homeworksForHome() {
    final now = _dayOnly(DateTime.now());
    return Bag2SchoolStore.homeworks
        .where((homework) => !homework.completed)
        .toList()
      ..sort((a, b) {
        final aOverdue = _dayOnly(a.dueDate).isBefore(now);
        final bOverdue = _dayOnly(b.dueDate).isBefore(now);
        if (aOverdue != bOverdue) return aOverdue ? -1 : 1;
        return a.dueDate.compareTo(b.dueDate);
      });
  }


  List<HomeworkItem> _homeworksForDate(DateTime date) {
    final clean = _dayOnly(date);
    return Bag2SchoolStore.homeworks
        .where((homework) => _dayOnly(homework.dueDate) == clean)
        .toList()
      ..sort((a, b) {
        final aTime = a.dueTime?.totalMinutes ?? 1440;
        final bTime = b.dueTime?.totalMinutes ?? 1440;
        return aTime.compareTo(bTime);
      });
  }

  Widget _buildHomeworkSummary() {
    final homework = _homeworksForHome();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _purpleSoft,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0D9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: _purple,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'HOMEWORK TO DO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            homework.isEmpty
                ? 'Everything is caught up. Great job! 🎉'
                : '${homework.length} homework item${homework.length == 1 ? '' : 's'} still need attention.',
            style: const TextStyle(
              fontSize: 12.5,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (homework.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...homework.take(3).map((item) {
              final overdue = _dayOnly(item.dueDate)
                  .isBefore(_dayOnly(DateTime.now()));
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .75),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        overdue
                            ? Icons.warning_amber_rounded
                            : Icons.book_outlined,
                        size: 20,
                        color: overdue ? const Color(0xFFD94B4B) : _purple,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.task,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              overdue
                                  ? 'Overdue · ${_formatDateLong(item.dueDate)}'
                                  : 'Due · ${_formatDateLong(item.dueDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: overdue
                                    ? const Color(0xFFD94B4B)
                                    : _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeworkPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(color: Color(0xFFCFC4F7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Open Homework'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  
    void _openNotificationTarget(LocalFamilyNotification notification) {
    Bag2SchoolStore.switchActiveChild(notification.childId);
    switch (notification.entityType) {
      case 'schedule':
      case 'exam':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePage()),
        );
        break;
      case 'homework':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeworkPage()),
        );
        break;
      case 'preparation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreparationPage(
              completed: const <bool>[false, false, false],
              onChanged: (_, __) {},
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FamilyActivityPage()),
        );
    }
  }

  void _openAccessResponseTarget(LocalAccessRequest request) {
    Bag2SchoolStore.switchActiveChild(request.childId);
    switch (request.feature) {
      case LocalPermissionFeature.schedule:
      case LocalPermissionFeature.exam:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePage()),
        );
        break;
      case LocalPermissionFeature.homework:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeworkPage()),
        );
        break;
      case LocalPermissionFeature.preparation:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreparationPage(
              completed: const <bool>[false, false, false],
              onChanged: (_, __) {},
            ),
          ),
        );
        break;
    }
  }

Future<void> _showNotifications() async {
    Bag2SchoolStore.pruneNotificationInbox();

    Bag2SchoolStore.markCurrentNotificationsRead();
    if (mounted) setState(() {});

    final isOwner =
        Bag2SchoolStore.currentAccount?.familyMemberId == 'member-owner';
    final activityNotifications =
        Bag2SchoolStore.notificationsForCurrentMember();
    final recentNotifications =
        activityNotifications.take(5).toList();
    List<LocalAccessRequest> pendingRequests() =>
        Bag2SchoolStore.accessRequests
            .where(
              (request) =>
                  request.status == AccessRequestStatus.pending,
            )
            .toList();

    if (!isOwner) {
      final responses =
          Bag2SchoolStore.responseNotificationsForCurrentMember();

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Family Updates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Access responses and family updates',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 14),
              if (responses.isEmpty && activityNotifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 42,
                        color: _orange,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No new updates.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              if (activityNotifications.isNotEmpty)
                ...recentNotifications.map(
                  (notification) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: _orange,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notification.message,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: _muted,
                                ),
                              ),                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openNotificationTarget(notification),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                label: const Text('View'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  foregroundColor: _orange,
                                  side: const BorderSide(
                                    color: Color(0xFFFFC18F),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (activityNotifications.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 10),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FamilyActivityPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('View all notifications'),
                  ),
                ),
              if (responses.isNotEmpty)
                ...responses.map(
                  (request) {
                    final child = Bag2SchoolStore.childProfiles
                        .where((entry) => entry.id == request.childId)
                        .cast<ChildProfile?>()
                        .firstWhere(
                          (entry) => entry != null,
                          orElse: () => null,
                        );
                    final feature =
                        LocalAuthorization.featureLabel(request.feature);
                    final approved =
                        request.status == AccessRequestStatus.approved;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            approved
                                ? Icons.verified_rounded
                                : Icons.block_rounded,
                            color: approved
                                ? const Color(0xFF55A56B)
                                : const Color(0xFFB55252),
                            size: 25,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  approved
                                      ? (request.requestEdit
                                          ? 'Edit access granted: $feature for ${child?.name ?? 'this child'}.'
                                          : 'Access granted: $feature for ${child?.name ?? 'this child'}.')
                                      : (request.requestEdit
                                          ? 'Edit access request declined: $feature for ${child?.name ?? 'this child'}.'
                                          : 'Access request declined: $feature for ${child?.name ?? 'this child'}.'),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _openAccessResponseTarget(request),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('View'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 32),
                                    foregroundColor: _orange,
                                    side: const BorderSide(
                                      color: Color(0xFFFFC18F),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
      return;
    }

    if (pendingRequests().isEmpty && activityNotifications.isEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 42,
                  color: _orange,
                ),
                SizedBox(height: 8),
                Text(
                  'Family Updates',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'No new access requests.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final pending = pendingRequests();
          return SafeArea(
            child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Text(
                'Family Updates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Access requests from family members',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 14),
              if (activityNotifications.isNotEmpty)
                ...recentNotifications.map(
                  (notification) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: _orange,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notification.message,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: _muted,
                                ),
                              ),                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openNotificationTarget(notification),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                label: const Text('View'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  foregroundColor: _orange,
                                  side: const BorderSide(
                                    color: Color(0xFFFFC18F),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (activityNotifications.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 10),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FamilyActivityPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('View all notifications'),
                  ),
                ),
              ...pending.map(
                (request) {
                  final member = Bag2SchoolStore.familyMembers
                      .where(
                        (entry) =>
                            entry.id == request.requesterMemberId,
                      )
                      .cast<FamilyMember?>()
                      .firstWhere(
                        (entry) => entry != null,
                        orElse: () => null,
                      );
                  final child = Bag2SchoolStore.childProfiles
                      .where(
                        (entry) => entry.id == request.childId,
                      )
                      .cast<ChildProfile?>()
                      .firstWhere(
                        (entry) => entry != null,
                        orElse: () => null,
                      );
                  final memberName =
                      member?.displayName ?? 'Family member';
                  final childName = child?.name ?? 'Child';
                  final feature =
                      LocalAuthorization.featureLabel(request.feature);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$memberName requests access',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$feature · $childName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final index = Bag2SchoolStore
                                      .accessRequests
                                      .indexWhere(
                                        (entry) =>
                                            entry.id == request.id,
                                      );
                                  if (index >= 0) {
                                    Bag2SchoolStore.accessRequests[index] =
                                        request.copyWith(
                                      status: AccessRequestStatus.denied,
                                    );
                                  }
                                  setSheetState(() {});
                                  setState(() {});
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      const Color(0xFFB55252),
                                  side: const BorderSide(
                                    color: Color(0xFFE6B7B7),
                                  ),
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  final memberId =
                                      request.requesterMemberId;
                                  final childId =
                                      request.childId;
                                  final existing =
                                      Bag2SchoolStore.accessGrantFor(
                                    childId,
                                    memberId,
                                  );
                                  final updated =
                                      existing ??
                                          FamilyAccessGrant(
                                            memberId: memberId,
                                            childId: childId,
                                          );
                                  final granted = switch (
                                      request.feature) {
                                    LocalPermissionFeature.schedule =>
                                      updated.copyWith(
                                        viewSchedule: true,
                                        editSchedule:
                                            request.requestEdit ||
                                                updated.editSchedule,
                                      ),
                                    LocalPermissionFeature.homework =>
                                      updated.copyWith(
                                        viewHomework: true,
                                        editHomework:
                                            request.requestEdit ||
                                                updated.editHomework,
                                      ),
                                    LocalPermissionFeature.preparation =>
                                      updated.copyWith(
                                        viewPreparation: true,
                                        editPreparation:
                                            request.requestEdit ||
                                                updated.editPreparation,
                                      ),
                                    LocalPermissionFeature.exam =>
                                      updated.copyWith(
                                        viewExam: true,
                                        editExam:
                                            request.requestEdit ||
                                                updated.editExam,
                                      ),
                                  };

                                  Bag2SchoolStore.saveAccessGrant(granted);

                                  final index = Bag2SchoolStore
                                      .accessRequests
                                      .indexWhere(
                                        (entry) =>
                                            entry.id == request.id,
                                      );
                                  if (index >= 0) {
                                    Bag2SchoolStore.accessRequests[index] =
                                        request.copyWith(
                                      status: AccessRequestStatus.approved,
                                    );
                                  }
                                  setSheetState(() {});
                                  setState(() {});
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: _orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            ),
          );
        },
      ),
    );
  }

Widget build(BuildContext context) {
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final targetPreparationDate =
        _showTodayPreparation ? today : tomorrow;

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Bag2SchoolLogo(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: _showNotifications,
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 30,
                          color: Color(0xFF40352F),
                        ),
                      ),
                      if (Bag2SchoolStore.pendingAccessRequestCount > 0 ||
                          Bag2SchoolStore.currentMemberNotificationCount > 0)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 21,
                            height: 21,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${Bag2SchoolStore.pendingAccessRequestCount +
                                    Bag2SchoolStore.currentMemberNotificationCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Child profile — editing is available only from Settings.
              Container(
                padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .04),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildChildAvatar(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Bag2SchoolStore.childName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              Bag2SchoolStore.childGrade,
                              style: const TextStyle(
                                fontSize: 16,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: _chooseActiveChild,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 15,
                                    color: _orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Switch child',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _orange,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // Bagi now lives between child profile and Tomorrow.
              _buildHomeBagiCompanion(),

              const SizedBox(height: 22),

              Text(
                'TOMORROW',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateLong(tomorrow),
                style: const TextStyle(
                  fontSize: 15.5,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _buildTomorrowSection(tomorrow),

              const SizedBox(height: 22),
              _buildPreparationSummary(targetPreparationDate),

              const SizedBox(height: 20),
              _buildHomeworkSummary(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchedulePage()),
            ).then((_) {
              if (mounted) setState(() {});
            });
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreparationPage()),
            ).then((_) {
              if (mounted) setState(() {});
            });
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeworkPage()),
            );
            return;
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ).then((_) {
              if (mounted) setState(() {});
            });
            return;
          }

          setState(() => selectedIndex = index);
        },
        indicatorColor: const Color(0xFFFFE2CF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Preparation',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _purple = Color(0xFF7661D8);
  static const Color _blue = Color(0xFF4C8FD9);
  static const Color _teal = Color(0xFF2A9D8F);
  static const Color _cream = Color(0xFFFFFCF8);

  String get _languageLabel =>
      Bag2SchoolStore.languageCode == 'id'
          ? 'Bahasa Indonesia'
          : 'English';

  Future<void> _chooseLanguage() async {
    var selectedLanguage = Bag2SchoolStore.languageCode;

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _cream,
            title: const Text(
              'Language',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _orange,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'en',
                  groupValue: selectedLanguage,
                  title: const Text('English'),
                  activeColor: _orange,
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedLanguage = value);
                  },
                ),
                RadioListTile<String>(
                  value: 'id',
                  groupValue: selectedLanguage,
                  title: const Text('Bahasa Indonesia'),
                  activeColor: _orange,
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedLanguage = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, selectedLanguage),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted || selected == null) return;
    setState(() {
      Bag2SchoolStore.languageCode = selected;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language set to ${selected == 'id' ? 'Bahasa Indonesia' : 'English'}.',
        ),
      ),
    );
  }


  Future<void> _editChildProfile() async {
    final nameController = TextEditingController(text: Bag2SchoolStore.childName);
    final gradeController = TextEditingController(text: Bag2SchoolStore.childGrade);

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: const Text(
          'Child Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE7D2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '👦🏻',
                    style: TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gradeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Photo upload will be added after local profile storage is ready.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final grade = gradeController.text.trim();
              if (name.isEmpty || grade.isEmpty) return;
              Navigator.pop(
                dialogContext,
                {'name': name, 'grade': grade},
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      gradeController.dispose();
    });

    if (!mounted || result == null) return;
    setState(() {
      Bag2SchoolStore.updateActiveChild(
        name: result['name'],
        grade: result['grade'],
      );
    });
  }

  void _showComingSoon(String title, String description) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 9),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w900,
          color: _muted,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: _muted,
            ),
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: _muted,
            ),
      ),
    );
  }

  Widget _buildAccountCard() {
    final account = Bag2SchoolStore.currentAccount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account?.displayName ?? 'My Account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account?.email ?? 'Not signed in',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocalAccountPage(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(_orange),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Color(0xFFFFC18F)),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              ),
            ),
            child: Text(
              account == null ? 'Sign in' : 'Manage',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChildEditor({
    ChildProfile? child,
  }) async {
    final nameController =
        TextEditingController(text: child?.name ?? '');
    final gradeController =
        TextEditingController(text: child?.grade ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: Text(
          child == null ? 'Add Child' : 'Child Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: _orange,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE7D2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '👦🏻',
                    style: TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gradeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final grade = gradeController.text.trim();
              if (name.isEmpty || grade.isEmpty) return;
              Navigator.pop(
                dialogContext,
                {'name': name, 'grade': grade},
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      gradeController.dispose();
    });

    if (!mounted || result == null) return;
    setState(() {
      if (child == null) {
        final id =
            'child-${DateTime.now().microsecondsSinceEpoch}';
        Bag2SchoolStore.childProfiles.add(
          ChildProfile(
            id: id,
            name: result['name']!,
            grade: result['grade']!,
          ),
        );
        Bag2SchoolStore.switchActiveChild(id);
      } else {
        final index = Bag2SchoolStore.childProfiles
            .indexWhere((entry) => entry.id == child.id);
        if (index >= 0) {
          Bag2SchoolStore.childProfiles[index] =
              child.copyWith(
            name: result['name'],
            grade: result['grade'],
          );
        }
      }
    });
  }

  Future<void> _chooseSettingsChild() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Select Active Child',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ),
            ...Bag2SchoolStore.childProfiles.map(
              (child) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE7D2),
                  child: Text('👦🏻'),
                ),
                title: Text(
                  child.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(child.grade),
                trailing: child.id == Bag2SchoolStore.activeChildId
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: _orange,
                      )
                    : null,
                onTap: () =>
                    Navigator.pop(sheetContext, child.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;
    setState(() {
      Bag2SchoolStore.switchActiveChild(selected);
    });
  }

  Widget _buildChildProfilesSection({required bool canManage}) {
    return Column(
      children: [
        _sectionTitle('Child Profiles'),
        ...Bag2SchoolStore.childProfiles.map(
          (child) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              onTap: canManage
                  ? () => _showChildEditor(child: child)
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ),
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFFE7D2),
                child: Text(
                  '👦🏻',
                  style: TextStyle(fontSize: 25),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  if (child.id == Bag2SchoolStore.activeChildId)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBDD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w900,
                          color: _orange,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(child.grade),
              trailing: canManage
                  ? const Icon(
                      Icons.edit_outlined,
                      color: _muted,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ),
        if (canManage)
          OutlinedButton.icon(
            onPressed: () => _showChildEditor(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Child'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: Color(0xFFFFC18F)),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole =
        Bag2SchoolStore.familyMemberForCurrentAccount()?.role;
    final canManageChildren =
        currentRole == FamilyMemberRole.owner ||
        currentRole == FamilyMemberRole.parentGuardian;
    final isOwner = currentRole == FamilyMemberRole.owner;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.popUntil(
            context,
            (route) => route.isFirst,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _orange,
          ),
        ),
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        children: [
          _buildAccountCard(),
          const SizedBox(height: 12),
          _buildChildProfilesSection(canManage: canManageChildren),

          _sectionTitle('Account & Family'),
          _settingTile(
            icon: Icons.person_outline_rounded,
            color: _orange,
            title: 'Account',
            subtitle: Bag2SchoolStore.isSignedIn
                ? (Bag2SchoolStore.currentAccount?.email ?? 'Signed in')
                : 'Not signed in',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocalAccountPage(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          _settingTile(
            icon: Icons.auto_awesome_rounded,
            color: _orange,
            title: '✨ Bagi',
            subtitle: 'Choose how Bagi should call you',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BagiIdentitySettingsPage(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          _settingTile(
            icon: Icons.family_restroom_rounded,
            color: _purple,
            title: 'Family',
            subtitle: 'Members, children and access',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FamilySettingsPage(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),

          _sectionTitle('Data & Sync'),
          _settingTile(
            icon: Icons.cloud_outlined,
            color: _blue,
            title: 'Cloud Backup & Sync',
            subtitle: 'Keep Bag2School data safe across devices',
            onTap: () => _showComingSoon(
              'Cloud Backup & Sync',
              'Cloud backup will be implemented before multi-device family synchronization.',
            ),
          ),

          _sectionTitle('Notifications'),
          _settingTile(
            icon: Icons.notifications_none_rounded,
            color: _orange,
            title: 'Family Activity',
            subtitle: 'See who added, edited or deleted family data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FamilyActivityPage(),
                ),
              );
            },
          ),

          _sectionTitle('Language'),
          _settingTile(
            icon: Icons.language_rounded,
            color: _orange,
            title: 'Language',
            subtitle: _languageLabel,
            onTap: _chooseLanguage,
          ),

          _sectionTitle('Subscription'),
          _settingTile(
            icon: Icons.workspace_premium_outlined,
            color: _teal,
            title: 'Subscription',
            subtitle: 'Bag2School Free',
            onTap: () => _showComingSoon(
              'Subscription',
              'Subscription will be added when the premium feature set is ready.',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'FREE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w900,
                  color: _teal,
                ),
              ),
            ),
          ),

          _sectionTitle('About'),
          _settingTile(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF7D6D64),
            title: 'About Bag2School',
            subtitle: 'Version 13 · School life, made simpler',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Bag2School',
              applicationVersion: 'V13',
              applicationLegalese:
                  'A friendly school companion for children and families.',
            ),
          ),
        ],
      ),
    );
  }
}



class FamilyActivityPage extends StatefulWidget {
  const FamilyActivityPage({super.key});

  @override
  State<FamilyActivityPage> createState() => _FamilyActivityPageState();
}

class _FamilyActivityPageState extends State<FamilyActivityPage> {
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);

  String _filter = 'All';

  String _actorName(String memberId) {
    final index = Bag2SchoolStore.familyMembers.indexWhere(
      (member) => member.id == memberId,
    );
    return index >= 0
        ? Bag2SchoolStore.familyMembers[index].displayName
        : 'Family member';
  }

  String _featureLabel(LocalPermissionFeature feature) =>
      LocalAuthorization.featureLabel(feature);

  @override
  Widget build(BuildContext context) {
    final all = [...Bag2SchoolStore.familyActivities]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final filtered = _filter == 'All'
        ? all
        : all
            .where(
              (activity) =>
                  _featureLabel(activity.feature) == _filter,
            )
            .toList();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family Activity',
          style: TextStyle(
            color: _orange,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                for (final filter in const [
                  'All',
                  'Schedule',
                  'Homework',
                  'Preparation',
                  'Exam',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      selectedColor: const Color(0xFFFFE2CF),
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No family activity yet.\nChanges made by family members will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final activity = filtered[index];
                      final actor = _actorName(activity.actorMemberId);
                      final child = Bag2SchoolStore.childProfiles
                          .where((entry) => entry.id == activity.childId)
                          .cast<ChildProfile?>()
                          .firstWhere(
                            (entry) => entry != null,
                            orElse: () => null,
                          );
                      final time =
                          '${activity.createdAt.day}/${activity.createdAt.month} '
                          '${activity.createdAt.hour.toString().padLeft(2, '0')}:'
                          '${activity.createdAt.minute.toString().padLeft(2, '0')}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  activity.action == 'Deleted'
                                      ? const Color(0xFFFFE3E3)
                                      : const Color(0xFFFFEBDD),
                              child: Icon(
                                activity.action == 'Added'
                                    ? Icons.add_rounded
                                    : activity.action == 'Edited'
                                        ? Icons.edit_outlined
                                        : Icons.delete_outline_rounded,
                                size: 19,
                                color: activity.action == 'Deleted'
                                    ? const Color(0xFFC95757)
                                    : _orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$actor · ${child?.name ?? 'Child'}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    activity.message,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.35,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class LocalAccountPage extends StatefulWidget {
  const LocalAccountPage({super.key});

  @override
  State<LocalAccountPage> createState() => _LocalAccountPageState();
}

class _LocalAccountPageState extends State<LocalAccountPage> {
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _cream = Color(0xFFFFFCF8);

  Future<void> _editAccount() async {
    final account = Bag2SchoolStore.currentAccount;
    if (account == null) return;

    final nameController = TextEditingController(
      text: account.displayName,
    );
    final emailController = TextEditingController(
      text: account.email,
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: const Text(
          'My Account',
          style: TextStyle(
            color: _orange,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Local simulation only. Real email verification will be handled by authentication later.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              if (name.isEmpty || email.isEmpty) return;
              Navigator.pop(
                dialogContext,
                {'name': name, 'email': email},
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      emailController.dispose();
    });

    if (!mounted || result == null) return;
    setState(() {
      Bag2SchoolStore.updateCurrentAccount(
        displayName: result['name'],
        email: result['email'],
      );
      final currentMember =
          Bag2SchoolStore.familyMemberForCurrentAccount();
      if (currentMember != null) {
        final memberIndex = Bag2SchoolStore.familyMembers.indexWhere(
          (member) => member.id == currentMember.id,
        );
        if (memberIndex >= 0) {
          Bag2SchoolStore.familyMembers[memberIndex] =
              Bag2SchoolStore.familyMembers[memberIndex].copyWith(
            displayName: result['name'],
          );
        }
      }
    });
  }

  Future<void> _showLocalSignIn() async {
    final available = Bag2SchoolStore.localAccounts;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                'Local Test Accounts',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ),
            ...available.map(
              (account) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBDD),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: _orange,
                  ),
                ),
                title: Text(
                  account.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(account.email),
                trailing: account.id == Bag2SchoolStore.currentAccountId
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: _orange,
                      )
                    : null,
                onTap: () =>
                    Navigator.pop(sheetContext, account.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;
    setState(() {
      Bag2SchoolStore.signInLocal(selected);
    });
  }

  String _roleLabel(FamilyMemberRole role) {
    switch (role) {
      case FamilyMemberRole.owner:
        return 'Owner';
      case FamilyMemberRole.parentGuardian:
        return 'Parent / Guardian';
      case FamilyMemberRole.caregiver:
        return 'Caregiver';
      case FamilyMemberRole.child:
        return 'Child';
    }
  }

  Widget _accessSummary(String childId) {
    final member = Bag2SchoolStore.familyMemberForCurrentAccount();
    if (member == null) {
      return const SizedBox.shrink();
    }

    final child = Bag2SchoolStore.childProfiles.firstWhere(
      (entry) => entry.id == childId,
      orElse: () => Bag2SchoolStore.childProfiles.first,
    );
    final grant = Bag2SchoolStore.currentGrantForChild(childId);

    final isOwner = member.role == FamilyMemberRole.owner;

    final rows = <(String, bool, bool)>[
      (
        'Schedule',
        isOwner ? true : (grant?.viewSchedule ?? false),
        isOwner ? true : (grant?.editSchedule ?? false),
      ),
      (
        'Homework',
        isOwner ? true : (grant?.viewHomework ?? false),
        isOwner ? true : (grant?.editHomework ?? false),
      ),
      (
        'Preparation',
        isOwner ? true : (grant?.viewPreparation ?? false),
        isOwner ? true : (grant?.editPreparation ?? false),
      ),
      (
        'Exam',
        isOwner ? true : (grant?.viewExam ?? false),
        isOwner ? true : (grant?.editExam ?? false),
      ),
    ];

    final visibleRows = rows.where((row) => row.$2).toList();

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Access · ${child.name}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${member.displayName} · ${_roleLabel(member.role)}',
            style: const TextStyle(
              fontSize: 11,
              color: _muted,
            ),
          ),
          const SizedBox(height: 12),
          if (visibleRows.isEmpty)
            const Text(
              'No access granted for this child.',
              style: TextStyle(
                fontSize: 11.5,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...visibleRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: Color(0xFF55A56B),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Icon(
                      row.$3
                          ? Icons.edit_rounded
                          : Icons.lock_outline_rounded,
                      size: 16,
                      color: row.$3 ? _orange : _muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      row.$3 ? 'Edit' : 'View only',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final account = Bag2SchoolStore.currentAccount;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            color: _orange,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBDD),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    size: 42,
                    color: _orange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  account?.displayName ?? 'Not signed in',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account?.email ?? 'No local account selected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 16),
                if (account != null)
                  OutlinedButton.icon(
                    onPressed: _editAccount,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orange,
                      side: const BorderSide(
                        color: Color(0xFFFFC18F),
                      ),
                    ),
                  )
                else
                  FilledButton(
                    onPressed: _showLocalSignIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign in'),
                  ),
              ],
            ),
          ),
          if (account != null &&
              Bag2SchoolStore.childProfiles.isNotEmpty)
            _accessSummary(Bag2SchoolStore.activeChildId),
          const SizedBox(height: 18),
          if (account != null)
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: _orange,
              ),
              title: const Text(
                'Sign out',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Local test session only',
              ),
              onTap: () {
                setState(() {
                  Bag2SchoolStore.signOutLocal();
                });
              },
            )
          else
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(
                Icons.login_rounded,
                color: _orange,
              ),
              title: const Text(
                'Local test sign in',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Choose a local account for testing',
              ),
              onTap: _showLocalSignIn,
            ),
          const SizedBox(height: 18),
          const Text(
            'V13 local simulation',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class FamilySettingsPage extends StatefulWidget {
  const FamilySettingsPage({super.key});

  @override
  State<FamilySettingsPage> createState() => _FamilySettingsPageState();
}

class _FamilySettingsPageState extends State<FamilySettingsPage> {
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _purple = Color(0xFF7661D8);
  static const Color _cream = Color(0xFFFFFCF8);

  String _roleLabel(FamilyMemberRole role) {
    switch (role) {
      case FamilyMemberRole.owner:
        return 'Owner';
      case FamilyMemberRole.parentGuardian:
        return 'Parent / Guardian';
      case FamilyMemberRole.caregiver:
        return 'Caregiver';
      case FamilyMemberRole.child:
        return 'Child';
    }
  }

  String _accessLabel(ChildAccessMode mode) {
    switch (mode) {
      case ChildAccessMode.managed:
        return 'Managed';
      case ChildAccessMode.shared:
        return 'Shared';
      case ChildAccessMode.independent:
        return 'Independent';
    }
  }

  Future<void> _showMemberEditor({
    FamilyMember? member,
  }) async {
    final nameController =
        TextEditingController(text: member?.displayName ?? '');
    var selectedRole =
        member?.role ?? FamilyMemberRole.parentGuardian;

    final result = await showDialog<Map<String, Object>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cream,
          title: Text(
            member == null ? 'Add Family Member' : 'Edit Family Member',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _orange,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<FamilyMemberRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: FamilyMemberRole.values
                    .where(
                      (role) =>
                          role != FamilyMemberRole.owner ||
                          member?.role == FamilyMemberRole.owner,
                    )
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedRole = value);
                  }
                },
              ),
              if (member?.role == FamilyMemberRole.owner) ...[
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'The family has one Owner. Owner role cannot be assigned to another member.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (member != null && member.role != FamilyMemberRole.owner)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      backgroundColor: _cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: const Text(
                        'Delete family member?',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      content: Text(
                        'Remove ${member.displayName} from the family? '
                        'Their family access and local account will also be removed.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(confirmContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD94B4B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete Member'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && dialogContext.mounted) {
                    Navigator.pop(
                      dialogContext,
                      <String, Object>{'delete': true},
                    );
                  }
                },
                child: const Text(
                  'Delete Member',
                  style: TextStyle(color: Color(0xFFD94B4B)),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                // Owner is unique. A new member may not be promoted to Owner.
                if (selectedRole == FamilyMemberRole.owner &&
                    (member == null ||
                        member.id !=
                            Bag2SchoolStore.familyMembers
                                .firstWhere(
                                  (m) => m.role == FamilyMemberRole.owner,
                                  orElse: () =>
                                      const FamilyMember(
                                    id: '__none__',
                                    displayName: '',
                                    role: FamilyMemberRole.owner,
                                  ),
                                )
                                .id)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Only one family Owner is allowed.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  <String, Object>{
                    'name': name,
                    'role': selectedRole,
                  },
                );
              },
              child: Text(member == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameController.dispose();
      });
      return;
    }

    if (result['delete'] == true && member != null) {
      setState(() {
        final memberId = member.id;

        Bag2SchoolStore.familyMembers.removeWhere(
          (entry) => entry.id == memberId,
        );

        Bag2SchoolStore.localAccounts.removeWhere(
          (account) => account.familyMemberId == memberId,
        );

        Bag2SchoolStore.familyAccessGrants.removeWhere(
          (key, grant) => grant.memberId == memberId,
        );

        final removedRequestIds = Bag2SchoolStore.accessRequests
            .where((request) => request.requesterMemberId == memberId)
            .map((request) => request.id)
            .toSet();

        Bag2SchoolStore.accessRequests.removeWhere(
          (request) => request.requesterMemberId == memberId,
        );

        Bag2SchoolStore.readAccessRequestIds
            .removeWhere(removedRequestIds.contains);
        Bag2SchoolStore.readAccessResponseIds
            .removeWhere(removedRequestIds.contains);

        final removedNotificationIds =
            Bag2SchoolStore.familyNotifications
                .where(
                  (notification) =>
                      notification.recipientMemberId == memberId,
                )
                .map((notification) => notification.id)
                .toSet();

        Bag2SchoolStore.familyNotifications.removeWhere(
          (notification) => notification.recipientMemberId == memberId,
        );

        Bag2SchoolStore.readNotificationIds
            .removeWhere(removedNotificationIds.contains);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameController.dispose();
      });
      return;
    }

    setState(() {
      final name = result['name']! as String;
      final role = result['role']! as FamilyMemberRole;

      if (member == null) {
        final memberId =
            'member-${DateTime.now().microsecondsSinceEpoch}';
        final accountId =
            Bag2SchoolStore.createLocalAccountForFamilyMember(
          memberId: memberId,
          displayName: name,
        );
        Bag2SchoolStore.familyMembers.add(
          FamilyMember(
            id: memberId,
            displayName: name,
            role: role == FamilyMemberRole.owner
                ? FamilyMemberRole.parentGuardian
                : role,
            accountId: accountId,
          ),
        );
      } else {
        final index = Bag2SchoolStore.familyMembers
            .indexWhere((entry) => entry.id == member.id);
        if (index >= 0) {
          Bag2SchoolStore.familyMembers[index] = member.copyWith(
            displayName: name,
            role: member.role == FamilyMemberRole.owner
                ? FamilyMemberRole.owner
                : (role == FamilyMemberRole.owner
                    ? FamilyMemberRole.parentGuardian
                    : role),
          );

          final accountIndex =
              Bag2SchoolStore.localAccounts.indexWhere(
            (account) => account.familyMemberId == member.id,
          );
          if (accountIndex >= 0) {
            Bag2SchoolStore.localAccounts[accountIndex] =
                Bag2SchoolStore.localAccounts[accountIndex].copyWith(
              displayName: name,
            );
          }
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
    });
  }

  Future<void> _grantAccess(ChildProfile child, {String? initialMemberId}) async {
    final eligibleMembers = Bag2SchoolStore.familyMembers
        .where((member) => member.id != 'member-owner')
        .toList();

    if (eligibleMembers.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Family Member Yet'),
          content: const Text(
            'Add a Family Member first, then you can grant access to this child.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    FamilyMember selectedMember = eligibleMembers.firstWhere(
      (member) => member.id == initialMemberId,
      orElse: () => eligibleMembers.first,
    );
    var viewSchedule = false;
    var editSchedule = false;
    var viewHomework = false;
    var editHomework = false;
    var viewPreparation = false;
    var editPreparation = false;
    var viewExam = false;
    var editExam = false;

    var accessChanged = false;

    final existing =
        Bag2SchoolStore.accessGrantFor(child.id, selectedMember.id);
    if (existing != null) {
      viewSchedule = existing.viewSchedule;
      editSchedule = existing.editSchedule;
      viewHomework = existing.viewHomework;
      editHomework = existing.editHomework;
      viewPreparation = existing.viewPreparation;
      editPreparation = existing.editPreparation;
      viewExam = existing.viewExam;
      editExam = existing.editExam;
    }

    final result = await showDialog<FamilyAccessGrant>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cream,
          title: Text(
            'Grant Access · ${child.name}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _orange,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FamilyMember>(
                  value: selectedMember,
                  decoration: const InputDecoration(
                    labelText: 'Family member',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: eligibleMembers
                      .map(
                        (member) => DropdownMenuItem<FamilyMember>(
                          value: member,
                          child: Text(member.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (member) {
                    if (member == null) return;
                    setDialogState(() {
                      selectedMember = member;
                      final saved = Bag2SchoolStore.accessGrantFor(
                        child.id,
                        member.id,
                      );
                      viewSchedule = saved?.viewSchedule ?? false;
                      editSchedule = saved?.editSchedule ?? false;
                      viewHomework = saved?.viewHomework ?? false;
                      editHomework = saved?.editHomework ?? false;
                      viewPreparation = saved?.viewPreparation ?? false;
                      editPreparation = saved?.editPreparation ?? false;
                      viewExam = saved?.viewExam ?? false;
                      editExam = saved?.editExam ?? false;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What this member can access',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: viewSchedule,
                  activeColor: _orange,
                  title: const Text('View Schedule'),
                  onChanged: (value) =>
                      setDialogState(() => viewSchedule = value),
                ),
                SwitchListTile(
                  value: editSchedule,
                  activeColor: _orange,
                  title: const Text('Edit Schedule'),
                  onChanged: viewSchedule
                      ? (value) =>
                          setDialogState(() => editSchedule = value)
                      : null,
                ),
                SwitchListTile(
                  value: viewHomework,
                  activeColor: _orange,
                  title: const Text('View Homework'),
                  onChanged: (value) =>
                      setDialogState(() => viewHomework = value),
                ),
                SwitchListTile(
                  value: editHomework,
                  activeColor: _orange,
                  title: const Text('Edit Homework'),
                  onChanged: viewHomework
                      ? (value) =>
                          setDialogState(() => editHomework = value)
                      : null,
                ),
                SwitchListTile(
                  value: viewPreparation,
                  activeColor: _orange,
                  title: const Text('View Preparation'),
                  onChanged: (value) =>
                      setDialogState(() => viewPreparation = value),
                ),
                SwitchListTile(
                  value: editPreparation,
                  activeColor: _orange,
                  title: const Text('Edit Preparation'),
                  onChanged: viewPreparation
                      ? (value) =>
                          setDialogState(() => editPreparation = value)
                      : null,
                ),
                SwitchListTile(
                  value: viewExam,
                  activeColor: _orange,
                  title: const Text('View Exam'),
                  onChanged: (value) =>
                      setDialogState(() => viewExam = value),
                ),
                SwitchListTile(
                  value: editExam,
                  activeColor: _orange,
                  title: const Text('Edit Exam'),
                  onChanged: viewExam
                      ? (value) => setDialogState(() => editExam = value)
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            if (Bag2SchoolStore.accessGrantFor(
                  child.id,
                  selectedMember.id,
                ) !=
                null)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: dialogContext,
                    builder: (confirmContext) => AlertDialog(
                      backgroundColor: _cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      title: const Text(
                        'Remove access?',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      content: Text(
                        'Remove ${selectedMember.displayName}’s access to ${child.name}? '
                        'They will no longer be able to use the permissions currently granted.',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(confirmContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD94B4B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Remove Access'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && dialogContext.mounted) {
                    Bag2SchoolStore.removeAccessGrant(
                      child.id,
                      selectedMember.id,
                    );
                    accessChanged = true;
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text(
                  'Remove Access',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                FamilyAccessGrant(
                  memberId: selectedMember.id,
                  childId: child.id,
                  viewSchedule: viewSchedule,
                  editSchedule: editSchedule,
                  viewHomework: viewHomework,
                  editHomework: editHomework,
                  viewPreparation: viewPreparation,
                  editPreparation: editPreparation,
                  viewExam: viewExam,
                  editExam: editExam,
                ),
              ),
              child: Text(
                Bag2SchoolStore.accessGrantFor(
                      child.id,
                      selectedMember.id,
                    ) ==
                    null
                    ? 'Grant Access'
                    : 'Save Access',
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        Bag2SchoolStore.saveAccessGrant(result);
      });
    } else if (accessChanged) {
      setState(() {});
    }
  }

  Future<void> _editChildAccess(ChildProfile child) async {
    final current = Bag2SchoolStore.accessForChild(child.id);
    var mode = current.mode;
    var viewSchedule = current.parentViewSchedule;
    var viewHomework = current.parentViewHomework;
    var viewPreparation = current.parentViewPreparation;
    var viewExam = current.parentViewExam;

    final result = await showDialog<ChildAccessSettings>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cream,
          title: Text(
            '${child.name} Access',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _orange,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ChildAccessMode>(
                  value: mode,
                  decoration: const InputDecoration(
                    labelText: 'Access mode',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  items: ChildAccessMode.values.map(
                    (entry) => DropdownMenuItem(
                      value: entry,
                      child: Text(_accessLabel(entry)),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => mode = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                if (mode != ChildAccessMode.independent) ...[
                  SwitchListTile(
                    value: viewSchedule,
                    activeColor: _orange,
                    title: const Text('View Schedule'),
                    onChanged: (value) =>
                        setDialogState(() => viewSchedule = value),
                  ),
                  SwitchListTile(
                    value: viewHomework,
                    activeColor: _orange,
                    title: const Text('View Homework'),
                    onChanged: (value) =>
                        setDialogState(() => viewHomework = value),
                  ),
                  SwitchListTile(
                    value: viewPreparation,
                    activeColor: _orange,
                    title: const Text('View Preparation'),
                    onChanged: (value) =>
                        setDialogState(() => viewPreparation = value),
                  ),
                  SwitchListTile(
                    value: viewExam,
                    activeColor: _orange,
                    title: const Text('View Exam'),
                    onChanged: (value) =>
                        setDialogState(() => viewExam = value),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  mode == ChildAccessMode.managed
                      ? 'Parent or guardian manages the child profile. The child does not need a separate account.'
                      : mode == ChildAccessMode.shared
                          ? 'The child can have their own account while selected family access remains available.'
                          : 'The child manages their own account. Family access can be added later according to the family arrangement.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                ChildAccessSettings(
                  childId: child.id,
                  mode: mode,
                  parentViewSchedule: viewSchedule,
                  parentViewHomework: viewHomework,
                  parentViewPreparation: viewPreparation,
                  parentViewExam: viewExam,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      Bag2SchoolStore.updateChildAccess(result);
    });
  }

  Widget _memberCard(FamilyMember member, {required bool canManage}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: canManage
            ? () => _showMemberEditor(member: member)
            : null,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFEBDD),
          child: Icon(
            member.role == FamilyMemberRole.child
                ? Icons.child_care_rounded
                : Icons.person_outline_rounded,
            color: member.role == FamilyMemberRole.child
                ? _purple
                : _orange,
          ),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        subtitle: Text(_roleLabel(member.role)),
        trailing: canManage
            ? const Icon(
                Icons.edit_outlined,
                color: _muted,
                size: 20,
              )
            : null,
      ),
    );
  }

  Widget _childAccessCard(ChildProfile child) {
    final settings = Bag2SchoolStore.accessForChild(child.id);
    final grants = Bag2SchoolStore.familyAccessGrants.values
        .where((grant) => grant.childId == child.id)
        .toList();

    String memberName(String memberId) {
      final index = Bag2SchoolStore.familyMembers.indexWhere(
        (entry) => entry.id == memberId,
      );
      return index >= 0
          ? Bag2SchoolStore.familyMembers[index].displayName
          : 'Family member';
    }

    String grantSummary(FamilyAccessGrant grant) {
      final parts = <String>[];
      if (grant.viewSchedule) {
        parts.add(grant.editSchedule ? 'Schedule edit' : 'Schedule view');
      }
      if (grant.viewHomework) {
        parts.add(grant.editHomework ? 'Homework edit' : 'Homework view');
      }
      if (grant.viewPreparation) {
        parts.add(
          grant.editPreparation
              ? 'Preparation edit'
              : 'Preparation view',
        );
      }
      if (grant.viewExam) {
        parts.add(grant.editExam ? 'Exam edit' : 'Exam view');
      }
      return parts.isEmpty ? 'No access' : parts.join(' · ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => _editChildAccess(child),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFE7D2),
              child: Text('👦🏻'),
            ),
            title: Text(
              child.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            subtitle: Text(
              '${child.grade} · ${_accessLabel(settings.mode)}',
            ),
            trailing: const Icon(
              Icons.tune_rounded,
              color: _muted,
            ),
          ),
          if (grants.isNotEmpty) ...[
            const Divider(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Granted access',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(height: 5),
            ...grants.map(
              (grant) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: _purple,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName(grant.memberId),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            grantSummary(grant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.2,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Manage access',
                      onPressed: () => _grantAccess(child, initialMemberId: grant.memberId),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _grantAccess(child),
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 18,
              ),
              label: Text(
                grants.isEmpty
                    ? 'Grant Access'
                    : 'Grant / Manage Access',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                side: const BorderSide(
                  color: Color(0xFFD8D0F8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isOwner =
        Bag2SchoolStore.currentAccount?.familyMemberId == 'member-owner';

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family',
          style: TextStyle(
            color: _orange,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const Text(
            'Family Members',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w900,
              color: _muted,
            ),
          ),
          const SizedBox(height: 10),
          ...Bag2SchoolStore.familyMembers.map(
            (member) => _memberCard(member, canManage: isOwner),
          ),
          if (isOwner)
            OutlinedButton.icon(
              onPressed: () => _showMemberEditor(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Family Member'),
              style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: Color(0xFFFFC18F)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isOwner) ...[
          const Text(
            'Child Access',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w900,
              color: _muted,
            ),
          ),
          const SizedBox(height: 10),
          ...Bag2SchoolStore.childProfiles.map(_childAccessCard),
          const SizedBox(height: 8),
          ],
          if (isOwner)
            const Text(
              'Access mode is a family setting for now. Login, invitations and cloud permissions will be connected in the Account/Cloud phase.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: _muted,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Family member access is managed by the Family Owner.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: _muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ============================================================
// LOGO
// ============================================================

class Bag2SchoolLogo extends StatelessWidget {
  const Bag2SchoolLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: 'Bag2',
            style: TextStyle(
              color: Color(0xFFFF6B1A),
            ),
          ),
          TextSpan(
            text: 'School',
            style: TextStyle(
              color: Color(0xFF29231F),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BAGI
// ============================================================

class BagiCharacter extends StatelessWidget {
  const BagiCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/bagi/bagi_wave.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class BagiSmallCharacter
    extends StatelessWidget {
  const BagiSmallCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '🎒',
      style: TextStyle(
        fontSize: 48,
      ),
    );
  }
}

class BagiMiniCharacter
    extends StatelessWidget {
  const BagiMiniCharacter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE7D2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '🎒',
          style: TextStyle(
            fontSize: 34,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SCHEDULE
// ============================================================

class _BagiBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0EDFF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BagiHomeBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0EDFF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();

  String _bagiScheduleMessage =
      "Hi Mom! Let's see what's on Kenneth's day. 😊";
  int _bagiMessageVersion = 0;
  Timer? _bagiScheduleTimer;
  Timer? _bagiResumeTimer;
  final Random _bagiRandom = Random();
  String? _lastBagiScheduleMessage;

  // The week selector uses PageView so the dates physically follow
  // the user's finger while swiping.
  late final PageController _weekPageController;
  final int _initialWeekPage = 1000;
  late DateTime _anchorMonday;
  int _visibleWeekPage = 1000;

  @override
  void initState() {
    super.initState();

    _anchorMonday = _mondayOf(selectedDate);
    _weekPageController = PageController(
      initialPage: _initialWeekPage,
    );
    _visibleWeekPage = _initialWeekPage;

    // Schedule can be created during the first frame. Start Bagi only after
    // the page has been painted so the first message is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startBagiScheduleConversation();
    });
  }

  void _startBagiScheduleConversation() {
    _bagiScheduleTimer?.cancel();
    _bagiResumeTimer?.cancel();
    _showNextBagiScheduleThought();
    _bagiScheduleTimer = Timer.periodic(
      const Duration(seconds: 13),
      (_) => _showNextBagiScheduleThought(),
    );
  }

  void _showNextBagiScheduleThought() {
    if (!mounted) return;

    final messages = <String>[
      ..._buildBagiScheduleThoughts(selectedDate),
      ..._buildBagiUpcomingReminderThoughts(selectedDate),
    ];
    if (messages.isEmpty) return;

    final candidates = messages.length > 1
        ? messages.where((message) => message != _lastBagiScheduleMessage).toList()
        : messages;

    final message = candidates[_bagiRandom.nextInt(candidates.length)];
    _lastBagiScheduleMessage = message;
    _showBagiScheduleMessage(message);
  }

  String _bagiActivityCategory(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return 'School';
      case ActivityType.lesson:
        return 'Class';
      case ActivityType.extracurricular:
        return 'Extracurricular';
      case ActivityType.exam:
        return 'Exam';
      case ActivityType.event:
        return 'Event';
    }
  }

  List<String> _buildBagiUpcomingReminderThoughts(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final reminders = <String>[];

    // Bagi starts preparing Mom two days before an activity.
    // Example: an Aug 19 activity can be mentioned on Aug 17 and Aug 18.
    for (var daysAhead = 1; daysAhead <= 2; daysAhead++) {
      final targetDate = cleanDate.add(Duration(days: daysAhead));

      final upcoming = Bag2SchoolStore.activities
          .where((activity) => activity.occursOn(targetDate))
          .toList();

      for (final activity in upcoming) {
        final dayLabel = daysAhead == 1 ? 'tomorrow' : 'in two days';
        reminders.add(
          "Psst, Mom! ${activity.title} (${_bagiActivityCategory(activity)}) "
          "is coming up $dayLabel. We can get a little ready ahead of time. 😊",
        );
      }
    }

    return reminders;
  }

  List<String> _buildBagiScheduleThoughts(DateTime date) {
    final cleanDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final activities = Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(date))
        .where((activity) => !Bag2SchoolStore.isOccurrenceCancelled(date, activity.id))
        .toList();

    final preparations = Bag2SchoolStore.preparations
        .where((item) => item.occursOn(cleanDate))
        .length;
    final extras = activities.where((activity) {
      return activity.type == ActivityType.lesson ||
          activity.type == ActivityType.extracurricular ||
          activity.type == ActivityType.event;
    }).length;

    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowActivities = Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(tomorrow))
        .toList();
    final tomorrowExtras = tomorrowActivities.where((activity) {
      return activity.type != ActivityType.school;
    }).length;

    final messages = <String>[];

    if (preparations == 1) {
      messages.add(
        "Hey Mom! There's still one little thing to prepare for today. "
        "No rush — we can take it step by step. 🎒",
      );
    } else if (preparations > 1) {
      messages.add(
        "Hey Mom! I spotted $preparations things to prepare for today. "
        "Let's get them ready one by one. 😊",
      );
    } else {
      messages.addAll([
        "Looks nice and light, Mom! Nothing extra is asking for attention right now. ✨",
        "A calm schedule today, Mom. That's one less thing for you to worry about. 😊",
        "We're all clear for now, Mom. I'll keep an eye on the little details with you. 👀",
        "Nice and steady, Mom! Sometimes a quiet schedule is exactly what we need. 🌼",
      ]);
    }

    final namedExtras = activities.where((activity) {
      return activity.type == ActivityType.lesson ||
          activity.type == ActivityType.extracurricular ||
          activity.type == ActivityType.event;
    }).toList();

    if (extras == 1 && namedExtras.isNotEmpty) {
      final activity = namedExtras.first;
      messages.add(
        "Hey Mom! ${activity.title} (${_bagiActivityCategory(activity)}) "
        "is on today's list. I've got my eye on it with you. 😊",
      );
    } else if (extras > 1) {
      final preview = namedExtras.take(2).map((activity) {
        return "${activity.title} (${_bagiActivityCategory(activity)})";
      }).join(' and ');
      messages.add(
        "Today looks a little busy, Mom! I spotted $extras extra activities. "
        "${preview.isEmpty ? "We'll take them one by one." : "$preview are on the radar."} 🎒",
      );
    }

    if (tomorrowExtras == 1) {
      messages.add(
        "Just a little heads-up, Mom: tomorrow has one extra activity. "
        "We can get ahead of it today. 😉",
      );
    } else if (tomorrowExtras > 1) {
      messages.add(
        "Tiny heads-up for tomorrow, Mom: there are $tomorrowExtras extra "
        "activities waiting. Let's not let them sneak up on us! 😄",
      );
    } else {
      messages.add(
        "I had a quick peek at tomorrow too, Mom. Nothing extra is waving "
        "for our attention yet. 😊",
      );
    }

    return messages;
  }

  DateTime _mondayOf(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    return cleanDate.subtract(
      Duration(days: cleanDate.weekday - DateTime.monday),
    );
  }

  DateTime _dateForWeekPage(int page, int index) {
    final weekOffset = page - _initialWeekPage;
    return _anchorMonday.add(
      Duration(days: weekOffset * 7 + index),
    );
  }

  @override
  void dispose() {
    _bagiScheduleTimer?.cancel();
    _bagiResumeTimer?.cancel();
    _weekPageController.dispose();
    super.dispose();
  }

  String _buildDateSummaryMessage(DateTime date) {
    final activities = Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(date))
        .where((activity) => !Bag2SchoolStore.isOccurrenceCancelled(date, activity.id))
        .toList();

    if (activities.isEmpty) {
      return "Looks like a calm day, Mom! Nothing extra is scheduled yet. 😊";
    }

    final schoolCount = activities
        .where((activity) => activity.type == ActivityType.school)
        .length;
    final lessonCount = activities
        .where((activity) => activity.type == ActivityType.lesson)
        .length;
    final extraCount = activities
        .where((activity) => activity.type == ActivityType.extracurricular)
        .length;
    final eventCount = activities
        .where((activity) => activity.type == ActivityType.event)
        .length;
    final cleanDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final preparationCount = Bag2SchoolStore.preparations
        .where((item) => item.occursOn(cleanDate))
        .length;

    final parts = <String>[];

    if (schoolCount > 0) {
      parts.add(schoolCount == 1 ? 'school' : '$schoolCount school activities');
    }
    if (lessonCount > 0) {
      parts.add(lessonCount == 1 ? 'a lesson' : '$lessonCount lessons');
    }
    if (extraCount > 0) {
      parts.add(
        extraCount == 1
            ? 'an extracurricular activity'
            : '$extraCount extracurricular activities',
      );
    }
    if (eventCount > 0) {
      parts.add(
        eventCount == 1 ? 'a school event' : '$eventCount school events',
      );
    }
    if (preparationCount > 0) {
      parts.add(
        preparationCount == 1
            ? 'something to prepare'
            : '$preparationCount things to prepare',
      );
    }

    final countText =
        activities.length == 1 ? '1 activity' : '${activities.length} activities';

    if (parts.isEmpty) {
      return "Hi Mom! I see $countText on this day. Let's take a look together. 😊";
    }

    if (parts.length == 1) {
      return "Hi Mom! This day has $countText, including ${parts.first}. "
          "Let's make sure Kenneth is ready. 🎒";
    }

    final last = parts.removeLast();
    return "Hi Mom! This day has $countText: "
        "${parts.join(', ')}, and $last. "
        "Let's make sure Kenneth is ready. 🎒";
  }

  void _onScheduleDateSelected(DateTime date) {
    final monday = _mondayOf(date);
    final weekDifference =
        monday.difference(_anchorMonday).inDays ~/ 7;
    final targetPage = _initialWeekPage + weekDifference;

    setState(() {
      selectedDate = date;
      _visibleWeekPage = targetPage;
    });

    if (_weekPageController.hasClients) {
      _weekPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    _showBagiScheduleMessage(_buildDateSummaryMessage(date));
  }

  void _showBagiScheduleMessage(
    String message, {
    bool priority = false,
  }) {
    if (priority) {
      // A confirmation is important: pause the 13-second conversation
      // so the success message gets enough time to finish.
      _bagiScheduleTimer?.cancel();
      _bagiResumeTimer?.cancel();
    }

    final version = ++_bagiMessageVersion;
    final words = message.split(' ');

    // Show the first word immediately so the bubble never gets stuck on "...".
    setState(() {
      _bagiScheduleMessage = words.isEmpty ? '' : words.first;
    });

    for (var i = 2; i <= words.length; i++) {
      Future.delayed(Duration(milliseconds: 90 * (i - 1)), () {
        if (!mounted || version != _bagiMessageVersion) return;
        setState(() {
          _bagiScheduleMessage = words.take(i).join(' ');
        });
      });
    }

    if (priority) {
      // Give Mom a comfortable pause after the confirmation, then resume
      // the normal 13-second Bagi conversation.
      _bagiResumeTimer = Timer(
        const Duration(seconds: 13),
        _startBagiScheduleConversation,
      );
    }
  }

  void _goToToday() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final todayMonday = _mondayOf(today);
    final weekDifference =
        todayMonday.difference(_anchorMonday).inDays ~/ 7;
    final targetPage = _initialWeekPage + weekDifference;

    setState(() {
      selectedDate = today;
      _visibleWeekPage = targetPage;
    });

    if (_weekPageController.hasClients) {
      _weekPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    _showBagiScheduleMessage(
      "We're back to today! Let's see what's on Kenneth's plate.",
    );
  }

  Widget _buildBagiHighlightedText() {
    final message = _bagiScheduleMessage.isEmpty
        ? "Hi Mom! Let's see what's on Kenneth's day. 😊"
        : _bagiScheduleMessage;

    final activityTitles = Bag2SchoolStore.activities
        .map((activity) => activity.title.trim())
        .where((title) => title.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    if (activityTitles.isEmpty) {
      return Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4D445B),
        ),
      );
    }

    final lowerMessage = message.toLowerCase();
    String? matchedTitle;
    int matchIndex = -1;

    for (final title in activityTitles) {
      final index = lowerMessage.indexOf(title.toLowerCase());
      if (index >= 0) {
        matchedTitle = title;
        matchIndex = index;
        break;
      }
    }

    if (matchedTitle == null) {
      return Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4D445B),
        ),
      );
    }

    final before = message.substring(0, matchIndex);
    final highlighted = message.substring(
      matchIndex,
      matchIndex + matchedTitle.length,
    );
    final after = message.substring(matchIndex + matchedTitle.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4D445B),
        ),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: highlighted,
            style: const TextStyle(
              color: Color(0xFFFF7A21),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildBagiScheduleBubble() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: const BagiCharacter(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    13,
                    16,
                    13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: const Color(0xFFE0D9FF),
                    ),
                  ),
                  child: _buildBagiHighlightedText(),
                ),
                Positioned(
                  left: -7,
                  top: 13,
                  child: CustomPaint(
                    size: const Size(14, 18),
                    painter: _BagiBubbleTailPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityChoice(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE7D2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFF7A21),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29231F),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF756B65),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFFB8ADA5),
      ),
      onTap: onTap ?? () {
        Navigator.pop(context);
      },
    );
  }

  void _afterActivitySaved(BagActivity activity) {
    Bag2SchoolStore.activities.add(activity);

    Bag2SchoolStore.recordFamilyActivity(
      feature: activity.type == ActivityType.exam
          ? LocalPermissionFeature.exam
          : LocalPermissionFeature.schedule,
      action: 'Added',
      title: 'Schedule added',
      message:
        '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
        'added ${Bag2SchoolStore.activeChild.name} [${activity.title}].',
      childId: Bag2SchoolStore.activeChildId,
      entityId: activity.id,
    );

    if (!mounted) return;
    setState(() {});

    // Rebuild once again after the dialog route has closed.
    // This prevents a newly added one-time Exam from appearing only
    // after another Activity triggers a later rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });

    final category = _bagiActivityCategory(activity);
    final message = switch (activity.type) {
      ActivityType.school =>
        "Yay, Mom! ${activity.title} is all set for School. 🏫 I'll keep it on my radar with you!",
      ActivityType.lesson =>
        "Got it, Mom! ${activity.title} is all set as a Class. 📚 We'll keep it nice and easy!",
      ActivityType.extracurricular =>
        "Woohoo, Mom! ${activity.title} is on the schedule. 🎉 I'll help you keep everything ready!",
      ActivityType.exam =>
        "Got it, Mom! ${activity.title} is an Exam. 📝 I'll keep it clearly marked on the schedule.",
      _ =>
        "All set, Mom! ${activity.title} ($category) is on the schedule. 😊 I'll keep an eye on it with you!",
    };

    // The successful-save message gets priority first. Preparation is offered
    // afterwards for every activity type, not only extracurriculars.
    _showBagiScheduleMessage(message, priority: true);
    // Let the success message finish typing and breathe for a moment before
    // opening the preparation conversation. This avoids two Bagi messages
    // competing visually.
    final messageDelay = Duration(
      milliseconds: 1200 + (message.split(' ').length * 90),
    );
    Future.delayed(messageDelay, () {
      if (!mounted) return;
      _showPreparationOffer(activity);
    });
  }

  void _showSchoolForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return SchoolActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }


  void _showLessonForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return LessonActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }


  void _showExtracurricularForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return ExtracurricularActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showEventForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return EventActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showExamForm() {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.exam)) {
      LocalAuthorization.showDenied(context, 'add', featureLabel: 'exam');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return ExamActivityForm(
          initialDate: selectedDate,
          onSaved: _afterActivitySaved,
        );
      },
    );
  }

  void _showPreparationOffer(BagActivity activity) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final activityDate = DateTime(
      activity.startDate.year,
      activity.startDate.month,
      activity.startDate.day,
    );

    // Keep today's and tomorrow's preparation visible in the active
    // Preparation dashboard. Further-ahead activities default to one day before.
    final preparationDate = activityDate.isBefore(
      today.add(const Duration(days: 2)),
    )
        ? today
        : activityDate.subtract(const Duration(days: 1));

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preparation',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _PreparationOfferCard(
              activity: activity,
              preparationDate: preparationDate,
              onNotNow: () => Navigator.pop(dialogContext),
              onAdd: (
                items,
                reminderEnabled,
                reminderDate,
                reminderHour,
                reminderMinute,
              ) {
                if (items.isEmpty) return;

                final now = DateTime.now().microsecondsSinceEpoch;
                for (var i = 0; i < items.length; i++) {
                  Bag2SchoolStore.preparations.add(
                    PreparationItem(
                      id: 'preparation-$now-$i',
                      activityId: activity.id,
                      title: items[i],
                      preparationDate: preparationDate,
                      reminderEnabled: reminderEnabled,
                      reminderDate: reminderDate,
                      reminderHour: reminderHour,
                      reminderMinute: reminderMinute,
                    ),
                  );
                }

                Navigator.pop(dialogContext);

                if (!mounted) return;
                setState(() {});

                final itemText = items.length == 1
                    ? items.first
                    : '${items.length} little things';

                _showBagiScheduleMessage(
                  reminderEnabled
                      ? "You're all set, Mom! 🎒✨ I'll remember "
                        "$itemText for ${activity.title} and remind you "
                        "when it's time to get ready. 😊"
                      : "You're all set, Mom! 🎒✨ I've added "
                        "$itemText to the preparation list for "
                        "${activity.title}. Easy peasy! 😊",
                  priority: true,
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.94,
                end: 1.0,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  String _formatFriendlyDate(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _activityCategoryLabel(ActivityType type) {
    switch (type) {
      case ActivityType.school:
        return 'School';
      case ActivityType.lesson:
        return 'Class';
      case ActivityType.extracurricular:
        return 'Extracurricular';
      case ActivityType.exam:
        return 'Exam';
      case ActivityType.event:
        return 'Event';
    }
  }

  void _showFriendlyTimeWarning() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.88, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              alignment: Alignment.bottomCenter,
              scale: scale,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2D8D0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 76,
                        height: 76,
                        child: BagiCharacter(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0EDFF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Oops, Mom! 😄 The timing is a little mixed up. "
                            "Let's make sure the class finishes after it starts.",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4D445B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pick an end time that's later than the start time.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF756B65),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A21),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Got it, let's fix it 😊",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditActivityDialog(BagActivity activity, {DateTime? occurrenceDate}) async {
    final feature = activity.type == ActivityType.exam
        ? LocalPermissionFeature.exam
        : LocalPermissionFeature.schedule;
    final featureLabel =
        activity.type == ActivityType.exam ? 'exam' : 'schedule';
    if (!LocalAuthorization.canEditActive(feature)) {
      LocalAuthorization.showDenied(
        context,
        'edit',
        featureLabel: featureLabel,
      );
      return;
    }
    final editOccurrenceDate = DateTime(
      (occurrenceDate ?? activity.startDate).year,
      (occurrenceDate ?? activity.startDate).month,
      (occurrenceDate ?? activity.startDate).day,
    );
    final titleController = TextEditingController(text: activity.title);
    var start = TimeOfDay(
      hour: activity.startTime.hour,
      minute: activity.startTime.minute,
    );
    var end = TimeOfDay(hour: activity.endTime.hour, minute: activity.endTime.minute);
    var editRecurrenceType =
        activity.type == ActivityType.exam
            ? RecurrenceType.none
            : activity.recurrence.type;
    var editSelectedWeekdays = <int>{...activity.recurrence.weekdays};

    String recurrenceLabel(RecurrenceType type) {
      switch (type) {
        case RecurrenceType.none: return 'One time';
        case RecurrenceType.daily: return 'Every day';
        case RecurrenceType.weekdays: return 'Every weekday (Mon–Fri)';
        case RecurrenceType.weekly: return 'Every week';
        case RecurrenceType.biweekly: return 'Every 2 weeks';
        case RecurrenceType.monthly: return 'Every month';
        case RecurrenceType.custom: return 'Custom days';
      }
    }

    ActivityRecurrence buildEditedRecurrence() => ActivityRecurrence(
      type: editRecurrenceType,
      interval: activity.recurrence.interval,
      weekdays: editRecurrenceType == RecurrenceType.custom
          ? (editSelectedWeekdays.toList()..sort())
          : activity.recurrence.weekdays,
      endDate: activity.recurrence.endDate,
    );

    Future<void> pickRecurrence(StateSetter setDialogState) async {
      if (activity.type == ActivityType.exam) return;
      if (activity.type == ActivityType.exam) return;
      await _settleDialogFocus();
      if (!mounted) return;
      final selected = await showDialog<RecurrenceType>(
        context: context,
        builder: (pickerContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('How often does it repeat?', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final option in const [RecurrenceType.none, RecurrenceType.daily, RecurrenceType.weekdays, RecurrenceType.weekly, RecurrenceType.biweekly, RecurrenceType.monthly, RecurrenceType.custom])
              ListTile(
                title: Text(recurrenceLabel(option)),
                leading: Icon(option == editRecurrenceType ? Icons.radio_button_checked : Icons.radio_button_off, color: const Color(0xFFFF7A21)),
                onTap: () => Navigator.pop(pickerContext, option),
              ),
          ])),
        ),
      );
      if (selected == null) return;
      if (selected == RecurrenceType.custom) {
        final days = <int>{...editSelectedWeekdays};
        final picked = await showDialog<Set<int>>(
          context: context,
          builder: (daysContext) => StatefulBuilder(builder: (context, setDays) {
            const labels = <int,String>{DateTime.monday:'Mon',DateTime.tuesday:'Tue',DateTime.wednesday:'Wed',DateTime.thursday:'Thu',DateTime.friday:'Fri',DateTime.saturday:'Sat',DateTime.sunday:'Sun'};
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Choose days', style: TextStyle(fontWeight: FontWeight.w800)),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: labels.entries.map((e) {
                  return FilterChip(
                    label: Text(e.value),
                    selected: days.contains(e.key),
                    selectedColor: const Color(0xFFFFE2CF),
                    onSelected: (v) {
                      setDays(() {
                        if (v) {
                          days.add(e.key);
                        } else {
                          days.remove(e.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _settleDialogFocus();
                    if (!daysContext.mounted) return;
                    Navigator.pop(daysContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: days.isEmpty
                      ? null
                      : () => Navigator.pop(daysContext, days),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A21),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          }),
        );
        if (picked == null || picked.isEmpty) return;
        editSelectedWeekdays = {...picked};
      }
      setDialogState(() => editRecurrenceType = selected);
    }

    final existingPreparations =
        Bag2SchoolStore.preparationsForOccurrence(
      editOccurrenceDate,
      activity.id,
    );

    // Draft only: Cancel must not mutate shared preparation data.
    var draftOccurrencePreparations = <PreparationItem>[
      ...existingPreparations,
    ];

    var sharedPreparationDate = existingPreparations.isNotEmpty
        ? existingPreparations.first.preparationDate
        : editOccurrenceDate;

    var sharedReminderEnabled = existingPreparations.any(
      (item) => item.reminderEnabled,
    );

    var sharedReminderDate = existingPreparations.isNotEmpty
        ? (existingPreparations.first.reminderDate ??
            sharedPreparationDate)
        : sharedPreparationDate;

    var sharedReminderHour = existingPreparations.isNotEmpty
        ? existingPreparations.first.reminderHour
        : 18;

    var sharedReminderMinute = existingPreparations.isNotEmpty
        ? existingPreparations.first.reminderMinute
        : 0;

    final addPreparationController = TextEditingController();
    var addingPreparationItem = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final invalidTime =
                (start.hour * 60 + start.minute) >=
                (end.hour * 60 + end.minute);

            final linkedPreparations = <PreparationItem>[
              ...draftOccurrencePreparations,
            ];

            Future<void> pickTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isStart ? start : end,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: true,
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStart) {
                    start = picked;
                  } else {
                    end = picked;
                  }
                });
              }
            }

            Future<void> pickSharedPreparationDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: sharedPreparationDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() {
                  sharedPreparationDate = picked;
                });
              }
            }

            Future<void> pickSharedReminderDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: sharedReminderDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() {
                  sharedReminderDate = picked;
                });
              }
            }

            Future<void> pickSharedReminderTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: sharedReminderHour,
                  minute: sharedReminderMinute,
                ),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: true,
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setDialogState(() {
                  sharedReminderHour = picked.hour;
                  sharedReminderMinute = picked.minute;
                });
              }
            }

            void removePreparation(PreparationItem item) {
              setDialogState(() {
                draftOccurrencePreparations.removeWhere(
                  (p) => p.id == item.id,
                );
              });
            }

            Future<void> renamePreparation(PreparationItem item) async {
              final controller = TextEditingController(text: item.title);
              await showDialog<void>(
                context: context,
                builder: (renameContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: const Text(
                      'Tweak this preparation',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'What should we call it?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await _settleDialogFocus();
                          if (!renameContext.mounted) return;
                          Navigator.pop(renameContext);
                        },
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) return;
                          final index =
                              draftOccurrencePreparations.indexWhere(
                            (p) => p.id == item.id,
                          );
                          if (index >= 0) {
                            draftOccurrencePreparations[index] =
                                draftOccurrencePreparations[index]
                                    .copyWith(title: value);
                          }
                          await _settleDialogFocus();
                          if (!renameContext.mounted) return;
                          Navigator.pop(renameContext);
                          setDialogState(() {});
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A21),
                        ),
                        child: const Text('Looks good'),
                      ),
                    ],
                  );
                },
              );
              controller.dispose();
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE9D8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_calendar_outlined,
                      color: Color(0xFFFF7A21),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Edit activity',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Activity name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _activityCategoryLabel(activity.type),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF7A21),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pickTime(true),
                            child: Text(
                              'Start\n${_formatTimeOfDay24(start)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pickTime(false),
                            child: Text(
                              'End\n${_formatTimeOfDay24(end)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (invalidTime) ...[
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Oops, Mom 😊 Let's make the end time a little later than the start time.",
                          style: TextStyle(
                            color: Color(0xFF8A7E76),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (activity.type != ActivityType.exam)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(13),
                                            decoration: BoxDecoration(color: const Color(0xFFFFF8F3), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEDE2DA))),
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              const Text('Repeat from this date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF5A4B43))),
                                              const SizedBox(height: 3),
                                              Text('Changes apply from ${_formatDateShort(editOccurrenceDate)} onward. Earlier dates stay unchanged.', style: const TextStyle(fontSize: 11.5, color: Color(0xFF756B65))),
                                              const SizedBox(height: 8),
                                              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => pickRecurrence(setDialogState), child: Text(recurrenceLabel(editRecurrenceType), maxLines: 1, overflow: TextOverflow.ellipsis))),
                                            ]),
                                          ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Let's get ready!",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await _settleDialogFocus();
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              addingPreparationItem = true;
                            });
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 19,
                          ),
                          label: const Text('Add something'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7A21),
                          ),
                        ),
                      ],
                    ),
                    if (addingPreparationItem) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFCBA9),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: addPreparationController,
                                autofocus: false,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  setDialogState(() {});
                                },
                                onSubmitted: (_) {
                                  final value =
                                      addPreparationController.text.trim();
                                  if (value.isEmpty) return;
                                  final now =
                                      DateTime.now().microsecondsSinceEpoch;
                                  draftOccurrencePreparations.add(
                                    PreparationItem(
                                      id: 'preparation-$now-edit',
                                      activityId: activity.id,
                                      title: value,
                                      preparationDate: editOccurrenceDate,
                                      reminderEnabled:
                                          sharedReminderEnabled,
                                      reminderDate: sharedReminderDate,
                                      reminderHour: sharedReminderHour,
                                      reminderMinute: sharedReminderMinute,
                                    ),
                                  );
                                  addPreparationController.clear();
                                  setDialogState(() {
                                    addingPreparationItem = false;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Jersey, water bottle...',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Add',
                              onPressed:
                                  addPreparationController.text.trim().isEmpty
                                      ? null
                                      : () {
                                          final value =
                                              addPreparationController.text.trim();
                                          final now =
                                              DateTime.now().microsecondsSinceEpoch;
                                          draftOccurrencePreparations.add(
                                            PreparationItem(
                                              id: 'preparation-$now-edit',
                                              activityId: activity.id,
                                              title: value,
                                              preparationDate: editOccurrenceDate,
                                              reminderEnabled:
                                                  sharedReminderEnabled,
                                              reminderDate: sharedReminderDate,
                                              reminderHour: sharedReminderHour,
                                              reminderMinute: sharedReminderMinute,
                                            ),
                                          );
                                          addPreparationController.clear();
                                          setDialogState(() {
                                            addingPreparationItem = false;
                                          });
                                        },
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFFF7A21),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cancel',
                              onPressed: () {
                                addPreparationController.clear();
                                setDialogState(() {
                                  addingPreparationItem = false;
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFFE36A55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (linkedPreparations.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          "Nothing packed yet. Add a little something and I'll help keep track of it. 😊",
                          style: TextStyle(
                            color: Color(0xFF756B65),
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...linkedPreparations.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEDE2DA),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 19,
                                color: Color(0xFFFF7A21),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Rename',
                                onPressed: () => renamePreparation(item),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 19,
                                  color: Color(0xFFFF7A21),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => removePreparation(item),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFFE36A55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEDE2DA),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'When should we get ready?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5A4B43),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: pickSharedPreparationDate,
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                              label: Text(
                                _formatDateShort(sharedPreparationDate),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: sharedReminderEnabled,
                            onChanged: (value) {
                              setDialogState(() {
                                sharedReminderEnabled = value;
                              });
                            },
                            activeColor: const Color(0xFFFF7A21),
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Want Bagi to give you a nudge?',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: const Text(
                              "I'll remind you at the right moment, so we can stay relaxed. 😊",
                            ),
                          ),
                          if (sharedReminderEnabled) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: pickSharedReminderDate,
                                    child: Text(
                                      _formatDateShort(sharedReminderDate),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: pickSharedReminderTime,
                                    child: Text(
                                      _formatTimeOfDay24(
                                        TimeOfDay(
                                          hour: sharedReminderHour,
                                          minute: sharedReminderMinute,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _settleDialogFocus();
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () async {
                          if (invalidTime) {
                            _showFriendlyTimeWarning();
                            return;
                          }

                          // If the user typed a preparation but forgot to
                          // press the small check button, Save commits that draft
                          // into THIS occurrence only. It never changes the
                          // recurring template or another date.
                          final pendingPreparation =
                              addPreparationController.text.trim();

                          final currentOccurrence =
                              <PreparationItem>[...draftOccurrencePreparations];

                          final editedOccurrence = <PreparationItem>[
                            ...currentOccurrence,
                          ];

                          if (pendingPreparation.isNotEmpty) {
                            final now =
                                DateTime.now().microsecondsSinceEpoch;
                            editedOccurrence.add(
                              PreparationItem(
                                id: 'preparation-$now-edit-occurrence',
                                activityId: activity.id,
                                title: pendingPreparation,
                                preparationDate: editOccurrenceDate,
                                reminderEnabled: sharedReminderEnabled,
                                reminderDate: sharedReminderDate,
                                reminderHour: sharedReminderHour,
                                reminderMinute: sharedReminderMinute,
                              ),
                            );
                          }

                          final occurrenceKey =
                              Bag2SchoolStore.preparationOccurrenceKey(
                            editOccurrenceDate,
                            activity.id,
                          );
                          Bag2SchoolStore.preparationOccurrenceOverrides[
                              occurrenceKey] = editedOccurrence
                              .map((item) => item.copyWith(
                                    preparationDate: editOccurrenceDate,
                                    reminderEnabled: sharedReminderEnabled,
                                    reminderDate: sharedReminderDate,
                                    reminderHour: sharedReminderHour,
                                    reminderMinute: sharedReminderMinute,
                                  ))
                              .toList();

                          // The occurrence override is now authoritative.
                          // Clear legacy hidden markers for this occurrence
                          // because an explicit list (including empty) is the
                          // new source of truth.
                          for (final item in currentOccurrence) {
                            Bag2SchoolStore.preparationOccurrenceHidden.remove(
                              '${editOccurrenceDate.toIso8601String()}|${item.id}',
                            );
                          }
                          addPreparationController.clear();
                          addingPreparationItem = false;

                          // Let the keyboard/focus tree settle before
                          // removing the parent dialog.
                          await _settleDialogFocus();
                          if (!dialogContext.mounted) return;

                          final index =
                              Bag2SchoolStore.activities.indexWhere(
                            (item) => item.id == activity.id,
                          );
                          if (index < 0) return;

                          final editedRecurrence = buildEditedRecurrence();
                          final editedTitle = titleController.text.trim();
                          final editedStart = TimeOfDayData(hour: start.hour, minute: start.minute);
                          final editedEnd = TimeOfDayData(hour: end.hour, minute: end.minute);
                          final startDay = DateTime(activity.startDate.year, activity.startDate.month, activity.startDate.day);
                          final future = editOccurrenceDate.isAfter(startDay) && activity.recurrence.type != RecurrenceType.none;
                          final recurrenceChanged = editedRecurrence.type != activity.recurrence.type || editedRecurrence.interval != activity.recurrence.interval || editedRecurrence.weekdays.join(',') != activity.recurrence.weekdays.join(',');
                          final timeChanged = editedStart.hour != activity.startTime.hour || editedStart.minute != activity.startTime.minute || editedEnd.hour != activity.endTime.hour || editedEnd.minute != activity.endTime.minute;
                          final titleChanged = editedTitle != activity.title;
                          if (future && (recurrenceChanged || timeChanged || titleChanged)) {
                            final oldEnd = editOccurrenceDate.subtract(const Duration(days: 1));
                            Bag2SchoolStore.activities[index] = activity.copyWith(recurrence: ActivityRecurrence(type: activity.recurrence.type, interval: activity.recurrence.interval, weekdays: activity.recurrence.weekdays, endDate: oldEnd));
                            final newId = '${activity.id}-from-${editOccurrenceDate.microsecondsSinceEpoch}';
                            final futureRecurrence = ActivityRecurrence(type: editedRecurrence.type, interval: editedRecurrence.interval, weekdays: editedRecurrence.weekdays, endDate: null);
                            Bag2SchoolStore.activities.add(BagActivity(id: newId, title: editedTitle, type: activity.type, startDate: editOccurrenceDate, startTime: editedStart, endTime: editedEnd, recurrence: futureRecurrence, isRoutine: activity.isRoutine, showIndicator: activity.showIndicator, indicatorType: activity.indicatorType, completed: false, location: activity.location, notes: activity.notes, homework: activity.homework));
                            final basePrep = Bag2SchoolStore.preparations.where((p) => p.activityId == activity.id).toList();
                            for (var i = 0; i < basePrep.length; i++) {
                              final p = basePrep[i];
                              Bag2SchoolStore.preparations.add(
                                PreparationItem(
                                  id: '$newId-prep-$i-${DateTime.now().microsecondsSinceEpoch}',
                                  activityId: newId,
                                  title: p.title,
                                  preparationDate: editOccurrenceDate,
                                  completed: false,
                                  reminderEnabled: p.reminderEnabled,
                                  reminderDate: p.reminderDate,
                                  reminderHour: p.reminderHour,
                                  reminderMinute: p.reminderMinute,
                                ),
                              );
                            }
                            for (var i = 0; i < Bag2SchoolStore.homeworks.length; i++) { final h = Bag2SchoolStore.homeworks[i]; final due = DateTime(h.dueDate.year, h.dueDate.month, h.dueDate.day); if (h.relatedActivityId == activity.id && !due.isBefore(editOccurrenceDate)) Bag2SchoolStore.homeworks[i] = h.copyWith(relatedActivityId: newId); }
                            final splitDay = DateTime(editOccurrenceDate.year, editOccurrenceDate.month, editOccurrenceDate.day);

                            // Move cancelled future occurrences with the new
                            // series identity. Each cancellation remains tied to
                            // its exact date; it never changes the series itself.
                            Bag2SchoolStore.moveCancelledOccurrences(
                              activity.id,
                              newId,
                              editOccurrenceDate,
                            );

                            final overrides = <String, List<PreparationItem>>{};
                            for (final entry in Bag2SchoolStore.preparationOccurrenceOverrides.entries.toList()) {
                              final suffix = '|${activity.id}';
                              if (!entry.key.endsWith(suffix)) continue;
                              final rawDate = entry.key.substring(0, entry.key.length - suffix.length);
                              final date = DateTime.tryParse(rawDate);
                              if (date == null || date.isBefore(splitDay)) continue;
                              overrides[Bag2SchoolStore.preparationOccurrenceKey(date, newId)] =
                                  entry.value.map((p) => PreparationItem(
                                    id: p.id,
                                    activityId: newId,
                                    title: p.title,
                                    preparationDate: date,
                                    completed: p.completed,
                                    reminderEnabled: p.reminderEnabled,
                                    reminderDate: p.reminderDate,
                                    reminderHour: p.reminderHour,
                                    reminderMinute: p.reminderMinute,
                                  )).toList();
                              Bag2SchoolStore.preparationOccurrenceOverrides.remove(entry.key);
                            }
                            Bag2SchoolStore.preparationOccurrenceOverrides.addAll(overrides);
                          } else {
                            Bag2SchoolStore.activities[index] = activity.copyWith(title: editedTitle, startTime: editedStart, endTime: editedEnd, recurrence: editedRecurrence);
                          }

                          Bag2SchoolStore.recordFamilyActivity(
                            feature: activity.type == ActivityType.exam
                                ? LocalPermissionFeature.exam
                                : LocalPermissionFeature.schedule,
                            action: 'Edited',
                            title: 'Schedule updated',
                            message:
                                '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                'updated ${Bag2SchoolStore.activeChild.name} [${titleController.text.trim()}].',
                            childId: Bag2SchoolStore.activeChildId,
                            entityId: activity.id,
                          );

                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          setState(() {});
                          _showBagiScheduleMessage(
                            "All fixed, Mom! ${titleController.text.trim()} "
                            "is looking good. 😊",
                            priority: true,
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A21),
                    disabledBackgroundColor: const Color(0xFFE7DCD5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Save & keep us ready'),
                ),
              ],
            );
          },
        );
      },
    );
    addPreparationController.dispose();
    titleController.dispose();
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTimeOfDay24(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  void _confirmDeleteActivity(BagActivity activity) {
    final feature = activity.type == ActivityType.exam
        ? LocalPermissionFeature.exam
        : LocalPermissionFeature.schedule;
    final featureLabel =
        activity.type == ActivityType.exam ? 'exam' : 'schedule';
    if (!LocalAuthorization.canEditActive(feature)) {
      LocalAuthorization.showDenied(
        context,
        'delete',
        featureLabel: featureLabel,
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.92, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: BagiCharacter(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDFF),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(19),
                              bottomLeft: Radius.circular(19),
                              bottomRight: Radius.circular(19),
                            ),
                          ),
                          child: Text(
                            "Hey Mom, are we sure we want to remove "
                            "'${activity.title}'? I can take it off the schedule "
                            "if you're ready. 😊",
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4D445B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (activity.recurrence.type != RecurrenceType.none && activity.occursOn(selectedDate)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Bag2SchoolStore.cancelActivityOccurrence(
                            selectedDate,
                            activity.id,
                          );
                          Bag2SchoolStore.recordFamilyActivity(
                            feature: activity.type == ActivityType.exam
                                ? LocalPermissionFeature.exam
                                : LocalPermissionFeature.schedule,
                            action: 'Deleted',
                            title: 'Schedule occurrence removed',
                            message:
                                '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                'removed ${Bag2SchoolStore.activeChild.name} [${activity.title}] '
                                'for ${_formatFriendlyDate(selectedDate)}.',
                            childId: Bag2SchoolStore.activeChildId,
                            entityId: activity.id,
                          );
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          setState(() {});
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB04A),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Remove ${_formatFriendlyDate(selectedDate)} only'),
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Keep it'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final activityId = activity.id;
                            Bag2SchoolStore.activities.removeWhere(
                              (item) => item.id == activityId,
                            );

                            // Remove preparations directly owned by this activity.
                            // Homework preparations use "homework:<id>", so they remain.
                            Bag2SchoolStore.preparations.removeWhere(
                              (preparation) =>
                                  preparation.activityId == activityId,
                            );
                            Bag2SchoolStore.cancelledActivityOccurrences.removeWhere((key) => key.endsWith('|${activity.id}'));
                            Bag2SchoolStore.cancelledActivityDatesBySeries.remove(activity.id);
                            Navigator.pop(dialogContext);
                            if (!mounted) return;
                            setState(() {});
                            Bag2SchoolStore.recordFamilyActivity(
                              feature: activity.type == ActivityType.exam
                                  ? LocalPermissionFeature.exam
                                  : LocalPermissionFeature.schedule,
                              action: 'Deleted',
                              title: 'Schedule deleted',
                              message:
                                  '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                  'deleted ${Bag2SchoolStore.activeChild.name} [${activity.title}].',
                              childId: Bag2SchoolStore.activeChildId,
                              entityId: activity.id,
                            );
                            _showBagiScheduleMessage(
                              "Done, Mom! ${activity.title} is off the schedule. 😊",
                              priority: true,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD94B4B),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Remove series'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<BagActivity> _savedActivitiesForSelectedDate() {
    return Bag2SchoolStore.activities
        .where((activity) => activity.occursOn(selectedDate))
        .where((activity) => !Bag2SchoolStore.isOccurrenceCancelled(selectedDate, activity.id))
        .toList()
      ..sort(
        (a, b) => a.startMinutes().compareTo(b.startMinutes()),
      );
  }

  List<HomeworkItem> _homeworkForSelectedDate() {
    final clean = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    return Bag2SchoolStore.homeworks
        .where((item) => DateTime(
              item.dueDate.year,
              item.dueDate.month,
              item.dueDate.day,
            ) == clean)
        .toList()
      ..sort((a, b) => (a.dueTime?.totalMinutes ?? 1440)
          .compareTo(b.dueTime?.totalMinutes ?? 1440));
  }

  void _openHomeworkFromSchedule(HomeworkItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeworkPage(),
      ),
    );
  }

  String _timelineType(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return 'School';
      case ActivityType.lesson:
        return 'Lesson';
      case ActivityType.extracurricular:
        return 'Extracurricular';
      case ActivityType.exam:
        return 'Exam';
      case ActivityType.event:
        return 'Event';
    }
  }

  IconData _timelineIcon(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return Icons.school_outlined;
      case ActivityType.lesson:
        return Icons.menu_book_outlined;
      case ActivityType.extracurricular:
        return Icons.sports_basketball_outlined;
      case ActivityType.exam:
        return Icons.assignment_outlined;
      case ActivityType.event:
        return Icons.event_outlined;
    }
  }

  Color _timelineBackground(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFFFFEEE2);
      case ActivityType.lesson:
        return const Color(0xFFF0EDFF);
      case ActivityType.extracurricular:
        return const Color(0xFFFFF0E3);
      case ActivityType.exam:
        return const Color(0xFFE5F7F5);
      case ActivityType.event:
        return const Color(0xFFEAF3FF);
    }
  }

  Color _timelineColor(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFFFF7A21);
      case ActivityType.lesson:
        return const Color(0xFF7661D8);
      case ActivityType.extracurricular:
        return const Color(0xFFFF9B3D);
      case ActivityType.exam:
        return const Color(0xFF2A9D8F);
      case ActivityType.event:
        return const Color(0xFF4C8FD9);
    }
  }

  String _formatTimelineTime(TimeOfDayData time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String dayName(DateTime date) {
    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return days[date.weekday - 1];
  }

  String monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String fullDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  List<DateTime> get dateList {
    return List.generate(
      7,
      (index) {
        return selectedDate
            .subtract(const Duration(days: 3))
            .add(Duration(days: index));
      },
    );
  }

  List<CalendarIndicator> _calendarIndicators(DateTime date) {
    // Month view is driven by real activities only.
    // Preparation items intentionally do NOT create calendar dots.
    final indicators = <IndicatorType>[];

    for (final activity in Bag2SchoolStore.activities) {
      if (!activity.occursOn(date) || Bag2SchoolStore.isOccurrenceCancelled(date, activity.id)) {
        continue;
      }

      // Class/Lesson is always an orange activity dot.
      if (activity.type == ActivityType.lesson) {
        if (!indicators.contains(IndicatorType.activity)) {
          indicators.add(IndicatorType.activity);
        }
        continue;
      }

      if (!activity.showIndicator) {
        continue;
      }

      switch (activity.indicatorType) {
        case ActivityIndicatorType.activity:
          if (!indicators.contains(IndicatorType.activity)) {
            indicators.add(IndicatorType.activity);
          }
          break;
        case ActivityIndicatorType.homework:
          if (!indicators.contains(IndicatorType.homework)) {
            indicators.add(IndicatorType.homework);
          }
          break;
        case ActivityIndicatorType.exam:
          if (!indicators.contains(IndicatorType.exam)) {
            indicators.add(IndicatorType.exam);
          }
          break;
        case ActivityIndicatorType.event:
          if (!indicators.contains(IndicatorType.event)) {
            indicators.add(IndicatorType.event);
          }
          break;
        case ActivityIndicatorType.preparation:
          // Preparation is a checklist linked to an activity, not a
          // calendar event. It must never add a month-view dot.
          break;
        case ActivityIndicatorType.overdue:
          if (!indicators.contains(IndicatorType.overdue)) {
            indicators.add(IndicatorType.overdue);
          }
          break;
        case ActivityIndicatorType.none:
          break;
      }
    }

    final cleanDate = DateTime(date.year, date.month, date.day);
    final hasActiveHomework = Bag2SchoolStore.homeworks.any((homework) {
      final due = DateTime(
        homework.dueDate.year,
        homework.dueDate.month,
        homework.dueDate.day,
      );
      return due == cleanDate && !homework.completed;
    });
    final hasAnyHomework = Bag2SchoolStore.homeworks.any((homework) {
      final due = DateTime(
        homework.dueDate.year,
        homework.dueDate.month,
        homework.dueDate.day,
      );
      return due == cleanDate;
    });
    if (hasActiveHomework || hasAnyHomework) {
      if (!indicators.contains(IndicatorType.homework)) {
        indicators.add(IndicatorType.homework);
      }
    }

    return indicators
        .map((type) => CalendarIndicator(type))
        .toList();
  }

  Future<void> openCalendar() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Bag2SchoolMonthCalendar(
          selectedDate: selectedDate,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _anchorMonday = _mondayOf(picked);
        _visibleWeekPage = _initialWeekPage;
      });

      _weekPageController.jumpToPage(_initialWeekPage);
      _showBagiScheduleMessage(_buildDateSummaryMessage(picked));
    }
  }

  @override
  void _showAddActivityChooser() {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.schedule)) {
      LocalAuthorization.showDenied(
        context,
        'add',
        featureLabel: 'schedule',
        feature: LocalPermissionFeature.schedule,
        requestEdit: true,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DDD7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'What would you like to add?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF29231F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _activityChoice(
                    sheetContext,
                    Icons.school_outlined,
                    'School',
                    'Regular school schedule',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(const Duration(milliseconds: 180), _showSchoolForm);
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.menu_book_outlined,
                    'Lesson',
                    'English, Math, language class, etc.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(const Duration(milliseconds: 180), _showLessonForm);
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.sports_basketball_outlined,
                    'Extracurricular',
                    'Basketball, Taekwondo, and more',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(const Duration(milliseconds: 180), _showExtracurricularForm);
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.assignment_outlined,
                    'Exam',
                    'Exam, test, or school assessment',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(const Duration(milliseconds: 180), _showExamForm);
                    },
                  ),
                  _activityChoice(
                    sheetContext,
                    Icons.event_outlined,
                    'Event',
                    'Field trip, parent meeting, or school event',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Future.delayed(const Duration(milliseconds: 180), _showEventForm);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget build(BuildContext context) {
    final currentRole =
        Bag2SchoolStore.familyMemberForCurrentAccount()?.role;
    final isOwner = currentRole == FamilyMemberRole.owner;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF8),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29231F),
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Kenneth's activities",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF756B65),
              ),
            ),
          ],
        ),
      ),

      body: LocalAuthorization.authorizedView(
        context: context,
        feature: LocalPermissionFeature.schedule,
        title: 'Schedule',
        featureLabel: 'Schedule',
        childId: Bag2SchoolStore.activeChildId,
        child:  Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ==================================================
            // DATE SELECTOR
            // ==================================================

            // ==================================================
            // WEEK DATE SELECTOR
            // PageView makes the dates follow the finger smoothly.
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 116,
                    padding: const EdgeInsets.fromLTRB(
                      10,
                      10,
                      10,
                      8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFF1E5DD),
                      ),
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              '${monthName(_dateForWeekPage(_visibleWeekPage, 0).month)} ${_dateForWeekPage(_visibleWeekPage, 0).year}',
                              key: ValueKey(
                                '${_dateForWeekPage(_visibleWeekPage, 0).year}-${_dateForWeekPage(_visibleWeekPage, 0).month}',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF756B65),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 3),

                        Expanded(
                          child: PageView.builder(
                            controller: _weekPageController,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            onPageChanged: (page) {
                              // Swiping only changes the visible week.
                              // The selected date/timeline stay where Mom
                              // left them until she taps another date.
                              setState(() {
                                _visibleWeekPage = page;
                              });
                            },
                            itemBuilder: (context, page) {
                              final weekDates = List.generate(
                                7,
                                (index) => _dateForWeekPage(
                                  page,
                                  index,
                                ),
                              );

                              return Row(
                                children: weekDates.map((date) {
                                  final bool isSelected =
                                      date.year ==
                                          selectedDate.year &&
                                      date.month ==
                                          selectedDate.month &&
                                      date.day ==
                                          selectedDate.day;

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _onScheduleDateSelected(date);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        margin:
                                            const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFF7A21)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              dayName(date),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(
                                                        0xFF756B65,
                                                      ),
                                              ),
                                            ),

                                            const SizedBox(height: 3),

                                            Text(
                                              '${date.day}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(
                                                        0xFF29231F,
                                                      ),
                                              ),
                                            ),

                                            const SizedBox(height: 3),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                              children:
                                                  _calendarIndicators(
                                                date,
                                              ).take(3).map(
                                                (indicator) =>
                                                    Container(
                                                  width: 5,
                                                  height: 5,
                                                  margin:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 1,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : indicator.color,
                                                    shape:
                                                        BoxShape.circle,
                                                  ),
                                                ),
                                              ).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // FULL CALENDAR
                Container(
                  width: 52,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7D2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    onPressed: openCalendar,
                    tooltip: 'Open calendar',
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFFFF7A21),
                      size: 27,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ==================================================
            // SELECTED DATE
            // ==================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _goToToday,
                  icon: const Icon(
                    Icons.today_outlined,
                    size: 17,
                  ),
                  label: const Text('Today'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A21),
                    side: const BorderSide(
                      color: Color(0xFFFFC8A5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullDate(selectedDate),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              '${_savedActivitiesForSelectedDate().length} ''${_savedActivitiesForSelectedDate().length == 1 ? 'activity' : 'activities'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF756B65),
              ),
            ),

            const SizedBox(height: 14),

            _buildBagiScheduleBubble(),

            // ==================================================
            // ACTIVITIES TIMELINE
            // ==================================================

            // Header above this point is fixed. Only this area scrolls.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
// ==================================================
            // SAVED ACTIVITIES
            // ==================================================

            ..._savedActivitiesForSelectedDate().map(
              (activity) => ScheduleTimelineItem(
                time: _formatTimelineTime(activity.startTime),
                endTime: _formatTimelineTime(activity.endTime),
                title: activity.title,
                type: _timelineType(activity),
                icon: _timelineIcon(activity),
                backgroundColor: _timelineBackground(activity),
                iconColor: _timelineColor(activity),
                onEdit: () => _showEditActivityDialog(
                  activity,
                  occurrenceDate: selectedDate,
                ),
                onDelete: () => _confirmDeleteActivity(activity),
              ),
            ),

            // Bagi already has a single conversational bubble above.
            // Keep the empty timeline clean instead of rendering a second Bagi.

             // Add Activity is now available from the floating + button.
            const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),

      

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      floatingActionButton: LocalAuthorization.canView(
        LocalPermissionFeature.schedule,
        childId: Bag2SchoolStore.activeChildId,
      )
          ? FloatingActionButton(
              heroTag: 'schedule_add_activity_fab',
              onPressed: _showAddActivityChooser,
              tooltip: 'Add Activity',
              backgroundColor: const Color(0xFFFF7A21),
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        indicatorColor: const Color(0xFFFFE2CF),
        onDestinationSelected: (index) {
          if (index == 1) {
            return;
          }

          if (index == 0) {
            // Always return to the actual Home root.
            // This avoids exposing Preparation when Schedule
            // was opened from Preparation.
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
            return;
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreparationPage(
                  completed: <bool>[false, false, false],
                  onChanged: (index, value) {
                    // Preparation currently manages its own checklist state.
                    // Shared preparation data will be connected later.
                  },
                ),
              ),
            );
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeworkPage(),
              ),
            );
            return;
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
            return;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Preparation',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCHEDULE TIMELINE ITEM
// ============================================================

class ScheduleTimelineItem extends StatefulWidget {
  final String time;
  final String endTime;
  final String title;
  final String type;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleTimelineItem({
    super.key,
    required this.time,
    required this.endTime,
    required this.title,
    required this.type,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ScheduleTimelineItem> createState() => _ScheduleTimelineItemState();
}

class _ScheduleTimelineItemState extends State<ScheduleTimelineItem> {
  bool _showActions = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final editable = widget.onEdit != null || widget.onDelete != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.time,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF756B65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.endTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFA69B94),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: _pressed ? 14 : 12,
                  height: _pressed ? 14 : 12,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: widget.iconColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: widget.iconColor.withValues(
                          alpha: _pressed ? 0.40 : 0.25,
                        ),
                        blurRadius: _pressed ? 7 : 4,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 88,
                  margin: const EdgeInsets.only(top: 4),
                  color: const Color(0xFFE8DED7),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: editable
                        ? () {
                            setState(() {
                              _showActions = !_showActions;
                              _pressed = false;
                            });
                          }
                        : null,
                    onTapDown: editable
                        ? (_) => setState(() => _pressed = true)
                        : null,
                    onTapCancel: editable
                        ? () => setState(() => _pressed = false)
                        : null,
                    onTapUp: editable
                        ? (_) => setState(() => _pressed = false)
                        : null,
                    child: AnimatedScale(
                      scale: _pressed ? 0.985 : 1.0,
                      duration: const Duration(milliseconds: 110),
                      curve: Curves.easeOut,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: _pressed
                              ? Color.lerp(
                                  widget.backgroundColor,
                                  Colors.black,
                                  0.035,
                                )
                              : widget.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _showActions
                                ? widget.iconColor.withValues(alpha: 0.30)
                                : Colors.transparent,
                            width: _showActions ? 1.5 : 0,
                          ),
                          boxShadow: _pressed
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : const [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.iconColor,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF302722),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.time} – ${widget.endTime}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF756B65),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.type,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: widget.iconColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!editable)
                              Icon(
                                Icons.chevron_right,
                                color: widget.iconColor,
                                size: 25,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showActions && editable) ...[
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    opacity: _showActions ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionIconButton(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFF7661D8),
                          tooltip: 'Edit',
                          onPressed: widget.onEdit,
                        ),
                        const SizedBox(height: 4),
                        _ActionIconButton(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFD94B4B),
                          tooltip: 'Delete',
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: color.withValues(alpha: 0.18),
        highlightColor: color.withValues(alpha: 0.10),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color backgroundColor;
  final Color iconColor;

  const ScheduleItem({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(width: 5),

          const Icon(
            Icons.chevron_right,
            color: Colors.black45,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TODO ITEM
// ============================================================

class TodoItem extends StatelessWidget {
  final String title;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const TodoItem({
    super.key,
    required this.title,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: checked
            ? const Color(0xFFEAF7EF)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: checked
              ? const Color(0xFFB8DFC7)
              : const Color(0xFFF1E5DD),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (value) {
              onChanged(
                value ?? false,
              );
            },
            activeColor:
                const Color(0xFF59A66F),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                    color: checked
                        ? const Color(
                            0xFF3F7652,
                          )
                        : const Color(
                            0xFF302722,
                          ),
                  ),
                ),

                if (checked)
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 3,
                    ),
                    child: Text(
                      'Ready! ✓',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF4E9565),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOMEWORK PAGE — V5
// ============================================================

class _HomeworkActivityOption {
  final BagActivity activity;
  final DateTime occurrenceDate;
  const _HomeworkActivityOption({required this.activity, required this.occurrenceDate});

  // The dropdown is scoped to ONE due date, so each activity can safely use
  // its real activity id as the DropdownButton value. This also avoids the
  // duplicate-value crash for recurring Mon-Fri activities.
  String get value => activity.id;
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage>
    with SingleTickerProviderStateMixin {
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _orangeSoft = Color(0xFFFFE8D5);
  static const Color _peach = Color(0xFFFFF1E6);
  static const Color _cream = Color(0xFFFFFCF8);
  static const Color _ink = Color(0xFF29231F);
  static const Color _muted = Color(0xFF756B65);

  bool _showCompleted = false;
  late final AnimationController _bagiController;
  Timer? _bagiTimer;
  int _messageIndex = 0;
  int _messageVersion = 0;
  String _visibleMessage = '';

  final List<String> _bagiMessages = const [
    "Yay! 🎉 You're all caught up!",
    "No homework waiting right now. Enjoy your free time! ✨",
    "Let's take homework one little step at a time! 📚",
    "I'm here to help you stay on track! 🎒",
  ];

  @override
  void initState() {
    super.initState();
    _bagiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _typeMessage(_bagiMessages.first);
    _bagiTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      _messageIndex = (_messageIndex + 1) % _bagiMessages.length;
      _typeMessage(_bagiMessages[_messageIndex]);
    });
  }

  @override
  void dispose() {
    _bagiTimer?.cancel();
    _bagiController.dispose();
    super.dispose();
  }

  void _typeMessage(String message) {
    final version = ++_messageVersion;
    setState(() => _visibleMessage = '');
    final characters = message.runes.toList();
    for (var i = 1; i <= characters.length; i++) {
      Future.delayed(Duration(milliseconds: 28 * i), () {
        if (!mounted || version != _messageVersion) return;
        setState(() => _visibleMessage = String.fromCharCodes(characters.take(i)));
      });
    }
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _dueLabel(HomeworkItem item) {
    final today = _dayOnly(DateTime.now());
    final due = _dayOnly(item.dueDate);
    final diff = due.difference(today).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${_dateLabel(due)}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _homeworkStatusLabel(HomeworkItem item) {
    final today = _dayOnly(DateTime.now());
    final due = _dayOnly(item.dueDate);
    final diff = due.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${_dateLabel(due)}';
  }

  List<HomeworkItem> _openHomework() {
    return Bag2SchoolStore.homeworks
        .where((h) => !h.completed)
        .toList()
      ..sort((a, b) {
        final d = _dayOnly(a.dueDate).compareTo(_dayOnly(b.dueDate));
        return d != 0 ? d : a.createdAt.compareTo(b.createdAt);
      });
  }

  List<HomeworkItem> _todayHomework() {
    final today = _dayOnly(DateTime.now());
    return _openHomework()
        .where((h) => _sameDay(_dayOnly(h.dueDate), today))
        .toList();
  }

  List<HomeworkItem> _tomorrowHomework() {
    final tomorrow = _dayOnly(DateTime.now()).add(const Duration(days: 1));
    return _openHomework()
        .where((h) => _sameDay(_dayOnly(h.dueDate), tomorrow))
        .toList();
  }

  List<HomeworkItem> _upcomingHomework() {
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    return _openHomework()
        .where((h) {
          final due = _dayOnly(h.dueDate);
          return due.isAfter(tomorrow);
        })
        .toList();
  }

  List<HomeworkItem> _overdueHomework() {
    final today = _dayOnly(DateTime.now());
    return _openHomework()
        .where((h) => _dayOnly(h.dueDate).isBefore(today))
        .toList()
      ..sort((a, b) => _dayOnly(b.dueDate).compareTo(_dayOnly(a.dueDate)));
  }

  List<HomeworkItem> _completedItems() {
    return Bag2SchoolStore.homeworks
        .where((h) => h.completed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _toggleDone(HomeworkItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(context, 'change', featureLabel: 'homework');
      return;
    }
    final index = Bag2SchoolStore.homeworks.indexWhere((h) => h.id == item.id);
    if (index < 0) return;
    setState(() {
      // Homework completion is independent from Preparation completion.
      Bag2SchoolStore.homeworks[index] =
          item.copyWith(completed: !item.completed);
    });
  }

  Future<void> _undoCompleted(HomeworkItem item) async {
    final index = Bag2SchoolStore.homeworks.indexWhere((h) => h.id == item.id);
    if (index < 0) return;
    setState(() {
      Bag2SchoolStore.homeworks[index] = item.copyWith(completed: false);
    });
  }

  void _removeHomeworkFromPreparation(HomeworkItem item) {
    final prepId = 'prep-${item.id}';
    Bag2SchoolStore.preparations.removeWhere((p) => p.id == prepId);
    for (final entry in Bag2SchoolStore.preparationOccurrenceOverrides.entries.toList()) {
      final updated = entry.value.where((p) => p.id != prepId).toList();
      Bag2SchoolStore.preparationOccurrenceOverrides[entry.key] = updated;
    }
  }

  void _addHomeworkToPreparation(HomeworkItem item) {
    if (item.relatedActivityId == null) return;
    final key = Bag2SchoolStore.preparationOccurrenceKey(item.dueDate, item.relatedActivityId!);
    final occurrenceItems = Bag2SchoolStore.preparationsForOccurrence(item.dueDate, item.relatedActivityId!);
    occurrenceItems.removeWhere((p) => p.id == 'prep-${item.id}');
    occurrenceItems.add(PreparationItem(
      id: 'prep-${item.id}',
      activityId: item.relatedActivityId!,
      title: item.task,
      preparationDate: item.dueDate,
      reminderEnabled: item.reminderEnabled,
      reminderDate: item.reminderDate,
      reminderHour: item.reminderHour,
      reminderMinute: item.reminderMinute,
    ));
    Bag2SchoolStore.preparationOccurrenceOverrides[key] = occurrenceItems;
  }

  Future<void> _delete(HomeworkItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(context, 'delete', featureLabel: 'homework');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cream,
        title: const Text('Delete homework?'),
        content: Text('Remove “${item.task}” from homework?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      Bag2SchoolStore.homeworks.removeWhere((h) => h.id == item.id);
      _removeHomeworkFromPreparation(item);
    });

    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.homework,
      action: 'Deleted',
      title: 'Homework deleted',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
          'deleted ${Bag2SchoolStore.activeChild.name} [${item.task}].',
      childId: Bag2SchoolStore.activeChildId,
      entityId: item.id,
    );
  }

  Widget _bagiHero() {
    return AnimatedBuilder(
      animation: _bagiController,
      builder: (context, child) {
        final y = sin(_bagiController.value * pi) * 5;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.translate(
              offset: Offset(0, -y),
              child: SizedBox(
                width: 128,
                height: 128,
                child: const BagiCharacter(),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(child: _speechBubble(_visibleMessage)),
          ],
        );
      },
    );
  }

  Widget _speechBubble(String text) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(20, 15, 18, 15),
          decoration: BoxDecoration(
            color: _peach,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(8),
            ),
            border: Border.all(color: const Color(0xFFFFC18F), width: 1.2),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              text.isEmpty ? '...' : text,
              key: ValueKey(text),
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          left: -9,
          bottom: 12,
          child: CustomPaint(
            size: const Size(18, 18),
            painter: _OrangeBubbleTailPainter(),
          ),
        ),
      ],
    );
  }

  Widget _segmentedTabs() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              'To Do',
              !_showCompleted,
              () => setState(() => _showCompleted = false),
            ),
          ),
          Expanded(
            child: _tabButton(
              'Completed',
              _showCompleted,
              () => setState(() => _showCompleted = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x12000000), blurRadius: 5, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _orange : _muted,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required bool completed}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD8B9)),
      ),
      child: Column(
        children: [
          Container(
            width: 116,
            height: 96,
            decoration: BoxDecoration(
              color: _orangeSoft,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.checklist_rounded, size: 65, color: _orange),
                Positioned(
                  right: 19,
                  bottom: 12,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: _orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            completed
                ? 'No completed homework yet.'
                : 'No homework waiting right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            completed ? 'We’ll celebrate it here! 🎉' : 'Enjoy your free time! 🌟',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _homeworkSection({
    required String title,
    required List<HomeworkItem> items,
    Color? titleColor,
    int? badgeCount,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isToday = title == 'TODAY';
    final isTomorrow = title == 'TOMORROW';
    final isOverdue = title == 'OVERDUE';
    final color = titleColor ?? (isToday
        ? _orange
        : isTomorrow
            ? const Color(0xFF7661D8)
            : isOverdue
                ? const Color(0xFFC95757)
                : const Color(0xFF4C8FD9));
    final background = isToday
        ? const Color(0xFFFFEBDD)
        : isTomorrow
            ? const Color(0xFFF0EDFF)
            : isOverdue
                ? const Color(0xFFFFEEEE)
                : const Color(0xFFEEF6FF);
    final border = isToday
        ? const Color(0xFFFFB87A)
        : isTomorrow
            ? const Color(0xFFD2C8F6)
            : isOverdue
                ? const Color(0xFFF1BABA)
                : const Color(0xFFC8DDF2);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: isToday ? 1.4 : 1),
        boxShadow: isToday
            ? const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 3))]
            : null,
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 9),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                  color: color,
                ),
              ),
              const Spacer(),
              if (badgeCount != null)
                Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0E0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC95757),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...items.map(_homeworkCard),
        const SizedBox(height: 6),
      ],
      ),
    );
  }

  Widget _homeworkEmptyHint() {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0C7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: _orange, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              "Nothing due here. You're doing great! ✨",
              style: TextStyle(
                fontSize: 12.5,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeworkCard(HomeworkItem item) {
    final prepExists = Bag2SchoolStore.preparations.any((p) => p.id == 'prep-${item.id}');

    BagActivity? relatedActivity;
    if (item.relatedActivityId != null) {
      for (final activity in Bag2SchoolStore.activities) {
        if (activity.id == item.relatedActivityId) {
          relatedActivity = activity;
          break;
        }
      }
    }

    if (item.completed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7EE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFB9DFC5)),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(color: Color(0xFFD8F0DF), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF4C956C), size: 26),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.task, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF31583E))),
                      if (item.subject.isNotEmpty)
                        Text(item.subject, style: const TextStyle(fontSize: 12, color: Color(0xFF5E8068), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                _completedInfo(Icons.calendar_today_outlined, _dateLabel(item.dueDate)),
                if (item.dueTime != null)
                  _completedInfo(Icons.schedule_outlined, '${item.dueTime!.hour.toString().padLeft(2, '0')}:${item.dueTime!.minute.toString().padLeft(2, '0')}'),
                if (relatedActivity != null)
                  _completedInfo(Icons.link_rounded, _relatedActivityLabel(relatedActivity!)),
              ],
            ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(item.notes, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5E8068), height: 1.35)),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _undoCompleted(item),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF4C956C)),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD8B9)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 9, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: _orangeSoft, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.menu_book_rounded, color: _orange),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.task, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ink)),
                    if (item.subject.isNotEmpty)
                      Text(item.subject, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                iconColor: _muted,
                onSelected: (v) {
                  if (v == 'edit') _editHomework(item);
                  if (v == 'delete') _delete(item);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 7,
            children: [
              _smallInfo(Icons.calendar_today_outlined, _homeworkStatusLabel(item)),
              if (item.dueTime != null)
                _smallInfo(Icons.schedule_outlined, '${item.dueTime!.hour.toString().padLeft(2, '0')}:${item.dueTime!.minute.toString().padLeft(2, '0')}'),
              if (relatedActivity != null)
                _smallInfo(Icons.link_rounded, _relatedActivityLabel(relatedActivity!)),
              if (item.reminderEnabled)
                _smallInfo(Icons.notifications_none_outlined, 'Reminder'),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(item.notes, style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.35)),
          ],
          if (prepExists) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.backpack_outlined, size: 16, color: _orange),
                SizedBox(width: 4),
                Text('Added to preparation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF9A5D31))),
              ],
            ),
          ],
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _toggleDone(item),
              style: TextButton.styleFrom(foregroundColor: _orange),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedInfo(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFDFF2E5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4C956C)),
          const SizedBox(width: 5),
          Flexible(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF31583E)))),
        ],
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _orangeSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _orange),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.sentences,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 21, color: _orange),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          textCapitalization: capitalization,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9B918B)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFFFC18F), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _orange, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selector({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFC18F), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(icon, color: _orange, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
                ),
              ),
              trailing ?? const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  String _relatedActivityLabel(BagActivity activity, {DateTime? occurrenceDate}) {
    final start =
        '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${activity.endTime.hour.toString().padLeft(2, '0')}:${activity.endTime.minute.toString().padLeft(2, '0')}';
    // The due date is already visible in the Homework form, so keep the
    // dropdown label compact and prevent the selected row from overflowing.
    return '${activity.title} · $start–$end';
  }

  Future<void> _addHomework() async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(
        context,
        'add',
        featureLabel: 'homework',
        feature: LocalPermissionFeature.homework,
        requestEdit: true,
      );
      return;
    }
    final task = TextEditingController();
    final subject = TextEditingController();
    final notes = TextEditingController();
    DateTime dueDate = _dayOnly(DateTime.now());
    TimeOfDayData? dueTime;
    bool reminder = false;
    DateTime reminderDate = dueDate.subtract(const Duration(days: 1));
    int reminderHour = 18;
    int reminderMinute = 30;
    String? relatedActivityId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Related Activity is scoped to the selected homework due date.
          // For a recurring Mon-Fri activity, this produces only the single
          // occurrence for the selected date instead of filling the dropdown
          // with dozens of repeated occurrences.
          final activityOptions = Bag2SchoolStore.activities
              .where((activity) =>
                  activity.type != ActivityType.exam &&
                  activity.occursOn(dueDate))
              .map((activity) => _HomeworkActivityOption(
                    activity: activity,
                    occurrenceDate: dueDate,
                  ))
              .toList()
            ..sort((a, b) =>
                a.activity.startMinutes().compareTo(b.activity.startMinutes()));

          // If the due date changes, an activity selected for the previous
          // date is no longer valid. Clear it before rendering the dropdown.
          if (relatedActivityId != null &&
              !activityOptions.any((option) => option.value == relatedActivityId)) {
            relatedActivityId = null;
          }

          return SafeArea(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 760),
              decoration: const BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D8CC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 3),
                          child: SizedBox(width: 105, height: 105, child: const BagiCharacter()),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _speechBubble(
                            'Let’s add a homework! 📚\nBagi will help you keep it simple.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                      decoration: BoxDecoration(
                        color: _peach,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFFFD2AD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formField(
                            controller: task,
                            label: 'What do you need to do?',
                            hint: 'e.g. Mandarin worksheet',
                            icon: Icons.menu_book_rounded,
                            autofocus: true,
                          ),
                          const SizedBox(height: 18),
                          _formField(
                            controller: subject,
                            label: 'Subject (optional)',
                            hint: 'e.g. Mandarin',
                            icon: Icons.school_rounded,
                            capitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 21, color: _orange),
                              SizedBox(width: 8),
                              Text('When is it due?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _selector(
                                icon: Icons.calendar_today_outlined,
                                label: _dateLabel(dueDate),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate,
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  );
                                  if (picked == null) return;
                                  setSheetState(() {
                                    dueDate = _dayOnly(picked);
                                    if (reminderDate.isAfter(dueDate)) reminderDate = dueDate;
                                  });
                                },
                              ),
                              const SizedBox(width: 9),
                              _selector(
                                icon: Icons.schedule_outlined,
                                label: dueTime == null
                                    ? 'Any time'
                                    : '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}',
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(hour: dueTime?.hour ?? 17, minute: dueTime?.minute ?? 0),
                                  );
                                  if (picked == null) return;
                                  setSheetState(() => dueTime = TimeOfDayData(hour: picked.hour, minute: picked.minute));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (activityOptions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5ED),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFFFC18F)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded, color: _orange, size: 21),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'No activity is scheduled on this date. You can still save the homework without linking it to an activity.',
                                      style: TextStyle(fontSize: 12.5, height: 1.35, color: _ink, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: relatedActivityId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Related activity (optional)',
                                prefixIcon: const Icon(Icons.link_rounded, color: _orange),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: Color(0xFFFFC18F), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(color: _orange, width: 1.8),
                                ),
                              ),
                              hint: const Text('No specific activity'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('No specific activity'),
                                ),
                                ...activityOptions.map((option) => DropdownMenuItem<String>(
                                  value: option.value,
                                  child: Text(
                                    _relatedActivityLabel(
                                      option.activity,
                                      occurrenceDate: option.occurrenceDate,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setSheetState(() {
                                  relatedActivityId = (value == null || value.isEmpty) ? null : value;
                                });
                              },
                            ),
                          if (relatedActivityId != null) ...[
                            const SizedBox(height: 10),
                            Builder(
                              builder: (_) {
                                final linked = activityOptions.where((o) => o.value == relatedActivityId).toList();
                                if (linked.isEmpty) return const SizedBox.shrink();
                                final option = linked.first;
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                                  decoration: BoxDecoration(
                                    color: _orangeSoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.event_available_rounded, color: _orange, size: 20),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          _relatedActivityLabel(option.activity, occurrenceDate: option.occurrenceDate),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w800, color: _ink),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFFC18F)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(color: _orangeSoft, shape: BoxShape.circle),
                                  child: const Icon(Icons.notifications_none_rounded, color: _orange),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Remind me', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
                                      SizedBox(height: 2),
                                      Text('Bagi can give you a little heads-up.', style: TextStyle(fontSize: 11.5, color: _muted)),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: reminder,
                                  activeColor: _orange,
                                  onChanged: (v) => setSheetState(() {
                                    reminder = v;
                                    if (v) reminderDate = dueDate.subtract(const Duration(days: 1));
                                  }),
                                ),
                              ],
                            ),
                          ),
                          if (reminder) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _selector(
                                  icon: Icons.notifications_none_outlined,
                                  label: _dateLabel(reminderDate),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: reminderDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: dueDate,
                                    );
                                    if (picked == null) return;
                                    setSheetState(() => reminderDate = _dayOnly(picked));
                                  },
                                ),
                                const SizedBox(width: 9),
                                _selector(
                                  icon: Icons.access_time_outlined,
                                  label: '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}',
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(hour: reminderHour, minute: reminderMinute),
                                    );
                                    if (picked == null) return;
                                    setSheetState(() {
                                      reminderHour = picked.hour;
                                      reminderMinute = picked.minute;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 18),
                          _formField(
                            controller: notes,
                            label: 'Anything else? (optional)',
                            hint: 'Add a note...',
                            icon: Icons.edit_note_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: task,
                            builder: (context, value, _) {
                              final enabled = value.text.trim().isNotEmpty;
                              return Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: OutlinedButton(
                                        onPressed: () async { await _settleDialogFocus(); if (!sheetContext.mounted) return; Navigator.pop(sheetContext, false); },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _muted,
                                          side: const BorderSide(color: Color(0xFFD9CCC4), width: 1.3),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                        ),
                                        child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: SizedBox(
                                      height: 56,
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: enabled ? _orange : const Color(0xFFE8E1DD),
                                          foregroundColor: enabled ? Colors.white : const Color(0xFFA9A19D),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                        ),
                                        onPressed: !enabled
                                            ? null
                                            : () async {
                                                final id = 'homework-${DateTime.now().microsecondsSinceEpoch}';
                                                final item = HomeworkItem(
                                                  id: id,
                                                  task: task.text.trim(),
                                                  subject: subject.text.trim(),
                                                  dueDate: dueDate,
                                                  dueTime: dueTime,
                                                  reminderEnabled: reminder,
                                                  reminderDate: reminder ? reminderDate : null,
                                                  reminderHour: reminderHour,
                                                  reminderMinute: reminderMinute,
                                                  notes: notes.text.trim(),
                                                  relatedActivityId: relatedActivityId,
                                                  createdAt: DateTime.now(),
                                                );
                                                Bag2SchoolStore.homeworks.add(item);
                                                _addHomeworkToPreparation(item);

                                                Bag2SchoolStore.recordFamilyActivity(
                                                  feature: LocalPermissionFeature.homework,
                                                  action: 'Added',
                                                  title: 'Homework added',
                                                  message:
                                                  '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                                  'added ${Bag2SchoolStore.activeChild.name} [${item.task}].',
                                                  childId: Bag2SchoolStore.activeChildId,
                                                  entityId: item.id,
                                                );

                                                await _settleDialogFocus();
                                                if (!sheetContext.mounted) return;
                                                Navigator.pop(sheetContext, true);
                                              },
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text('Save & Close', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      task.dispose();
      subject.dispose();
      notes.dispose();
    });
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _editHomework(HomeworkItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.homework)) {
      LocalAuthorization.showDenied(context, 'edit', featureLabel: 'homework');
      return;
    }
    final task = TextEditingController(text: item.task);
    final subject = TextEditingController(text: item.subject);
    DateTime dueDate = _dayOnly(item.dueDate);
    TimeOfDayData? dueTime = item.dueTime;
    bool reminder = item.reminderEnabled;
    DateTime reminderDate = item.reminderDate ?? dueDate.subtract(const Duration(days: 1));
    int reminderHour = item.reminderHour;
    int reminderMinute = item.reminderMinute;
    String? relatedActivityId = item.relatedActivityId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final activityOptions = Bag2SchoolStore.activities
              .where((activity) =>
                  activity.type != ActivityType.exam &&
                  activity.occursOn(dueDate))
              .where((activity) =>
                  !Bag2SchoolStore.isOccurrenceCancelled(
                    dueDate,
                    activity.id,
                  ))
              .map((activity) => _HomeworkActivityOption(
                    activity: activity,
                    occurrenceDate: dueDate,
                  ))
              .toList()
            ..sort((a, b) => a.activity.startMinutes().compareTo(b.activity.startMinutes()));
          if (relatedActivityId != null && !activityOptions.any((o) => o.value == relatedActivityId)) {
            relatedActivityId = null;
          }
          return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 720),
            decoration: const BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFE8D8CC), borderRadius: BorderRadius.circular(20)))),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(width: 92, height: 92, child: const BagiCharacter()),
                      const SizedBox(width: 4),
                      Expanded(child: _speechBubble('Let’s make a little update! ✏️')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                    decoration: BoxDecoration(color: _peach, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFFFD2AD))),
                    child: Column(
                      children: [
                        _formField(controller: task, label: 'What do you need to do?', hint: 'e.g. Mandarin worksheet', icon: Icons.menu_book_rounded),
                        const SizedBox(height: 18),
                        _formField(controller: subject, label: 'Subject (optional)', hint: 'e.g. Mandarin', icon: Icons.school_rounded, capitalization: TextCapitalization.words),
                        const SizedBox(height: 18),
                        const Align(alignment: Alignment.centerLeft, child: Text('When is it due?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink))),
                        const SizedBox(height: 8),
                        Row(children: [
                          _selector(icon: Icons.calendar_today_outlined, label: _dateLabel(dueDate), onTap: () async {
                            final p = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
                            if (p == null) return;
                            final newDate = _dayOnly(p);
                            setSheetState(() {
                              dueDate = newDate;
                              if (reminderDate.isAfter(dueDate)) reminderDate = dueDate;
                              if (relatedActivityId != null) {
                                final stillValid = Bag2SchoolStore.activities.any((a) => a.id == relatedActivityId && a.occursOn(newDate) && !Bag2SchoolStore.isOccurrenceCancelled(newDate, a.id));
                                if (!stillValid) relatedActivityId = null;
                              }
                            });
                          }),
                          const SizedBox(width: 9),
                          _selector(icon: Icons.schedule_outlined, label: dueTime == null ? 'Any time' : '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}', onTap: () async {
                            final p = await showTimePicker(context: context, initialTime: TimeOfDay(hour: dueTime?.hour ?? 17, minute: dueTime?.minute ?? 0));
                            if (p == null) return;
                            setSheetState(() => dueTime = TimeOfDayData(hour: p.hour, minute: p.minute));
                          }),
                        ]),
                        const SizedBox(height: 18),
                        if (activityOptions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(color: const Color(0xFFFFF7F1), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFFDEC5))),
                            child: const Text('No activity is scheduled on this date. The homework can stay unlinked.', style: TextStyle(fontSize: 12.5, color: _muted, fontWeight: FontWeight.w600)),
                          )
                        else
                          DropdownButtonFormField<String?>(
                            value: relatedActivityId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Related activity (optional)',
                              prefixIcon: const Icon(Icons.link_rounded, color: _orange),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFFFC18F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFFFC18F))),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('No specific activity')),
                              ...activityOptions.map((option) => DropdownMenuItem<String?>(value: option.value, child: Text(_relatedActivityLabel(option.activity, occurrenceDate: dueDate), overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (value) => setSheetState(() => relatedActivityId = value),
                          ),
                        if (relatedActivityId != null) ...[
                          const SizedBox(height: 7),
                          Builder(builder: (_) {
                            final linked = activityOptions.where((o) => o.value == relatedActivityId).toList();
                            if (linked.isEmpty) return const SizedBox.shrink();
                            return Text(_relatedActivityLabel(linked.first.activity, occurrenceDate: dueDate), style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w700));
                          }),
                        ],
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFC18F))),
                          child: Row(children: [
                            const Icon(Icons.notifications_none_rounded, color: _orange),
                            const SizedBox(width: 10),
                            const Expanded(child: Text('Remind me', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink))),
                            Switch.adaptive(value: reminder, activeColor: _orange, onChanged: (v) => setSheetState(() { reminder = v; if (v) reminderDate = dueDate.subtract(const Duration(days: 1)); })),
                          ]),
                        ),
                        if (reminder) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            _selector(icon: Icons.notifications_none_outlined, label: _dateLabel(reminderDate), onTap: () async {
                              final p = await showDatePicker(context: context, initialDate: reminderDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: dueDate);
                              if (p == null) return;
                              setSheetState(() => reminderDate = _dayOnly(p));
                            }),
                            const SizedBox(width: 9),
                            _selector(icon: Icons.access_time_outlined, label: '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}', onTap: () async {
                              final p = await showTimePicker(context: context, initialTime: TimeOfDay(hour: reminderHour, minute: reminderMinute));
                              if (p == null) return;
                              setSheetState(() { reminderHour = p.hour; reminderMinute = p.minute; });
                            }),
                          ]),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: () async { await _settleDialogFocus(); if (!sheetContext.mounted) return; Navigator.pop(sheetContext, false); },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _muted,
                                    side: const BorderSide(color: Color(0xFFD9CCC4), width: 1.3),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 56,
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: task,
                                  builder: (context, value, _) => FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: value.text.trim().isEmpty ? const Color(0xFFE8E1DD) : _orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                                    onPressed: value.text.trim().isEmpty ? null : () async {
                                      final index = Bag2SchoolStore.homeworks.indexWhere((h) => h.id == item.id);
                                      if (index < 0) return;
                                      _removeHomeworkFromPreparation(item);
                                      final updated = item.copyWith(task: task.text.trim(), subject: subject.text.trim(), dueDate: dueDate, dueTime: dueTime, reminderEnabled: reminder, reminderDate: reminder ? reminderDate : null, reminderHour: reminderHour, reminderMinute: reminderMinute, clearReminderDate: !reminder, relatedActivityId: relatedActivityId, clearRelatedActivity: relatedActivityId == null);
                                      Bag2SchoolStore.homeworks[index] = updated;
                                      _addHomeworkToPreparation(updated);

                                      Bag2SchoolStore.recordFamilyActivity(
                                        feature: LocalPermissionFeature.homework,
                                        action: 'Edited',
                                        title: 'Homework updated',
                                        message:
                                        '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                                        'updated ${Bag2SchoolStore.activeChild.name} [${updated.task}].',
                                        childId: Bag2SchoolStore.activeChildId,
                                        entityId: updated.id,
                                      );

                                      await _settleDialogFocus();
                                      if (!sheetContext.mounted) return;
                                      Navigator.pop(sheetContext, true);
                                    },
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      task.dispose();
      subject.dispose();
    });
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedItems();
    final todayItems = _todayHomework();
    final tomorrowItems = _tomorrowHomework();
    final upcomingItems = _upcomingHomework();
    final overdueItems = _overdueHomework();

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Homework', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: _ink)),
        actions: [
          if (LocalAuthorization.canView(
            LocalPermissionFeature.homework,
            childId: Bag2SchoolStore.activeChildId,
          ))
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeworkHistoryPage(),
                ),
              ),
              icon: const Icon(
                Icons.history_rounded,
                color: _orange,
              ),
              label: const Text(
                'History',
                style: TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: LocalAuthorization.authorizedView(
        context: context,
        feature: LocalPermissionFeature.homework,
        title: 'Homework',
        featureLabel: 'Homework',
        childId: Bag2SchoolStore.activeChildId,
        child:  SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Text('A little step at a time. ✨', style: TextStyle(fontSize: 17, color: _muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _bagiHero(),
            const SizedBox(height: 6),
            _segmentedTabs(),
            const SizedBox(height: 18),
            if (_showCompleted)
              if (completed.isEmpty)
                _emptyState(completed: true)
              else
                ...completed.map(_homeworkCard)
            else ...[
              _homeworkSection(
                title: 'TODAY',
                items: todayItems,
              ),
              _homeworkSection(
                title: 'TOMORROW',
                items: tomorrowItems,
                titleColor: const Color(0xFFE39A24),
              ),
              _homeworkSection(
                title: 'UPCOMING',
                items: upcomingItems,
                titleColor: _muted,
              ),
              _homeworkSection(
                title: 'OVERDUE',
                items: overdueItems,
                titleColor: const Color(0xFFC95757),
                badgeCount: overdueItems.length,
              ),
              if (todayItems.isEmpty && tomorrowItems.isEmpty &&
                  upcomingItems.isEmpty && overdueItems.isEmpty)
                _homeworkEmptyHint(),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),

      
      floatingActionButton: LocalAuthorization.canView(
        LocalPermissionFeature.homework,
        childId: Bag2SchoolStore.activeChildId,
      )
          ? FloatingActionButton(
              heroTag: 'homework_add_fab',
              onPressed: _addHomework,
              tooltip: 'Add Homework',
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        backgroundColor: const Color(0xFFFFF1E8),
        indicatorColor: _orangeSoft,
        onDestinationSelected: (index) {
          if (index == 3) return;
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SchedulePage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PreparationPage()));
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist_rounded), label: 'Preparation'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Homework'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

class _OrangeBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFF1E6);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeworkHistoryPage extends StatelessWidget {
  const HomeworkHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today=DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day);
    final items=Bag2SchoolStore.homeworks.where((h)=>DateTime(h.dueDate.year,h.dueDate.month,h.dueDate.day).isBefore(today)).toList()..sort((a,b)=>b.dueDate.compareTo(a.dueDate));
    return Scaffold(
      backgroundColor:const Color(0xFFFFFCF8),
      appBar:AppBar(backgroundColor:Colors.transparent,elevation:0,title:const Text('Homework History',style:TextStyle(fontWeight:FontWeight.w900))),
      body:ListView(padding:const EdgeInsets.fromLTRB(18,10,18,30),children:[
        if(items.isEmpty)Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:const Text('Your homework history will appear here. 😊',style:TextStyle(color:Color(0xFF756B65)))),
        ...items.map((item){
          final done=item.completed;
          return Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:(done?const Color(0xFF4C956C):const Color(0xFFC97845)).withOpacity(.18))),child:Row(children:[Icon(done?Icons.check_circle_rounded:Icons.warning_amber_rounded,color:done?const Color(0xFF4C956C):const Color(0xFFC97845)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item.task,style:const TextStyle(fontWeight:FontWeight.w800)),Text('${done?'Completed':'Overdue'} · ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',style:TextStyle(fontSize:11.5,color:done?const Color(0xFF4C956C):const Color(0xFFC97845),fontWeight:FontWeight.w700))]))]));
        }),
      ]),
    );
  }
}

// ============================================================
// PREPARATION PAGE
// ============================================================


class PreparationPage extends StatefulWidget {
  // Kept optional for compatibility with the earlier navigation code.
  // V3 reads the real shared preparation store instead of demo checklist data.
  final List<bool> completed;
  final void Function(int index, bool value)? onChanged;

  const PreparationPage({
    super.key,
    this.completed = const <bool>[],
    this.onChanged,
  });

  @override
  State<PreparationPage> createState() => _PreparationPageState();
}

class _PreparationPageState extends State<PreparationPage> {
  Timer? _bagiTimer;
  final Random _random = Random();
  final Set<String> _expandedPreparationGroups = <String>{};
  bool _showAllUpcoming = false;
  String _bagiMessage =
      "Good morning, Mom! 😊 Let's get ready for the day! ☀️";
  String? _lastMessage;

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDayData time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  BagActivity? _activityFor(PreparationItem item) {
    for (final activity in Bag2SchoolStore.activities) {
      if (activity.id == item.activityId) return activity;
    }
    return null;
  }

  HomeworkItem? _homeworkForPreparationId(String activityId) {
    if (!activityId.startsWith('homework:')) return null;
    final id = activityId.substring('homework:'.length);
    for (final homework in Bag2SchoolStore.homeworks) {
      if (homework.id == id) return homework;
    }
    return null;
  }

  HomeworkItem? _homeworkForGroup(_PreparationGroup group) {
    for (final item in group.items) {
      final homework = _homeworkForPreparationItem(item);
      if (homework != null) return homework;
    }
    return null;
  }

  String _preparationGroupTitle(_PreparationGroup group) {
    return group.activity?.title ?? 'Preparation';
  }

  String _categoryLabel(BagActivity? activity) {
    if (activity == null) return 'Activity';
    switch (activity.type) {
      case ActivityType.school:
        return 'School';
      case ActivityType.lesson:
        return 'Class';
      case ActivityType.extracurricular:
        return 'Extracurricular';
      case ActivityType.exam:
        return 'Exam';
      case ActivityType.event:
        return 'Event';
    }
  }

  IconData _activityIcon(BagActivity? activity) {
    if (activity == null) return Icons.event_note_outlined;
    switch (activity.type) {
      case ActivityType.school:
        return Icons.school_outlined;
      case ActivityType.lesson:
        return Icons.menu_book_outlined;
      case ActivityType.extracurricular:
        return Icons.sports_basketball_outlined;
      case ActivityType.exam:
        return Icons.assignment_outlined;
      case ActivityType.event:
        return Icons.event_outlined;
    }
  }

  Color _activityTint(BagActivity? activity) {
    if (activity == null) return const Color(0xFF7D6D64);
    switch (activity.type) {
      case ActivityType.school:
        return const Color(0xFF4C8FD9);
      case ActivityType.lesson:
        return const Color(0xFF7661D8);
      case ActivityType.extracurricular:
        return const Color(0xFFFF7A21);
      case ActivityType.exam:
        return const Color(0xFF2A9D8F);
      case ActivityType.event:
        return const Color(0xFF4C956C);
    }
  }

  List<PreparationItem> _itemsForDate(DateTime date) {
    final clean = _dayOnly(date);
    return Bag2SchoolStore.preparations
        .where((item) => item.occursOn(clean))
        .toList();
  }

  List<DateTime> _preparationDates() {
    final dates = Bag2SchoolStore.preparations
        .map((item) => _dayOnly(item.preparationDate))
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  int _done(List<PreparationItem> items) =>
      items.where(_isOccurrenceChecked).length;

  double _progress(List<PreparationItem> items) {
    if (items.isEmpty) return 0;
    return _done(items) / items.length;
  }

  String _progressText(List<PreparationItem> items) {
    return '${_done(items)} of ${items.length} ready';
  }

  List<_PreparationGroup> _groupsForTodayAndFuture() {
    final today = _dayOnly(DateTime.now());
    final byActivity = <String, _PreparationGroup>{};

    void addOccurrence(DateTime date, BagActivity? activity, String activityId) {
      if (date.isBefore(today)) return;
      if (activity != null && Bag2SchoolStore.isOccurrenceCancelled(date, activity.id)) return;

      final items = Bag2SchoolStore.preparationsForOccurrence(
        date,
        activityId,
      );

      // An explicit empty override means this occurrence was intentionally
      // cleared. Do not resurrect it from the recurring template.
      if (items.isEmpty) return;

      final key = '${date.toIso8601String()}|$activityId';
      final group = byActivity.putIfAbsent(
        key,
        () => _PreparationGroup(
          date: date,
          activityId: activityId,
          activity: activity,
        ),
      );

      group.items
        ..clear()
        ..addAll(items);
    }

    // First build every occurrence of every scheduled activity for the next
    // 30 days. This is what makes Mon-Fri School preparation appear on
    // Today, Tomorrow and Upcoming.
    for (final activity in Bag2SchoolStore.activities) {
      for (var offset = 0; offset <= 30; offset++) {
        final date = today.add(Duration(days: offset));
        if (activity.occursOn(date)) {
          addOccurrence(date, activity, activity.id);
        }
      }
    }

    // Also keep standalone preparations / explicitly dated preparations that
    // do not currently have a matching activity occurrence.
    for (final item in Bag2SchoolStore.preparations) {
      final date = _dayOnly(item.preparationDate);
      if (date.isBefore(today)) continue;
      final activity = _activityFor(item);
      if (activity == null) {
        final key = '${date.toIso8601String()}|${item.activityId}';
        final group = byActivity.putIfAbsent(
          key,
          () => _PreparationGroup(
            date: date,
            activityId: item.activityId,
            activity: null,
          ),
        );
        if (!group.items.any((existing) => existing.id == item.id)) {
          group.items.add(item);
        }
      }
    }

    final groups = byActivity.values.toList();
    groups.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;

      final aMinutes = a.activity?.startMinutes() ?? 1440;
      final bMinutes = b.activity?.startMinutes() ?? 1440;
      return aMinutes.compareTo(bMinutes);
    });
    return groups;
  }

  List<_PreparationGroup> _historyGroups() {
    final today = _dayOnly(DateTime.now());
    final byActivity = <String, _PreparationGroup>{};

    for (final item in Bag2SchoolStore.preparations) {
      final date = _dayOnly(item.preparationDate);
      if (!date.isBefore(today)) continue;

      final activity = _activityFor(item);
      final items = activity == null
          ? <PreparationItem>[item]
          : Bag2SchoolStore.preparationsForOccurrence(date, activity.id);

      if (items.isEmpty) continue;

      final key = '${date.toIso8601String()}|${item.activityId}';
      final group = byActivity.putIfAbsent(
        key,
        () => _PreparationGroup(
          date: date,
          activityId: item.activityId,
          activity: activity,
        ),
      );
      group.items
        ..clear()
        ..addAll(items);
    }

    final groups = byActivity.values.toList();
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  List<String> _bagiThoughts() {
    final today = _dayOnly(DateTime.now());
    final groups = _groupsForTodayAndFuture();
    final todayGroups =
        groups.where((group) => group.date == today).toList();

    final messages = <String>[];

    if (todayGroups.isEmpty) {
      messages.add(
        "Good morning, Mom! 😊 Looks like we're all set for today. "
        "Nothing needs preparing right now. ☀️",
      );
    } else {
      final total = todayGroups
          .expand((group) => group.items)
          .toList();
      final ready = _done(total);

      if (ready == total.length) {
        messages.add(
          "Good morning, Mom! 🎉 We're all set for today. "
          "You can relax — everything is ready!",
        );
      } else {
        messages.add(
          "Good morning, Mom! 😊 We have ${todayGroups.length} "
          "${todayGroups.length == 1 ? 'thing' : 'things'} today. "
          "$ready of ${total.length} little preparations are ready.",
        );
      }

      final needsAttention = todayGroups.where(
        (group) => _progress(group.items) < 1,
      ).toList();

      if (needsAttention.isNotEmpty) {
        final target = needsAttention[_random.nextInt(needsAttention.length)];
        final remaining = target.items.length - _done(target.items);
        messages.add(
          "${target.activity?.title ?? 'Today'} still has "
          "$remaining ${remaining == 1 ? 'little thing' : 'little things'} "
          "to get ready. No rush, Mom! 🌿",
        );
      }
    }

    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowGroups =
        groups.where((group) => group.date == tomorrow).toList();

    if (tomorrowGroups.isNotEmpty) {
      final group = tomorrowGroups.first;
      messages.add(
        "Psst, Mom! ${group.activity?.title ?? 'Something'} is tomorrow. "
        "We can get a little head start today. 😊",
      );
    }

    return messages;
  }

  void _startBagi() {
    _bagiTimer?.cancel();
    _showNextBagi();
    _bagiTimer = Timer.periodic(
      const Duration(seconds: 13),
      (_) => _showNextBagi(),
    );
  }

  void _showNextBagi() {
    if (!mounted) return;

    final messages = _bagiThoughts();
    if (messages.isEmpty) return;

    final candidates = messages.length > 1
        ? messages.where((message) => message != _lastMessage).toList()
        : messages;

    final message = candidates[_random.nextInt(candidates.length)];
    _lastMessage = message;

    setState(() {
      _bagiMessage = message;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      _startBagi();
    });
  }

  @override
  void dispose() {
    _bagiTimer?.cancel();
    super.dispose();
  }

  String _occurrenceKey(PreparationItem item) {
    return '${_dayOnly(item.preparationDate).toIso8601String()}|${item.id}';
  }

  bool _isOccurrenceChecked(PreparationItem item) {
    final linkedHomework = _homeworkForPreparationItem(item);
    if (linkedHomework != null) {
      final key =
          '${_dayOnly(item.preparationDate).toIso8601String()}|${linkedHomework.id}';
      return Bag2SchoolStore.homeworkPreparationCompletion[key] ?? false;
    }

    final date = _dayOnly(item.preparationDate);
    final overrideKey = Bag2SchoolStore.preparationOccurrenceKey(
      date,
      item.activityId,
    );

    final overrideItems =
        Bag2SchoolStore.preparationOccurrenceOverrides[overrideKey];
    if (overrideItems != null) {
      final overrideItem = overrideItems
          .where((entry) => entry.id == item.id)
          .cast<PreparationItem?>()
          .firstWhere((entry) => entry != null, orElse: () => null);
      if (overrideItem != null) return overrideItem.completed;
    }

    return Bag2SchoolStore.preparationOccurrenceCompletion[
          '${date.toIso8601String()}|${item.id}'
        ] ??
        item.completed;
  }

  Future<void> _editPreparationGroup(_PreparationGroup group) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(
        context,
        'edit',
        featureLabel: 'preparation',
        feature: LocalPermissionFeature.preparation,
        requestEdit: true,
      );
      return;
    }
    // Homework is displayed in Preparation as a linked reference only.
    // It must never enter the preparation editor or become removable from
    // this dialog. Only real preparation items are editable here.
    final editableItems = group.items
        .where((item) => !_isHomeworkPreparation(item))
        .toList();
    final homeworkItems = group.items
        .where((item) => _isHomeworkPreparation(item))
        .toList();

    final controllers = <TextEditingController>[
      for (final item in editableItems)
        TextEditingController(text: item.title),
    ];
    final ids = <String?>[
      for (final item in editableItems) item.id,
    ];
    final originalItems = <PreparationItem>[...editableItems];
    var dialogClosed = false;

    void disposeAllControllers() {
      for (final controller in controllers) {
        controller.dispose();
      }
    }

    void saveChanges(StateSetter setDialogState) {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final updated = <PreparationItem>[];

      for (var i = 0; i < controllers.length; i++) {
        final title = controllers[i].text.trim();
        if (title.isEmpty) continue;

        final existingId = ids[i];
        PreparationItem? source;

        if (existingId != null) {
          for (final item in originalItems) {
            if (item.id == existingId) {
              source = item;
              break;
            }
          }
        }

        source ??= PreparationItem(
          id: 'preparation-occurrence-$stamp-$i',
          activityId: group.activityId,
          title: title,
          preparationDate: group.date,
        );

        if (existingId == null) {
          // Prevent a second Save from creating the same new item again.
          ids[i] = source.id;
        }

        updated.add(
          source.copyWith(
            title: title,
            preparationDate: group.date,
          ),
        );
      }

      final key = Bag2SchoolStore.preparationOccurrenceKey(
        group.date,
        group.activityId,
      );

      // Keep linked homework in the occurrence untouched. Homework is not
      // part of the preparation editor, but it must remain visible in the
      // Preparation page after the edit is saved.
      final occurrenceItems = <PreparationItem>[...updated, ...homeworkItems];

      // The occurrence now owns its own list. This is the critical V4-style
      // boundary: editing Aug 17 cannot mutate Aug 18/Aug 19 templates.
      Bag2SchoolStore.preparationOccurrenceOverrides[key] = occurrenceItems;

      Bag2SchoolStore.recordFamilyActivity(
        feature: LocalPermissionFeature.preparation,
        action: 'Edited',
        title: 'Preparation updated',
        message:
        '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
        'updated preparation for ${Bag2SchoolStore.activeChild.name} on '
        '${group.date.day}/${group.date.month}/${group.date.year}.',
        childId: Bag2SchoolStore.activeChildId,
        entityId: group.activityId,
      );

      // Completion belongs to the edited occurrence. Preserve completion
      // for existing items while resetting brand-new items to false.
      for (final item in updated) {
        final occurrenceItemKey =
            '${_dayOnly(group.date).toIso8601String()}|${item.id}';
        if (Bag2SchoolStore.preparationOccurrenceCompletion
            .containsKey(occurrenceItemKey)) {
          continue;
        }
        final original = originalItems.where((entry) => entry.id == item.id);
        if (original.isNotEmpty && original.first.completed) {
          Bag2SchoolStore.preparationOccurrenceCompletion[occurrenceItemKey] =
              true;
        }
      }

      // Old hide flags must never resurrect/override the new occurrence list.
      for (final item in originalItems) {
        Bag2SchoolStore.preparationOccurrenceHidden.remove(
          '${_dayOnly(group.date).toIso8601String()}|${item.id}',
        );
      }

      setDialogState(() {});
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              title: Row(
                children: [
                  const SizedBox(
                    width: 46,
                    height: 46,
                    child: BagiCharacter(),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Let’s get things ready ✨',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Edit, remove, or add anything Kenneth needs.',
                          style: TextStyle(
                            color: Color(0xFF756B65),
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < controllers.length; i++)
                        Padding(
                          key: ValueKey(ids[i] ?? 'new-preparation-$i'),
                          padding: const EdgeInsets.only(bottom: 9),
                          child: TextField(
                            controller: controllers[i],
                            onChanged: (_) => setDialogState(() {}),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Preparation ${i + 1}',
                              suffixIcon: IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () async {
                                  final controller = controllers[i];
                                  await _settleDialogFocus();
                                  if (!dialogContext.mounted) return;

                                  setDialogState(() {
                                    if (controllers.length == 1) {
                                      controller.clear();
                                      ids[i] = null;
                                      return;
                                    }
                                    controllers.removeAt(i);
                                    ids.removeAt(i);
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (!dialogClosed) controller.dispose();
                                    });
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _settleDialogFocus();
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              controllers.add(TextEditingController());
                              ids.add(null);
                            });
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add preparation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Done means "finish editing". Commit the current draft
                    // before closing, including an intentionally empty list.
                    saveChanges(setDialogState);
                    await _settleDialogFocus();
                    if (!dialogContext.mounted) return;
                    dialogClosed = true;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Done'),
                ),
                Builder(
                  builder: (context) {
                    final hasAnyPreparationText = controllers.any(
                      (controller) => controller.text.trim().isNotEmpty,
                    );
                    return FilledButton.icon(
                      onPressed: hasAnyPreparationText
                          ? () => saveChanges(setDialogState)
                          : null,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      disposeAllControllers();
    });

    if (mounted) setState(() {});
  }


Future<void> _deletePreparationItem(PreparationItem item) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(
        context,
        'delete',
        featureLabel: 'preparation',
        feature: LocalPermissionFeature.preparation,
        requestEdit: true,
      );
      return;
    }
    final homework = _homeworkForPreparationItem(item);
    if (homework != null) {
      await _deleteHomeworkFromPreparation(homework);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this preparation?'),
        content: Text('Remove “${item.title}” from this preparation list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD94B4B),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final date = _dayOnly(item.preparationDate);
    final key = Bag2SchoolStore.preparationOccurrenceKey(
      date,
      item.activityId,
    );

    setState(() {
      final override = Bag2SchoolStore.preparationOccurrenceOverrides[key];

      if (override != null) {
        final updated = override.where((p) => p.id != item.id).toList();
        Bag2SchoolStore.preparationOccurrenceOverrides[key] = updated;
      } else {
        Bag2SchoolStore.preparations.removeWhere(
          (p) => p.id == item.id,
        );
        Bag2SchoolStore.preparationOccurrenceHidden.add(
          '${date.toIso8601String()}|${item.id}',
        );
      }

      Bag2SchoolStore.preparationOccurrenceCompletion.remove(
        '${date.toIso8601String()}|${item.id}',
      );
    });

    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.preparation,
      action: 'Deleted',
      title: 'Preparation deleted',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
          'deleted a preparation item for ${Bag2SchoolStore.activeChild.name}.',
      childId: Bag2SchoolStore.activeChildId,
      entityId: item.id,
    );
  }

Future<void> _deleteHomeworkFromPreparation(HomeworkItem homework) async {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(context, 'delete', featureLabel: 'preparation');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this homework?'),
        content: Text('This will also remove “${homework.task}” from the Homework page and its calendar dot.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD94B4B)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Homework'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      Bag2SchoolStore.homeworks.removeWhere((h) => h.id == homework.id);
      final prepId = 'prep-${homework.id}';
      Bag2SchoolStore.preparations.removeWhere((p) => p.id == prepId);
      for (final entry in Bag2SchoolStore.preparationOccurrenceOverrides.entries.toList()) {
        Bag2SchoolStore.preparationOccurrenceOverrides[entry.key] = entry.value.where((p) => p.id != prepId).toList();
      }
    });

    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.preparation,
      action: 'Deleted',
      title: 'Preparation homework removed',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
          'removed ${homework.task} from preparation for ${Bag2SchoolStore.activeChild.name}.',
      childId: Bag2SchoolStore.activeChildId,
      entityId: homework.id,
    );
  }

Future<void> _deletePreparationGroup(_PreparationGroup group) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Clear this preparation? 🧺',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove all preparation items for '
          '${group.activity?.title ?? 'this activity'} on ${_formatDate(group.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove all'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;

    final key = Bag2SchoolStore.preparationOccurrenceKey(
      group.date,
      group.activityId,
    );

    setState(() {
      // Empty override = intentionally empty occurrence. Tomorrow and
      // Upcoming keep their own template/override untouched.
      Bag2SchoolStore.preparationOccurrenceOverrides[key] =
          <PreparationItem>[];

      for (final item in group.items) {
        final occurrenceItemKey =
            '${_dayOnly(group.date).toIso8601String()}|${item.id}';
        Bag2SchoolStore.preparationOccurrenceHidden.add(occurrenceItemKey);
        Bag2SchoolStore.preparationOccurrenceCompletion
            .remove(occurrenceItemKey);
      }
    });
    Bag2SchoolStore.recordFamilyActivity(
      feature: LocalPermissionFeature.preparation,
      action: 'Deleted',
      title: 'Preparation cleared',
      message:
          '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} cleared preparation for ${_formatDate(group.date)}.',
      childId: Bag2SchoolStore.activeChildId,
      entityId: group.activityId,
    );

  }

  void _toggleItem(PreparationItem item, bool value) {
    if (!LocalAuthorization.canEditActive(LocalPermissionFeature.preparation)) {
      LocalAuthorization.showDenied(
        context,
        'change',
        featureLabel: 'preparation',
        feature: LocalPermissionFeature.preparation,
        requestEdit: true,
      );
      return;
    }
    final homework = _homeworkForPreparationItem(item);
    final activity = _activityFor(item);
    final activityTitle = activity?.title ?? 'Preparation';
    final date = _dayOnly(item.preparationDate);

    setState(() {
      if (homework != null) {
        final key = '${date.toIso8601String()}|${homework.id}';
        Bag2SchoolStore.homeworkPreparationCompletion[key] = value;
        Bag2SchoolStore.recordFamilyActivity(
          feature: LocalPermissionFeature.preparation,
          action: 'Edited',
          title: 'Preparation checklist updated',
          message:
              '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
              '${value ? 'checked' : 'unchecked'} ${homework.task} '
              'for $activityTitle.',
          childId: Bag2SchoolStore.activeChildId,
          entityId: homework.id,
        );
        return;
      }

      final activityId = item.activityId;
      final occurrenceKey = Bag2SchoolStore.preparationOccurrenceKey(
        date,
        activityId,
      );

      if (Bag2SchoolStore.preparationOccurrenceOverrides
          .containsKey(occurrenceKey)) {
        final overrideItems =
            Bag2SchoolStore.preparationOccurrenceOverrides[occurrenceKey]!;
        final index = overrideItems.indexWhere((entry) => entry.id == item.id);
        if (index >= 0) {
          overrideItems[index] = overrideItems[index].copyWith(
            completed: value,
          );
          Bag2SchoolStore.recordFamilyActivity(
            feature: LocalPermissionFeature.preparation,
            action: 'Edited',
            title: 'Preparation checklist updated',
            message:
                '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
                '${value ? 'checked' : 'unchecked'} a preparation item '
              'for $activityTitle.',
            childId: Bag2SchoolStore.activeChildId,
            entityId: item.id,
          );
        }
        return;
      }

      // For a recurring template, completion is occurrence-local.
      final activity = _activityFor(item);
      if (activity != null && activity.occursOn(date)) {
        Bag2SchoolStore.preparationOccurrenceCompletion[
          '${date.toIso8601String()}|${item.id}'
        ] = value;
        Bag2SchoolStore.recordFamilyActivity(
          feature: LocalPermissionFeature.preparation,
          action: 'Edited',
          title: 'Preparation checklist updated',
          message:
              '${Bag2SchoolStore.currentAccount?.displayName ?? 'A family member'} '
              '${value ? 'checked' : 'unchecked'} a preparation item '
              'for $activityTitle.',
          childId: Bag2SchoolStore.activeChildId,
          entityId: item.id,
        );
        return;
      }

      final index = Bag2SchoolStore.preparations.indexWhere(
        (entry) => entry.id == item.id,
      );
      if (index >= 0) {
        Bag2SchoolStore.preparations[index] =
            Bag2SchoolStore.preparations[index].copyWith(
          completed: value,
        );
      }
    });
  }

  void _showHistory() {
    final history = _historyGroups();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFCF8),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * .72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4DAD3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Preparation history',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF302722),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Past preparations stay here so nothing gets lost.',
                    style: TextStyle(
                      color: Color(0xFF756B65),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (history.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "No preparation history yet. We'll keep it here for you. 😊",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF756B65),
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 9),
                        itemBuilder: (_, index) {
                          final group = history[index];
                          return _buildPreparationCard(
                            group,
                            compact: true,
                            history: true,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  HomeworkItem? _homeworkForPreparationItem(PreparationItem item) {
    for (final homework in Bag2SchoolStore.homeworks) {
      if (item.id == 'prep-${homework.id}') return homework;
    }
    return null;
  }

  bool _isHomeworkPreparation(PreparationItem item) =>
      _homeworkForPreparationItem(item) != null;

  bool _hasEditablePreparations(_PreparationGroup group) =>
      group.items.any((item) => !_isHomeworkPreparation(item));

  Widget _buildPreparationCard(
    _PreparationGroup group, {
    bool compact = false,
    bool history = false,
  }) {
    final items = group.items;
    final progress = _progress(items);
    final color = _activityTint(group.activity);
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow = _dayOnly(group.date) == tomorrow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        compact ? 13 : 15,
        compact ? 12 : 15,
        compact ? 13 : 15,
        compact ? 12 : 15,
      ),
      decoration: BoxDecoration(
        color: compact
            ? Colors.white
            : isTomorrow
                ? const Color(0xFFF4F1FF)
                : const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(
          color: history
              ? const Color(0xFFE8DDD5)
              : isTomorrow
                  ? const Color(0xFFDCD3FF)
                  : const Color(0xFFFFD6BD),
          width: compact ? 1 : 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final key =
                  '${group.date.toIso8601String()}|${group.activityId}';
              setState(() {
                if (_expandedPreparationGroups.contains(key)) {
                  _expandedPreparationGroups.remove(key);
                } else {
                  _expandedPreparationGroups.add(key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 42 : 46,
                    height: compact ? 42 : 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _homeworkForPreparationId(group.activityId) != null
                          ? Icons.menu_book_outlined
                          : _activityIcon(group.activity),
                      color: color,
                      size: compact ? 21 : 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _preparationGroupTitle(group),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 15 : 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF302722),
                          ),
                        ),
                        if (_homeworkForGroup(group) != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E1FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HOMEWORK',
                              style: TextStyle(
                                fontSize: 9.5,
                                height: 1.0,
                                letterSpacing: .7,
                                color: Color(0xFF7661D8),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _homeworkForGroup(group)!.task,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              color: Color(0xFF302722),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Builder(
                          builder: (context) {
                            final homework = _homeworkForGroup(group);
                            return Text(
                              homework != null
                                  ? '${group.activity?.title ?? 'No specific activity'} · ${_formatDate(group.date)}'
                                  : '${_formatDate(group.date)}'
                                    '${group.activity == null ? '' : ' · ${_categoryLabel(group.activity)}'}'
                                    '${group.activity == null ? '' : ' · ${_formatTime(group.activity!.startTime)}'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF83766E),
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFEFE7E1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: compact ? 15 : 17,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _progressText(items),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF8B7E76),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  if (!history && _hasEditablePreparations(group))
                    _preparationActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit preparation',
                      onPressed: () => _editPreparationGroup(group),
                    ),
                  if (!history && _hasEditablePreparations(group))
                    const SizedBox(width: 3),
                  AnimatedRotation(
                    turns: _expandedPreparationGroups.contains('${group.date.toIso8601String()}|${group.activityId}') ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF81736B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expandedPreparationGroups.contains(
                '${group.date.toIso8601String()}|${group.activityId}',
              )
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(
                top: 13,
                left: 4,
                right: 4,
              ),
              child: Column(
                children: [
                  ...items.map(
                    (item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: PreparationChecklistItem(
                          title: item.title,
                          checked: _isOccurrenceChecked(item),
                          isHomework: _homeworkForPreparationItem(item) != null,
                          onChanged: (value) {
                            if (!history) {
                              _toggleItem(item, value);
                            }
                          },
                          onDelete: !history
                              ? () => _deletePreparationItem(item)
                              : null,
                        ),
                      );
                    },
                  ),
                  if (!history && items.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        items.first.reminderEnabled &&
                                items.first.reminderDate != null
                            ? 'Bagi reminder · ${_formatDate(items.first.reminderDate!)} '
                              '${items.first.reminderHour.toString().padLeft(2, '0')}:'
                              '${items.first.reminderMinute.toString().padLeft(2, '0')}'
                            : 'No reminder set',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B7E76),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preparationActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            icon,
            size: 17,
            color: danger
                ? const Color(0xFFCC6B62)
                : const Color(0xFF7A6B63),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(
    String title, {
    required IconData icon,
    Color color = const Color(0xFF6F625A),
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
        top: 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: .3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final groups = _groupsForTodayAndFuture();

    final todayGroups =
        groups.where((group) => group.date == today).toList();
    final tomorrowGroups =
        groups.where((group) => group.date == tomorrow).toList();
    final allUpcomingGroups = groups.where(
      (group) => group.date.isAfter(tomorrow),
    ).toList();
    final upcomingDates = allUpcomingGroups.map((g) => _dayOnly(g.date)).toSet().toList()..sort();

    // Keep the default Preparation page concise: show at most 10 upcoming
    // preparation tasks, ordered by occurrence date and then item order.
    // We keep whole groups when possible, but stop adding groups once the
    // visible task count reaches the limit. 'Show all upcoming' restores
    // the complete list.
    final upcomingGroups = <_PreparationGroup>[];
    if (_showAllUpcoming) {
      upcomingGroups.addAll(allUpcomingGroups);
    } else {
      var taskCount = 0;
      for (final group in allUpcomingGroups) {
        if (taskCount >= 10) break;
        upcomingGroups.add(group);
        taskCount += group.items.length;
      }
    }

    final todayItems = todayGroups.expand((group) => group.items).toList();
    final todayProgress = _progress(todayItems);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF8),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Preparation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF302722),
          ),
        ),
        actions: [
          if (LocalAuthorization.canView(
            LocalPermissionFeature.preparation,
            childId: Bag2SchoolStore.activeChildId,
          ))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showHistory,
                icon: const Icon(
                  Icons.history_rounded,
                  size: 19,
                ),
                label: const Text(
                  'History',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6E625A),
                ),
              ),
            ),
        ],
      ),
      body: LocalAuthorization.authorizedView(
        context: context,
        feature: LocalPermissionFeature.preparation,
        title: 'Preparation',
        featureLabel: 'Preparation',
        childId: Bag2SchoolStore.activeChildId,
        child:  SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(width: 72, height: 72, child: const BagiCharacter()),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0EDFF),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  border: Border.all(color: const Color(0xFFE0D9FF)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x10000000),
                                      blurRadius: 9,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  child: Text(
                                    _bagiMessage,
                                    key: ValueKey(_bagiMessage),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.42,
                                      color: Color(0xFF4D445B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -8,
                                bottom: 13,
                                child: CustomPaint(
                                  size: const Size(10, 16),
                                  painter: _PreparationBubbleTailPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // TODAY HERO / SPOTLIGHT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFE7D2),
                          Color(0xFFFFF4E9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFFFFC89E),
                        width: 1.4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A21),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '☀️ TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              todayItems.isEmpty
                                  ? 'All clear'
                                  : '${_done(todayItems)} of ${todayItems.length} ready',
                              style: const TextStyle(
                                color: Color(0xFF7A675B),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                todayItems.isEmpty
                                    ? "You're all set for today! 🎉"
                                    : '${(todayProgress * 100).round()}% ready for today',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4C3529),
                                ),
                              ),
                            ),
                            if (todayItems.isNotEmpty)
                              Text(
                                '${(todayProgress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF6F1E),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: todayProgress,
                            minHeight: 8,
                            backgroundColor: Colors.white,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF7A21),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (todayGroups.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(
                              bottom: 4,
                            ),
                            child: Text(
                              "Nothing needs preparing today. Bagi's got you. 😊",
                              style: TextStyle(
                                color: Color(0xFF715F55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...todayGroups.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _buildPreparationCard(group),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  if (tomorrowGroups.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFECE7FF),
                            Color(0xFFF7F4FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFD2C8F6),
                          width: 1.4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7661D8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '🌤 TOMORROW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${tomorrowGroups.length} '
                                '${tomorrowGroups.length == 1 ? 'plan' : 'plans'}',
                                style: const TextStyle(
                                  color: Color(0xFF665A80),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          const Padding(
                            padding: EdgeInsets.only(left: 2, bottom: 7),
                            child: Text(
                              'A little head start for tomorrow ✨',
                              style: TextStyle(
                                color: Color(0xFF655A78),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ...tomorrowGroups.map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _buildPreparationCard(
                                group,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (upcomingGroups.isNotEmpty) ...[
                    _sectionLabel(
                      'COMING UP',
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFF81736B),
                    ),
                    ...upcomingGroups.map(
                      (group) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _buildPreparationCard(
                          group,
                          compact: true,
                        ),
                      ),
                    ),
                    if (allUpcomingGroups.fold<int>(0, (sum, group) => sum + group.items.length) > 10)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showAllUpcoming = !_showAllUpcoming),
                          icon: Icon(_showAllUpcoming ? Icons.keyboard_arrow_up_rounded : Icons.expand_more_rounded),
                          label: Text(_showAllUpcoming ? 'Show less' : 'Show all upcoming'),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF7661D8), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],

                  if (todayGroups.isEmpty &&
                      tomorrowGroups.isEmpty &&
                      upcomingGroups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE9DED6),
                        ),
                      ),
                      child: const Text(
                        "No upcoming preparations yet. When an activity needs a little planning, "
                        "I'll bring it here. 😊",
                        style: TextStyle(
                          color: Color(0xFF756B65),
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          ],
        ),
      ),
      ),

      
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        indicatorColor: const Color(0xFFFFE2CF),
        onDestinationSelected: (index) {
          if (index == 2) return;

          if (index == 0) {
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
            return;
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SchedulePage(),
              ),
            );
            return;
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeworkPage(),
              ),
            );
            return;
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
            return;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Preparation',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _PreparationBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0EDFF)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreparationGroup {
  final DateTime date;
  final String activityId;
  final BagActivity? activity;
  final List<PreparationItem> items = <PreparationItem>[];
  bool expanded = false;

  _PreparationGroup({
    required this.date,
    required this.activityId,
    required this.activity,
  });
}

// ============================================================
// PREPARATION CHECKLIST
// ============================================================

class PreparationChecklistItem extends StatefulWidget {
  final String title;
  final bool checked;
  final bool isHomework;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onDelete;

  const PreparationChecklistItem({
    super.key,
    required this.title,
    required this.checked,
    this.isHomework = false,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<PreparationChecklistItem> createState() =>
      _PreparationChecklistItemState();
}

class _PreparationChecklistItemState
    extends State<PreparationChecklistItem> {
  bool _expanded = false;

  IconData _itemIcon() {
    final value = widget.title.toLowerCase();
    if (value.contains('bottle') ||
        value.contains('drink') ||
        value.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (value.contains('book') ||
        value.contains('text') ||
        value.contains('lesson')) {
      return Icons.menu_book_rounded;
    }
    if (value.contains('lunch') || value.contains('food')) {
      return Icons.lunch_dining_rounded;
    }
    if (value.contains('uniform') ||
        value.contains('jersey') ||
        value.contains('shirt')) {
      return Icons.checkroom_rounded;
    }
    return Icons.backpack_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _itemIcon();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        decoration: BoxDecoration(
          color: widget.isHomework
              ? const Color(0xFFF4F0FF)
              : widget.checked
                  ? const Color(0xFFF1FAF3)
                  : const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isHomework
                ? const Color(0xFFD8CDFB)
                : widget.checked
                    ? const Color(0xFFA9D6B8)
                    : const Color(0xFFEED8CA),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 9,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => widget.onChanged(!widget.checked),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: widget.checked
                    ? const Icon(
                        Icons.check_circle_rounded,
                        size: 28,
                        color: Color(0xFF55A56B),
                      )
                    : const Icon(
                        Icons.radio_button_unchecked_rounded,
                        size: 25,
                        color: Color(0xFFD9C7BB),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.checked
                    ? const Color(0xFFDDF1E3)
                    : widget.isHomework
                        ? const Color(0xFFE5DEFF)
                        : const Color(0xFFFFE6D6),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 22,
                color: widget.checked
                    ? const Color(0xFF55A56B)
                    : widget.isHomework
                        ? const Color(0xFF7661D8)
                        : const Color(0xFFFF7A21),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: widget.isHomework
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: const Color(0xFF302722),
                          decoration: widget.checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (widget.title.trim().length > 70)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            _expanded
                                ? 'Tap to collapse'
                                : 'Tap to see full text',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF8B7E76),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.onDelete != null)
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 4),
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Color(0xFFB06F65),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BagiTip extends StatelessWidget {
  const BagiTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF4E8),

        borderRadius:
            BorderRadius.circular(24),

        border: Border.all(
          color:
              const Color(0xFFFFD8B8),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            '🎒',
            style: TextStyle(
              fontSize: 30,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Bagi's Tip",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFFFF6B1A),
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  "Put Kenneth's basketball shoes "
                  "near the door tonight so you "
                  "won't forget them tomorrow morning. 👟",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color:
                        Color(0xFF625851),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ============================================================
// SCHOOL ACTIVITY FORM
// ============================================================


class _BagiConflictCard extends StatelessWidget {
  final ActivityConflict conflict;
  final VoidCallback onKeepBoth;
  final VoidCallback onAdjust;

  const _BagiConflictCard({
    required this.conflict,
    required this.onKeepBoth,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFFFD7BF),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: const BagiCharacter(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(19),
                      bottomLeft: Radius.circular(19),
                      bottomRight: Radius.circular(19),
                    ),
                    border: Border.all(
                      color: const Color(0xFFE0D9FF),
                    ),
                  ),
                  child: const Text(
                    "Hey Mom! I think these two are meeting at the same time. "
                    "No worries 😊 Want to keep both, or shall we find a "
                    "better spot for the new one?",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D445B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF6),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  color: Color(0xFFFF7A21),
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    conflict.existingActivity.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE0A52D),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAdjust,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A21),
                    side: const BorderSide(
                      color: Color(0xFFFFC8A5),
                    ),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Let me adjust',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onKeepBoth,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A21),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Keep both',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SchoolActivityForm extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<BagActivity> onSaved;

  const SchoolActivityForm({
    super.key,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<SchoolActivityForm> createState() => _SchoolActivityFormState();
}

class _SchoolActivityFormState extends State<SchoolActivityForm> {
  final TextEditingController _titleController =
      TextEditingController(text: 'School');

  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);

  RecurrenceType _recurrenceType = RecurrenceType.weekdays;
  final Set<int> _selectedWeekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7A21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTime({
    required bool start,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'One time';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon–Fri)';
      case RecurrenceType.weekly:
        return 'Every week';
      case RecurrenceType.biweekly:
        return 'Every 2 weeks';
      case RecurrenceType.custom:
        return 'Custom days';
      default:
        return 'Every week';
    }
  }

  ActivityRecurrence _buildRecurrence() {
    switch (_recurrenceType) {
      case RecurrenceType.weekdays:
        return const ActivityRecurrence(
          type: RecurrenceType.weekdays,
        );

      case RecurrenceType.weekly:
        return const ActivityRecurrence(
          type: RecurrenceType.weekly,
        );

      case RecurrenceType.biweekly:
        return const ActivityRecurrence(
          type: RecurrenceType.biweekly,
        );

      case RecurrenceType.custom:
        return ActivityRecurrence(
          type: RecurrenceType.custom,
          weekdays: _selectedWeekdays.toList()..sort(),
        );

      case RecurrenceType.none:
        return const ActivityRecurrence(
          type: RecurrenceType.none,
        );

      default:
        return const ActivityRecurrence(
          type: RecurrenceType.weekly,
        );
    }
  }

  bool _hasTimeError() {
    return _endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute;
  }

  BagActivity _buildActivity() {
    return BagActivity(
      id: 'school-${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty
          ? 'School'
          : _titleController.text.trim(),
      type: ActivityType.school,
      startDate: _startDate,
      startTime: TimeOfDayData(
        hour: _startTime.hour,
        minute: _startTime.minute,
      ),
      endTime: TimeOfDayData(
        hour: _endTime.hour,
        minute: _endTime.minute,
      ),
      recurrence: _buildRecurrence(),
      isRoutine: true,
      showIndicator: false,
      indicatorType: ActivityIndicatorType.none,
    );
  }

  void _save() {
    if (_saving) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Give this class a name first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_hasTimeError()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time should be later than start time.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_recurrenceType == RecurrenceType.custom &&
        _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one day.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final candidate = _buildActivity();

    final conflicts = const ActivityConflictDetector().findConflicts(
      candidate: candidate,
      existingActivities: Bag2SchoolStore.activities,
    );

    if (conflicts.isNotEmpty) {
      _showConflictWarning(candidate, conflicts.first);
      return;
    }

    _finishSave(candidate);
  }

  void _showConflictWarning(
    BagActivity candidate,
    ActivityConflict conflict,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Schedule conflict',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(curved),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: _BagiConflictCard(
                conflict: conflict,
                onKeepBoth: () {
                  Navigator.pop(context);
                  _finishSave(candidate);
                },
                onAdjust: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _finishSave(BagActivity activity) {
    setState(() => _saving = true);
    widget.onSaved(activity);
    Navigator.pop(context);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29231F),
        ),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD7BF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF756B65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29231F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _repeatOption(
    BuildContext dialogContext,
    RecurrenceType value,
    String label,
  ) {
    final selected = _recurrenceType == value;

    return InkWell(
      onTap: () => Navigator.pop(dialogContext, value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 3,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFE7D2)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF7A21)
                : const Color(0xFFE5DDD7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: const Color(0xFF29231F),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF7A21),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayChip(int weekday, String label) {
    final selected = _selectedWeekdays.contains(weekday);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
      selectedColor: const Color(0xFFFFDCC6),
      checkmarkColor: const Color(0xFFFF7A21),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected
            ? const Color(0xFFFF6B1A)
            : const Color(0xFF625851),
      ),
      side: const BorderSide(
        color: Color(0xFFE5DDD7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7D2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Color(0xFFFF7A21),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add school schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _sectionTitle('Activity name'),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _titleController.clear();
                      setState(() {});
                    },
                  ),
                hintText: 'School',
                filled: true,
                fillColor: const Color(0xFFFFFAF6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5DDD7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5DDD7),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Starts on'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5DDD7),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFFFF7A21),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_startDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB8ADA5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Time'),
            Row(
              children: [
                _timeCard(
                  label: 'Start',
                  time: _startTime,
                  onTap: () => _pickTime(start: true),
                ),
                const SizedBox(width: 10),
                _timeCard(
                  label: 'End',
                  time: _endTime,
                  onTap: () => _pickTime(start: false),
                ),
              ],
            ),

            const SizedBox(height: 18),
            _sectionTitle('Repeats'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final selected = await showDialog<RecurrenceType>(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.62),
                  builder: (dialogContext) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFFF7A21),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'How often?',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF29231F),
                                  ),
                                ),
                              ),
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekdays,
                              'Every weekday (Mon–Fri)',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekly,
                              'Every week',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.biweekly,
                              'Every 2 weeks',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.custom,
                              'Custom days',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.none,
                              'One time',
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (selected != null) {
                  setState(() => _recurrenceType = selected);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF7A21),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.repeat,
                      color: Color(0xFFFF7A21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _recurrenceLabel(_recurrenceType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF29231F),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8A7E76),
                    ),
                  ],
                ),
              ),
            ),

            if (_recurrenceType == RecurrenceType.custom) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _weekdayChip(DateTime.monday, 'Mon'),
                  _weekdayChip(DateTime.tuesday, 'Tue'),
                  _weekdayChip(DateTime.wednesday, 'Wed'),
                  _weekdayChip(DateTime.thursday, 'Thu'),
                  _weekdayChip(DateTime.friday, 'Fri'),
                  _weekdayChip(DateTime.saturday, 'Sat'),
                  _weekdayChip(DateTime.sunday, 'Sun'),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Text(
              'School is treated as a routine, so it will not create a calendar dot.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF756B65),
              ),
            ),

            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () async {
                      await _settleDialogFocus();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: const Color(0xFF756B65),
                      side: const BorderSide(color: Color(0xFFD9CCC4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      'Save School Schedule',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BAG2SCHOOL ACTIVITY STORE
// ============================================================

class LessonActivityForm extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<BagActivity> onSaved;

  const LessonActivityForm({
    super.key,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<LessonActivityForm> createState() => _LessonActivityFormState();
}

class _LessonActivityFormState extends State<LessonActivityForm> {
  final TextEditingController _titleController =
      TextEditingController(text: 'English Class');

  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 0);

  RecurrenceType _recurrenceType = RecurrenceType.weekly;
  final Set<int> _selectedWeekdays = {
    DateTime.monday,
  };

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7A21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTime({
    required bool start,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'One time';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon–Fri)';
      case RecurrenceType.weekly:
        return 'Every week';
      case RecurrenceType.biweekly:
        return 'Every 2 weeks';
      case RecurrenceType.custom:
        return 'Custom days';
      default:
        return 'Every week';
    }
  }

  ActivityRecurrence _buildRecurrence() {
    switch (_recurrenceType) {
      case RecurrenceType.weekdays:
        return const ActivityRecurrence(
          type: RecurrenceType.weekdays,
        );

      case RecurrenceType.weekly:
        return const ActivityRecurrence(
          type: RecurrenceType.weekly,
        );

      case RecurrenceType.biweekly:
        return const ActivityRecurrence(
          type: RecurrenceType.biweekly,
        );

      case RecurrenceType.custom:
        return ActivityRecurrence(
          type: RecurrenceType.custom,
          weekdays: _selectedWeekdays.toList()..sort(),
        );

      case RecurrenceType.none:
        return const ActivityRecurrence(
          type: RecurrenceType.none,
        );

      default:
        return const ActivityRecurrence(
          type: RecurrenceType.weekly,
        );
    }
  }

  bool _hasTimeError() {
    return _endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute;
  }

  BagActivity _buildActivity() {
    return BagActivity(
      id: 'lesson-${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty
          ? 'Lesson'
          : _titleController.text.trim(),
      type: ActivityType.lesson,
      startDate: _startDate,
      startTime: TimeOfDayData(
        hour: _startTime.hour,
        minute: _startTime.minute,
      ),
      endTime: TimeOfDayData(
        hour: _endTime.hour,
        minute: _endTime.minute,
      ),
      recurrence: _buildRecurrence(),
      isRoutine: false,
      showIndicator: true,
      // Class/Lesson uses the orange activity dot.
      indicatorType: ActivityIndicatorType.activity,
    );
  }

  void _save() {
    if (_saving) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Give this class a name first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_hasTimeError()) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.92, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 64,
                          height: 64,
                          child: BagiCharacter(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EDFF),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(19),
                                bottomLeft: Radius.circular(19),
                                bottomRight: Radius.circular(19),
                              ),
                            ),
                            child: const Text(
                              "Oops, Mom! I think the clock got a little mixed up. 😄 "
                              "The class needs to finish after it starts. "
                              "Let's pick a later end time together.",
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4D445B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A21),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Okay, let's fix it",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    if (_recurrenceType == RecurrenceType.custom &&
        _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one day.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final candidate = _buildActivity();

    final conflicts = const ActivityConflictDetector().findConflicts(
      candidate: candidate,
      existingActivities: Bag2SchoolStore.activities,
    );

    if (conflicts.isNotEmpty) {
      _showConflictWarning(candidate, conflicts.first);
      return;
    }

    _finishSave(candidate);
  }

  void _showConflictWarning(
    BagActivity candidate,
    ActivityConflict conflict,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Schedule conflict',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(curved),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: _BagiConflictCard(
                conflict: conflict,
                onKeepBoth: () {
                  Navigator.pop(context);
                  _finishSave(candidate);
                },
                onAdjust: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _finishSave(BagActivity activity) {
    setState(() => _saving = true);
    widget.onSaved(activity);
    Navigator.pop(context);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29231F),
        ),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD7BF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF756B65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29231F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _repeatOption(
    BuildContext dialogContext,
    RecurrenceType value,
    String label,
  ) {
    final selected = _recurrenceType == value;

    return InkWell(
      onTap: () => Navigator.pop(dialogContext, value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 3,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFE7D2)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF7A21)
                : const Color(0xFFE5DDD7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: const Color(0xFF29231F),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF7A21),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayChip(int weekday, String label) {
    final selected = _selectedWeekdays.contains(weekday);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
      selectedColor: const Color(0xFFFFDCC6),
      checkmarkColor: const Color(0xFFFF7A21),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected
            ? const Color(0xFFFF6B1A)
            : const Color(0xFF625851),
      ),
      side: const BorderSide(
        color: Color(0xFFE5DDD7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7D2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Color(0xFFFF7A21),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add school schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _sectionTitle('Activity name'),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _titleController.clear();
                      setState(() {});
                    },
                  ),
                hintText: 'Lesson',
                filled: true,
                fillColor: const Color(0xFFFFFAF6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5DDD7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5DDD7),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Starts on'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5DDD7),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFFFF7A21),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_startDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB8ADA5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Time'),
            Row(
              children: [
                _timeCard(
                  label: 'Start',
                  time: _startTime,
                  onTap: () => _pickTime(start: true),
                ),
                const SizedBox(width: 10),
                _timeCard(
                  label: 'End',
                  time: _endTime,
                  onTap: () => _pickTime(start: false),
                ),
              ],
            ),

            const SizedBox(height: 18),
            _sectionTitle('Repeats'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final selected = await showDialog<RecurrenceType>(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.62),
                  builder: (dialogContext) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFFF7A21),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'How often?',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF29231F),
                                  ),
                                ),
                              ),
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekdays,
                              'Every weekday (Mon–Fri)',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekly,
                              'Every week',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.biweekly,
                              'Every 2 weeks',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.custom,
                              'Custom days',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.none,
                              'One time',
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (selected != null) {
                  setState(() => _recurrenceType = selected);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF7A21),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.repeat,
                      color: Color(0xFFFF7A21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _recurrenceLabel(_recurrenceType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF29231F),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8A7E76),
                    ),
                  ],
                ),
              ),
            ),

            if (_recurrenceType == RecurrenceType.custom) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _weekdayChip(DateTime.monday, 'Mon'),
                  _weekdayChip(DateTime.tuesday, 'Tue'),
                  _weekdayChip(DateTime.wednesday, 'Wed'),
                  _weekdayChip(DateTime.thursday, 'Thu'),
                  _weekdayChip(DateTime.friday, 'Fri'),
                  _weekdayChip(DateTime.saturday, 'Sat'),
                  _weekdayChip(DateTime.sunday, 'Sun'),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Text(
              'Lesson will appear as an activity dot on the calendar.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF756B65),
              ),
            ),

            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () async {
                      await _settleDialogFocus();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: const Color(0xFF756B65),
                      side: const BorderSide(color: Color(0xFFD9CCC4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      'Save Lesson Schedule',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BAG2SCHOOL ACTIVITY STORE
// ============================================================



class _PreparationOfferCard extends StatefulWidget {
  final BagActivity activity;
  final DateTime preparationDate;
  final VoidCallback onNotNow;
  final void Function(
    List<String> items,
    bool reminderEnabled,
    DateTime reminderDate,
    int reminderHour,
    int reminderMinute,
  ) onAdd;

  const _PreparationOfferCard({
    required this.activity,
    required this.preparationDate,
    required this.onNotNow,
    required this.onAdd,
  });

  @override
  State<_PreparationOfferCard> createState() => _PreparationOfferCardState();
}

class _PreparationOfferCardState extends State<_PreparationOfferCard> {
  final TextEditingController _customController = TextEditingController();
  final Set<String> _selectedItems = <String>{};
  bool _reminderEnabled = true;
  late DateTime _reminderDate;
  int _reminderHour = 18;
  int _reminderMinute = 0;

  List<String> get _suggestedItems {
    switch (widget.activity.type) {
      case ActivityType.school:
        return const [
          'School uniform',
          'Books',
          'Water bottle',
          'Lunch box',
        ];
      case ActivityType.lesson:
        return const [
          'Books / workbook',
          'Stationery',
          'Water bottle',
        ];
      case ActivityType.extracurricular:
        return const [
          'Equipment / gear',
          'Water bottle',
          'Towel',
          'Extra clothes',
        ];
      case ActivityType.exam:
        return const [
          'Study materials',
          'Stationery',
          'Calculator / exam tools',
        ];
      case ActivityType.event:
        return const [
          'Event items',
          'Uniform / outfit',
          'Water bottle',
        ];
      default:
        return const [
          'Bag',
          'Water bottle',
          'Something important',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _reminderDate = DateTime(
      widget.preparationDate.year,
      widget.preparationDate.month,
      widget.preparationDate.day,
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _formatTime() {
    final h = _reminderHour.toString().padLeft(2, '0');
    final m = _reminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }

  void _addCustomItem() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      _selectedItems.add(value);
      _customController.clear();
    });
  }

  void _toggleItem(String item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _pickReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime(
        widget.preparationDate.year,
        widget.preparationDate.month,
        widget.preparationDate.day,
      ).subtract(const Duration(days: 30)),
      lastDate: DateTime(
        widget.activity.startDate.year,
        widget.activity.startDate.month,
        widget.activity.startDate.day,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFF7A21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _reminderDate = picked);
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderHour,
        minute: _reminderMinute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFF7A21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 68,
                    height: 68,
                    child: BagiCharacter(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(7),
                          topRight: Radius.circular(21),
                          bottomLeft: Radius.circular(21),
                          bottomRight: Radius.circular(21),
                        ),
                      ),
                      child: Text(
                        _messageFor(widget.activity),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.42,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4D4038),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What should we get ready?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedItems.map((item) {
                  final selected = _selectedItems.contains(item);
                  return FilterChip(
                    selected: selected,
                    label: Text(item),
                    onSelected: (_) => _toggleItem(item),
                    selectedColor: const Color(0xFFFFE1CC),
                    checkmarkColor: const Color(0xFFFF7A21),
                    labelStyle: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF514640),
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFFF7A21)
                          : const Color(0xFFE4DDD7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              if (_selectedItems.any((item) => !_suggestedItems.contains(item))) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _selectedItems
                        .where((item) => !_suggestedItems.contains(item))
                        .map((item) {
                      return InputChip(
                        label: Text(item),
                        selected: true,
                        onDeleted: () => _toggleItem(item),
                        deleteIconColor: const Color(0xFFFF7A21),
                        backgroundColor: const Color(0xFFFFF0E3),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF514640),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                          side: const BorderSide(
                            color: Color(0xFFFFC49D),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCustomItem(),
                      decoration: InputDecoration(
                        labelText: 'Anything else?',
                        hintText: 'Type your own item',
                        filled: true,
                        fillColor: const Color(0xFFFFFAF6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5DDD7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5DDD7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: FilledButton(
                      onPressed: _addCustomItem,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE1CC),
                        foregroundColor: const Color(0xFFFF7A21),
                        minimumSize: const Size(52, 48),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF58A879),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Prepare on ${_formatDate(widget.preparationDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF45634F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: _reminderEnabled,
                  onChanged: (value) {
                    setState(() => _reminderEnabled = value);
                  },
                  activeColor: const Color(0xFFFF7A21),
                  title: const Text(
                    'Remind me',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _reminderEnabled
                        ? 'Bagi will remind you at ${_formatTime()}'
                        : 'No reminder for this preparation',
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              if (_reminderEnabled) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickReminderDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text(_formatShortDate(_reminderDate)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF7A21),
                          side: const BorderSide(
                            color: Color(0xFFFFC49D),
                          ),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickReminderTime,
                        icon: const Icon(
                          Icons.schedule_outlined,
                          size: 18,
                        ),
                        label: Text(_formatTime()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF7A21),
                          side: const BorderSide(
                            color: Color(0xFFFFC49D),
                          ),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onNotNow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF756B65),
                        side: const BorderSide(
                          color: Color(0xFFE5DDD7),
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Maybe later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final items = <String>[..._selectedItems];
                        final custom = _customController.text.trim();
                        if (custom.isNotEmpty) {
                          items.add(custom);
                        }
                        if (items.isEmpty) return;
                        widget.onAdd(
                          items,
                          _reminderEnabled,
                          _reminderDate,
                          _reminderHour,
                          _reminderMinute,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A21),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save preparation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _messageFor(BagActivity activity) {
    switch (activity.type) {
      case ActivityType.school:
        return "Yay, school is sorted, Mom! 🏫✨ "
            "Want to pick a few little things to get ready? "
            "I'll keep them together for you.";
      case ActivityType.lesson:
        return "Nice, ${activity.title} is sorted! 📚😊 "
            "Let's make the next class feel easy. "
            "Pick what Kenneth should have ready.";
      case ActivityType.extracurricular:
        return "Woohoo, ${activity.title} is on the schedule! 🎉 "
            "Let's get the little things ready now, "
            "so future-you can relax. 😄";
      case ActivityType.exam:
        return "You've got an Exam coming up! 📝 "
            "Let's prepare the study materials and exam tools together.";
      case ActivityType.event:
        return "Ooh, ${activity.title} is coming up! ✨ "
            "Let's choose what we need beforehand and make it easy.";
      default:
        return "All set, Mom! 🎒✨ "
            "Let's pick a few things to get ready.";
    }
  }
}


class ExamActivityForm extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<BagActivity> onSaved;

  const ExamActivityForm({
    super.key,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<ExamActivityForm> createState() => _ExamActivityFormState();
}

class _ExamActivityFormState extends State<ExamActivityForm> {
  final TextEditingController _titleController = TextEditingController();

  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _invalidTime {
    return _endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Give the event a name first — then we'll get it on the calendar. 😊",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_invalidTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Let's make the end time a little later than the start time. 😊",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSaved(
      BagActivity(
        id: 'exam-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        type: ActivityType.exam,
        startDate: _date,
        startTime: TimeOfDayData(
          hour: _startTime.hour,
          minute: _startTime.minute,
        ),
        endTime: TimeOfDayData(
          hour: _endTime.hour,
          minute: _endTime.minute,
        ),
        recurrence: const ActivityRecurrence(
          type: RecurrenceType.none,
        ),
        isRoutine: false,
        showIndicator: true,
        indicatorType: ActivityIndicatorType.exam,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Exam',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29231F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Exam, test, or school assessment. Repetition is not needed for an exam.",
              style: TextStyle(
                color: Color(0xFF756B65),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _titleController.clear();
                      setState(() {});
                    },
                  ),
                labelText: 'Exam name',
                hintText: 'e.g. Math Mid Test',
                prefixIcon: const Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text(
                      'Start\n${_formatTime(_startTime)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text(
                      'End\n${_formatTime(_endTime)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _settleDialogFocus();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: const Color(0xFF756B65),
                      side: const BorderSide(color: Color(0xFFD9CCC4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Add to schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class EventActivityForm extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<BagActivity> onSaved;

  const EventActivityForm({
    super.key,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<EventActivityForm> createState() => _EventActivityFormState();
}

class _EventActivityFormState extends State<EventActivityForm> {
  final TextEditingController _titleController = TextEditingController();

  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _invalidTime {
    return _endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Give the event a name first — then we'll get it on the calendar. 😊",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_invalidTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Let's make the end time a little later than the start time. 😊",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSaved(
      BagActivity(
        id: 'event-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        type: ActivityType.event,
        startDate: _date,
        startTime: TimeOfDayData(
          hour: _startTime.hour,
          minute: _startTime.minute,
        ),
        endTime: TimeOfDayData(
          hour: _endTime.hour,
          minute: _endTime.minute,
        ),
        recurrence: const ActivityRecurrence(
          type: RecurrenceType.none,
        ),
        isRoutine: false,
        showIndicator: true,
        indicatorType: ActivityIndicatorType.event,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Event',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29231F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Field trips, parent meetings, report cards, graduation, and other special days.",
              style: TextStyle(
                color: Color(0xFF756B65),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _titleController.clear();
                      setState(() {});
                    },
                  ),
                labelText: 'Event name',
                hintText: 'e.g. Parent Meeting',
                prefixIcon: const Icon(Icons.event_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text(
                      'Start\n${_formatTime(_startTime)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text(
                      'End\n${_formatTime(_endTime)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _settleDialogFocus();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: const Color(0xFF756B65),
                      side: const BorderSide(color: Color(0xFFD9CCC4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Add to schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExtracurricularActivityForm extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<BagActivity> onSaved;

  const ExtracurricularActivityForm({
    super.key,
    required this.initialDate,
    required this.onSaved,
  });

  @override
  State<ExtracurricularActivityForm> createState() =>
      _ExtracurricularActivityFormState();
}

class _ExtracurricularActivityFormState
    extends State<ExtracurricularActivityForm> {
  final TextEditingController _titleController =
      TextEditingController(text: 'Basketball');

  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 30);

  RecurrenceType _recurrenceType = RecurrenceType.weekly;
  final Set<int> _selectedWeekdays = {
    DateTime.wednesday,
  };

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF7A21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (start) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'One time';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon–Fri)';
      case RecurrenceType.weekly:
        return 'Every week';
      case RecurrenceType.biweekly:
        return 'Every 2 weeks';
      case RecurrenceType.custom:
        return 'Custom days';
      default:
        return 'Every week';
    }
  }

  ActivityRecurrence _buildRecurrence() {
    switch (_recurrenceType) {
      case RecurrenceType.weekdays:
        return const ActivityRecurrence(
          type: RecurrenceType.weekdays,
        );
      case RecurrenceType.weekly:
        return const ActivityRecurrence(
          type: RecurrenceType.weekly,
        );
      case RecurrenceType.biweekly:
        return const ActivityRecurrence(
          type: RecurrenceType.biweekly,
        );
      case RecurrenceType.custom:
        return ActivityRecurrence(
          type: RecurrenceType.custom,
          weekdays: _selectedWeekdays.toList()..sort(),
        );
      case RecurrenceType.none:
        return const ActivityRecurrence(
          type: RecurrenceType.none,
        );
      default:
        return const ActivityRecurrence(
          type: RecurrenceType.weekly,
        );
    }
  }

  bool _hasTimeError() {
    return _endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute;
  }

  BagActivity _buildActivity() {
    return BagActivity(
      id: 'extracurricular-${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim().isEmpty
          ? 'Extracurricular'
          : _titleController.text.trim(),
      type: ActivityType.extracurricular,
      startDate: _startDate,
      startTime: TimeOfDayData(
        hour: _startTime.hour,
        minute: _startTime.minute,
      ),
      endTime: TimeOfDayData(
        hour: _endTime.hour,
        minute: _endTime.minute,
      ),
      recurrence: _buildRecurrence(),
      isRoutine: false,
      showIndicator: true,
      indicatorType: ActivityIndicatorType.activity,
    );
  }

  void _save() {
    if (_saving) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Give this activity a name first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_hasTimeError()) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.92, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 64,
                          height: 64,
                          child: BagiCharacter(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              15, 12, 15, 12,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0EDFF),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(19),
                                bottomLeft: Radius.circular(19),
                                bottomRight: Radius.circular(19),
                              ),
                            ),
                            child: const Text(
                              "Oops, Mom! 😄 I think the timing got a little "
                              "mixed up. Let's make sure the activity finishes "
                              "after it starts.",
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4D445B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A21),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Okay, let's fix it",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    if (_recurrenceType == RecurrenceType.custom &&
        _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one day.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final candidate = _buildActivity();

    final conflicts = const ActivityConflictDetector().findConflicts(
      candidate: candidate,
      existingActivities: Bag2SchoolStore.activities,
    );

    if (conflicts.isNotEmpty) {
      _showConflictWarning(candidate, conflicts.first);
      return;
    }

    _finishSave(candidate);
  }

  void _showConflictWarning(
    BagActivity candidate,
    ActivityConflict conflict,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Schedule conflict',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(curved),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: _BagiConflictCard(
                conflict: conflict,
                onKeepBoth: () {
                  Navigator.pop(context);
                  _finishSave(candidate);
                },
                onAdjust: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _finishSave(BagActivity activity) {
    setState(() => _saving = true);
    widget.onSaved(activity);
    Navigator.pop(context);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF29231F),
        ),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD7BF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF756B65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29231F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _repeatOption(
    BuildContext dialogContext,
    RecurrenceType value,
    String label,
  ) {
    final selected = _recurrenceType == value;

    return InkWell(
      onTap: () => Navigator.pop(dialogContext, value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 3,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFE7D2)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF7A21)
                : const Color(0xFFE5DDD7),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: const Color(0xFF29231F),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF7A21),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayChip(int weekday, String label) {
    final selected = _selectedWeekdays.contains(weekday);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
      selectedColor: const Color(0xFFFFDCC6),
      checkmarkColor: const Color(0xFFFF7A21),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected
            ? const Color(0xFFFF6B1A)
            : const Color(0xFF625851),
      ),
      side: const BorderSide(
        color: Color(0xFFE5DDD7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7D2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sports_basketball_outlined,
                    color: Color(0xFFFF7A21),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add extracurricular',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _sectionTitle('Activity name'),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                  suffixIcon: IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _titleController.clear();
                      setState(() {});
                    },
                  ),
                hintText: 'Basketball',
                filled: true,
                fillColor: const Color(0xFFFFFAF6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5DDD7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5DDD7),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Starts on'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5DDD7),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFFFF7A21),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_startDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFB8ADA5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            _sectionTitle('Time'),
            Row(
              children: [
                _timeCard(
                  label: 'Start',
                  time: _startTime,
                  onTap: () => _pickTime(start: true),
                ),
                const SizedBox(width: 10),
                _timeCard(
                  label: 'End',
                  time: _endTime,
                  onTap: () => _pickTime(start: false),
                ),
              ],
            ),

            const SizedBox(height: 18),
            _sectionTitle('Repeats'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final selected = await showDialog<RecurrenceType>(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.62),
                  builder: (dialogContext) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFFF7A21),
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(
                                20, 18, 20, 8,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'How often?',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF29231F),
                                  ),
                                ),
                              ),
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekdays,
                              'Every weekday (Mon–Fri)',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.weekly,
                              'Every week',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.biweekly,
                              'Every 2 weeks',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.custom,
                              'Custom days',
                            ),
                            _repeatOption(
                              dialogContext,
                              RecurrenceType.none,
                              'One time',
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );

                if (selected != null) {
                  setState(() => _recurrenceType = selected);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAF6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF7A21),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.repeat,
                      color: Color(0xFFFF7A21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _recurrenceLabel(_recurrenceType),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF29231F),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8A7E76),
                    ),
                  ],
                ),
              ),
            ),

            if (_recurrenceType == RecurrenceType.custom) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _weekdayChip(DateTime.monday, 'Mon'),
                  _weekdayChip(DateTime.tuesday, 'Tue'),
                  _weekdayChip(DateTime.wednesday, 'Wed'),
                  _weekdayChip(DateTime.thursday, 'Thu'),
                  _weekdayChip(DateTime.friday, 'Fri'),
                  _weekdayChip(DateTime.saturday, 'Sat'),
                  _weekdayChip(DateTime.sunday, 'Sun'),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Text(
              'This will appear as an extracurricular activity on the schedule.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF756B65),
              ),
            ),

            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () async {
                      await _settleDialogFocus();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: const Color(0xFF756B65),
                      side: const BorderSide(color: Color(0xFFD9CCC4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A21),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      'Save Extracurricular',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// Let Flutter finish keyboard/focus cleanup before a dialog is
/// removed from the tree. This avoids the InheritedElement
/// `_dependents.isEmpty` assertion when a TextField is focused.
Future<void> _settleDialogFocus() async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(const Duration(milliseconds: 120));
}

enum LocalPermissionFeature {
  schedule,
  homework,
  preparation,
  exam,
}

class LocalAuthorization {
  static FamilyMember? _currentMember() =>
      Bag2SchoolStore.familyMemberForCurrentAccount();

  static FamilyAccessGrant? _grantFor(
    String childId,
  ) {
    final member = _currentMember();
    if (member == null) return null;
    return Bag2SchoolStore.accessGrantFor(childId, member.id);
  }

  static bool _isOwner() =>
      _currentMember()?.role == FamilyMemberRole.owner;

  static bool canView(
    LocalPermissionFeature feature, {
    String? childId,
  }) {
    if (!Bag2SchoolStore.isSignedIn) return false;
    if (_isOwner()) return true;

    final id = childId ?? Bag2SchoolStore.activeChildId;
    final grant = _grantFor(id);
    if (grant == null) return false;

    switch (feature) {
      case LocalPermissionFeature.schedule:
        return grant.viewSchedule;
      case LocalPermissionFeature.homework:
        return grant.viewHomework;
      case LocalPermissionFeature.preparation:
        return grant.viewPreparation;
      case LocalPermissionFeature.exam:
        return grant.viewExam;
    }
  }

  static bool canEdit(
    LocalPermissionFeature feature, {
    String? childId,
  }) {
    if (!Bag2SchoolStore.isSignedIn) return false;
    if (_isOwner()) return true;

    final id = childId ?? Bag2SchoolStore.activeChildId;
    final grant = _grantFor(id);
    if (grant == null) return false;

    switch (feature) {
      case LocalPermissionFeature.schedule:
        return grant.editSchedule;
      case LocalPermissionFeature.homework:
        return grant.editHomework;
      case LocalPermissionFeature.preparation:
        return grant.editPreparation;
      case LocalPermissionFeature.exam:
        return grant.editExam;
    }
  }

  static bool canEditActive(LocalPermissionFeature feature) =>
      canEdit(feature, childId: Bag2SchoolStore.activeChildId);

  static void requestViewAccess(
    BuildContext context, {
    required LocalPermissionFeature feature,
    bool requestEdit = false,
  }) {
    final member = Bag2SchoolStore.familyMemberForCurrentAccount();
    if (member == null) return;
    final childId = Bag2SchoolStore.activeChildId;

    final exists = Bag2SchoolStore.accessRequests.any(
      (request) =>
          request.requesterMemberId == member.id &&
          request.childId == childId &&
          request.feature == feature &&
          request.requestEdit == requestEdit &&
          request.status == AccessRequestStatus.pending,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your access request is already waiting for the Family Owner.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Bag2SchoolStore.accessRequests.add(
      LocalAccessRequest(
        id: 'request-${DateTime.now().microsecondsSinceEpoch}',
        requesterMemberId: member.id,
        childId: childId,
        feature: feature,
        requestEdit: requestEdit,
        createdAt: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          requestEdit
              ? 'Edit access request sent to the Family Owner.'
              : 'Access request sent to the Family Owner.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String featureLabel(LocalPermissionFeature feature) {
    switch (feature) {
      case LocalPermissionFeature.schedule:
        return 'Schedule';
      case LocalPermissionFeature.homework:
        return 'Homework';
      case LocalPermissionFeature.preparation:
        return 'Preparation';
      case LocalPermissionFeature.exam:
        return 'Exam';
    }
  }

  static Future<void> showDenied(
    BuildContext context,
    String action, {
    String? featureLabel,
    LocalPermissionFeature? feature,
    bool requestEdit = false,
  }) async {
    if (feature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You don’t have permission to $action ${featureLabel ?? 'this item'} yet. '
            'Please ask the Family Owner to grant you access.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final wantsEdit = requestEdit ||
        action == 'add' ||
        action == 'edit' ||
        action == 'delete' ||
        action == 'change';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFFCF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Access needed',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF302722),
          ),
        ),
        content: Text(
          wantsEdit
              ? 'You don’t have permission to $action ${featureLabel ?? 'this item'}. '
                'Would you like to request edit access from the Family Owner?'
              : 'You don’t have permission to view ${featureLabel ?? 'this item'}. '
                'Would you like to request access from the Family Owner?',
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFF756B65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              requestViewAccess(
                context,
                feature: feature,
                requestEdit: wantsEdit,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A21),
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Access'),
          ),
        ],
      ),
    );
  }

  static Widget restrictedView({
    required String title,
    required String feature,
    required BuildContext context,
    required LocalPermissionFeature permission,
  }) {
    final member = Bag2SchoolStore.familyMemberForCurrentAccount();
    final alreadyPending = member != null &&
        Bag2SchoolStore.accessRequests.any(
          (request) =>
              request.requesterMemberId == member.id &&
              request.childId == Bag2SchoolStore.activeChildId &&
              request.feature == permission &&
              request.status == AccessRequestStatus.pending,
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 54,
              color: Color(0xFF9B8F87),
            ),
            const SizedBox(height: 14),
            Text(
              '$title access is limited',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF302722),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'You don’t currently have permission to view $feature for this child.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF756B65),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: alreadyPending
                  ? null
                  : () => requestViewAccess(
                        context,
                        feature: permission,
                      ),
              icon: Icon(
                alreadyPending
                    ? Icons.hourglass_top_rounded
                    : Icons.lock_open_rounded,
              ),
              label: Text(
                alreadyPending
                    ? 'Request pending'
                    : 'Request Access',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A21),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE6DED8),
                disabledForegroundColor: const Color(0xFF8A7E76),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The Family Owner can approve or decline this request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF8A7E76),
              ),
            ),
          ],
        ),
      ),
    );
  }
  static Widget authorizedView({
    required BuildContext context,
    required LocalPermissionFeature feature,
    required String title,
    required String featureLabel,
    required Widget child,
    String? childId,
  }) {
    return canView(
      feature,
      childId: childId ?? Bag2SchoolStore.activeChildId,
    )
        ? child
        : restrictedView(
            context: context,
            permission: feature,
            title: title,
            feature: featureLabel,
          );
  }

}

enum AccessRequestStatus {
  pending,
  approved,
  denied,
}

class LocalAccessRequest {
  final String id;
  final String requesterMemberId;
  final String childId;
  final LocalPermissionFeature feature;
  final bool requestEdit;
  final AccessRequestStatus status;
  final DateTime createdAt;

  const LocalAccessRequest({
    required this.id,
    required this.requesterMemberId,
    required this.childId,
    required this.feature,
    this.requestEdit = false,
    this.status = AccessRequestStatus.pending,
    required this.createdAt,
  });

  LocalAccessRequest copyWith({
    AccessRequestStatus? status,
  }) {
    return LocalAccessRequest(
      id: id,
      requesterMemberId: requesterMemberId,
      childId: childId,
      feature: feature,
      requestEdit: requestEdit,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class LocalFamilyNotification {
  final String id;
  final String recipientMemberId;
  final String childId;
  final String title;
  final String message;
  final DateTime createdAt;
  final String entityType;
  final String? entityId;

  const LocalFamilyNotification({
    required this.id,
    required this.recipientMemberId,
    required this.childId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.entityType,
    this.entityId,
  });
}


class LocalFamilyActivity {
  final String id;
  final String actorMemberId;
  final String childId;
  final LocalPermissionFeature feature;
  final String action;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? entityId;

  const LocalFamilyActivity({
    required this.id,
    required this.actorMemberId,
    required this.childId,
    required this.feature,
    required this.action,
    required this.title,
    required this.message,
    required this.createdAt,
    this.entityId,
  });
}

class LocalAccount {
  final String id;
  final String displayName;
  final String email;
  final String familyMemberId;

  const LocalAccount({
    required this.id,
    required this.displayName,
    required this.email,
    required this.familyMemberId,
  });

  LocalAccount copyWith({
    String? displayName,
    String? email,
    String? familyMemberId,
  }) {
    return LocalAccount(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      familyMemberId: familyMemberId ?? this.familyMemberId,
    );
  }
}

enum FamilyMemberRole {
  owner,
  parentGuardian,
  caregiver,
  child,
}

enum ChildAccessMode {
  managed,
  shared,
  independent,
}

class FamilyMember {
  final String id;
  final String displayName;
  final FamilyMemberRole role;
  final String? accountId;

  const FamilyMember({
    required this.id,
    required this.displayName,
    required this.role,
    this.accountId,
  });

  FamilyMember copyWith({
    String? id,
    String? displayName,
    FamilyMemberRole? role,
    String? accountId,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      accountId: accountId ?? this.accountId,
    );
  }
}

class FamilyAccessGrant {
  final String memberId;
  final String childId;
  final bool viewSchedule;
  final bool editSchedule;
  final bool viewHomework;
  final bool editHomework;
  final bool viewPreparation;
  final bool editPreparation;
  final bool viewExam;
  final bool editExam;

  const FamilyAccessGrant({
    required this.memberId,
    required this.childId,
    this.viewSchedule = true,
    this.editSchedule = false,
    this.viewHomework = true,
    this.editHomework = false,
    this.viewPreparation = true,
    this.editPreparation = false,
    this.viewExam = true,
    this.editExam = false,
  });

  FamilyAccessGrant copyWith({
    String? memberId,
    String? childId,
    bool? viewSchedule,
    bool? editSchedule,
    bool? viewHomework,
    bool? editHomework,
    bool? viewPreparation,
    bool? editPreparation,
    bool? viewExam,
    bool? editExam,
  }) {
    return FamilyAccessGrant(
      memberId: memberId ?? this.memberId,
      childId: childId ?? this.childId,
      viewSchedule: viewSchedule ?? this.viewSchedule,
      editSchedule: editSchedule ?? this.editSchedule,
      viewHomework: viewHomework ?? this.viewHomework,
      editHomework: editHomework ?? this.editHomework,
      viewPreparation: viewPreparation ?? this.viewPreparation,
      editPreparation: editPreparation ?? this.editPreparation,
      viewExam: viewExam ?? this.viewExam,
      editExam: editExam ?? this.editExam,
    );
  }
}

class ChildAccessSettings {
  final String childId;
  final ChildAccessMode mode;
  final bool parentViewSchedule;
  final bool parentViewHomework;
  final bool parentViewPreparation;
  final bool parentViewExam;

  const ChildAccessSettings({
    required this.childId,
    this.mode = ChildAccessMode.managed,
    this.parentViewSchedule = true,
    this.parentViewHomework = true,
    this.parentViewPreparation = true,
    this.parentViewExam = true,
  });

  ChildAccessSettings copyWith({
    String? childId,
    ChildAccessMode? mode,
    bool? parentViewSchedule,
    bool? parentViewHomework,
    bool? parentViewPreparation,
    bool? parentViewExam,
  }) {
    return ChildAccessSettings(
      childId: childId ?? this.childId,
      mode: mode ?? this.mode,
      parentViewSchedule: parentViewSchedule ?? this.parentViewSchedule,
      parentViewHomework: parentViewHomework ?? this.parentViewHomework,
      parentViewPreparation: parentViewPreparation ?? this.parentViewPreparation,
      parentViewExam: parentViewExam ?? this.parentViewExam,
    );
  }
}

class ChildProfile {
  final String id;
  final String name;
  final String grade;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.grade,
  });

  ChildProfile copyWith({
    String? id,
    String? name,
    String? grade,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
    );
  }
}

class _ChildDataBundle {
  final List<BagActivity> activities;
  final List<PreparationItem> preparations;
  final List<HomeworkItem> homeworks;
  final Map<String, bool> homeworkPreparationCompletion;
  final Set<String> cancelledActivityOccurrences;
  final Map<String, Set<String>> cancelledActivityDatesBySeries;
  final Map<String, bool> preparationOccurrenceCompletion;
  final Set<String> preparationOccurrenceHidden;
  final Map<String, List<PreparationItem>> preparationOccurrenceOverrides;

  const _ChildDataBundle({
    required this.activities,
    required this.preparations,
    required this.homeworks,
    required this.homeworkPreparationCompletion,
    required this.cancelledActivityOccurrences,
    required this.cancelledActivityDatesBySeries,
    required this.preparationOccurrenceCompletion,
    required this.preparationOccurrenceHidden,
    required this.preparationOccurrenceOverrides,
  });
}

class Bag2SchoolStore {
  // Multi-child local profile foundation. Data ownership by child will be
  // connected to Account/Cloud later; for now the selected child drives the UI.
  static final List<ChildProfile> childProfiles = <ChildProfile>[
    const ChildProfile(
      id: 'child-1',
      name: 'Kenneth',
      grade: 'Grade 4',
    ),
  ];

  static String activeChildId = 'child-1';

  // V13 local account/session simulation. No real authentication or cloud yet.
  static final List<LocalAccount> localAccounts = <LocalAccount>[
    const LocalAccount(
      id: 'account-owner',
      displayName: 'Family Owner',
      email: 'owner@bag2school.local',
      familyMemberId: 'member-owner',
    ),
  ];

  static String? currentAccountId = 'account-owner';

  static LocalAccount? get currentAccount {
    if (currentAccountId == null) return null;
    for (final account in localAccounts) {
      if (account.id == currentAccountId) return account;
    }
    return null;
  }

  static bool get isSignedIn => currentAccount != null;

  static void signInLocal(String accountId) {
    if (localAccounts.any((account) => account.id == accountId)) {
      currentAccountId = accountId;
    }
  }

  static void signOutLocal() {
    currentAccountId = null;
  }

  static void updateCurrentAccount({
    String? displayName,
    String? email,
  }) {
    final index = localAccounts.indexWhere(
      (account) => account.id == currentAccountId,
    );
    if (index < 0) return;
    localAccounts[index] = localAccounts[index].copyWith(
      displayName: displayName,
      email: email,
    );
  }

  static FamilyMember? familyMemberForCurrentAccount() {
    final account = currentAccount;
    if (account == null) return null;
    for (final member in familyMembers) {
      if (member.id == account.familyMemberId) return member;
    }
    return null;
  }

  static String createLocalAccountForFamilyMember({
    required String memberId,
    required String displayName,
  }) {
    final id = 'account-${DateTime.now().microsecondsSinceEpoch}';
    final email = '${displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.')}@bag2school.local';
    localAccounts.add(
      LocalAccount(
        id: id,
        displayName: displayName,
        email: email,
        familyMemberId: memberId,
      ),
    );
    return id;
  }

  static bool canViewChild(
    String childId, {
    String? memberId,
  }) {
    final member = memberId == null
        ? familyMemberForCurrentAccount()
        : familyMembers.cast<FamilyMember?>().firstWhere(
              (entry) => entry?.id == memberId,
              orElse: () => null,
            );
    if (member == null) return false;

    if (member.role == FamilyMemberRole.owner) {
      return true;
    }

    if (member.role == FamilyMemberRole.child) {
      final child = childProfiles.cast<ChildProfile?>().firstWhere(
            (entry) => entry?.id == childId,
            orElse: () => null,
          );
      return child?.id == childId;
    }

    return familyAccessGrants.containsKey(
      familyAccessGrantKey(childId, member.id),
    );
  }

  static FamilyAccessGrant? currentGrantForChild(String childId) {
    final member = familyMemberForCurrentAccount();
    if (member == null) return null;
    return accessGrantFor(childId, member.id);
  }

  // V12 Family & Access foundation. These remain local placeholders until
  // Account/Cloud Sync is implemented.
  static final List<FamilyMember> familyMembers = <FamilyMember>[
    const FamilyMember(
      id: 'member-owner',
      displayName: 'Family Owner',
      role: FamilyMemberRole.owner,
      accountId: 'account-owner',
    ),
  ];

  static final Map<String, ChildAccessSettings> childAccessByChildId =
      <String, ChildAccessSettings>{
    'child-1': const ChildAccessSettings(childId: 'child-1'),
  };

  // Key: childId|memberId. Local grant simulation until Account/Cloud.
  static final Map<String, FamilyAccessGrant> familyAccessGrants =
      <String, FamilyAccessGrant>{};

  static final List<LocalAccessRequest> accessRequests =
      <LocalAccessRequest>[];

  static final List<LocalFamilyNotification> familyNotifications =
      <LocalFamilyNotification>[];

  static final List<LocalFamilyActivity> familyActivities =
      <LocalFamilyActivity>[];

  static final Set<String> readAccessRequestIds = <String>{};
  static final Set<String> readAccessResponseIds = <String>{};
  static final Set<String> readNotificationIds = <String>{};

  // The notification inbox is bounded; Family Activity remains the complete
  // history/audit trail.
  static const int maxStoredReadNotificationsPerMember = 50;

  static void pruneNotificationInbox() {
    final memberIds = familyMembers.map((member) => member.id).toSet();

    for (final memberId in memberIds) {
      final items = familyNotifications
          .where(
            (notification) => notification.recipientMemberId == memberId,
          )
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

      final unread = items.where(
        (notification) => !readNotificationIds.contains(notification.id),
      );
      final read = items.where(
        (notification) => readNotificationIds.contains(notification.id),
      );

      final keepIds = <String>{
        ...unread.map((notification) => notification.id),
        ...read
            .take(maxStoredReadNotificationsPerMember)
            .map((notification) => notification.id),
      };

      familyNotifications.removeWhere(
        (notification) =>
            notification.recipientMemberId == memberId &&
            !keepIds.contains(notification.id),
      );
    }

    readNotificationIds.removeWhere(
      (id) => !familyNotifications.any(
        (notification) => notification.id == id,
      ),
    );
  }

  static int get pendingAccessRequestCount {
    final member = familyMemberForCurrentAccount();
    if (member?.role != FamilyMemberRole.owner) return 0;
    return accessRequests.where((request) =>
        request.status == AccessRequestStatus.pending &&
        !readAccessRequestIds.contains(request.id)).length;
  }

  static int get currentMemberNotificationCount {
    final unreadActivity = notificationsForCurrentMember()
        .where(
          (notification) =>
              !readNotificationIds.contains(notification.id),
        )
        .length;
    final unreadAccessResponses = responseNotificationsForCurrentMember()
        .where(
          (request) => !readAccessResponseIds.contains(request.id),
        )
        .length;
    return unreadActivity + unreadAccessResponses;
  }

  static void markCurrentNotificationsRead() {
    final member = familyMemberForCurrentAccount();
    if (member == null) return;
    if (member.role == FamilyMemberRole.owner) {
      for (final request in accessRequests) {
        if (request.status == AccessRequestStatus.pending) {
          readAccessRequestIds.add(request.id);
        }
      }
    }
    for (final notification in familyNotifications) {
      if (notification.recipientMemberId == member.id) {
        readNotificationIds.add(notification.id);
      }
    }
    for (final request in accessRequests) {
      if (request.requesterMemberId == member.id &&
          request.status != AccessRequestStatus.pending) {
        readAccessResponseIds.add(request.id);
      }
    }
  }

  static bool memberCanViewFeature({
    required String memberId,
    required String childId,
    required LocalPermissionFeature feature,
  }) {
    final index =
        familyMembers.indexWhere((member) => member.id == memberId);
    if (index < 0) return false;

    final member = familyMembers[index];
    if (member.role == FamilyMemberRole.owner) return true;

    final grant = accessGrantFor(childId, memberId);
    if (grant == null) return false;

    switch (feature) {
      case LocalPermissionFeature.schedule:
        return grant.viewSchedule;
      case LocalPermissionFeature.homework:
        return grant.viewHomework;
      case LocalPermissionFeature.preparation:
        return grant.viewPreparation;
      case LocalPermissionFeature.exam:
        return grant.viewExam;
    }
  }

  static void recordFamilyActivity({
    required LocalPermissionFeature feature,
    required String action,
    required String title,
    required String message,
    required String childId,
    String? entityId,
  }) {
    final actor = familyMemberForCurrentAccount();
    if (actor == null) return;

    final now = DateTime.now();
    final activityId = 'family-activity-${now.microsecondsSinceEpoch}';

    familyActivities.add(
      LocalFamilyActivity(
        id: activityId,
        actorMemberId: actor.id,
        childId: childId,
        feature: feature,
        action: action,
        title: title,
        message: message,
        createdAt: now,
        entityId: entityId,
      ),
    );

    for (final member in familyMembers) {
      if (member.id == actor.id) continue;
      if (!memberCanViewFeature(
        memberId: member.id,
        childId: childId,
        feature: feature,
      )) {
        continue;
      }

      final notification = LocalFamilyNotification(
        id: 'notification-${now.microsecondsSinceEpoch}-${member.id}',
        recipientMemberId: member.id,
        childId: childId,
        title: title,
        message: message,
        createdAt: now,
        entityType: LocalAuthorization.featureLabel(feature).toLowerCase(),
        entityId: entityId,
      );

      if (feature == LocalPermissionFeature.preparation &&
          action == 'Edited' &&
          entityId != null) {
        final existingIndex = familyNotifications.indexWhere(
          (existing) =>
              existing.recipientMemberId == member.id &&
              existing.childId == childId &&
              existing.entityType == 'preparation' &&
              existing.entityId == entityId,
        );
        if (existingIndex >= 0) {
          final oldNotification = familyNotifications[existingIndex];
          familyNotifications[existingIndex] = notification;
          readNotificationIds.remove(oldNotification.id);
          continue;
        }
      }

      familyNotifications.add(notification);
    }

    pruneNotificationInbox();
  }

  static List<LocalFamilyNotification>
      notificationsForCurrentMember() {
    final member = familyMemberForCurrentAccount();
    if (member == null) return const <LocalFamilyNotification>[];

    return familyNotifications
        .where((notification) =>
            notification.recipientMemberId == member.id)
        .toList()
      ..sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );
  }

  static List<LocalAccessRequest> responseNotificationsForCurrentMember() {
    final member = familyMemberForCurrentAccount();
    if (member == null) return const <LocalAccessRequest>[];
    return accessRequests
        .where(
          (request) =>
              request.requesterMemberId == member.id &&
              request.status != AccessRequestStatus.pending,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static String familyAccessGrantKey(String childId, String memberId) =>
      '$childId|$memberId';

  static FamilyAccessGrant? accessGrantFor(
    String childId,
    String memberId,
  ) {
    return familyAccessGrants[familyAccessGrantKey(childId, memberId)];
  }

  static void saveAccessGrant(FamilyAccessGrant grant) {
    familyAccessGrants[familyAccessGrantKey(
      grant.childId,
      grant.memberId,
    )] = grant;
  }

  static void removeAccessGrant(String childId, String memberId) {
    familyAccessGrants.remove(
      familyAccessGrantKey(childId, memberId),
    );
  }

  static final Map<String, FamilyMemberRole> childLinkedMemberRoles =
      <String, FamilyMemberRole>{};

  static final Map<String, ChildAccessSettings> childAccessDefaults =
      <String, ChildAccessSettings>{};

  static final Map<String, _ChildDataBundle> _childDataById =
      <String, _ChildDataBundle>{};

  static ChildProfile get activeChild =>
      childProfiles.firstWhere(
        (child) => child.id == activeChildId,
        orElse: () => childProfiles.first,
      );

  // Backward-compatible accessors used by the existing Home/Settings UI.
  static String get childName => activeChild.name;
  static String get childGrade => activeChild.grade;

  static void updateActiveChild({
    String? name,
    String? grade,
  }) {
    final index =
        childProfiles.indexWhere((child) => child.id == activeChildId);
    if (index < 0) return;
    childProfiles[index] = childProfiles[index].copyWith(
      name: name,
      grade: grade,
    );
  }

  static ChildAccessSettings accessForChild(String childId) {
    return childAccessByChildId[childId] ??
        ChildAccessSettings(childId: childId);
  }

  static void updateChildAccess(ChildAccessSettings settings) {
    childAccessByChildId[settings.childId] = settings;
  }

  static void _saveActiveChildData() {
    final clonedOverrides = <String, List<PreparationItem>>{};
    preparationOccurrenceOverrides.forEach((key, items) {
      clonedOverrides[key] = items
          .map((item) => item.copyWith())
          .toList();
    });

    final clonedCancelledDates = <String, Set<String>>{};
    cancelledActivityDatesBySeries.forEach((key, dates) {
      clonedCancelledDates[key] = <String>{...dates};
    });

    _childDataById[activeChildId] = _ChildDataBundle(
      activities: List<BagActivity>.from(activities),
      preparations: preparations.map((item) => item.copyWith()).toList(),
      homeworks: homeworks.map((item) => item.copyWith()).toList(),
      homeworkPreparationCompletion:
          Map<String, bool>.from(homeworkPreparationCompletion),
      cancelledActivityOccurrences:
          <String>{...cancelledActivityOccurrences},
      cancelledActivityDatesBySeries: clonedCancelledDates,
      preparationOccurrenceCompletion:
          Map<String, bool>.from(preparationOccurrenceCompletion),
      preparationOccurrenceHidden: <String>{...preparationOccurrenceHidden},
      preparationOccurrenceOverrides: clonedOverrides,
    );
  }

  static void _clearActiveChildData() {
    activities.clear();
    preparations.clear();
    homeworks.clear();
    homeworkPreparationCompletion.clear();
    cancelledActivityOccurrences.clear();
    cancelledActivityDatesBySeries.clear();
    preparationOccurrenceCompletion.clear();
    preparationOccurrenceHidden.clear();
    preparationOccurrenceOverrides.clear();
  }

  static void _loadChildData(String childId) {
    _clearActiveChildData();

    final data = _childDataById[childId];
    if (data == null) return;

    activities.addAll(data.activities);
    preparations.addAll(data.preparations);
    homeworks.addAll(data.homeworks);
    homeworkPreparationCompletion.addAll(data.homeworkPreparationCompletion);
    cancelledActivityOccurrences.addAll(data.cancelledActivityOccurrences);
    data.cancelledActivityDatesBySeries.forEach((key, dates) {
      cancelledActivityDatesBySeries[key] = <String>{...dates};
    });
    preparationOccurrenceCompletion.addAll(
      data.preparationOccurrenceCompletion,
    );
    preparationOccurrenceHidden.addAll(data.preparationOccurrenceHidden);
    data.preparationOccurrenceOverrides.forEach((key, items) {
      preparationOccurrenceOverrides[key] =
          items.map((item) => item.copyWith()).toList();
    });
  }

  static void switchActiveChild(String childId) {
    if (childId == activeChildId) return;

    final exists =
        childProfiles.any((child) => child.id == childId);
    if (!exists) return;

    // Preserve current child's current in-memory data before switching.
    _saveActiveChildData();

    activeChildId = childId;
    _loadChildData(childId);
  }

  static String languageCode = 'en';

  static final List<BagActivity> activities = <BagActivity>[];
  static final List<PreparationItem> preparations = <PreparationItem>[];
  static final List<HomeworkItem> homeworks = <HomeworkItem>[];

  // Homework completion (done with the homework) is intentionally separate
  // from Homework-as-Preparation readiness (packed/prepared for the activity).
  // Key: dayOnly|homeworkId.
  static final Map<String, bool> homeworkPreparationCompletion =
      <String, bool>{};

  // A recurring activity can be cancelled for one occurrence without
  // deleting the underlying recurring series. Key: dayOnly|activityId.
  static final Set<String> cancelledActivityOccurrences = <String>{};

  // Robust occurrence cancellation store. The activity id is the series
  // identity and each date is cancelled independently. This prevents
  // deleting one occurrence from ever mutating/removing the parent series.
  static final Map<String, Set<String>> cancelledActivityDatesBySeries =
      <String, Set<String>>{};

  static void cancelActivityOccurrence(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    cancelledActivityDatesBySeries
        .putIfAbsent(activityId, () => <String>{})
        .add(clean.toIso8601String());
    // Keep the legacy set in sync for backward compatibility.
    cancelledActivityOccurrences.add(activityOccurrenceKey(clean, activityId));
  }

  static bool isOccurrenceCancelled(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    final dates = cancelledActivityDatesBySeries[activityId];
    if (dates != null && dates.contains(clean.toIso8601String())) return true;
    return cancelledActivityOccurrences.contains(activityOccurrenceKey(clean, activityId));
  }

  static void moveCancelledOccurrences(String oldActivityId, String newActivityId, DateTime fromDate) {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final oldDates = cancelledActivityDatesBySeries[oldActivityId];
    if (oldDates == null || oldDates.isEmpty) return;
    final moved = <String>{};
    for (final raw in oldDates.toList()) {
      final date = DateTime.tryParse(raw);
      if (date != null && !date.isBefore(from)) {
        moved.add(raw);
        oldDates.remove(raw);
        cancelledActivityOccurrences.remove(activityOccurrenceKey(date, oldActivityId));
        cancelledActivityOccurrences.add(activityOccurrenceKey(date, newActivityId));
      }
    }
    if (moved.isNotEmpty) {
      cancelledActivityDatesBySeries
          .putIfAbsent(newActivityId, () => <String>{})
          .addAll(moved);
    }
  }

  static String activityOccurrenceKey(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    return '${clean.toIso8601String()}|$activityId';
  }

  static bool isActivityOccurrenceCancelled(DateTime date, String activityId) =>
      cancelledActivityOccurrences.contains(activityOccurrenceKey(date, activityId));

  static final Map<String, bool> preparationOccurrenceCompletion =
      <String, bool>{};

  // Legacy per-item hide state kept for backward compatibility with older
  // V3 data. New occurrence edits use the full-list override below.
  static final Set<String> preparationOccurrenceHidden = <String>{};

  // IMPORTANT: a recurring activity has a base preparation template, but
  // every calendar occurrence can be edited independently. Once an
  // occurrence is edited, this map becomes the source of truth for that
  // date/activity pair. An empty list means "intentionally no preparation".
  static final Map<String, List<PreparationItem>>
      preparationOccurrenceOverrides = <String, List<PreparationItem>>{};

  static String preparationOccurrenceKey(DateTime date, String activityId) {
    final clean = DateTime(date.year, date.month, date.day);
    return '${clean.toIso8601String()}|$activityId';
  }

  static bool hasPreparationOccurrenceOverride(
    DateTime date,
    String activityId,
  ) {
    return preparationOccurrenceOverrides
        .containsKey(preparationOccurrenceKey(date, activityId));
  }

  static List<PreparationItem> preparationsForOccurrence(
    DateTime date,
    String activityId,
  ) {
    final clean = DateTime(date.year, date.month, date.day);
    final key = preparationOccurrenceKey(clean, activityId);

    if (preparationOccurrenceOverrides.containsKey(key)) {
      return preparationOccurrenceOverrides[key]!
          .map((item) => item.copyWith(preparationDate: clean))
          .toList();
    }

    final activity = activities.cast<BagActivity?>().firstWhere(
      (item) => item?.id == activityId,
      orElse: () => null,
    );

    return preparations
        .where((item) => item.activityId == activityId)
        .where((item) {
          final savedDate = DateTime(
            item.preparationDate.year,
            item.preparationDate.month,
            item.preparationDate.day,
          );

          // Non-recurring activity: preparation belongs to its saved day.
          // Recurring activity: the saved preparation is the template and
          // appears on each matching occurrence.
          final matchesActivityOccurrence =
              activity != null && activity.occursOn(clean);

          if (!matchesActivityOccurrence) {
            return savedDate == clean;
          }

          return true;
        })
        .where((item) {
          final occurrenceItemKey =
              '${clean.toIso8601String()}|${item.id}';
          return !preparationOccurrenceHidden.contains(occurrenceItemKey);
        })
        .map((item) => item.copyWith(preparationDate: clean))
        .toList();
  }
}

// ============================================================
// PREPARATION DATA
// ============================================================
//
// Preparation is intentionally NOT an Activity.
// It belongs to an Activity through activityId and has its own
// date/completion state.

class PreparationItem {
  final String id;
  final String activityId;
  final String title;
  final DateTime preparationDate;
  final bool completed;
  final bool reminderEnabled;
  final DateTime? reminderDate;
  final int reminderHour;
  final int reminderMinute;

  const PreparationItem({
    required this.id,
    required this.activityId,
    required this.title,
    required this.preparationDate,
    this.completed = false,
    this.reminderEnabled = false,
    this.reminderDate,
    this.reminderHour = 18,
    this.reminderMinute = 0,
  });

  PreparationItem copyWith({
    String? title,
    DateTime? preparationDate,
    bool? completed,
    bool? reminderEnabled,
    DateTime? reminderDate,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return PreparationItem(
      id: id,
      activityId: activityId,
      title: title ?? this.title,
      preparationDate: preparationDate ?? this.preparationDate,
      completed: completed ?? this.completed,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  bool occursOn(DateTime date) {
    final a = DateTime(
      preparationDate.year,
      preparationDate.month,
      preparationDate.day,
    );
    final b = DateTime(date.year, date.month, date.day);
    return a == b;
  }
}

// ============================================================
// BAG2SCHOOL ACTIVITY FOUNDATION
// ============================================================
//
// This is the data foundation for Add Activity.
// It is intentionally not changing the visible UI yet.
//
// Activity -> Recurrence -> Conflict Detection
// The activity model feeds Schedule, Calendar, Preparation, and Bagi.
// Homework remains a separate task model.

enum ActivityType {
  school,
  lesson,
  extracurricular,
  exam,
  event,
}

enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekly,
  biweekly,
  monthly,
  custom,
}

enum ActivityIndicatorType {
  none,
  activity,
  homework,
  exam,
  event,
  preparation,
  overdue,
}

class ActivityRecurrence {
  final RecurrenceType type;
  final int interval;
  final List<int> weekdays; // DateTime.monday ... DateTime.sunday
  final DateTime? endDate;

  const ActivityRecurrence({
    this.type = RecurrenceType.none,
    this.interval = 1,
    this.weekdays = const [],
    this.endDate,
  });

  bool occursOn(DateTime date, DateTime startDate) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    if (day.isBefore(start)) {
      return false;
    }

    if (endDate != null) {
      final end = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
      );

      if (day.isAfter(end)) {
        return false;
      }
    }

    final difference = day.difference(start).inDays;

    switch (type) {
      case RecurrenceType.none:
        return difference == 0;

      case RecurrenceType.daily:
        return difference % interval == 0;

      case RecurrenceType.weekdays:
        return day.weekday >= DateTime.monday &&
            day.weekday <= DateTime.friday;

      case RecurrenceType.weekly:
        return day.weekday == start.weekday &&
            difference % (7 * interval) == 0;

      case RecurrenceType.biweekly:
        return day.weekday == start.weekday &&
            difference % 14 == 0;

      case RecurrenceType.monthly:
        return day.day == start.day &&
            difference >= 0 &&
            _monthsBetween(start, day) % interval == 0;

      case RecurrenceType.custom:
        if (weekdays.isEmpty) {
          return false;
        }

        return weekdays.contains(day.weekday) &&
            difference >= 0 &&
            _weeksBetween(start, day) % interval == 0;
    }
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 +
        to.month -
        from.month;
  }

  int _weeksBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays ~/ 7;
  }
}

class HomeworkItem {
  final String id;
  final String task;
  final String subject;
  final DateTime dueDate;
  final TimeOfDayData? dueTime;
  final bool reminderEnabled;
  final DateTime? reminderDate;
  final int reminderHour;
  final int reminderMinute;
  final String notes;
  final String? relatedActivityId;
  final bool completed;
  final DateTime createdAt;

  const HomeworkItem({
    required this.id,
    required this.task,
    required this.subject,
    required this.dueDate,
    this.dueTime,
    this.reminderEnabled = false,
    this.reminderDate,
    this.reminderHour = 18,
    this.reminderMinute = 30,
    this.notes = '',
    this.relatedActivityId,
    this.completed = false,
    required this.createdAt,
  });

  HomeworkItem copyWith({
    String? task,
    String? subject,
    DateTime? dueDate,
    TimeOfDayData? dueTime,
    bool clearDueTime = false,
    bool? reminderEnabled,
    DateTime? reminderDate,
    bool clearReminderDate = false,
    int? reminderHour,
    int? reminderMinute,
    String? notes,
    String? relatedActivityId,
    bool clearRelatedActivity = false,
    bool? completed,
  }) {
    return HomeworkItem(
      id: id,
      task: task ?? this.task,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDate: clearReminderDate
          ? null
          : (reminderDate ?? this.reminderDate),
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      notes: notes ?? this.notes,
      relatedActivityId: clearRelatedActivity
          ? null
          : (relatedActivityId ?? this.relatedActivityId),
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }
}

class HomeworkDetails {
  final String subject;
  final String task;
  final DateTime dueDate;
  final String notes;
  final bool completed;

  const HomeworkDetails({
    required this.subject,
    required this.task,
    required this.dueDate,
    this.notes = '',
    this.completed = false,
  });

  HomeworkDetails copyWith({
    String? subject,
    String? task,
    DateTime? dueDate,
    String? notes,
    bool? completed,
  }) {
    return HomeworkDetails(
      subject: subject ?? this.subject,
      task: task ?? this.task,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }
}

class BagActivity {
  final String id;
  final String title;
  final ActivityType type;
  final DateTime startDate;
  final TimeOfDayData startTime;
  final TimeOfDayData endTime;
  final ActivityRecurrence recurrence;
  final bool isRoutine;
  final bool showIndicator;
  final ActivityIndicatorType indicatorType;
  final bool completed;
  final String location;
  final String notes;
  final HomeworkDetails? homework;

  const BagActivity({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    this.recurrence = const ActivityRecurrence(),
    this.isRoutine = false,
    this.showIndicator = true,
    this.indicatorType = ActivityIndicatorType.activity,
    this.completed = false,
    this.location = '',
    this.notes = '',
    this.homework,
  });

  bool occursOn(DateTime date) {
    return recurrence.occursOn(date, startDate);
  }

  int startMinutes() {
    return startTime.hour * 60 + startTime.minute;
  }

  int endMinutes() {
    return endTime.hour * 60 + endTime.minute;
  }

  BagActivity copyWith({
    String? title,
    ActivityType? type,
    DateTime? startDate,
    TimeOfDayData? startTime,
    TimeOfDayData? endTime,
    ActivityRecurrence? recurrence,
    bool? isRoutine,
    bool? showIndicator,
    ActivityIndicatorType? indicatorType,
    bool? completed,
    String? location,
    String? notes,
    HomeworkDetails? homework,
  }) {
    return BagActivity(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrence: recurrence ?? this.recurrence,
      isRoutine: isRoutine ?? this.isRoutine,
      showIndicator: showIndicator ?? this.showIndicator,
      indicatorType: indicatorType ?? this.indicatorType,
      completed: completed ?? this.completed,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      homework: homework ?? this.homework,
    );
  }
}

class TimeOfDayData {
  final int hour;
  final int minute;

  const TimeOfDayData({
    required this.hour,
    required this.minute,
  });

  int get totalMinutes => hour * 60 + minute;
}

class ActivityConflict {
  final BagActivity existingActivity;
  final DateTime date;
  final String message;

  const ActivityConflict({
    required this.existingActivity,
    required this.date,
    required this.message,
  });
}

class ActivityConflictDetector {
  const ActivityConflictDetector();

  List<ActivityConflict> findConflicts({
    required BagActivity candidate,
    required List<BagActivity> existingActivities,
  }) {
    final conflicts = <ActivityConflict>[];

    for (final existing in existingActivities) {
      if (existing.id == candidate.id) {
        continue;
      }

      final dates = _overlappingDates(candidate, existing);

      for (final date in dates) {
        final overlaps =
            candidate.startMinutes() < existing.endMinutes() &&
            candidate.endMinutes() > existing.startMinutes();

        if (overlaps) {
          conflicts.add(
            ActivityConflict(
              existingActivity: existing,
              date: date,
              message:
                  '${candidate.title} overlaps with '
                  '${existing.title}.',
            ),
          );
        }
      }
    }

    return conflicts;
  }

  List<DateTime> _overlappingDates(
    BagActivity first,
    BagActivity second,
  ) {
    final results = <DateTime>[];

    final firstStart = DateTime(
      first.startDate.year,
      first.startDate.month,
      first.startDate.day,
    );

    final secondStart = DateTime(
      second.startDate.year,
      second.startDate.month,
      second.startDate.day,
    );

    final earliest = firstStart.isAfter(secondStart)
        ? firstStart
        : secondStart;

    // For now we inspect a practical one-year window.
    // The UI will later use this same function for the
    // specific date being added/edited.
    for (var i = 0; i < 366; i++) {
      final date = earliest.add(Duration(days: i));

      if (first.occursOn(date) && second.occursOn(date)) {
        results.add(date);
      }

      if (results.length >= 20) {
        break;
      }
    }

    return results;
  }
}


// ============================================================
// BAG2SCHOOL MONTH CALENDAR
// ============================================================

enum IndicatorType {
  activity,
  homework,
  exam,
  event,
  preparation,
  overdue,
}

class CalendarIndicator {
  final IndicatorType type;

  const CalendarIndicator(this.type);

  Color get color {
    switch (type) {
      case IndicatorType.activity:
        return const Color(0xFFFF7A21);
      case IndicatorType.homework:
        return const Color(0xFF7661D8);
      case IndicatorType.exam:
        return const Color(0xFF2A9D8F);
      case IndicatorType.event:
        return const Color(0xFF4C8FD9);
      case IndicatorType.preparation:
        return const Color(0xFF58A879);
      case IndicatorType.overdue:
        return const Color(0xFFE45757);
    }
  }
}

class Bag2SchoolMonthCalendar extends StatefulWidget {
  final DateTime selectedDate;

  const Bag2SchoolMonthCalendar({
    super.key,
    required this.selectedDate,
  });

  @override
  State<Bag2SchoolMonthCalendar> createState() =>
      _Bag2SchoolMonthCalendarState();
}

class _Bag2SchoolMonthCalendarState
    extends State<Bag2SchoolMonthCalendar> {
  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();

    displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  String monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  int daysInMonth() {
    return DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;
  }

  List<CalendarIndicator> indicatorsFor(DateTime date) {
    // Month view is driven by real activities only.
    // Preparation items never create month-view dots.
    final indicators = <IndicatorType>[];

    // Keep month view in sync with real activities.
    for (final activity in Bag2SchoolStore.activities) {
      if (!activity.occursOn(date) || Bag2SchoolStore.isOccurrenceCancelled(date, activity.id)) {
        continue;
      }

      // Class/Lesson is always an orange activity dot.
      if (activity.type == ActivityType.lesson) {
        if (!indicators.contains(IndicatorType.activity)) {
          indicators.add(IndicatorType.activity);
        }
        continue;
      }

      if (!activity.showIndicator) {
        continue;
      }

      switch (activity.indicatorType) {
        case ActivityIndicatorType.activity:
          if (!indicators.contains(IndicatorType.activity)) {
            indicators.add(IndicatorType.activity);
          }
          break;
        case ActivityIndicatorType.homework:
          if (!indicators.contains(IndicatorType.homework)) {
            indicators.add(IndicatorType.homework);
          }
          break;
        case ActivityIndicatorType.exam:
          if (!indicators.contains(IndicatorType.exam)) {
            indicators.add(IndicatorType.exam);
          }
          break;
        case ActivityIndicatorType.event:
          if (!indicators.contains(IndicatorType.event)) {
            indicators.add(IndicatorType.event);
          }
          break;
        case ActivityIndicatorType.preparation:
          // Preparation is not a calendar event.
          break;
        case ActivityIndicatorType.overdue:
          if (!indicators.contains(IndicatorType.overdue)) {
            indicators.add(IndicatorType.overdue);
          }
          break;
        case ActivityIndicatorType.none:
          break;
      }
    }

    final cleanDate = DateTime(date.year, date.month, date.day);
    final hasHomework = Bag2SchoolStore.homeworks.any((homework) {
      final due = DateTime(
        homework.dueDate.year,
        homework.dueDate.month,
        homework.dueDate.day,
      );
      return due == cleanDate;
    });
    if (hasHomework && !indicators.contains(IndicatorType.homework)) {
      indicators.add(IndicatorType.homework);
    }

    return indicators
        .map((type) => CalendarIndicator(type))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final leadingEmptyDays = firstDay.weekday - 1;
    final totalDays = daysInMonth();

    return Dialog(
      backgroundColor: const Color(0xFFFFFCF8),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 35,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${monthName(displayedMonth.month)} '
                    '${displayedMonth.year}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final today = DateTime.now();
                    Navigator.pop(
                      context,
                      DateTime(today.year, today.month, today.day),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A21),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      displayedMonth = DateTime(
                        displayedMonth.year,
                        displayedMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      displayedMonth = DateTime(
                        displayedMonth.year,
                        displayedMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Row(
              children: [
                Expanded(child: _CalendarWeekday('M')),
                Expanded(child: _CalendarWeekday('T')),
                Expanded(child: _CalendarWeekday('W')),
                Expanded(child: _CalendarWeekday('T')),
                Expanded(child: _CalendarWeekday('F')),
                Expanded(child: _CalendarWeekday('S')),
                Expanded(child: _CalendarWeekday('S')),
              ],
            ),

            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingEmptyDays + totalDays,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyDays) {
                  return const SizedBox();
                }

                final day = index - leadingEmptyDays + 1;

                final date = DateTime(
                  displayedMonth.year,
                  displayedMonth.month,
                  day,
                );

                final indicators = indicatorsFor(date);

                final isSelected =
                    widget.selectedDate.year == date.year &&
                    widget.selectedDate.month == date.month &&
                    widget.selectedDate.day == date.day;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, date);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A21)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF29231F),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: indicators.take(3).map(
                              (indicator) {
                                return Container(
                                  width: 5,
                                  height: 5,
                                  margin:
                                      const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : indicator.color,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                _CalendarLegend(
                  color: Color(0xFFFF7A21),
                  text: 'Activity',
                ),
                _CalendarLegend(
                  color: Color(0xFF7661D8),
                  text: 'Homework',
                ),
                _CalendarLegend(
                  color: Color(0xFF2A9D8F),
                  text: 'Exam',
                ),
                _CalendarLegend(
                  color: Color(0xFF4C8FD9),
                  text: 'Event',
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarWeekday extends StatelessWidget {
  final String text;

  const _CalendarWeekday(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9A9089),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final Color color;
  final String text;

  const _CalendarLegend({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF756B65),
          ),
        ),
      ],
    );
  }
}
