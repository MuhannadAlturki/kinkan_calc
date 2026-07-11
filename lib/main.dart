// lib/main.dart - PART 1 of 2
// ═══════════════════════════════════════════════════════════════════
//  KINKAN CALCULATOR - FULL REVAMP v2
//  انسخ هذا الجزء + الجزء الثاني في ملف واحد lib/main.dart
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/*═══════════════════════════│ ثوابت الألوان │═══════════════════════════*/
class AppColors {
  static const primary = Color(0xFF6750A4);
  static const primaryDark = Color(0xFF4A3B7C);
  static const accent = Color(0xFFFFB300);
  static const success = Color(0xFF2E7D32);
  static const danger = Color(0xFFD32F2F);
  static const warning = Color(0xFFF57C00);

  static const playerColors = [
    Color(0xFF1976D2),
    Color(0xFFD32F2F),
    Color(0xFF388E3C),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
    Color(0xFFC2185B),
    Color(0xFF5D4037),
  ];

  static Color forPlayer(String name, List<String> allPlayers) {
    final idx = allPlayers.indexOf(name);
    if (idx == -1) return primary;
    return playerColors[idx % playerColors.length];
  }

  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFC0C0C0);
}

/// يعرض الفائزين مقسّمين لمستويات: الأول ذهبي، الثاني فضي (ولو تعادلوا
/// يقعون كلهم بنفس المستوى الذهبي).
Widget buildWinnerTiersDisplay({
  required Map<String, int> finalScores,
  required List<String> winners,
  double iconSize = 16,
  double fontSize = 13,
  Color? textColor,
}) {
  final tiers =
  rankTiers({for (final name in winners) name: finalScores[name] ?? 0});
  return Wrap(
    spacing: 10,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (int i = 0; i < tiers.length && i < 2; i++)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded,
                color: i == 0 ? AppColors.gold : AppColors.silver,
                size: iconSize),
            const SizedBox(width: 4),
            Text(
              tiers[i].join('، '),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  color: textColor),
            ),
          ],
        ),
    ],
  );
}

/// يرتب اللاعبين لمستويات حسب النقاط تصاعدياً: المستوى الأول (index 0) هو
/// الأقل نقاطاً (الفائز)، يليه المستوى الثاني، وهكذا. المتعادلون بنفس
/// النقاط يقعون بنفس المستوى.
List<List<String>> rankTiers(Map<String, int> scores) {
  if (scores.isEmpty) return [];
  final entries = scores.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  final tiers = <List<String>>[];
  int i = 0;
  while (i < entries.length) {
    final score = entries[i].value;
    final tier = <String>[];
    while (i < entries.length && entries[i].value == score) {
      tier.add(entries[i].key);
      i++;
    }
    tiers.add(tier);
  }
  return tiers;
}

/*═══════════════════════════│ تشغيل التطبيق │═══════════════════════════*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialTheme = await ThemeManager.load();
  KinkanApp.themeNotifier.value = initialTheme;
  runApp(const KinkanApp());
}

class KinkanApp extends StatelessWidget {
  const KinkanApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier =
  ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: themeNotifier,
    builder: (_, currentMode, __) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حاسبة كنكان',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: currentMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const PlayerSetupScreen(),
    ),
  );

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      scaffoldBackgroundColor:
      isDark ? const Color(0xFF121212) : const Color(0xFFF7F7FA),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFF7F7FA),
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

/*═══════════════════════════│ الكيانات │═══════════════════════════*/
class Player {
  Player(this.name);
  final String name;
  int score = 0;
  bool out = false;
  Player clone() => Player(name);
}

class Round {
  Round({
    required this.index,
    required this.preset,
    required this.winner,
    required this.points,
    this.isPlayerAddition = false,
    this.addedPlayers = const [],
    this.isPlayerRemoval = false,
    this.removedPlayers = const [],
  });

  final int index;
  final int preset;
  final String winner;
  Map<String, int> points;
  final bool isPlayerAddition;
  final List<String> addedPlayers;
  final bool isPlayerRemoval;
  final List<String> removedPlayers;

  bool get isEvent => isPlayerAddition || isPlayerRemoval;

  Map<String, dynamic> toJson() => {
    'index': index,
    'preset': preset,
    'winner': winner,
    'points': points,
    'isPlayerAddition': isPlayerAddition,
    'addedPlayers': addedPlayers,
    'isPlayerRemoval': isPlayerRemoval,
    'removedPlayers': removedPlayers,
  };

  factory Round.fromJson(Map<String, dynamic> j) => Round(
    index: j['index'],
    preset: j['preset'],
    winner: j['winner'],
    points: Map<String, int>.from(j['points']),
    isPlayerAddition: j['isPlayerAddition'] ?? false,
    addedPlayers: List<String>.from(j['addedPlayers'] ?? []),
    isPlayerRemoval: j['isPlayerRemoval'] ?? false,
    removedPlayers: List<String>.from(j['removedPlayers'] ?? []),
  );
}

class GameRecord {
  GameRecord({
    required this.id,
    required this.date,
    required this.players,
    required this.limit,
    required this.rounds,
    required this.finalScores,
    this.durationSeconds = 0,
    this.winnersCount = 2,
    this.completed = true,
    List<String>? winners,
  }) : _storedWinners = winners;

  final String id;
  final DateTime date;
  final List<String> players;
  final int limit;
  final List<Round> rounds;
  final Map<String, int> finalScores;
  final int durationSeconds;

  /// عدد الفائزين المحدد بالإعدادات وقت اللعبة.
  final int winnersCount;

  /// false إذا خرج المستخدم قبل انتهاء اللعبة — لا تُحسب في الإحصائيات.
  final bool completed;

  /// الفائزون الفعليون المخزَّنون لحظة انتهاء اللعبة. الألعاب القديمة
  /// (قبل هذا الحقل) تعتمد على الاستنتاج من النقاط في getter أدناه.
  final List<String>? _storedWinners;

  List<String> get winners {
    if (_storedWinners != null) return _storedWinners;
    final survivors =
    finalScores.entries.where((e) => e.value < limit).map((e) => e.key);
    if (survivors.isNotEmpty) return survivors.toList();
    final minScore = finalScores.values.reduce(math.min);
    return finalScores.entries
        .where((e) => e.value == minScore)
        .map((e) => e.key)
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'players': players,
    'limit': limit,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'finalScores': finalScores,
    'durationSeconds': durationSeconds,
    'winnersCount': winnersCount,
    'completed': completed,
    if (_storedWinners != null) 'winners': _storedWinners,
  };

  factory GameRecord.fromJson(Map<String, dynamic> j) => GameRecord(
    id: j['id'],
    date: DateTime.parse(j['date']),
    players: List<String>.from(j['players']),
    limit: j['limit'],
    rounds: (j['rounds'] as List).map((e) => Round.fromJson(e)).toList(),
    finalScores: Map<String, int>.from(j['finalScores']),
    durationSeconds: j['durationSeconds'] ?? 0,
    winnersCount: j['winnersCount'] ?? 2,
    completed: j['completed'] ?? true,
    winners:
    j['winners'] != null ? List<String>.from(j['winners']) : null,
  );
}

/// نتيجة تقييم قاعدة نهاية اللعبة بعد كل جولة.
class _EndEval {
  _EndEval({required this.ended, required this.newlyOut, required this.winners});
  final bool ended;
  final Set<String> newlyOut;
  final List<String> winners;
}

class _RolesData {
  _RolesData(this.silent, this.winners);
  final List<String> silent;
  final List<String> winners;
}

/*═══════════════════════════│ التخزين │═══════════════════════════*/
class ThemeManager {
  static const _key = 'theme_mode';
  static Future<ThemeMode> load() async {
    final p = await SharedPreferences.getInstance();
    final isDark = p.getBool(_key);
    if (isDark == null) return ThemeMode.system;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> save(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, mode == ThemeMode.dark);
  }
}

class SavedNames {
  static const _key = 'saved_names';
  static Future<List<String>> load() async =>
      (await SharedPreferences.getInstance()).getStringList(_key) ?? [];
  static Future<void> add(String name) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? [];
    if (!list.contains(name)) {
      list.add(name);
      await p.setStringList(_key, list);
    }
  }

  static Future<void> remove(String name) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? [];
    list.remove(name);
    await p.setStringList(_key, list);
  }
}

class SavedGames {
  static const _key = 'games_history';
  static Future<List<GameRecord>> load() async {
    final p = await SharedPreferences.getInstance();
    final data = p.getStringList(_key) ?? [];
    return data.map((s) => GameRecord.fromJson(jsonDecode(s))).toList();
  }

  static Future<void> add(GameRecord g) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? [];
    list.add(jsonEncode(g.toJson()));
    await p.setStringList(_key, list);
  }

  static Future<void> overwriteAll(List<GameRecord> games) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
        _key, games.map((g) => jsonEncode(g.toJson())).toList());
  }

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

/// لعبة جارية لم تنته بعد — تُحفظ دورياً حتى ما تضيع لو أغلق النظام
/// التطبيق فجأة (شائع على متصفحات الجوال بعد فترة بالخلفية).
class DraftGame {
  DraftGame({
    required this.players,
    required this.limit,
    required this.rounds,
    required this.durationSeconds,
    this.existingRecordId,
    this.winnersCount = 2,
  });

  final List<String> players;
  final int limit;
  final List<Round> rounds;
  final int durationSeconds;
  final String? existingRecordId;
  final int winnersCount;

  Map<String, dynamic> toJson() => {
    'players': players,
    'limit': limit,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'durationSeconds': durationSeconds,
    'existingRecordId': existingRecordId,
    'winnersCount': winnersCount,
  };

