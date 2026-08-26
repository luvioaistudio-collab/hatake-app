import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const String _supabaseUrl = 'https://zhcsmkhoctutyucqpett.supabase.co';
const String _supabaseKey = 'sb_publishable_fAx9Ap9mQweb3d_uCVGqTw_JlM-QPlh';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);
  runApp(const MyApp());
}

final _sb = Supabase.instance.client;

// ===== 畑情報の定義 =====
class FieldInfo {
  final String id;
  final String name;
  final String emoji;
  final double lat;
  final double lng;
  final String locationLabel;
  final Color color;

  const FieldInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lat,
    required this.lng,
    required this.locationLabel,
    required this.color,
  });
}

const kFields = [
  FieldInfo(
    id: 'kaonashi',
    name: 'カオナシ農園',
    emoji: '🌿',
    lat: 34.6937,
    lng: 135.7010,
    locationLabel: '📍生駒市',
    color: Color(0xFF388E3C),
  ),
  FieldInfo(
    id: 'nao',
    name: 'なお農園',
    emoji: '🌸',
    lat: 34.6873,
    lng: 135.5022,
    locationLabel: '📍大阪',
    color: Color(0xFF7B1FA2),
  ),
];

final ValueNotifier<FieldInfo> selectedField = ValueNotifier(kFields[0]);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '畑ノート',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

