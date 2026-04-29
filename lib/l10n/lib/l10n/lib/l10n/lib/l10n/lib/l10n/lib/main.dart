import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ============================================
// COLORS & CONSTANTS
// ============================================
class AppColors {
  static const Color primary = Color(0xFF2E8B57);
  static const Color secondary = Color(0xFFDAA520);
  static const Color forbidden = Color(0xFF8B0000);
  static const Color lightBg = Color(0xFFF5F5DC);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF16213E);
  static const Color white = Colors.white;
  static const Color black = Colors.black87;
  static const Color grey = Colors.grey;
}

// ============================================
// MODELS
// ============================================
class FastingTimer {
  DateTime? startTime;
  DateTime? endTime;
  int targetHours;
  bool isActive;
  String type;

  FastingTimer({
    this.startTime,
    this.endTime,
    this.targetHours = 16,
    this.isActive = false,
    this.type = '16:8',
  });

  Duration get elapsed {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }

  Duration get remaining {
    final target = Duration(hours: targetHours);
    return target - elapsed;
  }

  double get progress {
    final target = Duration(hours: targetHours).inSeconds;
    final current = elapsed.inSeconds;
    return (current / target).clamp(0.0, 1.0);
  }

  bool get isComplete => progress >= 1.0;

  String get elapsedTimeString {
    final e = elapsed;
    final h = e.inHours.toString().padLeft(2, '0');
    final m = (e.inMinutes % 60).toString().padLeft(2, '0');
    final s = (e.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get remainingTimeString {
    final r = remaining;
    if (r.isNegative) return '00:00:00';
    final h = r.inHours.toString().padLeft(2, '0');
    final m = (r.inMinutes % 60).toString().padLeft(2, '0');
    final s = (r.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ============================================
// PROVIDERS
// ============================================
class FastingProvider extends ChangeNotifier {
  FastingTimer _timer = FastingTimer();
  Timer? _tickTimer;

  FastingTimer get timer => _timer;
  bool get isFasting => _timer.isActive;
  String get elapsedTime => _timer.elapsedTimeString;
  String get remainingTime => _timer.remainingTimeString;
  double get progress => _timer.progress;

  void startFasting({int hours = 16, String type = '16:8'}) {
    _timer = FastingTimer(
      startTime: DateTime.now(),
      targetHours: hours,
      isActive: true,
      type: type,
    );
    _startTicker();
    notifyListeners();
  }

  void stopFasting() {
    _timer = FastingTimer(
      endTime: DateTime.now(),
      targetHours: _timer.targetHours,
      isActive: false,
      type: _timer.type,
    );
    _tickTimer?.cancel();
    notifyListeners();
  }

  void reset() {
    _timer = FastingTimer();
    _tickTimer?.cancel();
    notifyListeners();
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    _locale = Locale(languageCode);
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLargeFont = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLargeFont => _isLargeFont;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _isLargeFont = prefs.getBool('large_font') ?? false;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleLargeFont() async {
    final prefs = await SharedPreferences.getInstance();
    _isLargeFont = !_isLargeFont;
    await prefs.setBool('large_font', _isLargeFont);
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  ThemeData get _lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBg,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData get _darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBg,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      cardTheme: const CardTheme(color: AppColors.cardDark),
    );
  }
}

// ============================================
// FOOD LISTS
// ============================================
class FoodLists {
  static const List<String> allowedFoods = [
    'Whole grain bread (rye toast)',
    'Olive oil',
    'Butter & ghee',
    'Potatoes (fried, boiled, homemade chips)',
    'Bulgur wheat',
    'Corn (popcorn, grilled)',
    'Feta cheese (Greek)',
    'Pecorino Romano cheese',
    'Cheddar, Edam, Gouda, Mozzarella',
    'Red meat (once/week)',
    'Lamb/Goat/Camel (twice/week)',
    'Sea fish',
    'Grilled pigeon',
    'Rabbit',
    'Apple, grapes, mango (reduce)',
    'Fresh or dried figs',
    'Kiwi',
    'Pomegranate',
    'Nuts (except almonds, hazelnuts, peanuts)',
    'Tahini with grape molasses',
    'Greek semolina cake',
    'Dark chocolate',
    'Turkish coffee',
    'Green tea',
    'Tamarind juice',
    'Rose syrup',
    'Carob juice',
  ];

  static const List<String> forbiddenFoods = [
    'All eggs',
    'Cow & buffalo milk',
    'Yogurt, laban, labneh',
    'Cottage cheese',
    'White cheese',
    'Cucumber, lettuce, arugula',
    'Parsley, celery, cilantro',
    'Tomato, spinach, peas',
    'Beans, lupini, fava beans',
    'Chickpeas, lentils',
    'All white flour',
    'Cake, croissant, pastry',
    'Kunafa, balah el sham, zalabia',
    'Pasta & noodles',
    'Farm-raised fish',
    'Shrimp, squid, tilapia',
    'Chicken & liver',
    'Duck, turkey',
    'Sodas & energy drinks',
    'Nescafe',
    'Watermelon, cantaloupe, orange',
    'Tangerine, mango, papaya, avocado',
  ];
}

// ============================================
// SCREENS
// ============================================

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const FastingScreen(),
    const MealsScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
          BottomNavigationBarItem(icon: const Icon(Icons.timer), label: l10n.fasting),
          BottomNavigationBarItem(icon: const Icon(Icons.restaurant), label: l10n.meals),
          BottomNavigationBarItem(icon: const Icon(Icons.show_chart), label: l10n.progress),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: l10n.settings),
        ],
      ),
    );
  }
}