  factory DraftGame.fromJson(Map<String, dynamic> j) => DraftGame(
    players: List<String>.from(j['players']),
    limit: j['limit'],
    rounds: (j['rounds'] as List).map((e) => Round.fromJson(e)).toList(),
    durationSeconds: j['durationSeconds'] ?? 0,
    existingRecordId: j['existingRecordId'],
    winnersCount: j['winnersCount'] ?? 2,
  );
}

class DraftGameManager {
  static const _key = 'draft_game';

  static Future<void> save(DraftGame draft) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(draft.toJson()));
  }

  static Future<DraftGame?> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return null;
    try {
      return DraftGame.fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

class StatsManager {
  static const _dateKey = 'stats_reset_date';
  static Future<DateTime?> getResetDate() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString(_dateKey);
    return d != null ? DateTime.parse(d) : null;
  }

  static Future<void> setResetDate(DateTime date) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_dateKey, date.toIso8601String());
  }
}

class AppSettings {
  static const _defaults = {
    'khalasOthers': 100, 'khalasWinner': 0,
    'dablOthers': 200,   'dablWinner': 0,
    'dablLonOthers': 400,'dablLonWinner': 0,
    'khalasQuick1': 25,  'khalasQuick2': 50,
    'dablQuick1': 25,    'dablQuick2': 50,
    'dablLonQuick1': 25, 'dablLonQuick2': 100,
    'khalasEnabled': 1,  'dablEnabled': 1, 'dablLonEnabled': 1,
    'winnersCount': 2,
  };

  static Future<Map<String, int>> load() async {
    final p = await SharedPreferences.getInstance();
    return {for (final e in _defaults.entries) e.key: p.getInt(e.key) ?? e.value};
  }

  static Future<void> save(Map<String, int> s) async {
    final p = await SharedPreferences.getInstance();
    for (final e in s.entries) await p.setInt(e.key, e.value);
  }

  static int othersValue(int preset, Map<String, int> s) {
    if (preset == 100) return s['khalasOthers']!;
    if (preset == 200) return s['dablOthers']!;
    if (preset == 400) return s['dablLonOthers']!;
    return 0;
  }

  static int winnerValue(int preset, Map<String, int> s) {
    if (preset == 100) return s['khalasWinner']!;
    if (preset == 200) return s['dablWinner']!;
    if (preset == 400) return s['dablLonWinner']!;
    return 0;
  }

  /// قيمة الزر السريع (slot = 1 أو 2) حسب نوع الجولة المحدد.
  static int quickValue(int preset, int slot, Map<String, int> s) {
    if (preset == 100) return s['khalasQuick$slot'] ?? 0;
    if (preset == 200) return s['dablQuick$slot'] ?? 0;
    if (preset == 400) return s['dablLonQuick$slot'] ?? 0;
    return 0;
  }

  /// هل نوع اللعب مفعّل في الإعدادات؟
  static bool presetEnabled(int preset, Map<String, int> s) {
    if (preset == 100) return (s['khalasEnabled'] ?? 1) != 0;
    if (preset == 200) return (s['dablEnabled'] ?? 1) != 0;
    if (preset == 400) return (s['dablLonEnabled'] ?? 1) != 0;
    return true;
  }
}

class PlayerGroup {
  PlayerGroup({required this.name, required this.players});
  final String name;
  final List<String> players;
  Map<String, dynamic> toJson() => {'name': name, 'players': players};
  factory PlayerGroup.fromJson(Map<String, dynamic> j) =>
      PlayerGroup(name: j['name'], players: List<String>.from(j['players']));
}

class SavedGroups {
  static const _key = 'saved_groups';
  static Future<List<PlayerGroup>> load() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? [])
        .map((s) => PlayerGroup.fromJson(jsonDecode(s)))
        .toList();
  }
  static Future<void> _save(List<PlayerGroup> groups) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, groups.map((g) => jsonEncode(g.toJson())).toList());
  }
  static Future<void> add(PlayerGroup group) async {
    final groups = await load();
    groups.removeWhere((g) => g.name == group.name);
    groups.add(group);
    await _save(groups);
  }
  static Future<void> remove(String name) async {
    final groups = await load();
    groups.removeWhere((g) => g.name == name);
    await _save(groups);
  }
}