// ===== パスワード認証画面 =====
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _password = 'hatake358';
  static const _storageKey = 'hatake_auth';
  final _controller = TextEditingController();
  bool _obscure = true;
  String _errorMsg = '';
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSavedAuth();
  }

  void _checkSavedAuth() {
    try {
      final saved = html.window.localStorage[_storageKey];
      if (saved == _password) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
        return;
      }
    } catch (e) {}
    setState(() => _checking = false);
  }

  void _login() {
    if (_controller.text == _password) {
      try { html.window.localStorage[_storageKey] = _password; } catch (e) {}
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _errorMsg = 'パスワードが違います');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: Colors.green[700], shape: BoxShape.circle),
                child: const Icon(Icons.grass, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('畑ノート 🌱', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('パスワードを入力してください', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'パスワード',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    if (_errorMsg.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _login,
                        child: const Text('ログイン', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== ホーム画面 =====
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildPage(FieldInfo field) {
    switch (_currentIndex) {
      case 0: return HomePage(key: ValueKey('home_${field.id}'), field: field);
      case 1: return FieldMapPage(key: ValueKey('map_${field.id}'), field: field);
      case 2: return const GuidePage();
      case 3: return DiaryPage(key: ValueKey('diary_${field.id}'), field: field);
      case 4: return FertilizerPage(key: ValueKey('fert_${field.id}'), field: field);
      default: return HomePage(key: ValueKey('home_${field.id}'), field: field);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FieldInfo>(
      valueListenable: selectedField,
      builder: (context, field, _) {
        return Scaffold(
          body: _buildPage(field),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: field.color,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: '畑マップ'),
              BottomNavigationBarItem(icon: Icon(Icons.eco), label: '栽培ガイド'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: '作業日誌'),
              BottomNavigationBarItem(icon: Icon(Icons.science), label: '肥料管理'),
            ],
          ),
        );
      },
    );
  }
}

// ===== ホームページ =====
class HomePage extends StatefulWidget {
  final FieldInfo field;
  const HomePage({super.key, required this.field});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, String>> _fieldCrops = [];
  List<Map<String, dynamic>> _weather = [];
  bool _weatherLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadFieldCrops();
    _fetchWeather();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadTasks();
      _loadFieldCrops();
    });
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.id != widget.field.id) {
      _loadTasks();
      _loadFieldCrops();
      _fetchWeather();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final data = await _sb
          .from('tasks')
          .select()
          .eq('field_id', widget.field.id)
          .order('created_at', ascending: false);
      if (mounted) setState(() => _tasks = List<Map<String, dynamic>>.from(data));
    } catch (e) {}
  }

  Future<void> _loadFieldCrops() async {
    try {
      final data = await _sb
          .from('crops')
          .select()
          .eq('field_id', widget.field.id);
      if (!mounted) return;
      final seen = <String>{};
      final crops = <Map<String, String>>[];
      for (final c in data) {
        final name = c['name'] as String? ?? '';
        if (name.isNotEmpty && !seen.contains(name)) {
          seen.add(name);
          crops.add({'emoji': c['emoji'] ?? '', 'name': name});
        }
      }
      setState(() => _fieldCrops = crops);
    } catch (e) {}
  }

  Future<void> _fetchWeather() async {
    setState(() => _weatherLoading = true);
    try {
      final url = 'https://api.open-meteo.com/v1/forecast'
          '?latitude=${widget.field.lat}&longitude=${widget.field.lng}'
          '&daily=weathercode,temperature_2m_max,temperature_2m_min'
          '&timezone=Asia%2FTokyo'
          '&forecast_days=7';
      final request = await html.HttpRequest.request(url, method: 'GET');
      final data = jsonDecode(request.responseText ?? '{}');
      if (data['daily'] != null) {
        final daily = data['daily'] as Map<String, dynamic>;
        final dates = (daily['time'] as List).cast<String>();
        final codes = (daily['weathercode'] as List).cast<int>();
        final maxTemps = (daily['temperature_2m_max'] as List)
            .map((e) => (e as num).toDouble()).toList();
        final List<Map<String, dynamic>> weatherList = [];
        for (int i = 0; i < min(5, dates.length); i++) {
          final date = DateTime.parse(dates[i]);
          String label;
          if (i == 0) { label = '今日'; }
          else if (i == 1) { label = '明日'; }
          else { const w = ['月','火','水','木','金','土','日']; label = w[date.weekday - 1]; }
          weatherList.add({'label': label, 'icon': _codeToEmoji(codes[i]), 'temp': '${maxTemps[i].round()}°'});
        }
        setState(() { _weather = weatherList; _weatherLoading = false; });
      } else { _fallbackWeather(); }
    } catch (e) { _fallbackWeather(); }
  }

  void _fallbackWeather() {
    setState(() {
      _weather = [
        {'label': '今日', 'icon': '☀️', 'temp': '--°'},
        {'label': '明日', 'icon': '🌥', 'temp': '--°'},
        {'label': '水', 'icon': '🌧️', 'temp': '--°'},
        {'label': '木', 'icon': '🌧️', 'temp': '--°'},
        {'label': '金', 'icon': '☀️', 'temp': '--°'},
      ];
      _weatherLoading = false;
    });
  }

  String _codeToEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '🌤';
    if (code == 3) return '☁️';
    if (code <= 49) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '🌦️';
    if (code <= 86) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌥';
  }

  void _toggleTask(int index) async {
    final t = _tasks[index];
    await _sb.from('tasks').update({'done': !(t['done'] ?? false)}).eq('id', t['id']);
    await _loadTasks();
  }

  void _deleteTask(int index) async {
    await _sb.from('tasks').delete().eq('id', _tasks[index]['id']);
    await _loadTasks();
  }

  void _showAddTaskDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('タスクを追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '例：トマトの水やり'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.field.color),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                try {
                  await _sb.from('tasks').insert({
                    'emoji': '📝',
                    'text': text,
                    'done': false,
                    'field_id': widget.field.id,
                  });
                  Navigator.pop(ctx);
                  await _loadTasks();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            },
            child: const Text('追加', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${_tasks[index]['text']}」を削除します'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { Navigator.pop(ctx); _deleteTask(index); },
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _tasks.where((t) => t['done'] == true).length;
    final fc = widget.field.color;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: fc,
        title: const Text('畑ノート 🌱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { _loadFieldCrops(); _loadTasks(); _fetchWeather(); },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: fc,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldSelector(),
            const SizedBox(height: 16),
            // 天気
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [fc, fc.withOpacity(0.6)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('今週の天気', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(widget.field.locationLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  const SizedBox(height: 8),
                  _weatherLoading
                      ? const Center(child: SizedBox(height: 48,
                          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _weather.map((w) => _weatherItem(w['label'], w['icon'], w['temp'])).toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_fieldCrops.isNotEmpty) ...[
              Text('🌾 ${widget.field.name}の野菜',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fieldCrops.length,
                  itemBuilder: (ctx, i) {
                    final crop = _fieldCrops[i];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: fc.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: fc.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: fc.withOpacity(0.7), shape: BoxShape.circle),
                            child: const Icon(Icons.grass, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(crop['name'] ?? '',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_fieldCrops.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fc.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fc.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.map, color: fc, size: 20),
                  const SizedBox(width: 8),
                  Text('畑マップに野菜を登録すると、ここに表示されます',
                      style: TextStyle(color: fc, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📋 今日の作業', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$doneCount/${_tasks.length} 完了', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            if (_tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('＋ボタンでタスクを追加しましょう', style: TextStyle(color: Colors.grey))),
              ),
            ..._tasks.asMap().entries.map((e) => _taskItem(e.key, e.value, fc)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: kFields.map((f) {
          final isSelected = selectedField.value.id == f.id;
          return Expanded(
            child: GestureDetector(
              onTap: () { if (selectedField.value.id != f.id) selectedField.value = f; },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? f.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [BoxShadow(color: f.color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(f.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(f.name, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _weatherItem(String day, String icon, String temp) {
    return Column(children: [
      Text(day, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(icon, style: const TextStyle(fontSize: 20)),
      Text(temp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _taskItem(int index, Map<String, dynamic> task, Color fc) {
    final bool done = task['done'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(children: [
        Text(task['emoji'] ?? '📝', style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(task['text'] ?? '',
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? Colors.grey : Colors.black87,
          ),
        )),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => _showDeleteConfirm(index),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _toggleTask(index),
          child: Icon(done ? Icons.check_circle : Icons.circle_outlined,
              color: done ? fc : Colors.grey),
        ),
      ]),
    );
  }
}

// ===== 畑マップ画面 =====
class FieldMapPage extends StatefulWidget {
  final FieldInfo field;
  const FieldMapPage({super.key, required this.field});
  @override
  State<FieldMapPage> createState() => _FieldMapPageState();
}

class _FieldMapPageState extends State<FieldMapPage> {
  Map<String, Map<String, dynamic>> _crops = {};
  Timer? _pollTimer;

  final List<Map<String, String>> _cropOptions = [
    {'emoji': '🍅', 'name': 'トマト',       'category': '実野菜'},
    {'emoji': '🥒', 'name': 'キュウリ',     'category': '実野菜'},
    {'emoji': '🍆', 'name': 'ナス',         'category': '実野菜'},
    {'emoji': '🥦', 'name': 'ピーマン',     'category': '実野菜'},
    {'emoji': '🌶', 'name': 'シシトウ',     'category': '実野菜'},
    {'emoji': '🌶', 'name': 'トウガラシ',   'category': '実野菜'},
    {'emoji': '🎃', 'name': 'カボチャ',     'category': '実野菜'},
    {'emoji': '🍉', 'name': 'スイカ',       'category': '実野菜'},
    {'emoji': '🌽', 'name': 'トウモロコシ', 'category': '実野菜'},
    {'emoji': '🍓', 'name': 'イチゴ',       'category': '実野菜'},
    {'emoji': '🌱', 'name': 'オクラ',       'category': '実野菜'},
    {'emoji': '🥬', 'name': 'ゴーヤー',     'category': '実野菜'},
    {'emoji': '🥬', 'name': 'レタス',           'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'ミックスレタス',   'category': '葉・茎もの'},
    {'emoji': '🥦', 'name': 'ブロッコリー',     'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ほうれん草',       'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'こまつな',         'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'キャベツ',         'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'ハクサイ',         'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'チンゲン菜',       'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'シュンギク',       'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ミズナ',           'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ツルムラサキ',     'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ニラ',             'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ネギ',             'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ワケギ',           'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'タカナ',           'category': '葉・茎もの'},
    {'emoji': '🥕', 'name': 'ニンジン',   'category': '根菜'},
    {'emoji': '🥔', 'name': 'じゃがいも', 'category': '根菜'},
    {'emoji': '🧅', 'name': 'タマネギ',   'category': '根菜'},
    {'emoji': '🧄', 'name': 'ニンニク',   'category': '根菜'},
    {'emoji': '🌰', 'name': 'サトイモ',   'category': '根菜'},
    {'emoji': '🍠', 'name': 'サツマイモ', 'category': '根菜'},
    {'emoji': '🥕', 'name': 'ダイコン',   'category': '根菜'},
    {'emoji': '🥔', 'name': 'カブ',       'category': '根菜'},
    {'emoji': '🌿', 'name': 'ゴボウ',     'category': '根菜'},
    {'emoji': '🌱', 'name': '枝豆',            'category': '豆類'},
    {'emoji': '🌱', 'name': 'そら豆',          'category': '豆類'},
    {'emoji': '🌱', 'name': 'えんどう豆',      'category': '豆類'},
    {'emoji': '🌱', 'name': 'スナップエンドウ', 'category': '豆類'},
    {'emoji': '🌱', 'name': 'インゲン',        'category': '豆類'},
    {'emoji': '🌿', 'name': 'バジル', 'category': 'ハーブ'},
    {'emoji': '🍃', 'name': 'シソ',   'category': 'ハーブ'},
    {'emoji': '🌿', 'name': 'パセリ', 'category': 'ハーブ'},
    {'emoji': '🌸', 'name': 'ミント', 'category': 'ハーブ'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCrops();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadCrops());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    try {
      final data = await _sb
          .from('crops')
          .select()
          .eq('field_id', widget.field.id);
      if (!mounted) return;
      final map = <String, Map<String, dynamic>>{};
      for (final c in data) {
        final pos = c['position'] as String? ?? '';
        if (pos.isNotEmpty) {
          map[pos] = {
            'id': c['id'],
            'emoji': c['emoji'] ?? '',
            'name': c['name'] ?? '',
            'planted_date': c['planted_date'] ?? '',
            'harvest_date': c['harvest_date'] ?? '',
          };
        }
      }
      setState(() => _crops = map);
    } catch (e) {}
  }

  void _showCropDetailDialog(String key, Map<String, dynamic> crop) async {
    DateTime? plantedDate = (crop['planted_date'] ?? '').toString().isNotEmpty
        ? DateTime.tryParse(crop['planted_date'].toString()) : null;
    DateTime? harvestDate = (crop['harvest_date'] ?? '').toString().isNotEmpty
        ? DateTime.tryParse(crop['harvest_date'].toString()) : null;

    String fmt(DateTime? d) => d != null
        ? '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'
        : '未設定';

    // 植えた日・収穫日をcropsテーブルに保存（yearも自動でセット）
    Future<void> saveDates() async {
      if (crop['id'] != null) {
        await _sb.from('crops').update({
          'planted_date': plantedDate?.toIso8601String().substring(0, 10),
          'harvest_date': harvestDate?.toIso8601String().substring(0, 10),
          'year': plantedDate?.year ?? harvestDate?.year,
        }).eq('id', crop['id']);
        await _loadCrops();
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Text(crop['emoji']?.toString() ?? '', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(child: Text(crop['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                onPressed: () { Navigator.pop(ctx); _showPlaceCropDialog(key); },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '作物を変更',
              ),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== 植えた日 =====
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Text('🌱', style: TextStyle(fontSize: 24)),
                      title: const Text('植えた日',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(fmt(plantedDate),
                          style: TextStyle(
                              color: plantedDate != null ? Colors.green[700] : Colors.grey,
                              fontSize: 15)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (plantedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () async {
                              setDS(() => plantedDate = null);
                              await saveDates();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.green),
                          onPressed: () async {
                            final d = await showDatePicker(
                                context: ctx,
                                initialDate: plantedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030));
                            if (d != null) {
                              setDS(() => plantedDate = d);
                              await saveDates();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ]),
                    ),
                    const Divider(height: 1),
                    // ===== 収穫日 =====
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Text('🧺', style: TextStyle(fontSize: 24)),
                      title: const Text('収穫日',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(fmt(harvestDate),
                          style: TextStyle(
                              color: harvestDate != null ? Colors.orange[800] : Colors.grey,
                              fontSize: 15)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (harvestDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () async {
                              setDS(() => harvestDate = null);
                              await saveDates();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.orange),
                          onPressed: () async {
                            final d = await showDatePicker(
                                context: ctx,
                                initialDate: harvestDate ?? plantedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030));
                            if (d != null) {
                              setDS(() => harvestDate = d);
                              await saveDates();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ]),
                    ),
                    // ===== 経過日数 / 栽培期間 =====
                    if (plantedDate != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            harvestDate != null
                                ? '栽培期間 ${harvestDate!.difference(plantedDate!).inDays} 日間'
                                : '植えてから ${DateTime.now().difference(plantedDate!).inDays} 日目',
                            style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        ]),
                      ),
                    ],
                    // ===== 連作防止メモ =====
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('💡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(
                          '植えた日・収穫日を記録しておくと、同じ場所に同じ科の野菜を続けて植えていないか（連作）の確認に役立ちます。',
                          style: TextStyle(color: Colors.brown[700], fontSize: 11, height: 1.4),
                        )),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (crop['id'] != null) {
                    await _sb.from('crops').delete().eq('id', crop['id']);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadCrops();
                },
                child: const Text('このマスを空にする', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('閉じる', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPlaceCropDialog(String key) {
    String selCat = 'すべて';
    final cats = ['すべて', '実野菜', '葉・茎もの', '根菜', '豆類', 'ハーブ'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          final filtered = selCat == 'すべて'
              ? _cropOptions
              : _cropOptions.where((c) => c['category'] == selCat).toList();
          return AlertDialog(
            title: const Text('作物を選択'),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: Column(children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cats.map((cat) => GestureDetector(
                      onTap: () => setDS(() => selCat = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selCat == cat ? Colors.green[700] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat, style: TextStyle(
                            color: selCat == cat ? Colors.white : Colors.black, fontSize: 12)),
                      ),
                    )).toList(),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    children: filtered.map((crop) => GestureDetector(
                      onTap: () async {
                        try {
                          final existing = await _sb
                              .from('crops')
                              .select()
                              .eq('position', key)
                              .eq('field_id', widget.field.id)
                              .maybeSingle();
                          final bool isNew = existing == null;
                          if (existing == null) {
                            await _sb.from('crops').insert({
                              'position': key,
                              'emoji': crop['emoji']!,
                              'name': crop['name']!,
                              'field_id': widget.field.id,
                            });
                          } else {
                            await _sb.from('crops').update({
                              'emoji': crop['emoji']!,
                              'name': crop['name']!,
                            }).eq('id', existing['id']);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadCrops();
                          // 新しく作物を置いたら、続けて植えた日・収穫日の入力ダイアログを開く
                          if (isNew && mounted && _crops[key] != null) {
                            _showCropDetailDialog(key, _crops[key]!);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(crop['emoji']!, style: const TextStyle(fontSize: 24)),
                          Text(crop['name']!, style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center),
                        ]),
                      ),
                    )).toList(),
                  ),
                ),
              ]),
            ),
            actions: [
              if (_crops[key] != null)
                TextButton(
                  onPressed: () async {
                    final c = _crops[key];
                    if (c != null && c['id'] != null) {
                      await _sb.from('crops').delete().eq('id', c['id']);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadCrops();
                  },
                  child: const Text('このマスを空にする', style: TextStyle(color: Colors.red)),
                ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fc = widget.field.color;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: fc,
        title: Text('${widget.field.name} 🗺️',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadCrops),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: fc.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.touch_app, color: fc, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('マスをタップ→作物を選び、植えた日・収穫日を記録できます',
                    style: TextStyle(color: fc, fontSize: 12))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const SizedBox(width: 24),
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: fc, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('植えた日あり', style: TextStyle(color: fc, fontSize: 11)),
                const SizedBox(width: 12),
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('収穫済み', style: TextStyle(color: fc, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFA8D5A2), borderRadius: BorderRadius.circular(16)),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, mainAxisSpacing: 6, crossAxisSpacing: 6),
                itemCount: 24,
                itemBuilder: (ctx, i) {
                  final row = i ~/ 4;
                  final col = i % 4;
                  final key = '$row-$col';
                  final crop = _crops[key];
                  return GestureDetector(
                    onTap: () => crop != null
                        ? _showCropDetailDialog(key, crop)
                        : _showPlaceCropDialog(key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: crop != null ? fc.withOpacity(0.2) : const Color(0xFFD4EDDA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: crop != null
                          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(crop['name']!.toString().substring(0, 1),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text(crop['name']!.toString(),
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                              if ((crop['harvest_date'] ?? '').toString().isNotEmpty)
                                Container(margin: const EdgeInsets.only(top: 2),
                                    width: 6, height: 6,
                                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))
                              else if ((crop['planted_date'] ?? '').toString().isNotEmpty)
                                Container(margin: const EdgeInsets.only(top: 2),
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(color: fc, shape: BoxShape.circle)),
                            ])
                          : const Icon(Icons.add, color: Colors.white54, size: 20),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ===== 栽培ガイド画面（共通）=====
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});
  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final List<Map<String, String>> _guides = [
    {'name': 'トマト',       'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '2〜3月',          'plant': '4〜5月',         'fert': '2週間に1回、カリ多め',       'pest': 'アブラムシ・疫病に注意'},
    {'name': 'キュウリ',     'soil': 'pH6.0〜7.0、保水性高め',    'seed': '4月',             'plant': '5月上旬',         'fert': '週1回、窒素多め',            'pest': 'うどんこ病に注意'},
    {'name': 'ナス',         'soil': 'pH6.0〜6.5、深耕が必要',    'seed': '2月',             'plant': '5月中旬',         'fert': '2週間に1回',                 'pest': 'テントウムシダマシに注意'},
    {'name': 'ピーマン',     'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '2〜3月',          'plant': '5月',             'fert': '2週間に1回',                 'pest': 'アブラムシに注意'},
    {'name': 'シシトウ',     'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '2〜3月',          'plant': '5月',             'fert': '2週間に1回',                 'pest': 'アブラムシに注意'},
    {'name': 'カボチャ',     'soil': 'pH5.5〜6.5、水はけ良好',    'seed': '4月',             'plant': '5月',             'fert': '着果後に追肥',               'pest': 'うどんこ病・アブラムシに注意'},
    {'name': 'スイカ',       'soil': 'pH5.5〜6.5、砂質土が良い',  'seed': '3〜4月',          'plant': '5月',             'fert': '着果後に追肥',               'pest': 'うどんこ病に注意'},
    {'name': 'トウモロコシ', 'soil': 'pH5.5〜6.5、肥沃な土',      'seed': '4〜5月',          'plant': '直播き',          'fert': '2週間に1回',                 'pest': 'アワノメイガに注意'},
    {'name': 'オクラ',       'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '5〜6月',          'plant': '5〜6月',          'fert': '2週間に1回',                 'pest': 'アブラムシ・カメムシに注意'},
    {'name': 'ゴーヤー',     'soil': 'pH5.5〜6.5、保水性高め',    'seed': '4〜5月',          'plant': '5月',             'fert': '2週間に1回',                 'pest': 'うどんこ病に注意'},
    {'name': 'レタス',       'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '3〜4月、9〜10月', 'plant': '4〜5月、10〜11月','fert': '2週間に1回',                 'pest': 'アブラムシに注意'},
    {'name': 'ブロッコリー', 'soil': 'pH6.0〜7.0、肥沃な土',      'seed': '7〜8月',          'plant': '8〜9月',          'fert': '2〜3週間に1回',              'pest': 'アオムシ・コナガに注意'},
    {'name': 'ほうれん草',   'soil': 'pH6.5〜7.0、アルカリ性好み','seed': '3〜5月、9〜10月', 'plant': '直播き',          'fert': '本葉2〜3枚で追肥',           'pest': 'べと病に注意'},
    {'name': 'キャベツ',     'soil': 'pH6.0〜6.5、肥沃な土',      'seed': '7〜8月',          'plant': '8〜9月',          'fert': '2〜3週間に1回',              'pest': 'アオムシ・コナガに注意'},
    {'name': 'ハクサイ',     'soil': 'pH6.0〜7.0、保水性高め',    'seed': '8〜9月',          'plant': '9月',             'fert': '2週間に1回',                 'pest': 'アブラムシ・コナガに注意'},
    {'name': 'ニンジン',     'soil': 'pH6.0〜6.5、深耕が必要',    'seed': '3〜4月、8〜9月',  'plant': '直播き',          'fert': '月1〜2回',                   'pest': 'キアゲハの幼虫に注意'},
    {'name': 'じゃがいも',   'soil': 'pH5.5〜6.0、水はけ良好',    'seed': '2〜3月（春）',    'plant': '種芋を植える',    'fert': '植付時と芽が出たら',         'pest': 'アブラムシ・疫病に注意'},
    {'name': 'タマネギ',     'soil': 'pH6.0〜6.5、肥沃な土',      'seed': '9〜10月',         'plant': '10〜11月',        'fert': '2〜3週間に1回',              'pest': 'べと病に注意'},
    {'name': 'ニンニク',     'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '9〜10月',         'plant': '鱗片を植える',    'fert': '2〜3週間に1回',              'pest': 'さび病に注意'},
    {'name': 'サツマイモ',   'soil': 'pH5.5〜6.5、やせ地でもOK',  'seed': '5月',             'plant': '5〜6月',          'fert': '少なめ（肥料過多は葉茂り）', 'pest': 'コガネムシの幼虫に注意'},
    {'name': '枝豆',         'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '4〜7月',          'plant': '直播きまたは移植','fert': '少なめ（根粒菌で窒素固定）', 'pest': 'カメムシ・アブラムシに注意'},
    {'name': 'そら豆',       'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '10〜11月',        'plant': '直播き',          'fert': '2〜3週間に1回',              'pest': 'アブラムシに注意'},
    {'name': 'スナップエンドウ','soil': 'pH6.0〜6.5、水はけ良好', 'seed': '10〜11月',        'plant': '直播き',          'fert': '2週間に1回',                 'pest': 'うどんこ病に注意'},
    {'name': 'バジル',       'soil': 'pH6.0〜7.0、水はけ良好',    'seed': '4〜6月',          'plant': '5〜6月',          'fert': '月1〜2回',                   'pest': 'アブラムシに注意'},
    {'name': 'シソ',         'soil': 'pH6.0〜6.5、保水性高め',    'seed': '4〜5月',          'plant': '5〜6月',          'fert': '2〜3週間に1回',              'pest': 'ハスモンヨトウに注意'},
    {'name': 'ダイコン',     'soil': 'pH6.0〜6.8、深耕が必要',    'seed': '3〜4月、8〜9月',  'plant': '直播き',          'fert': '月1〜2回',                   'pest': 'アブラムシ・べと病に注意'},
    {'name': 'ネギ',         'soil': 'pH6.0〜7.0、水はけ良好',    'seed': '3〜4月、8〜9月',  'plant': '5〜6月、10〜11月','fert': '2〜3週間に1回',              'pest': 'べと病・さび病に注意'},
    {'name': 'ニラ',         'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '3〜4月',          'plant': '春〜秋',          'fert': '収穫後に追肥',               'pest': 'アブラムシに注意'},
    {'name': 'こまつな',     'soil': 'pH6.0〜6.5、水はけ良好',    'seed': '3〜5月、9〜10月', 'plant': '直播き',          'fert': '2週間に1回',                 'pest': 'アブラムシ・コナガに注意'},
    {'name': 'チンゲン菜',   'soil': 'pH6.0〜6.8、水はけ良好',    'seed': '3〜5月、9〜10月', 'plant': '直播き',          'fert': '2週間に1回',                 'pest': 'アブラムシ・コナガに注意'},
  ];

  Map<String, String>? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('栽培ガイド 🌿', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: _selected != null
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _selected = null))
            : null,
      ),
      body: _selected == null ? _buildList() : _buildDetail(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guides.length,
      itemBuilder: (ctx, i) {
        final g = _guides[i];
        return GestureDetector(
          onTap: () => setState(() => _selected = g),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
                child: Center(child: Text(g['name']!.substring(0, 1),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('種まき: ${g['seed']} / 定植: ${g['plant']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildDetail() {
    final g = _selected!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
            child: Center(child: Text(g['name']!.substring(0, 1),
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green[800]))),
          ),
          const SizedBox(height: 8),
          Text(g['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _detailRow('🌍 土づくり',     g['soil']!),
          _detailRow('🌱 種まき時期',   g['seed']!),
          _detailRow('🌿 植え付け時期', g['plant']!),
          _detailRow('💧 肥料のあげ方', g['fert']!),
          _detailRow('🐛 病害虫対策',   g['pest']!),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

// ===== 作業日誌画面 =====
class DiaryPage extends StatefulWidget {
  final FieldInfo field;
  const DiaryPage({super.key, required this.field});
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<Map<String, dynamic>> _diaries = [];
  Timer? _pollTimer;

  DateTime _parseDiaryDate(dynamic value) {
    final s = value?.toString() ?? '';
    final parts = s.split('/');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return DateTime(y, m, d);
    }
    return DateTime.tryParse(s) ?? DateTime(1970);
  }

  @override
  void initState() {
    super.initState();
    _loadDiaries();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadDiaries());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDiaries() async {
    try {
      final data = await _sb
          .from('diaries')
          .select()
          .eq('field_id', widget.field.id);
      final list = List<Map<String, dynamic>>.from(data);
      list.sort((a, b) {
        final dateCompare = _parseDiaryDate(b['date']).compareTo(_parseDiaryDate(a['date']));
        if (dateCompare != 0) return dateCompare;
        // 同じ日付の場合はidが新しい方（＝あとで登録した方）を上に
        final idA = a['id'];
        final idB = b['id'];
        if (idA is num && idB is num) return idB.compareTo(idA);
        return 0;
      });
      if (mounted) setState(() => _diaries = list);
    } catch (e) {}
  }

  Future<void> _deleteDiary(dynamic id) async {
    if (id != null) await _sb.from('diaries').delete().eq('id', id);
    await _loadDiaries();
  }

  Future<String?> _pickImage() async {
    final completer = Completer<String?>();
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) { completer.complete(null); return; }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((_) async {
        final dataUrl = reader.result as String;
        final img = html.ImageElement();
        img.src = dataUrl;
        await img.onLoad.first;
        final canvas = html.CanvasElement();
        const maxW = 800;
        double w = img.naturalWidth!.toDouble();
        double h = img.naturalHeight!.toDouble();
        if (w > maxW) { h = h * maxW / w; w = maxW.toDouble(); }
        canvas.width = w.toInt();
        canvas.height = h.toInt();
        canvas.context2D.drawImageScaled(img, 0, 0, w, h);
        completer.complete(canvas.toDataUrl('image/jpeg', 0.7));
      });
      reader.onError.listen((_) => completer.complete(null));
    });
    return completer.future;
  }

  void _showAddDiaryDialog() {
    final cropCtrl = TextEditingController();
    final workCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? selectedImage;
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month}/${now.day}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: Text('${widget.field.name} 日誌を追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 $dateStr', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 8),
                TextField(controller: cropCtrl,
                    decoration: const InputDecoration(labelText: '作物名', hintText: '例：トマト')),
                const SizedBox(height: 8),
                TextField(controller: workCtrl,
                    decoration: const InputDecoration(labelText: '作業内容', hintText: '例：水やり・追肥・収穫')),
                const SizedBox(height: 8),
                TextField(controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'メモ（任意）'), maxLines: 3),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final img = await _pickImage();
                    if (img != null) setDS(() => selectedImage = img);
                  },
                  child: Container(
                    width: double.infinity,
                    height: selectedImage != null ? null : 80,
                    decoration: BoxDecoration(
                      color: Colors.green[50], borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: selectedImage != null
                        ? Stack(children: [
                            ClipRRect(borderRadius: BorderRadius.circular(12),
                                child: Image.network(selectedImage!, width: double.infinity, fit: BoxFit.cover)),
                            Positioned(top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setDS(() => selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ])
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_a_photo, color: Colors.green[400], size: 28),
                            Text('写真を追加（任意）', style: TextStyle(color: Colors.green[600], fontSize: 12)),
                          ]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: widget.field.color),
              onPressed: () async {
                final crop = cropCtrl.text.trim();
                final work = workCtrl.text.trim();
                if (crop.isNotEmpty && work.isNotEmpty) {
                  try {
                    await _sb.from('diaries').insert({
                      'date': dateStr,
                      'crop': crop,
                      'work': work,
                      'note': noteCtrl.text.trim(),
                      'field_id': widget.field.id,
                      if (selectedImage != null) 'image': selectedImage!,
                    });
                    Navigator.pop(ctx);
                    await _loadDiaries();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('${_diaries[index]["date"]} の「${_diaries[index]["crop"]}」を削除します'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { Navigator.pop(ctx); _deleteDiary(_diaries[index]['id']); },
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageData) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black, insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          Center(child: Image.network(imageData, fit: BoxFit.contain)),
          Positioned(top: 16, right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fc = widget.field.color;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: fc,
        title: Text('${widget.field.name} 日誌 📖',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _showAddDiaryDialog),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadDiaries),
        ],
      ),
      body: _diaries.isEmpty
          ? const Center(child: Text('日誌がありません。\n右上の＋ボタンで追加しましょう！',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diaries.length,
              itemBuilder: (ctx, i) {
                final d = _diaries[i];
                final hasImage = (d['image'] ?? '').toString().isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: fc, width: 4)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (hasImage)
                      GestureDetector(
                        onTap: () => _showFullImage(d['image'].toString()),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16), topRight: Radius.circular(12)),
                          child: Image.network(d['image'].toString(),
                              width: double.infinity, height: 180, fit: BoxFit.cover),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(d['crop']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Row(children: [
                            Text(d['date']?.toString() ?? '',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showDeleteConfirm(i),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            ),
                          ]),
                        ]),
                        const SizedBox(height: 6),
                        Text('作業: ${d["work"] ?? ""}', style: const TextStyle(fontSize: 13)),
                        if ((d['note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: fc.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                            child: Text('📝 ${d["note"]}', style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                        if (hasImage) ...[
                          const SizedBox(height: 4),
                          Text('📷 タップで拡大', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                        ],
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}

// ===== 肥料管理画面 =====
class FertilizerPage extends StatefulWidget {
  final FieldInfo field;
  const FertilizerPage({super.key, required this.field});
  @override
  State<FertilizerPage> createState() => _FertilizerPageState();
}

class _FertilizerPageState extends State<FertilizerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _fertilizers = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecords();
    _loadFertilizers();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRecords();
      _loadFertilizers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    try {
      final data = await _sb
          .from('fertilizer_records')
          .select()
          .eq('field_id', widget.field.id)
          .order('date', ascending: false);
      if (mounted) setState(() => _records = List<Map<String, dynamic>>.from(data));
    } catch (e) {}
  }

  Future<void> _loadFertilizers() async {
    try {
      final data = await _sb.from('fertilizers').select().order('id', ascending: true);
      if (mounted) setState(() => _fertilizers = List<Map<String, dynamic>>.from(data));
    } catch (e) {}
  }

  void _showAddRecordDialog() {
    if (_fertilizers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に「肥料の種類」タブで肥料を登録してください')));
      _tabController.animateTo(1);
      return;
    }
    final cropCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selFert = _fertilizers[0]['name']?.toString() ?? '';
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month}/${now.day}';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: const Text('施肥を記録'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 $dateStr', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 12),
                TextField(controller: cropCtrl,
                    decoration: const InputDecoration(labelText: '作物名', hintText: '例：トマト')),
                const SizedBox(height: 8),
                const Text('使用した肥料', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selFert,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _fertilizers.map((f) => DropdownMenuItem(
                    value: f['name']?.toString() ?? '',
                    child: Text(f['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDS(() => selFert = v ?? ''),
                ),
                const SizedBox(height: 8),
                TextField(controller: amountCtrl,
                    decoration: const InputDecoration(labelText: '使用量', hintText: '例：100g、500ml')),
                const SizedBox(height: 8),
                TextField(controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'メモ（任意）'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
              onPressed: () async {
                final crop = cropCtrl.text.trim();
                if (crop.isNotEmpty && selFert.isNotEmpty) {
                  try {
                    await _sb.from('fertilizer_records').insert({
                      'date': dateStr,
                      'crop': crop,
                      'fert': selFert,
                      'amount': amountCtrl.text.trim(),
                      'note': noteCtrl.text.trim(),
                      'field_id': widget.field.id,
                    });
                    Navigator.pop(ctx);
                    await _loadRecords();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('記録', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFertilizerDialog() {
    final nameCtrl = TextEditingController();
    final npkCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selType = '化成';
    final types = ['化成', '有機', '液肥', 'その他'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          title: const Text('肥料を登録'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '肥料名', hintText: '例：化成肥料 8-8-8')),
                const SizedBox(height: 8),
                const Text('種類', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: types.map((t) => GestureDetector(
                    onTap: () => setDS(() => selType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selType == t ? Colors.orange[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t, style: TextStyle(
                          color: selType == t ? Colors.white : Colors.black, fontSize: 12)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                TextField(controller: npkCtrl,
                    decoration: const InputDecoration(labelText: 'N-P-K（任意）', hintText: '例：N8-P8-K8')),
                const SizedBox(height: 8),
                TextField(controller: noteCtrl,
                    decoration: const InputDecoration(labelText: '特徴・メモ', hintText: '例：元肥に最適'),
                    maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await _sb.from('fertilizers').insert({
                      'name': name,
                      'type': selType,
                      'npk': npkCtrl.text.isEmpty ? '−' : npkCtrl.text.trim(),
                      'note': noteCtrl.text.trim(),
                    });
                    Navigator.pop(ctx);
                    await _loadFertilizers();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              child: const Text('登録', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case '化成': return Colors.blue;
      case '有機': return Colors.brown;
      case '液肥': return Colors.cyan[700]!;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        title: Text('${widget.field.name} 肥料管理 🌿',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _tabController.index == 0
                ? _showAddRecordDialog()
                : _showAddFertilizerDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { _loadRecords(); _loadFertilizers(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: '施肥記録'),
            Tab(icon: Icon(Icons.inventory), text: '肥料の種類'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRecordList(), _buildFertilizerList()],
      ),
    );
  }

  Widget _buildRecordList() {
    if (_records.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text('施肥の記録がありません', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text('右上の＋ボタンで記録しましょう', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (ctx, i) {
        final r = _records[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: Colors.orange[700]!, width: 4)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(r['crop']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Row(children: [
                Text(r['date']?.toString() ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showDialog(context: ctx, builder: (c2) => AlertDialog(
                    title: const Text('削除しますか？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c2), child: const Text('キャンセル')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await _sb.from('fertilizer_records').delete().eq('id', r['id']);
                          Navigator.pop(c2);
                          await _loadRecords();
                        },
                        child: const Text('削除', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
              ]),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.science, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Expanded(child: Text(
                  '${r['fert'] ?? ''}${(r['amount'] ?? '').toString().isNotEmpty ? '　${r['amount']}' : ''}',
                  style: const TextStyle(fontSize: 13))),
            ]),
            if ((r['note'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                child: Text('📝 ${r['note']}', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ]),
        );
      },
    );
  }

  Widget _buildFertilizerList() {
    if (_fertilizers.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text('肥料が登録されていません', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text('右上の＋ボタンで登録しましょう', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fertilizers.length,
      itemBuilder: (ctx, i) {
        final f = _fertilizers[i];
        final color = _typeColor(f['type']?.toString() ?? 'その他');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(f['type']?.toString() ?? '',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f['name']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if ((f['npk']?.toString() ?? '−') != '−') ...[
                const SizedBox(height: 2),
                Text('NPK: ${f['npk']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
              if ((f['note'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(f['note'].toString(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ])),
            GestureDetector(
              onTap: () => showDialog(context: ctx, builder: (c2) => AlertDialog(
                title: const Text('削除しますか？'),
                content: Text('「${f['name']}」を削除します'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c2), child: const Text('キャンセル')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await _sb.from('fertilizers').delete().eq('id', f['id']);
                      Navigator.pop(c2);
                      await _loadFertilizers();
                    },
                    child: const Text('削除', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
          ]),
        );
      },
    );
  }
}