// --- HOME CONTENT ---
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fastingProvider = Provider.of<FastingProvider>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.appName, style: TextStyle(color: AppColors.grey)),
                    Text(
                      l10n.appTagline,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    fastingProvider.isFasting ? l10n.youAreFasting : l10n.startFasting,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (fastingProvider.isFasting) ...[
                    Text(
                      fastingProvider.elapsedTime,
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.remainingTime}: ${fastingProvider.remainingTime}',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () => fastingProvider.startFasting(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(l10n.startNow),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.todaysTasks, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTaskCard(Icons.local_drink, l10n.drinkVinegar, false),
            const SizedBox(height: 8),
            _buildTaskCard(Icons.water_drop, l10n.drinkWater, true),
            const SizedBox(height: 8),
            _buildTaskCard(Icons.nights_stay, l10n.fastingTomorrow, false),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.drugFree,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Text(
                          l10n.foodIsMedicine,
                          style: TextStyle(color: AppColors.grey, fontSize: 12),
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
    );
  }

  Widget _buildTaskCard(IconData icon, String title, bool isDone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: isDone ? AppColors.primary : AppColors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Checkbox(value: isDone, onChanged: (v) {}, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

// --- FASTING SCREEN ---
class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  String selectedType = '16:8';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fastingProvider = Provider.of<FastingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(l10n.fasting, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: fastingProvider.isFasting
                      ? [AppColors.primary, AppColors.secondary]
                      : [Colors.grey.shade300, Colors.grey.shade500],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    fastingProvider.isFasting ? Icons.timer : Icons.timer_off,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fastingProvider.isFasting ? l10n.youAreFasting : l10n.startFasting,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    fastingProvider.elapsedTime,
                    style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
                  ),
                  if (fastingProvider.isFasting) ...[
                    const SizedBox(height: 16),
                    Text('${l10n.remainingTime}: ${fastingProvider.remainingTime}', 
                        style: const TextStyle(color: Colors.white70, fontSize: 20)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: fastingProvider.progress,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => fastingProvider.stopFasting(),
                          icon: const Icon(Icons.stop),
                          label: Text(l10n.stop),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => fastingProvider.reset(),
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.reset),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => fastingProvider.startFasting(
                        hours: int.parse(selectedType.split(':')[0]),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.startNow),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!fastingProvider.isFasting) ...[
              const SizedBox(height: 24),
              Text(l10n.fastingTypes, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['16:8', '18:6', '20:4', 'OMAD'].map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: selectedType == type,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selectedType == type ? Colors.white : Colors.black,
                    ),
                    onSelected: (s) => setState(() => selectedType = type),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- MEALS SCREEN ---
class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  bool showAllowed = true;
  String searchQuery = '';

  List<String> get filteredFoods {
    final foods = showAllowed ? FoodLists.allowedFoods : FoodLists.forbiddenFoods;
    if (searchQuery.isEmpty) return foods;
    return foods.where((f) => f.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(l10n.meals, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showAllowed = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showAllowed ? AppColors.primary : Colors.grey.shade300,
                      foregroundColor: showAllowed ? Colors.white : Colors.black,
                    ),
                    child: Text(l10n.allowed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showAllowed = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !showAllowed ? AppColors.forbidden : Colors.grey.shade300,
                      foregroundColor: !showAllowed ? Colors.white : Colors.black,
                    ),
                    child: Text(l10n.forbidden),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: l10n.searchFood,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        showAllowed ? Icons.check_circle : Icons.cancel,
                        color: showAllowed ? AppColors.primary : AppColors.forbidden,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(filteredFoods[index])),
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

// --- PROGRESS SCREEN ---
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(l10n.progress, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.weight, style: TextStyle(color: AppColors.grey)),
                          const Text('85 kg', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      CircularPercentIndicator(
                        radius: 50,
                        lineWidth: 10,
                        percent: 0.66,
                        center: const Text('66%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        progressColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 12,
                    percent: 0.66,
                    progressColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fastingStats, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(l10n.fastingHours, '142', Icons.timer),
                      _statItem(l10n.fastingDays, '8/12', Icons.mosque),
                      _statItem(l10n.longestFast, '20:15', Icons.emoji_events),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.achievements, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      _badge('🥇', l10n.fullWeek, true),
                      _badge('🥈', l10n.hundredHours, true),
                      _badge('🥉', l10n.fullMonth, false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _badge(String emoji, String title, bool unlocked) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.5,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.secondary.withOpacity(0.2) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// --- SETTINGS SCREEN ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(l10n.settings, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection(l10n.language),
            Card(
              child: Column(
                children: [
                  _languageTile('🇺🇸', 'English', 'en', localeProvider),
                  _languageTile('🇫🇷', 'Français', 'fr', localeProvider),
                  _languageTile('🇩🇪', 'Deutsch', 'de', localeProvider),
                  _languageTile('🇮🇹', 'Italiano', 'it', localeProvider),
                  _languageTile('🇸🇦', 'العربية', 'ar', localeProvider),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(l10n.settings),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.darkMode),
                    value: themeProvider.isDarkMode,
                    onChanged: (v) => themeProvider.toggleDarkMode(),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: Text(l10n.largeFont),
                    value: themeProvider.isLargeFont,
                    onChanged: (v) => themeProvider.toggleLargeFont(),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l10n.sadaqa,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.sadaqaDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.version, style: TextStyle(color: AppColors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _languageTile(String flag, String name, String code, LocaleProvider provider) {
    final isSelected = provider.locale.languageCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () => provider.setLocale(code),
    );
  }
}

// ============================================
// MAIN ENTRY
// ============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => localeProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => FastingProvider()),
      ],
      child: const HealithApp(),
    ),
  );
}

class HealithApp extends StatelessWidget {
  const HealithApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Healith',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('de'),
        Locale('it'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: themeProvider.getTheme(),
      home: const HomeScreen(),
    );
  }
}