/*═══════════════════════════│ Widgets مشتركة │═══════════════════════════*/
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.allPlayers,
    this.size = 40,
    this.isOut = false,
  });

  final String name;
  final List<String> allPlayers;
  final double size;
  final bool isOut;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forPlayer(name, allPlayers);
    final initial = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOut
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [color, color.withValues(alpha: 0.7)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isOut ? 0 : 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

/*═══════════════════════════│ شاشة الإعداد │═══════════════════════════*/
class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});
  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController(text: '2000');
  final List<Player> _players = [];
  List<String> _savedNames = [];
  List<PlayerGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    SavedNames.load().then((v) => setState(() => _savedNames = v));
    SavedGroups.load().then((v) => setState(() => _groups = v));
    DraftGameManager.load().then((draft) {
      if (draft != null && mounted) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _offerResumeDraft(draft));
      }
    });
  }

  Future<void> _offerResumeDraft(DraftGame draft) async {
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('لعبة لم تكتمل'),
        content: Text(
            'لديك لعبة سابقة لم تُنهَ (${draft.players.join('، ')}). '
                'هل تريد استكمالها؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تجاهل'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('استكمال'),
          ),
        ],
      ),
    );

    if (resume == true) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            players: draft.players.map((n) => Player(n)).toList(),
            limit: draft.limit,
            existingRecordId: draft.existingRecordId,
            initialHistory: draft.rounds,
            initialDuration: draft.durationSeconds,
            winnersCount: draft.winnersCount,
          ),
        ),
      );
    } else {
      await DraftGameManager.clear();
    }
  }

  Future<void> _saveGroup() async {
    if (_players.length < 2) return;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حفظ المجموعة'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اسم المجموعة'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final group = PlayerGroup(name: name, players: _players.map((p) => p.name).toList());
    await SavedGroups.add(group);
    final groups = await SavedGroups.load();
    setState(() => _groups = groups);
  }

  void _loadGroup(PlayerGroup group) {
    setState(() {
      _players.clear();
      for (final name in group.players) {
        _players.add(Player(name));
      }
    });
  }

  void _addPlayer(String name) {
    name = name.trim();
    if (name.isEmpty || _players.any((p) => p.name == name)) {
      if (name.isNotEmpty) HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _players.add(Player(name)));
    SavedNames.add(name);
    if (!_savedNames.contains(name)) {
      setState(() => _savedNames.add(name));
    }
    _nameCtrl.clear();
  }

  Future<void> _start() async {
    if (_players.length < 2) return;
    final settings = await AppSettings.load();
    final winnersCount = settings['winnersCount'] ?? 2;
    if (!mounted) return;
    // لعبة عدد لاعبيها لا يتجاوز عدد الفائزين تنتهي قبل أن تبدأ
    if (_players.length <= winnersCount) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'عدد اللاعبين يجب أن يكون أكبر من عدد الفائزين ($winnersCount) '
              '— أضف لاعبين أو عدّل عدد الفائزين من الإعدادات'),
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final limit = int.tryParse(_limitCtrl.text) ?? 2000;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          players: _players.map((p) => p.clone()).toList(),
          limit: limit,
          winnersCount: winnersCount,
        ),
      ),
    );
  }

  void _toggleTheme() {
    HapticFeedback.selectionClick();
    final isCurrentlyDark = KinkanApp.themeNotifier.value == ThemeMode.dark;
    final newMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    KinkanApp.themeNotifier.value = newMode;
    ThemeManager.save(newMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final names = _players.map((p) => p.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة كنكان'),
        actions: [
          IconButton(
            tooltip: 'السجل',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.casino_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'لعبة جديدة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'أضف اللاعبين وحدد حد الخسارة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'اسم اللاعب',
                        prefixIcon: const Icon(Icons.person_add_rounded),
                        suffixIcon: _nameCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _nameCtrl.clear();
                            setState(() {});
                          },
                        )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _addPlayer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () => _addPlayer(_nameCtrl.text),
                    ),
                  ),
                ],
              ),
              if (_savedNames.where((n) => !names.contains(n)).isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('الأسماء المحفوظة',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _savedNames
                        .where((n) => !names.contains(n))
                        .map(
                          (n) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: InputChip(
                          avatar: PlayerAvatar(
                              name: n,
                              allPlayers: _savedNames,
                              size: 24),
                          label: Text(n),
                          onPressed: () => _addPlayer(n),
                          onDeleted: () async {
                            await SavedNames.remove(n);
                            setState(() => _savedNames.remove(n));
                          },
                        ),
                      ),
                    )
                        .toList(),
                  ),
                ),
              ],
              if (_groups.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.group_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('المجموعات المحفوظة', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _groups.map((g) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InputChip(
                        avatar: const Icon(Icons.group_rounded, size: 16),
                        label: Text(g.name),
                        onPressed: () => _loadGroup(g),
                        onDeleted: () async {
                          await SavedGroups.remove(g.name);
                          setState(() => _groups.remove(g));
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: _players.isEmpty
                    ? _buildEmptyState()
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'اللاعبون (${_players.length})',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (_, i) {
                          final p = _players[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: ListTile(
                                leading: PlayerAvatar(
                                    name: p.name, allPlayers: names),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: Colors.red.shade300),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    setState(
                                            () => _players.removeAt(i));
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _limitCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'حد الخسارة',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (_players.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: _saveGroup,
                    icon: const Icon(Icons.group_add_rounded),
                    label: const Text('حفظ المجموعة'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _players.length < 2 ? null : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  _players.length < 2
                      ? 'أضف لاعبين على الأقل 2'
                      : 'ابدأ اللعبة',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.groups_rounded,
          size: 80,
          color:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Text(
          'لم يتم إضافة أي لاعب بعد',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Text(
          'أدخل اسماً واضغط على + للإضافة',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

/*═══════════════════════════│ شاشة اللعب │═══════════════════════════*/
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.players,
    required this.limit,
    this.existingRecordId,
    this.initialHistory,
    this.initialDuration = 0,
    this.winnersCount = 2,
  });

  final List<Player> players;
  final int limit;
  final String? existingRecordId;
  final List<Round>? initialHistory;
  final int initialDuration;
  final int winnersCount;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  // نملك قائمة اللاعبين بالكامل داخل الـ State (نسخة من widget.players
  // تُهيّأ مرة وحدة بـinitState) بدل قراءتها مباشرة من widget في كل مكان.
  // ثبت فعلياً (بتشخيص مرئي) أن Flutter يستبدل كائن widget.players بنسخة
  // جديدة بنقاط صفرية عند الرجوع من الخلفية على الويب، بينما حقول الـ
  // State (مثل _history ورقم الجولة) تبقى سليمة دائماً — فامتلاك قائمة
  // اللاعبين كحقل State يجعلها محصّنة من نفس المشكلة.
  late List<Player> _players;

  late int _limit;
  late int _winnersCount;
  int _roundNo = 1;
  Set<String> _winners = {};
  int _preset = 0;
  Map<String, int> _settings = {
    'khalasOthers': 100, 'khalasWinner': 0,
    'dablOthers': 200,   'dablWinner': 0,
    'dablLonOthers': 400,'dablLonWinner': 0,
    'khalasQuick1': 25,  'khalasQuick2': 50,
    'dablQuick1': 25,    'dablQuick2': 50,
    'dablLonQuick1': 25, 'dablLonQuick2': 100,
    'khalasEnabled': 1,  'dablEnabled': 1, 'dablLonEnabled': 1,
    'winnersCount': 2,
  };

  final Map<String, TextEditingController> _fields = {};
  final Map<String, int> _previousScores = {};
  final List<Round> _history = [];

  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  bool _dialogOpen = false;
  List<String> _silentPlayers = [];
  List<String> _currentWinners = [];
  List<String> _secondPlace = [];

  /// هل انتهت اللعبة حسب قاعدة عدد الفائزين؟ ومن هم الفائزون النهائيون.
  bool _gameEnded = false;
  List<String> _finalWinners = [];

  /// يتغيّر عند الرجوع من الخلفية لإجبار Flutter على إعادة بناء شجرة
  /// الشاشة بالكامل (مو مجرد إعادة رسم) — يعالج بقايا رسم قديمة على
  /// المتصفحات بعد فقدان سياق العرض (GPU context) أثناء وجود التبويب
  /// بالخلفية.
  int _redrawKey = 0;

  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  int _lastSavedHistoryLength = -1;

  List<Player> get _active => _players.where((p) => !p.out).toList();
  List<String> get _playerNames =>
      _players.map((p) => p.name).toList();

  int get _realRoundsCount =>
      _history.where((r) => !r.isEvent).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _players = List.of(widget.players);
    _limit = widget.limit;
    _winnersCount = widget.winnersCount;
    _elapsedSeconds = widget.initialDuration;
    for (final p in _players) {
      _fields[p.name] = TextEditingController(text: '0');
      _previousScores[p.name] = 0;
    }

    if (widget.initialHistory != null) {
      _history.addAll(
          widget.initialHistory!.map((r) => Round.fromJson(r.toJson())));
    }
    _roundNo = _realRoundsCount + 1;
    _lastSavedHistoryLength = _history.length;

    AppSettings.load().then((s) => setState(() => _settings = s));

    _refreshDefaultPoints();
    _recalcTotals(isInit: true);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    // إجراء دفاعي لعلة "الإطار القديم" على iOS: أول رسمة لشاشة لعب جديدة
    // (مثل استكمال لعبة محفوظة بعد إعادة تشغيل التطبيق) قد تعرض محتوى
    // قديماً رغم سلامة البيانات — نجبر إعادة بناء الشجرة بعد أول إطار.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _redrawKey++);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameTimer?.cancel();
    _confetti.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // على المتصفحات (ويب/PWA)، الشاشة قد تعرض إطاراً قديماً بعد الرجوع من
    // الخلفية رغم أن البيانات سليمة — نعيد حساب النقاط من السجل (مصدر
    // الحقيقة) ونغيّر _redrawKey لإجبار إعادة بناء شجرة الشاشة بالكامل.
    // isInit:true يتجنب إعادة إطلاق نافذة "مبروك" أو حفظ مسودة إضافية.
    if (state == AppLifecycleState.resumed && mounted) {
      _recalcTotals(isInit: true);
      setState(() => _redrawKey++);
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _refreshDefaultPoints() {
    for (final p in _active) {
      final ctrl = _fields[p.name]!;
      if (_preset == 0) {
        ctrl.text = '0';
      } else if (_winners.contains(p.name)) {
        final w = AppSettings.winnerValue(_preset, _settings);
        ctrl.text = w > 0 ? '-$w' : '0';
      } else {
        ctrl.text = '${AppSettings.othersValue(_preset, _settings)}';
      }
    }
    setState(() {});
  }

  void _togglePreset(int value) {
    HapticFeedback.selectionClick();
    _preset = (_preset == value) ? 0 : value;
    _winners.clear();
    _refreshDefaultPoints();
  }

  void _toggleWinner(String name) {
    HapticFeedback.lightImpact();
    if (_winners.contains(name)) {
      _winners.remove(name);
    } else {
      _winners.add(name);
    }
    _refreshDefaultPoints();
  }

  void _addQuick(String playerName, int amount) {
    HapticFeedback.lightImpact();
    final ctrl = _fields[playerName]!;
    int current = int.tryParse(ctrl.text) ?? 0;
    current += amount;
    ctrl.text = current.toString();
    _recalcTotals();
  }

  void _recalcTotals({bool isInit = false}) {
    // نحسب على نسخ مؤقتة من اللاعبين، ولا نطبّق النتيجة على الحالة
    // الحقيقية (_players) إلا بعد نجاح إعادة تشغيل السجل بالكامل.
    // هذا يمنع نصف حساب فاشل (استثناء غير متوقع) من ترك نقاط اللاعبين
    // مصفّرة نهائياً — لو صار خطأ، تبقى آخر نقاط صحيحة كما هي بدل ما
    // تنصفر بصمت (شفنا هذا يصير فعلياً عند الرجوع من الخلفية).
    final working = _players.map((p) => p.clone()).toList();

    List<String> stepSilent = [];
    List<String> stepWinners = [];
    final Set<String> outNames = {};
    bool ended = false;
    List<String> finalWinners = [];

    try {
      for (int i = 0; i < _history.length; i++) {
        final r = _history[i];
        r.points.forEach((n, v) {
          final player = working.firstWhere(
                (p) => p.name == n,
            orElse: () => Player(''),
          );
          if (player.name.isNotEmpty) player.score += v;
        });

        if (r.isEvent) continue;

        // تقييم قاعدة نهاية اللعبة على من لم يخرج بعد
        final eval = _evaluateEnd(
            working.where((p) => !outNames.contains(p.name)).toList());
        outNames.addAll(eval.newlyOut);
        ended = eval.ended;
        finalWinners = eval.winners;

        for (final p in working) {
          p.out = outNames.contains(p.name);
        }

        final roles = _computeRoles(
          activePlayers: working.where((p) => !p.out).toList(),
          previousSilent: stepSilent,
          lastWinner: r.winner.split(',').first.trim(),
          historySubset: _history.sublist(0, i + 1),
        );
        stepSilent = roles.silent;
        stepWinners = roles.winners;
      }
    } catch (e, st) {
      debugPrint('kinkan: _recalcTotals فشلت، تم تجاهل النتيجة والاحتفاظ '
          'بآخر نقاط صحيحة: $e\n$st');
      return;
    }

    // نجاح كامل — الآن فقط نطبّق النتائج على اللاعبين الحقيقيين
    for (final p in _players) {
      _previousScores[p.name] = p.score;
      final w = working.firstWhere((x) => x.name == p.name, orElse: () => p);
      p.score = w.score;
      p.out = w.out;
    }

    final hasRealRound = _history.any((r) => !r.isEvent);

    _silentPlayers = hasRealRound ? stepSilent : [];
    _currentWinners = hasRealRound ? stepWinners : [];
    // الفضي يظهر فقط إذا كان عدد المتصدرين (الذهبي) أقل من عدد الفائزين،
    // حتى لا يوحي العرض بعدد فائزين أكبر من المحدد للعبة.
    _secondPlace = hasRealRound && stepWinners.length < _winnersCount
        ? rankTiers({for (final p in _active) p.name: p.score})
        .skip(1)
        .take(1)
        .expand((tier) => tier)
        .toList()
        : [];

    _gameEnded = ended;
    _finalWinners = finalWinners;

    if (!isInit) {
      _checkForWinners();
      setState(() {});
      if (_history.length != _lastSavedHistoryLength) {
        _lastSavedHistoryLength = _history.length;
        _saveDraft();
      }
    }
  }

  Future<void> _saveDraft() async {
    await DraftGameManager.save(DraftGame(
      players: _players.map((p) => p.name).toList(),
      limit: _limit,
      rounds: List.of(_history),
      durationSeconds: _elapsedSeconds,
      existingRecordId: widget.existingRecordId,
      winnersCount: _winnersCount,
    ));
  }

  /// قاعدة نهاية اللعبة:
  /// - آمنون (تحت الحد) أكثر من عدد الفائزين → اللعبة مستمرة والمتجاوزون
  ///   يخرجون خاسرين.
  /// - آمنون بعددٍ من 1 إلى عدد الفائزين → تنتهي اللعبة والآمنون هم
  ///   الفائزون فقط (ولو أقل من العدد المحدد)، وكل المتجاوزين خاسرون.
  /// - لا آمن إطلاقاً (الكل تجاوز بنفس الجولة) → تُملأ مقاعد الفائزين من
  ///   المتجاوزين بمجموعات متساوية النقاط تصاعدياً: ملء تام أو جزئي يُنهي
  ///   اللعبة بالمقبولين فقط (والباقي خاسر نهائياً). وإن كانت أول مجموعة
  ///   متعادلة أكبر من المقاعد، تلك المجموعة وحدها تكمل اللعب، وأي مجموعة
  ///   أعلى منها نقاطاً تخرج نهائياً كخاسرة فوراً.
  _EndEval _evaluateEnd(List<Player> players) {
    final safe = players.where((p) => p.score < _limit).toList();
    final crossed = players.where((p) => p.score >= _limit).toList();

    if (safe.length > _winnersCount) {
      return _EndEval(
        ended: false,
        newlyOut: crossed.map((p) => p.name).toSet(),
        winners: [],
      );
    }
    if (safe.isNotEmpty) {
      return _EndEval(
        ended: true,
        newlyOut: crossed.map((p) => p.name).toSet(),
        winners: safe.map((p) => p.name).toList(),
      );
    }
    if (crossed.isEmpty) {
      return _EndEval(ended: false, newlyOut: {}, winners: []);
    }

    final tiers = rankTiers({for (final p in crossed) p.name: p.score});
    final seated = <String>[];
    int remaining = _winnersCount;
    int contestedIndex = -1;
    for (int i = 0; i < tiers.length; i++) {
      if (tiers[i].length > remaining) {
        contestedIndex = i;
        break;
      }
      seated.addAll(tiers[i]);
      remaining -= tiers[i].length;
      if (remaining == 0) break;
    }

    if (seated.isEmpty) {
      // أول مجموعة متعادلة أكبر من المقاعد المتاحة: تعادل يمنع فصل
      // الفائزين ضمن هذي المجموعة تحديداً — تكمل اللعب وحدها، وأي مجموعة
      // أعلى منها نقاطاً تخرج نهائياً كخاسرة (أسوأ منها بلا جدال).
      final higherLosers =
      tiers.skip(contestedIndex + 1).expand((t) => t).toSet();
      return _EndEval(ended: false, newlyOut: higherLosers, winners: []);
    }
    return _EndEval(
      ended: true,
      newlyOut: crossed
          .where((p) => !seated.contains(p.name))
          .map((p) => p.name)
          .toSet(),
      winners: seated,
    );
  }

  _RolesData _computeRoles({
    required List<Player> activePlayers,
    required List<String> previousSilent,
    required String lastWinner,
    required List<Round> historySubset,
  }) {
    if (activePlayers.isEmpty) return _RolesData([], []);

    int numSilent = activePlayers.length == 3 ? 1 : 2;
    if (activePlayers.length <= 2) numSilent = 0;

    List<Player> active = List.from(activePlayers);
    active.sort((a, b) => b.score.compareTo(a.score));
    List<String> newSilent = [];

    if (numSilent > 0) {
      int cutoffScore = active[numSilent - 1].score;

      List<String> aboveCutoff = active
          .where((p) => p.score > cutoffScore)
          .map((e) => e.name)
          .toList();

      List<String> tiedAtCutoff = active
          .where((p) => p.score == cutoffScore)
          .map((e) => e.name)
          .toList();

      newSilent.addAll(aboveCutoff);
      int needed = numSilent - aboveCutoff.length;

      if (needed > 0) {
        List<String> previouslySilentTied = tiedAtCutoff
            .where((name) => previousSilent.contains(name))
            .toList();

        if (previouslySilentTied.length >= needed) {
          previouslySilentTied =
              _sortByCircularOrder(previouslySilentTied, lastWinner);
          newSilent.addAll(previouslySilentTied.take(needed));
        } else {
          newSilent.addAll(previouslySilentTied);
          needed -= previouslySilentTied.length;
          tiedAtCutoff
              .removeWhere((name) => previouslySilentTied.contains(name));
          List<String> orderedTies =
          _sortByCircularOrder(tiedAtCutoff, lastWinner);
          newSilent.addAll(orderedTies.take(needed));
        }
      }
    }

    int minScore = active.map((p) => p.score).reduce(math.min);
    List<String> currentWinners = active
        .where((p) => p.score == minScore)
        .map((p) => p.name)
        .toList();

    return _RolesData(newSilent, currentWinners);
  }

  List<String> _sortByCircularOrder(
      List<String> playersToSort, String lastWinnerName) {
    List<String> originalOrder = _players.map((p) => p.name).toList();
    int startIndex = 0;
    if (lastWinnerName.isNotEmpty) {
      int wIdx = originalOrder.indexOf(lastWinnerName);
      if (wIdx != -1) {
        startIndex = (wIdx + 1) % originalOrder.length;
      }
    }
    List<String> result = [];
    for (int i = 0; i < originalOrder.length; i++) {
      int idx = (startIndex + i) % originalOrder.length;
      String candidate = originalOrder[idx];
      if (playersToSort.contains(candidate)) {
        result.add(candidate);
      }
    }
    return result;
  }

  void _checkForWinners() {
    if (_dialogOpen) return;
    if (_gameEnded && _finalWinners.isNotEmpty) {
      _dialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCongrats());
    }
  }

  void _showCongrats() async {
    HapticFeedback.heavyImpact();
    final winnersToShow = _players
        .where((p) => _finalWinners.contains(p.name))
        .toList();
    winnersToShow.sort((a, b) => a.score.compareTo(b.score));
    final winnerTiers =
    rankTiers({for (final p in winnersToShow) p.name: p.score});
    Color? medalColor(String name) {
      final idx = winnerTiers.indexWhere((t) => t.contains(name));
      if (idx == 0) return AppColors.gold;
      if (idx == 1) return AppColors.silver;
      return null;
    }

    final String titleText =
    winnersToShow.length > 1 ? 'مبروك للفائزين! 🎉' : 'مبروك للفائز! 🎉';

    _confetti.play();
    _gameTimer?.cancel();

    await showDialog(
      context: context,
      builder: (_) => Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              AppColors.accent,
              AppColors.primary,
              AppColors.success,
              Colors.pink,
              Colors.cyan,
            ],
          ),
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: AppColors.accent, size: 48),
                ),
                const SizedBox(height: 12),
                Text(titleText,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: winnersToShow
                  .map(
                    (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (medalColor(p.name) != null) ...[
                        Icon(Icons.emoji_events_rounded,
                            color: medalColor(p.name), size: 20),
                        const SizedBox(width: 4),
                      ],
                      PlayerAvatar(
                          name: p.name,
                          allPlayers: _playerNames,
                          size: 36),
                      const SizedBox(width: 12),
                      Text(
                        p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                          AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p.score}',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('استمر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  void _saveRound() {
    HapticFeedback.mediumImpact();
    final pts = <String, int>{
      for (final p in _active)
        p.name: int.tryParse(_fields[p.name]!.text) ?? 0
    };

    _history.add(Round(
      index: _realRoundsCount + 1,
      preset: _preset,
      winner: _winners.join(', '),
      points: pts,
    ));

    _roundNo = _realRoundsCount + 1;
    _winners.clear();
    _preset = 0;
    _refreshDefaultPoints();
    _recalcTotals();
  }

  Future<void> _undoLastRound() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد التراجع'),
        content: const Text('هل أنت متأكد من التراجع عن آخر إدخال وحذفه؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (ok == true && _history.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        final last = _history.removeLast();
        if (last.isPlayerAddition) {
          _players
              .removeWhere((p) => last.addedPlayers.contains(p.name));
          for (final n in last.addedPlayers) {
            _fields.remove(n);
          }
        } else if (last.isPlayerRemoval) {
          for (final n in last.removedPlayers) {
            _players.add(Player(n));
            _fields[n] = TextEditingController(text: '0');
            _previousScores[n] = 0;
          }
        }
        _roundNo = _realRoundsCount + 1;
        _recalcTotals();
      });
    }
  }

  void _editRound(Round r) async {
    final ctrls = {
      for (final e in r.points.entries)
        e.key: TextEditingController(text: e.value.toString())
    };

    await showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('تعديل الجولة رقم ${r.index}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 20),
            ...ctrls.entries.map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    PlayerAvatar(
                        name: e.key, allPlayers: _playerNames, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: e.value,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        onTap: () {
                          e.value.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: e.value.text.length,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                r.points = {
                  for (final e in ctrls.entries)
                    e.key: int.tryParse(e.value.text) ?? 0
                };
                Navigator.pop(context);
                _recalcTotals();
                _saveDraft();
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ التعديلات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGameToHistory() async {
    final record = GameRecord(
      id: widget.existingRecordId ?? const Uuid().v4(),
      date: DateTime.now(),
      players: _players.map((p) => p.name).toList(),
      limit: _limit,
      rounds: List.of(_history),
      finalScores: {for (final p in _players) p.name: p.score},
      durationSeconds: _elapsedSeconds,
      winnersCount: _winnersCount,
      completed: _gameEnded,
      winners: _gameEnded ? List.of(_finalWinners) : <String>[],
    );

    if (widget.existingRecordId != null) {
      final allGames = await SavedGames.load();
      allGames.removeWhere((g) => g.id == widget.existingRecordId);
      allGames.add(record);
      await SavedGames.overwriteAll(allGames);
    } else {
      await SavedGames.add(record);
    }
    await DraftGameManager.clear();
  }

  Future<bool> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إنهاء اللعبة؟'),
        content: Text(!_gameEnded
            ? 'اللعبة لم تنتهِ بعد — ستُحفظ كلعبة غير مكتملة ولن تُحسب في '
                'الإحصائيات، ويمكنك استكمالها لاحقاً من السجل.'
            : widget.existingRecordId != null
                ? 'بالرجوع سيتم تحديث هذه اللعبة في السجل ولن تفقد بياناتها.'
                : 'بالرجوع ستُحفظ هذه اللعبة في السجل ويبدأ حساب جديد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );
    if (ok == true) await _saveGameToHistory();
    return ok ?? false;
  }

  int _playerTotalBeforeRound(String player, int roundIndex) {
    int total = 0;
    for (final r in _history) {
      if (r.isPlayerAddition) {
        if (r.points.containsKey(player)) {
          total += r.points[player]!;
        }
        continue;
      }
      if (r.index >= roundIndex) break;
      total += r.points[player] ?? 0;
    }
    return total;
  }

  String _getPresetName(int p) {
    if (p == 400) return 'دبل لون';
    if (p == 200) return 'دبل';
    if (p == 100) return 'خالص';
    return 'صفر';
  }

  Color _scoreProgressColor(int score) {
    final ratio = score / _limit;
    if (ratio < 0.5) return AppColors.success;
    if (ratio < 0.75) return AppColors.warning;
    return AppColors.danger;
  }

  // ─── إعدادات اللعبة ───
  void _openGameSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _GameSettingsSheet(
        currentLimit: _limit,
        onLimitChanged: (newLimit) {
          setState(() {
            _limit = newLimit;
            _recalcTotals();
          });
        },
        onEditPlayers: () {
          Navigator.pop(ctx);
          _openEditPlayers();
        },
      ),
    );
  }

  void _openEditPlayers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditPlayersSheet(
        players: _players.map((p) => p.name).toList(),
        onSave: (renames, newPlayers, finalOrder) {
          _applyPlayerEdits(renames, newPlayers, finalOrder);
        },
      ),
    );
  }

  void _applyPlayerEdits(
      Map<String, String> renames, List<String> newPlayers, List<String> finalOrder) {
    HapticFeedback.mediumImpact();

    if (renames.isNotEmpty) {
      for (final entry in renames.entries) {
        final oldName = entry.key;
        final newName = entry.value;
        if (oldName == newName) continue;

        final playerIdx =
        _players.indexWhere((p) => p.name == oldName);
        if (playerIdx == -1) continue;

        final oldPlayer = _players[playerIdx];
        _players[playerIdx] = Player(newName)
          ..score = oldPlayer.score
          ..out = oldPlayer.out;

        final oldCtrl = _fields.remove(oldName);
        if (oldCtrl != null) _fields[newName] = oldCtrl;

        if (_previousScores.containsKey(oldName)) {
          _previousScores[newName] = _previousScores.remove(oldName)!;
        }

        for (final r in _history) {
          if (r.points.containsKey(oldName)) {
            r.points = {
              for (final e in r.points.entries)
                (e.key == oldName ? newName : e.key): e.value
            };
          }
        }

        SavedNames.add(newName);
      }
    }

    // Remove players deleted in the sheet (post-rename names not in finalOrder)
    final removedNames = _players
        .map((p) => p.name)
        .where((n) => !finalOrder.contains(n))
        .toList();
    if (removedNames.isNotEmpty) {
      for (final name in removedNames) {
        _players.removeWhere((p) => p.name == name);
        _fields.remove(name)?.dispose();
        _previousScores.remove(name);
      }
      _history.add(Round(
        index: _realRoundsCount,
        preset: 0,
        winner: '',
        points: const {},
        isPlayerRemoval: true,
        removedPlayers: List.from(removedNames),
      ));
    }

    if (newPlayers.isNotEmpty) {
      int maxScore = 0;
      for (final p in _players) {
        if (p.score > maxScore) maxScore = p.score;
      }
      final startingScore = maxScore > 0 ? maxScore + 1 : 0;

      for (final name in newPlayers) {
        _players.add(Player(name));
        _fields[name] = TextEditingController(text: '0');
        _previousScores[name] = 0;
        SavedNames.add(name);
      }

      final additionEntry = Round(
        index: _realRoundsCount,
        preset: 0,
        winner: '',
        points: {for (final n in newPlayers) n: startingScore},
        isPlayerAddition: true,
        addedPlayers: List.from(newPlayers),
      );
      _history.add(additionEntry);
    }

    // Reorder _players to match the order the user set in the sheet.
    // finalOrder contains new names (post-rename) for existing players + new players.
    if (finalOrder.isNotEmpty) {
      final nameToPlayer = <String, Player>{
        for (final p in _players) p.name: p
      };
      final reordered = finalOrder
          .map((n) => nameToPlayer[n])
          .whereType<Player>()
          .toList();
      if (reordered.length == _players.length) {
        _players
          ..clear()
          ..addAll(reordered);
      }
    }

    setState(() {
      _recalcTotals();
    });
  }

  void _openRoundsHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoundsHistoryScreen(
          history: _history,
          allPlayers: _players.map((p) => p.name).toList(),
          onEditRound: (r) {
            Navigator.pop(context);
            _editRound(r);
          },
          getPresetName: _getPresetName,
          playerTotalBeforeRound: _playerTotalBeforeRound,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      final bool shouldPop = await _confirmExit();
      if (shouldPop && context.mounted) {
        Navigator.of(context).pop();
      }
    },
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('حاسبة كنكان'),
            Text(
              '⏱ ${_formatDuration(_elapsedSeconds)}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إعدادات اللعبة',
            icon: const Icon(Icons.settings_rounded),
            onPressed: _openGameSettings,
          ),
          IconButton(
            tooltip: 'سجل الجولات',
            icon: const Icon(Icons.list_alt_rounded),
            onPressed:
            _history.isEmpty ? null : _openRoundsHistoryScreen,
          ),
          IconButton(
            tooltip: 'تراجع عن آخر إدخال',
            icon: const Icon(Icons.undo_rounded),
            onPressed: _history.isEmpty ? null : _undoLastRound,
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(_redrawKey),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.casino_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الجولة $_roundNo',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                    if (_silentPlayers.isNotEmpty ||
                        _currentWinners.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (_silentPlayers.isNotEmpty)
                            _buildRankChip(
                              icon: Icons.volume_off_rounded,
                              label: '🃏 الموزّعون',
                              names: _silentPlayers.join('، '),
                              color: AppColors.danger,
                            ),
                          if (_currentWinners.isNotEmpty)
                            _buildRankChip(
                              icon: Icons.emoji_events_rounded,
                              label: 'الأول',
                              names: _currentWinners.join('، '),
                              color: AppColors.gold,
                            ),
                          if (_secondPlace.isNotEmpty)
                            _buildRankChip(
                              icon: Icons.emoji_events_rounded,
                              label: 'الثاني',
                              names: _secondPlace.join('، '),
                              color: AppColors.silver,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildPresetSelector(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                      bottom:
                      MediaQuery.of(context).viewInsets.bottom),
                  itemCount: _active.length,
                  itemBuilder: (_, i) =>
                      _buildPlayerInputCard(_active[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _saveRound,
                  icon: const Icon(Icons.check_circle_rounded,
                      size: 24),
                  label: const Text(
                    'حفظ الجولة',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              _buildScoresSection(),
            ],
          ),
        ),
        ),
      ),
    ),
  );

  Widget _buildPresetSelector() {
    final presets = [
      {'value': 100, 'label': 'خالص', 'icon': Icons.looks_one_rounded,
       'display': _settings['khalasOthers']},
      {'value': 200, 'label': 'دبل', 'icon': Icons.looks_two_rounded,
       'display': _settings['dablOthers']},
      {'value': 400, 'label': 'دبل لون', 'icon': Icons.palette_rounded,
       'display': _settings['dablLonOthers']},
    ]
        .where((p) =>
            AppSettings.presetEnabled(p['value'] as int, _settings))
        .toList();

    return Row(
      children: presets.map((p) {
        final isSelected = _preset == p['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _togglePreset(p['value'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark
                    ],
                  )
                      : null,
                  color: isSelected
                      ? null
                      : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      p['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${p['display']}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : Theme.of(context).colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerInputCard(Player p) {
    final isWinner = _winners.contains(p.name);
    final ctrl = _fields[p.name]!;
    final progress = (p.score / _limit).clamp(0.0, 1.0);
    final progressColor = _scoreProgressColor(p.score);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleWinner(p.name),
                  child: Stack(
                    children: [
                      PlayerAvatar(
                          name: p.name,
                          allPlayers: _playerNames,
                          size: 44),
                      if (isWinner)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${p.score} / $_limit',
                            style: TextStyle(
                                fontSize: 11,
                                color: progressColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                          AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                    ),
                    onTap: () {
                      ctrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: ctrl.text.length,
                      );
                    },
                    onChanged: (_) => _recalcTotals(),
                  ),
                ),
              ],
            ),
            // زرّان سريعان بقيم قابلة للتعديل حسب نوع الجولة المحدد
            if (_preset != 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _quickActionButton(
                        label: '+${AppSettings.quickValue(_preset, 1, _settings)}',
                        onTap: () => _addQuick(p.name,
                            AppSettings.quickValue(_preset, 1, _settings)),
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _quickActionButton(
                        label: '+${AppSettings.quickValue(_preset, 2, _settings)}',
                        onTap: () => _addQuick(p.name,
                            AppSettings.quickValue(_preset, 2, _settings)),
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankChip({
    required IconData icon,
    required String names,
    required Color color,
    String? label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          if (label != null) ...[
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
          Text(
            names,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'النقاط الحالية',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _players.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: p.out
                      ? AppColors.danger.withValues(alpha: 0.15)
                      : AppColors.forPlayer(p.name, _playerNames)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: p.out
                        ? AppColors.danger.withValues(alpha: 0.4)
                        : AppColors.forPlayer(p.name, _playerNames)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayerAvatar(
                      name: p.name,
                      allPlayers: _playerNames,
                      size: 20,
                      isOut: p.out,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${p.name}: ${p.score}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: p.out
                            ? AppColors.danger
                            : Theme.of(context).colorScheme.onSurface,
                        decoration:
                        p.out ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// نهاية الجزء الأول
// انتقل للجزء الثاني وألصقه مباشرة بعد هذا الجزء في نفس الملف
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
// lib/main.dart - PART 2 of 2
// الصق هذا الجزء مباشرة بعد الجزء الأول في نفس الملف
// ═══════════════════════════════════════════════════════════════════

/*═══════════════════════════│ شاشة سجل الجولات الكاملة │═══════════════════════════*/
class RoundsHistoryScreen extends StatelessWidget {
  const RoundsHistoryScreen({
    super.key,
    required this.history,
    required this.allPlayers,
    required this.onEditRound,
    required this.getPresetName,
    required this.playerTotalBeforeRound,
  });

  final List<Round> history;
  final List<String> allPlayers;
  final void Function(Round) onEditRound;
  final String Function(int) getPresetName;
  final int Function(String, int) playerTotalBeforeRound;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('سجل الجولات')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              const Text('لم تبدأ أي جولات بعد'),
            ],
          ),
        ),
      );
    }

    final reversed = history.reversed.toList();
    final realRoundsCount = history.where((r) => !r.isEvent).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل الجولات ($realRoundsCount)'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: reversed.length,
        itemBuilder: (_, i) {
          final r = reversed[i];
          if (r.isPlayerAddition) {
            return _PlayerAdditionCard(round: r, allPlayers: allPlayers);
          }
          if (r.isPlayerRemoval) {
            return _PlayerRemovalCard(round: r);
          }
          return _RoundDetailCard(
            round: r,
            allPlayers: allPlayers,
            onEdit: () => onEditRound(r),
            getPresetName: getPresetName,
            playerTotalBeforeRound: playerTotalBeforeRound,
          );
        },
      ),
    );
  }
}

/*═══════════════════════════│ كرت جولة في سجل الجولات │═══════════════════════════*/
class _RoundDetailCard extends StatelessWidget {
  const _RoundDetailCard({
    required this.round,
    required this.allPlayers,
    required this.onEdit,
    required this.getPresetName,
    required this.playerTotalBeforeRound,
  });

  final Round round;
  final List<String> allPlayers;
  final VoidCallback onEdit;
  final String Function(int) getPresetName;
  final int Function(String, int) playerTotalBeforeRound;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'جولة ${round.index}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    getPresetName(round.preset),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.warning),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: onEdit,
                ),
              ],
            ),
            const Divider(height: 16),
            ...round.points.entries.map((e) {
              final before = playerTotalBeforeRound(e.key, round.index);
              final added = e.value;
              final after = before + added;
              final color = AppColors.forPlayer(e.key, allPlayers);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    PlayerAvatar(
                        name: e.key, allPlayers: allPlayers, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$before',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                          AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+$added',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_back_rounded,
                        size: 22, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$after',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/*═══════════════════════════│ كرت إضافة لاعبين │═══════════════════════════*/
class _PlayerAdditionCard extends StatelessWidget {
  const _PlayerAdditionCard(
      {required this.round, required this.allPlayers});

  final Round round;
  final List<String> allPlayers;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.blue.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'إضافة لاعبين',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue),
                ),
              ],
            ),
            const Divider(height: 16),
            ...round.points.entries.map((e) {
              final color = AppColors.forPlayer(e.key, allPlayers);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    PlayerAvatar(
                        name: e.key, allPlayers: allPlayers, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                    ),
                    const Text('نقاط البداية: ',
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/*═══════════════════════════│ كرت حذف لاعبين │═══════════════════════════*/
class _PlayerRemovalCard extends StatelessWidget {
  const _PlayerRemovalCard({required this.round});
  final Round round;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.danger.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppColors.danger.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_remove_rounded,
                      color: AppColors.danger, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'حذف لاعبين',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.danger),
                ),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: round.removedPlayers
                  .map((name) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off_rounded,
                                size: 14, color: AppColors.danger),
                            const SizedBox(width: 5),
                            Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.danger),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/*═══════════════════════════│ ورقة إعدادات اللعبة │═══════════════════════════*/
class _GameSettingsSheet extends StatefulWidget {
  const _GameSettingsSheet({
    required this.currentLimit,
    required this.onLimitChanged,
    required this.onEditPlayers,
  });

  final int currentLimit;
  final void Function(int) onLimitChanged;
  final VoidCallback onEditPlayers;

  @override
  State<_GameSettingsSheet> createState() => _GameSettingsSheetState();
}

class _GameSettingsSheetState extends State<_GameSettingsSheet> {
  late TextEditingController _limitCtrl;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(text: '${widget.currentLimit}');
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.settings_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('إعدادات اللعبة',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('حد الخسارة',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _limitCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final v = int.tryParse(_limitCtrl.text);
                  if (v != null && v > 0) {
                    widget.onLimitChanged(v);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تم تحديث حد الخسارة إلى $v'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('حفظ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group_rounded, color: Colors.blue),
            ),
            title: const Text('تعديل اللاعبين',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text(
                'تعديل أسماء اللاعبين أو إضافة لاعبين جدد',
                style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_back_ios_rounded, size: 16),
            onTap: widget.onEditPlayers,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/*═══════════════════════════│ ورقة تعديل اللاعبين │═══════════════════════════*/
class _PlayerEntry {
  _PlayerEntry({required this.ctrl, this.originalName});
  final TextEditingController ctrl;
  final String? originalName;
  bool get isNew => originalName == null;
}

class _EditPlayersSheet extends StatefulWidget {
  const _EditPlayersSheet({
    required this.players,
    required this.onSave,
  });

  final List<String> players;
  final void Function(
    Map<String, String> renames,
    List<String> newPlayers,
    List<String> finalOrder,
  ) onSave;

  @override
  State<_EditPlayersSheet> createState() => _EditPlayersSheetState();
}

class _EditPlayersSheetState extends State<_EditPlayersSheet> {
  late List<_PlayerEntry> _entries;
  final _newNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entries = widget.players
        .map((n) => _PlayerEntry(
              ctrl: TextEditingController(text: n),
              originalName: n,
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.ctrl.dispose();
    }
    _newNameCtrl.dispose();
    super.dispose();
  }

  void _addNew() {
    final name = _newNameCtrl.text.trim();
    if (name.isEmpty) return;

    final allCurrent = _entries.map((e) => e.ctrl.text.trim()).toList();
    if (allCurrent.contains(name)) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا الاسم موجود مسبقًا'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _entries.add(_PlayerEntry(ctrl: TextEditingController(text: name)));
      _newNameCtrl.clear();
    });
  }

  void _save() {
    final Map<String, String> renames = {};
    final List<String> newPlayers = [];
    final List<String> finalOrder = [];

    for (final entry in _entries) {
      final name = entry.ctrl.text.trim();
      if (name.isEmpty) continue;
      finalOrder.add(name);
      if (entry.isNew) {
        newPlayers.add(name);
      } else if (entry.originalName != name) {
        renames[entry.originalName!] = name;
      }
    }

    final remainingOriginalNames = _entries
        .where((e) => !e.isNew)
        .map((e) => e.originalName!)
        .toSet();
    final hasDeleted =
        widget.players.any((p) => !remainingOriginalNames.contains(p));
    final deletedCount =
        widget.players.where((p) => !remainingOriginalNames.contains(p)).length;

    // Compare entry order against original order filtered to survivors
    final survivorsInOriginalOrder = widget.players
        .where((p) => remainingOriginalNames.contains(p))
        .toList();
    final existingInEntryOrder = _entries
        .where((e) => !e.isNew)
        .map((e) => e.originalName!)
        .toList();
    bool orderChanged = false;
    for (int i = 0; i < existingInEntryOrder.length; i++) {
      if (i >= survivorsInOriginalOrder.length ||
          existingInEntryOrder[i] != survivorsInOriginalOrder[i]) {
        orderChanged = true;
        break;
      }
    }

    if (renames.isEmpty && newPlayers.isEmpty && !orderChanged && !hasDeleted) {
      Navigator.pop(context);
      return;
    }

    widget.onSave(renames, newPlayers, finalOrder);
    Navigator.pop(context);

    final msgs = <String>[];
    if (renames.isNotEmpty) msgs.add('تم تعديل ${renames.length} لاعب');
    if (newPlayers.isNotEmpty) msgs.add('تم إضافة ${newPlayers.length} لاعب جديد');
    if (hasDeleted) msgs.add('تم حذف $deletedCount لاعب');
    if (orderChanged) msgs.add('تم تحديث الترتيب');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${msgs.join(" • ")}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.group_rounded, color: Colors.blue),
                SizedBox(width: 8),
                Text('تعديل اللاعبين',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'اسحب ↕ لتغيير الترتيب — يؤثر على تحديد الساكتين',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _entries.removeAt(oldIndex);
                        _entries.insert(newIndex, item);
                      });
                    },
                    children: List.generate(_entries.length, (i) {
                      final entry = _entries[i];
                      final allNames =
                          _entries.map((e) => e.ctrl.text).toList();

                      if (entry.isNew) {
                        return Container(
                          key: ObjectKey(entry.ctrl),
                          margin:
                              const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: Colors.grey),
                                ),
                              ),
                              const Icon(Icons.person_rounded,
                                  color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: entry.ctrl,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    fillColor: Colors.transparent,
                                    filled: false,
                                  ),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.danger),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    entry.ctrl.dispose();
                                    _entries.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        key: ObjectKey(entry.ctrl),
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Icon(
                                    Icons.drag_handle_rounded,
                                    color: Colors.grey),
                              ),
                            ),
                            PlayerAvatar(
                                name: entry.ctrl.text,
                                allPlayers: allNames),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: entry.ctrl,
                                decoration: InputDecoration(
                                  hintText: entry.originalName,
                                  prefixIcon: const Icon(
                                      Icons.edit_rounded,
                                      size: 18),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger),
                              onPressed: () {
                                final remaining = _entries.length - 1;
                                if (remaining < 2) {
                                  HapticFeedback.heavyImpact();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'يجب أن يبقى لاعبان على الأقل'),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ));
                                  return;
                                }
                                HapticFeedback.lightImpact();
                                setState(() {
                                  entry.ctrl.dispose();
                                  _entries.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.person_add_rounded,
                          color: AppColors.success, size: 18),
                      SizedBox(width: 6),
                      Text('إضافة لاعبين جدد',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'سيبدأ كل لاعب جديد بنقاط = أعلى لاعب + 1',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newNameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'اسم اللاعب الجديد',
                            prefixIcon:
                                Icon(Icons.person_add_alt_rounded),
                          ),
                          onSubmitted: (_) => _addNew(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.white),
                          onPressed: _addNew,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('حفظ التغييرات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*═══════════════════════════│ شاشة السجل │═══════════════════════════*/
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<GameRecord>> _future;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = SavedGames.load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async =>
      setState(() => _future = SavedGames.load());

  void _shareGame(GameRecord g) {
    final d = g.date;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final buffer = StringBuffer()
      ..writeln('🎴 لعبة كنكان - $dateStr')
      ..writeln('━━━━━━━━━━━━━━━━━━')
      ..writeln(g.completed
          ? '🏆 الفائزون: ${g.winners.join("، ")}'
          : '⏸ لعبة غير مكتملة')
      ..writeln('🎯 حد الخسارة: ${g.limit}')
      ..writeln('📊 عدد الجولات: ${g.rounds.where((r) => !r.isEvent).length}')
      ..writeln('')
      ..writeln('النقاط النهائية:');
    for (final e in g.finalScores.entries) {
      buffer.writeln('• ${e.key}: ${e.value}');
    }
    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('سجلّ الألعاب'),
      actions: [
        IconButton(
          tooltip: 'الإحصائيات',
          icon: const Icon(Icons.leaderboard_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const TopWinnersScreen()),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو التاريخ...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<GameRecord>>(
            future: _future,
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              var list = snap.data!;
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                list = list.where((g) {
                  final dateStr =
                      '${g.date.year}-${g.date.month.toString().padLeft(2, '0')}-${g.date.day.toString().padLeft(2, '0')}';
                  return g.players.any(
                          (p) => p.toLowerCase().contains(q)) ||
                      dateStr.contains(q);
                }).toList();
              }
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .outline),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'لا يوجد ألعاب محفوظة'
                            : 'لم يتم العثور على نتائج',
                        style:
                        Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }
              list.sort((a, b) => b.date.compareTo(a.date));
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      _buildGameCard(list[i], list, i),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildGameCard(GameRecord g, List<GameRecord> list, int i) {
    final d = g.date;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final realRoundsCount =
        g.rounds.where((r) => !r.isEvent).length;

    return Dismissible(
      key: Key(g.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('حذف هذه اللعبة؟'),
            content: const Text('سيتم حذفها نهائيًا من السجل.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('نعم'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        list.removeAt(i);
        await SavedGames.overwriteAll(list);
        _refresh();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailScreen(record: g),
              ),
            );
            _refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                        AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.casino_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          Text(
                            '$timeStr • $realRoundsCount جولات',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                      const Icon(Icons.share_rounded, size: 20),
                      onPressed: () => _shareGame(g),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (g.completed)
                  buildWinnerTiersDisplay(
                    finalScores: g.finalScores,
                    winners: g.winners,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline_rounded,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'لعبة غير مكتملة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: g.players
                      .map((name) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                      AppColors.forPlayer(name, g.players)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.forPlayer(
                            name, g.players),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*═══════════════════════════│ الإعدادات │═══════════════════════════*/
const String kAppVersion = '1.1.9';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, int> _settings = {};
  bool _loading = true;

  final _keys = [
    ('khalasOthers', 'يُضاف للباقين — خالص'),
    ('khalasWinner', 'يُنقص من المخلص'),
    ('khalasQuick1', 'الزر السريع 1 — خالص'),
    ('khalasQuick2', 'الزر السريع 2 — خالص'),
    ('dablOthers', 'يُضاف للباقين — دبل'),
    ('dablWinner', 'يُنقص من المدبل'),
    ('dablQuick1', 'الزر السريع 1 — دبل'),
    ('dablQuick2', 'الزر السريع 2 — دبل'),
    ('dablLonOthers', 'يُضاف للباقين — دبل لون'),
    ('dablLonWinner', 'يُنقص من مدبل اللون'),
    ('dablLonQuick1', 'الزر السريع 1 — دبل لون'),
    ('dablLonQuick2', 'الزر السريع 2 — دبل لون'),
    ('winnersCount', 'عدد الفائزين'),
  ];

  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {for (final k in _keys) k.$1: TextEditingController()};
    AppSettings.load().then((s) {
      setState(() {
        _settings = s;
        _loading = false;
        for (final k in _keys) _ctrls[k.$1]!.text = '${s[k.$1]}';
      });
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = <String, int>{};
    for (final k in _keys) {
      updated[k.$1] = int.tryParse(_ctrls[k.$1]!.text) ?? _settings[k.$1]!;
    }
    // عدد الفائزين لا يقل عن 1
    if ((updated['winnersCount'] ?? 2) < 1) updated['winnersCount'] = 1;
    // مفاتيح تفعيل الأنواع (ليست حقولاً نصية)
    for (final k in ['khalasEnabled', 'dablEnabled', 'dablLonEnabled']) {
      updated[k] = _settings[k] ?? 1;
    }
    await AppSettings.save(updated);
    if (mounted) Navigator.pop(context);
  }

  int get _enabledPresetsCount =>
      ['khalasEnabled', 'dablEnabled', 'dablLonEnabled']
          .where((k) => (_settings[k] ?? 1) != 0)
          .length;

  Future<void> _exportData() async {
    final games = await SavedGames.load();
    final json = jsonEncode(games.map((g) => g.toJson()).toList());
    await Share.share(json, subject: 'بيانات حاسبة كنكان');
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb,
      );
      if (result == null) return;
      final file = result.files.single;
      final String content;
      if (kIsWeb) {
        content = String.fromCharCodes(file.bytes!);
      } else {
        content = await File(file.path!).readAsString();
      }
      final List<dynamic> list = jsonDecode(content);
      final games = list.map((e) => GameRecord.fromJson(e)).toList();
      final existing = await SavedGames.load();
      final existingIds = existing.map((g) => g.id).toSet();
      int added = 0;
      for (final g in games) {
        if (!existingIds.contains(g.id)) {
          await SavedGames.add(g);
          added++;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد $added لعبة')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الاستيراد')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          TextButton(onPressed: _loading ? null : _save, child: const Text('حفظ')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // المظهر
                Card(
                  child: ListTile(
                    leading: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    title: const Text('المظهر'),
                    subtitle: Text(isDark ? 'داكن' : 'فاتح'),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) {
                        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                        KinkanApp.themeNotifier.value = newMode;
                        ThemeManager.save(newMode);
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // قواعد اللعبة
                Text('قواعد اللعبة', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('تُطبَّق على كل لعبة جديدة',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: AppColors.gold),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('عدد الفائزين',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _ctrls['winnersCount'],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // قيم الأنواع
                Text('قيم الأنواع', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('عطّل الأنواع التي لا تلعبونها لإخفائها من شاشة اللعب',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                ..._buildPresetSection('خالص', 'khalasEnabled',
                    ['khalasOthers', 'khalasWinner', 'khalasQuick1', 'khalasQuick2']),
                const SizedBox(height: 8),
                ..._buildPresetSection('دبل', 'dablEnabled',
                    ['dablOthers', 'dablWinner', 'dablQuick1', 'dablQuick2']),
                const SizedBox(height: 8),
                ..._buildPresetSection('دبل لون', 'dablLonEnabled',
                    ['dablLonOthers', 'dablLonWinner', 'dablLonQuick1', 'dablLonQuick2']),
                const SizedBox(height: 24),
                // تصدير واستيراد
                Text('البيانات', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('تصدير البيانات'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _importData,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('استيراد البيانات'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'النسخة $kAppVersion',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildPresetSection(
      String title, String enabledKey, List<String> keys) {
    final labels = {
      'khalasOthers': 'يُضاف للباقين',
      'khalasWinner': 'يُنقص من المخلص',
      'khalasQuick1': 'الزر السريع 1',
      'khalasQuick2': 'الزر السريع 2',
      'dablOthers': 'يُضاف للباقين',
      'dablWinner': 'يُنقص من المدبل',
      'dablQuick1': 'الزر السريع 1',
      'dablQuick2': 'الزر السريع 2',
      'dablLonOthers': 'يُضاف للباقين',
      'dablLonWinner': 'يُنقص من مدبل اللون',
      'dablLonQuick1': 'الزر السريع 1',
      'dablLonQuick2': 'الزر السريع 2',
    };
    final enabled = (_settings[enabledKey] ?? 1) != 0;

    Widget field(String k) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: _ctrls[k],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: labels[k],
            labelStyle: const TextStyle(fontSize: 11),
            border: const OutlineInputBorder(),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ),
    );

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (v) {
                      if (!v && _enabledPresetsCount <= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'يجب أن يبقى نوع لعب واحد مفعّلاً على الأقل')),
                        );
                        return;
                      }
                      setState(() => _settings[enabledKey] = v ? 1 : 0);
                    },
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 12),
                Row(children: [field(keys[0]), field(keys[1])]),
                const SizedBox(height: 8),
                Row(children: [field(keys[2]), field(keys[3])]),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}

/*═══════════════════════════│ متصدّرو الفوز │═══════════════════════════*/
class TopWinnersScreen extends StatefulWidget {
  const TopWinnersScreen({super.key});
  @override
  State<TopWinnersScreen> createState() => _TopWinnersScreenState();
}

class _TopWinnersScreenState extends State<TopWinnersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<_StatsData> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _future = _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_StatsData> _loadStats() async {
    final games = await SavedGames.load();
    final resetDate = await StatsManager.getResetDate();

    final Map<String, int> wins = {};
    final Map<String, int> gamesPlayed = {};
    final Map<String, List<int>> validScores = {};
    final Map<String, int> currentStreak = {};
    final Map<String, int> longestStreak = {};
    int totalGames = 0;

    final filteredGames = games
        .where((g) => resetDate == null || !g.date.isBefore(resetDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final g in filteredGames) {
      // الألعاب غير المكتملة لا تدخل الإحصائيات إطلاقاً
      if (!g.completed) continue;
      totalGames++;
      final winners = g.winners.toSet();

      for (final p in g.players) {
        gamesPlayed[p] = (gamesPlayed[p] ?? 0) + 1;
        if (winners.contains(p)) {
          currentStreak[p] = (currentStreak[p] ?? 0) + 1;
          if ((currentStreak[p] ?? 0) > (longestStreak[p] ?? 0)) {
            longestStreak[p] = currentStreak[p]!;
          }
        } else {
          currentStreak[p] = 0;
        }
      }

      for (final w in winners) {
        wins[w] = (wins[w] ?? 0) + 1;
      }

      for (final entry in g.finalScores.entries) {
        validScores[entry.key] ??= [];
        validScores[entry.key]!.add(entry.value);
      }
    }

    final Map<String, double> avgScore = {
      for (final e in validScores.entries)
        if (e.value.isNotEmpty)
          e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    final sorted = wins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _StatsData(
      wins: {for (final e in sorted) e.key: e.value},
      gamesPlayed: gamesPlayed,
      totalGames: totalGames,
      avgScore: avgScore,
      longestStreak: longestStreak,
    );
  }

  Future<void> _resetStats() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إعادة تعيين الإحصاءات؟'),
        content:
        const Text('لن يُحذف سجل الألعاب، لكن عدّاد الفوز سيعود للصفر.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StatsManager.setResetDate(DateTime.now());
      setState(() => _future = _loadStats());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('الإحصائيات'),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        tabs: const [
          Tab(icon: Icon(Icons.star_rounded), text: 'الترتيب'),
          Tab(icon: Icon(Icons.pie_chart_rounded), text: 'الرسم البياني'),
        ],
      ),
    ),
    body: FutureBuilder<_StatsData>(
      future: _future,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snap.data!;
        if (stats.wins.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text('لا توجد إحصاءات بعد',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }
        return TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboard(stats),
            _buildChart(stats),
          ],
        );
      },
    ),
  );

  Widget _buildLeaderboard(_StatsData stats) {
    final entries = stats.wins.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final played = stats.gamesPlayed[entry.key] ?? entry.value;
        final winRate =
        played > 0 ? (entry.value / played * 100).toStringAsFixed(0) : '0';

        Color rankColor;
        IconData? rankIcon;
        if (i == 0) {
          rankColor = const Color(0xFFFFD700);
          rankIcon = Icons.emoji_events_rounded;
        } else if (i == 1) {
          rankColor = const Color(0xFFC0C0C0);
          rankIcon = Icons.emoji_events_rounded;
        } else if (i == 2) {
          rankColor = const Color(0xFFCD7F32);
          rankIcon = Icons.emoji_events_rounded;
        } else {
          rankColor = Colors.grey.shade400;
          rankIcon = null;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: rankIcon != null
                        ? Icon(rankIcon, color: rankColor)
                        : Text(
                      '#${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rankColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PlayerAvatar(
                  name: entry.key,
                  allPlayers: entries.map((e) => e.key).toList(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$played مباراة • $winRate% فوز',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (stats.avgScore[entry.key] != null) ...[
                            Icon(Icons.analytics_rounded,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Text(
                              'متوسط ${stats.avgScore[entry.key]!.toStringAsFixed(0)} نقطة',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if ((stats.longestStreak[entry.key] ?? 0) >= 2) ...[
                            Icon(Icons.local_fire_department_rounded,
                                size: 11, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(
                              'سلسلة ${stats.longestStreak[entry.key]} فوز',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.warning),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(_StatsData stats) {
    final entries = stats.wins.entries.toList();
    final names = entries.map((e) => e.key).toList();
    final maxWins =
    entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBlock('${stats.totalGames}', 'إجمالي الألعاب',
                    Icons.casino_rounded),
                _statBlock('${entries.length}', 'لاعبين',
                    Icons.groups_rounded),
                _statBlock(entries.first.key, 'الأفضل',
                    Icons.emoji_events_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxWins.toDouble() + 1,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      return BarTooltipItem(
                        '${names[group.x.toInt()]}\n${rod.toY.round()} فوز',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= names.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            names[idx],
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        if (value == value.toInt()) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((e) {
                  final color = AppColors.forPlayer(e.value.key, names);
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value.toDouble(),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _StatsData {
  _StatsData({
    required this.wins,
    required this.gamesPlayed,
    required this.totalGames,
    required this.avgScore,
    required this.longestStreak,
  });
  final Map<String, int> wins;
  final Map<String, int> gamesPlayed;
  final int totalGames;
  final Map<String, double> avgScore;
  final Map<String, int> longestStreak;
}

/*═══════════════════════════│ تفاصيل لعبة محفوظة │═══════════════════════════*/
class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({super.key, required this.record});
  final GameRecord record;

  String _getPresetName(int p) {
    if (p == 400) return 'دبل لون';
    if (p == 200) return 'دبل';
    if (p == 100) return 'خالص';
    return 'صفر';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}س ${m}د';
    return '${m}د';
  }

  @override
  Widget build(BuildContext context) {
    final d = record.date;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final realRoundsCount =
        record.rounds.where((r) => !r.isPlayerAddition).length;
    final winnerTiers = rankTiers({
      for (final name in record.winners) name: record.finalScores[name] ?? 0
    });
    Color? medalColor(String name) {
      final idx = winnerTiers.indexWhere((t) => t.contains(name));
      if (idx == 0) return AppColors.gold;
      if (idx == 1) return AppColors.silver;
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل اللعبة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              final buffer = StringBuffer()
                ..writeln('🎴 لعبة كنكان - $dateStr')
                ..writeln(record.completed
                    ? '🏆 الفائزون: ${record.winners.join("، ")}'
                    : '⏸ لعبة غير مكتملة');
              for (final e in record.finalScores.entries) {
                buffer.writeln('• ${e.key}: ${e.value}');
              }
              Share.share(buffer.toString());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(
                players: record.players.map((n) => Player(n)).toList(),
                limit: record.limit,
                existingRecordId: record.id,
                initialHistory: record.rounds,
                initialDuration: record.durationSeconds,
                winnersCount: record.winnersCount,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('إكمال اللعبة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!record.completed)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.blueGrey.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pause_circle_outline_rounded,
                        color: Colors.blueGrey, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'لعبة غير مكتملة',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'لا تُحسب في الإحصائيات — يمكنك استكمالها '
                            'بزر الإكمال بالأسفل',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            winnerTiers.length > 1 ? 'الفائزون' : 'الفائز',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                          for (int i = 0;
                          i < winnerTiers.length && i < 2;
                          i++)
                            Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (i == 1)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(Icons.emoji_events_rounded,
                                          color: AppColors.silver, size: 16),
                                    ),
                                  Text(
                                    winnerTiers[i].join('، '),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: i == 0 ? 22 : 15,
                                      fontWeight: i == 0
                                          ? FontWeight.bold
                                          : FontWeight.w600,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'التاريخ',
                    value: dateStr,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoCard(
                    icon: Icons.flag_rounded,
                    label: 'حد الخسارة',
                    value: '${record.limit}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.casino_rounded,
                    label: 'الجولات',
                    value: '$realRoundsCount',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoCard(
                    icon: Icons.timer_rounded,
                    label: 'المدة',
                    value: _formatDuration(record.durationSeconds),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.scoreboard_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('النقاط النهائية',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ...record.finalScores.entries.map((e) {
              final isWinner = record.winners.contains(e.key);
              final medal = medalColor(e.key);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isWinner
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                    isWinner ? AppColors.success : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    PlayerAvatar(
                        name: e.key, allPlayers: record.players),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                    if (medal != null)
                      Icon(Icons.emoji_events_rounded,
                          color: medal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${e.value}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isWinner ? AppColors.success : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('سجل الجولات',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ...record.rounds.map((r) {
              if (r.isPlayerAddition) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.blue.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_add_rounded,
                                color: Colors.blue, size: 16),
                            SizedBox(width: 6),
                            Text('إضافة لاعبين',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blue)),
                          ],
                        ),
                        const Divider(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: r.points.entries
                              .map((e) => Text(
                              '${e.key}: نقاط البداية ${e.value}',
                              style: const TextStyle(fontSize: 13)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (r.isPlayerRemoval) {
                return _PlayerRemovalCard(round: r);
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'جولة ${r.index}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getPresetName(r.preset),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: r.points.entries
                            .map((e) => Text('${e.key}: +${e.value}',
                            style: const TextStyle(fontSize: 13)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}