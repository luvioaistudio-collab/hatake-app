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
        // 認証済みならそのままホームへ
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
      try {
        html.window.localStorage[_storageKey] = _password;
      } catch (e) {}
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
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
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grass, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('畑ノート 🌱',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('パスワードを入力してください',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  // HomePageの再読み込みを制御するキー
  Key _homeKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomePage(key: _homeKey),
      const FieldMapPage(),
      const GuidePage(),
      const DiaryPage(),
      const FertilizerPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // 畑マップ(1)からホーム(0)に戻るときにHomePageを再生成して野菜を再読み込み
          if (index == 0 && _currentIndex != 0) {
            setState(() {
              _homeKey = UniqueKey();
              _currentIndex = index;
            });
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
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
  }
}

// ===== ホーム画面 =====
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _tasks = [
    {'emoji': '🌱', 'text': 'トマトの水やり', 'done': false},
    {'emoji': '🌿', 'text': 'ナスの支柱組み', 'done': false},
    {'emoji': '🌾', 'text': '肥料やり（トマト）', 'done': false},
  ];

  // 畑マップから読み込んだ野菜リスト
  List<Map<String, String>> _fieldCrops = [];

  // 生駒市の天気（Open-Meteo APIを使用）
  List<Map<String, dynamic>> _weather = [];
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadFieldCrops();
    _fetchWeather();
  }

  StreamSubscription? _cropHomeSub;

  // ★機能1: 畑マップから野菜を読み込む（Supabase）
  void _loadFieldCrops() {
    _cropHomeSub?.cancel();
    _cropHomeSub = _sb.from('crops').stream(primaryKey: ['id']).listen((data) {
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
    });
  }

  // ★機能2: 生駒市（奈良県）の天気を取得
  // Open-Meteo API（無料・APIキー不要）
  // 生駒市: 緯度 34.6937, 経度 135.7010
  Future<void> _fetchWeather() async {
    setState(() => _weatherLoading = true);
    try {
      // Open-Meteo APIで週間天気を取得
      final url = 'https://api.open-meteo.com/v1/forecast'
          '?latitude=34.6937&longitude=135.7010'
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
            .map((e) => (e as num).toDouble())
            .toList();

        final List<Map<String, dynamic>> weatherList = [];
        final dayLabels = ['今日', '明日', '水', '木', '金', '土', '日'];

        for (int i = 0; i < min(5, dates.length); i++) {
          final date = DateTime.parse(dates[i]);
          String label;
          if (i < 2) {
            label = dayLabels[i];
          } else {
            const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
            label = weekdays[date.weekday - 1];
          }
          weatherList.add({
            'label': label,
            'icon': _weatherCodeToEmoji(codes[i]),
            'temp': '${maxTemps[i].round()}°',
          });
        }
        setState(() {
          _weather = weatherList;
          _weatherLoading = false;
        });
      } else {
        _setFallbackWeather();
      }
    } catch (e) {
      _setFallbackWeather();
    }
  }

  void _setFallbackWeather() {
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

  String _weatherCodeToEmoji(int code) {
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

  StreamSubscription? _taskSub;

  @override
  void dispose() {
    _taskSub?.cancel();
    _cropHomeSub?.cancel();
    super.dispose();
  }

  void _loadTasks() {
    _taskSub?.cancel();
    _taskSub = _sb.from('tasks').stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
      if (mounted) setState(() => _tasks = List<Map<String, dynamic>>.from(data));
    });
  }

  void _saveTasks() {} // Supabase使用のため不要

  void _toggleTask(int index) async {
    final t = _tasks[index];
    await _sb.from('tasks').update({'done': !(t['done'] ?? false)}).eq('id', t['id']);
  }

  void _deleteTask(int index) async {
    await _sb.from('tasks').delete().eq('id', _tasks[index]['id']);
  }

  void _showAddTaskDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '例：トマトの水やり'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _sb.from('tasks').insert({'emoji': '📝', 'text': controller.text, 'done': false});
                Navigator.pop(context);
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
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${_tasks[index]['text']}」を削除します'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { _deleteTask(index); Navigator.pop(context); },
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _tasks.where((t) => t['done'] == true).length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('畑ノート 🌱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadFieldCrops();
              _fetchWeather();
            },
            tooltip: '更新',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ★天気ウィジェット（生駒市）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green[700]!, Colors.green[400]!]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('今週の天気', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(width: 4),
                      Text('📍生駒市', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _weatherLoading
                      ? const Center(child: SizedBox(
                          height: 48,
                          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _weather
                              .map((w) => _weatherItem(w['label'], w['icon'], w['temp']))
                              .toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ★畑マップの野菜一覧
            if (_fieldCrops.isNotEmpty) ...[
              const Text('🌾 畑マップの野菜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fieldCrops.length,
                  itemBuilder: (context, index) {
                    final crop = _fieldCrops[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.grass, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(crop['name'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.green[400], size: 20),
                    const SizedBox(width: 8),
                    Text('畑マップに野菜を登録すると、ここに表示されます',
                        style: TextStyle(color: Colors.green[700], fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 今日の作業
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
            ..._tasks.asMap().entries.map((entry) => _taskItem(entry.key, entry.value)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _weatherItem(String day, String icon, String temp) {
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(icon, style: const TextStyle(fontSize: 20)),
        Text(temp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _taskItem(int index, Map<String, dynamic> task) {
    final bool done = task['done'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Text(task['emoji'] ?? '📝', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(task['text'] ?? '',
              style: TextStyle(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _showDeleteConfirm(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toggleTask(index),
            child: Icon(done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? Colors.green : Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ===== 畑マップ画面（4×6 = 24マス）=====
class FieldMapPage extends StatefulWidget {
  const FieldMapPage({super.key});

  @override
  State<FieldMapPage> createState() => _FieldMapPageState();
}

class _FieldMapPageState extends State<FieldMapPage> {
  Map<String, Map<String, String>> _crops = {};

  final List<Map<String, String>> _cropOptions = [
    // 実野菜（12種類）
    {'emoji': '🍅', 'name': 'トマト',       'category': '実野菜'},
    {'emoji': '🥒', 'name': 'キュウリ',     'category': '実野菜'},
    {'emoji': '🍆', 'name': 'ナス',         'category': '実野菜'},
    {'emoji': '🥦', 'name': 'ピーマン',     'category': '実野菜'},
    {'emoji': '🌶', 'name': 'シシトウ',    'category': '実野菜'},
    {'emoji': '🌶', 'name': 'トウガラシ',  'category': '実野菜'},
    {'emoji': '🎃', 'name': 'カボチャ',     'category': '実野菜'},
    {'emoji': '🍉', 'name': 'スイカ',       'category': '実野菜'},
    {'emoji': '🌽', 'name': 'トウモロコシ', 'category': '実野菜'},
    {'emoji': '🍓', 'name': 'イチゴ',       'category': '実野菜'},
    {'emoji': '🌱', 'name': 'オクラ',       'category': '実野菜'},
    {'emoji': '🥬', 'name': 'ゴーヤー',     'category': '実野菜'},
    // 葉・茎もの野菜（15種類）
    {'emoji': '🥬', 'name': 'レタス',         'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'ミックスレタス', 'category': '葉・茎もの'},
    {'emoji': '🥦', 'name': 'ブロッコリー',   'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ほうれん草',     'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'こまつな',       'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'キャベツ',       'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'ハクサイ',       'category': '葉・茎もの'},
    {'emoji': '🥬', 'name': 'チンゲン菜',     'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'シュンギク',     'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ミズナ',         'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ツルムラサキ',   'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ニラ',           'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ネギ',           'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'ワケギ',         'category': '葉・茎もの'},
    {'emoji': '🌿', 'name': 'タカナ',         'category': '葉・茎もの'},
    // 根菜
    {'emoji': '🥕', 'name': 'ニンジン',   'category': '根菜'},
    {'emoji': '🥔', 'name': 'じゃがいも', 'category': '根菜'},
    {'emoji': '🧅', 'name': 'タマネギ',   'category': '根菜'},
    {'emoji': '🧄', 'name': 'ニンニク',   'category': '根菜'},
    {'emoji': '🌰', 'name': 'サトイモ',   'category': '根菜'},
    {'emoji': '🍠', 'name': 'サツマイモ', 'category': '根菜'},
    {'emoji': '🥕', 'name': 'ダイコン',   'category': '根菜'},
    {'emoji': '🥔', 'name': 'カブ',       'category': '根菜'},
    {'emoji': '🌿', 'name': 'ゴボウ',     'category': '根菜'},
    // 豆類（5種類）
    {'emoji': '🌱', 'name': '枝豆',           'category': '豆類'},
    {'emoji': '🌱', 'name': 'そら豆',         'category': '豆類'},
    {'emoji': '🌱', 'name': 'えんどう豆',     'category': '豆類'},
    {'emoji': '🌱', 'name': 'スナップエンドウ','category': '豆類'},
    {'emoji': '🌱', 'name': 'インゲン',       'category': '豆類'},
    // ハーブ（4種類）
    {'emoji': '🌿', 'name': 'バジル',  'category': 'ハーブ'},
    {'emoji': '🍃', 'name': 'シソ',    'category': 'ハーブ'},
    {'emoji': '🌿', 'name': 'パセリ',  'category': 'ハーブ'},
    {'emoji': '🌸', 'name': 'ミント',  'category': 'ハーブ'},
  ];

  StreamSubscription? _cropSub;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  @override
  void dispose() {
    _cropSub?.cancel();
    super.dispose();
  }

  void _loadCrops() {
    _cropSub?.cancel();
    _cropSub = _sb.from('crops').stream(primaryKey: ['id']).listen((data) {
      if (mounted) {
        setState(() {
          _crops = {};
          for (final c in data) {
            final pos = c['position'] as String? ?? '';
            if (pos.isNotEmpty) {
              _crops[pos] = {'emoji': c['emoji'] ?? '', 'name': c['name'] ?? ''};
            }
          }
        });
      }
    });
  }

  void _saveCrops() {} // Supabase使用のため不要

  void _showPlaceCropDialog(String key) {
    String selectedCategory = 'すべて';
    final categories = ['すべて', '実野菜', '葉・茎もの', '根菜', '豆類', 'ハーブ'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = selectedCategory == 'すべて'
              ? _cropOptions
              : _cropOptions.where((c) => c['category'] == selectedCategory).toList();
          return AlertDialog(
            title: const Text('作物を選択'),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) => GestureDetector(
                        onTap: () => setDialogState(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: selectedCategory == cat ? Colors.green[700] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cat, style: TextStyle(
                            color: selectedCategory == cat ? Colors.white : Colors.black,
                            fontSize: 12,
                          )),
                        ),
                      )).toList(),
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      children: filtered.map((crop) => GestureDetector(
                        onTap: () async {
                          final existing = await _sb.from('crops').select().eq('position', key).maybeSingle();
                          if (existing == null) {
                            await _sb.from('crops').insert({'position': key, 'emoji': crop['emoji']!, 'name': crop['name']!});
                          } else {
                            await _sb.from('crops').update({'emoji': crop['emoji']!, 'name': crop['name']!}).eq('id', existing['id']);
                          }
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(crop['emoji']!, style: const TextStyle(fontSize: 24)),
                            Text(crop['name']!, style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center),
                          ]),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_crops[key] != null)
                TextButton(
                  onPressed: () async {
                    final existing = await _sb.from('crops').select().eq('position', key).maybeSingle();
                    if (existing != null) await _sb.from('crops').delete().eq('id', existing['id']);
                    Navigator.pop(context);
                  },
                  child: const Text('このマスを空にする', style: TextStyle(color: Colors.red)),
                ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('畑マップ 🗺️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text('マスをタップして作物を配置・変更できます', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6914),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: 24,
                  itemBuilder: (context, index) {
                    final row = index ~/ 4;
                    final col = index % 4;
                    final key = '$row-$col';
                    final crop = _crops[key];
                    return GestureDetector(
                      onTap: () => _showPlaceCropDialog(key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: crop != null ? Colors.green[100] : Colors.brown[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: crop != null
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(
                                  crop['name']!.substring(0, 1),
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
                                ),
                                Text(crop['name']!, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                              ])
                            : const Icon(Icons.add, color: Colors.white54, size: 20),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 栽培ガイド画面 =====
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final List<Map<String, String>> _guides = [
    {'emoji': '🍅', 'name': 'トマト',       'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '2〜3月',         'plant': '4〜5月',       'fert': '2週間に1回、カリ多め',       'pest': 'アブラムシ・疫病に注意'},
    {'emoji': '🥒', 'name': 'キュウリ',     'soil': 'pH6.0〜7.0、保水性高め',   'seed': '4月',            'plant': '5月上旬',       'fert': '週1回、窒素多め',            'pest': 'うどんこ病に注意'},
    {'emoji': '🍆', 'name': 'ナス',         'soil': 'pH6.0〜6.5、深耕が必要',   'seed': '2月',            'plant': '5月中旬',       'fert': '2週間に1回',                 'pest': 'テントウムシダマシに注意'},
    {'emoji': '🥦', 'name': 'ピーマン',     'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '2〜3月',         'plant': '5月',           'fert': '2週間に1回',                 'pest': 'アブラムシに注意'},
    {'emoji': '🌶', 'name': 'シシトウ',    'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '2〜3月',         'plant': '5月',           'fert': '2週間に1回',                 'pest': 'アブラムシに注意'},
    {'emoji': '🎃', 'name': 'カボチャ',     'soil': 'pH5.5〜6.5、水はけ良好',   'seed': '4月',            'plant': '5月',           'fert': '着果後に追肥',               'pest': 'うどんこ病・アブラムシに注意'},
    {'emoji': '🍉', 'name': 'スイカ',       'soil': 'pH5.5〜6.5、砂質土が良い', 'seed': '3〜4月',         'plant': '5月',           'fert': '着果後に追肥',               'pest': 'うどんこ病に注意'},
    {'emoji': '🌽', 'name': 'トウモロコシ', 'soil': 'pH5.5〜6.5、肥沃な土',     'seed': '4〜5月',         'plant': '直播き',        'fert': '2週間に1回',                 'pest': 'アワノメイガに注意'},
    {'emoji': '🌱', 'name': 'オクラ',       'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '5〜6月',         'plant': '5〜6月',        'fert': '2週間に1回',                 'pest': 'アブラムシ・カメムシに注意'},
    {'emoji': '🥬', 'name': 'ゴーヤー',     'soil': 'pH5.5〜6.5、保水性高め',   'seed': '4〜5月',         'plant': '5月',           'fert': '2週間に1回',                 'pest': 'うどんこ病に注意'},
    {'emoji': '🥬', 'name': 'レタス',       'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '3〜4月、9〜10月','plant': '4〜5月、10〜11月','fert': '2週間に1回',                'pest': 'アブラムシに注意'},
    {'emoji': '🥦', 'name': 'ブロッコリー', 'soil': 'pH6.0〜7.0、肥沃な土',     'seed': '7〜8月',         'plant': '8〜9月',        'fert': '2〜3週間に1回',              'pest': 'アオムシ・コナガに注意'},
    {'emoji': '🌿', 'name': 'ほうれん草',   'soil': 'pH6.5〜7.0、アルカリ性好み','seed': '3〜5月、9〜10月','plant': '直播き',        'fert': '本葉2〜3枚で追肥',          'pest': 'べと病に注意'},
    {'emoji': '🥬', 'name': 'キャベツ',     'soil': 'pH6.0〜6.5、肥沃な土',     'seed': '7〜8月',         'plant': '8〜9月',        'fert': '2〜3週間に1回',              'pest': 'アオムシ・コナガに注意'},
    {'emoji': '🥬', 'name': 'ハクサイ',     'soil': 'pH6.0〜7.0、保水性高め',   'seed': '8〜9月',         'plant': '9月',           'fert': '2週間に1回',                 'pest': 'アブラムシ・コナガに注意'},
    {'emoji': '🌿', 'name': 'シュンギク',   'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '3〜5月、9〜10月','plant': '直播き',        'fert': '2〜3週間に1回',              'pest': 'アブラムシに注意'},
    {'emoji': '🌿', 'name': 'ミズナ',       'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '3〜5月、9〜10月','plant': '直播き',        'fert': '2週間に1回',                 'pest': 'アブラムシに注意'},
    {'emoji': '🌿', 'name': 'ニラ',         'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '3〜4月',         'plant': '春〜秋',        'fert': '収穫後に追肥',               'pest': 'アブラムシに注意'},
    {'emoji': '🌿', 'name': 'ネギ',         'soil': 'pH6.0〜7.0、水はけ良好',   'seed': '3〜4月、8〜9月', 'plant': '5〜6月、10〜11月','fert': '2〜3週間に1回',             'pest': 'べと病・さび病に注意'},
    {'emoji': '🥕', 'name': 'ニンジン',     'soil': 'pH6.0〜6.5、深耕が必要',   'seed': '3〜4月、8〜9月', 'plant': '直播き',        'fert': '月1〜2回',                   'pest': 'キアゲハの幼虫に注意'},
    {'emoji': '🥔', 'name': 'じゃがいも',   'soil': 'pH5.5〜6.0、水はけ良好',   'seed': '2〜3月（春）、8月（秋）','plant': '種芋を植える','fert': '植付時と芽が出たら',       'pest': 'アブラムシ・疫病に注意'},
    {'emoji': '🧅', 'name': 'タマネギ',     'soil': 'pH6.0〜6.5、肥沃な土',     'seed': '9〜10月',        'plant': '10〜11月',      'fert': '2〜3週間に1回',              'pest': 'べと病に注意'},
    {'emoji': '🧄', 'name': 'ニンニク',     'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '9〜10月',        'plant': '鱗片を植える',  'fert': '2〜3週間に1回',              'pest': 'さび病に注意'},
    {'emoji': '🍠', 'name': 'サツマイモ',   'soil': 'pH5.5〜6.5、やせ地でもOK', 'seed': '5月',            'plant': '5〜6月',        'fert': '少なめ（肥料過多は葉茂り）', 'pest': 'コガネムシの幼虫に注意'},
    {'emoji': '🌿', 'name': 'ゴボウ',       'soil': 'pH6.0〜6.5、深耕が必要',   'seed': '3〜4月',         'plant': '直播き',        'fert': '月1回',                      'pest': 'アブラムシに注意'},
    {'emoji': '🌱', 'name': '枝豆',         'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '4〜7月',         'plant': '直播きまたは移植','fert': '少なめ（根粒菌で窒素固定）', 'pest': 'カメムシ・アブラムシに注意'},
    {'emoji': '🌱', 'name': 'そら豆',       'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '10〜11月',       'plant': '直播き',        'fert': '2〜3週間に1回',              'pest': 'アブラムシに注意'},
    {'emoji': '🌱', 'name': 'スナップエンドウ','soil': 'pH6.0〜6.5、水はけ良好', 'seed': '10〜11月',       'plant': '直播き',        'fert': '2週間に1回',                 'pest': 'うどんこ病に注意'},
    {'emoji': '🌿', 'name': 'バジル',       'soil': 'pH6.0〜7.0、水はけ良好',   'seed': '4〜6月',         'plant': '5〜6月',        'fert': '月1〜2回',                   'pest': 'アブラムシに注意'},
    {'emoji': '🍃', 'name': 'シソ',         'soil': 'pH6.0〜6.5、保水性高め',   'seed': '4〜5月',         'plant': '5〜6月',        'fert': '2〜3週間に1回',              'pest': 'ハスモンヨトウに注意'},
    {'emoji': '🌿', 'name': 'パセリ',       'soil': 'pH6.0〜7.0、水はけ良好',   'seed': '3〜5月',         'plant': '4〜6月',        'fert': '月1〜2回',                   'pest': 'キアゲハの幼虫に注意'},
    {'emoji': '🌸', 'name': 'ミント',       'soil': 'pH6.0〜7.0、保水性高め',   'seed': '3〜5月',         'plant': '4〜6月',        'fert': '月1〜2回',                   'pest': 'アブラムシに注意'},
    {'emoji': '🥕', 'name': 'ダイコン',     'soil': 'pH6.0〜6.8、深耕が必要',   'seed': '3〜4月、8〜9月', 'plant': '直播き',        'fert': '月1〜2回',                   'pest': 'アブラムシ・べと病に注意'},
    {'emoji': '🌰', 'name': 'サトイモ',     'soil': 'pH6.0〜6.5、保水性高め',   'seed': '4〜5月',         'plant': '種芋を植える',  'fert': '2〜3週間に1回',              'pest': 'アブラムシ・疫病に注意'},
    {'emoji': '🌿', 'name': 'こまつな',     'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '3〜5月、9〜10月','plant': '直播き',        'fert': '2週間に1回',                 'pest': 'アブラムシ・コナガに注意'},
    {'emoji': '🥬', 'name': 'チンゲン菜',   'soil': 'pH6.0〜6.8、水はけ良好',   'seed': '3〜5月、9〜10月','plant': '直播き',        'fert': '2週間に1回',                 'pest': 'アブラムシ・コナガに注意'},
    {'emoji': '🌿', 'name': 'ツルムラサキ', 'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '5〜6月',         'plant': '5〜6月',        'fert': '2週間に1回',                 'pest': 'アブラムシに注意'},
    {'emoji': '🌿', 'name': 'ワケギ',       'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '8〜9月',         'plant': '鱗片を植える',  'fert': '2〜3週間に1回',              'pest': 'べと病に注意'},
    {'emoji': '🥬', 'name': 'ミックスレタス','soil': 'pH6.0〜6.5、水はけ良好',  'seed': '3〜4月、9〜10月','plant': '4〜5月、10〜11月','fert': '2週間に1回',                'pest': 'アブラムシに注意'},
    {'emoji': '🌶', 'name': 'トウガラシ',  'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '2〜3月',         'plant': '5月',           'fert': '2週間に1回',                 'pest': 'アブラムシ・タバコガに注意'},
    {'emoji': '🍓', 'name': 'イチゴ',       'soil': 'pH5.5〜6.5、水はけ良好',   'seed': '9〜10月',        'plant': '10〜11月',      'fert': '月1〜2回',                   'pest': 'アブラムシ・うどんこ病に注意'},
    {'emoji': '🌱', 'name': 'えんどう豆',   'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '10〜11月',       'plant': '直播き',        'fert': '2〜3週間に1回',              'pest': 'うどんこ病に注意'},
    {'emoji': '🌱', 'name': 'インゲン',     'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '4〜7月',         'plant': '直播き',        'fert': '2週間に1回（少なめ）',       'pest': 'アブラムシ・カメムシに注意'},
    {'emoji': '🌿', 'name': 'タカナ',       'soil': 'pH6.0〜6.5、水はけ良好',   'seed': '9〜10月',        'plant': '10〜11月',      'fert': '2〜3週間に1回',              'pest': 'アブラムシに注意'},
  ];
  Map<String, String>? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('栽培ガイド 🌿', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: _selected != null
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() => _selected = null))
            : null,
      ),
      body: _selected == null ? _buildList() : _buildDetail(),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guides.length,
      itemBuilder: (context, index) {
        final g = _guides[index];
        return GestureDetector(
          onTap: () => setState(() => _selected = g),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      g['name']!.substring(0, 1),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('種まき: ${g['seed']} / 定植: ${g['plant']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ])),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
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
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  g['name']!.substring(0, 1),
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(g['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _detailRow('🌍 土づくり',     g['soil']!),
            _detailRow('🌱 種まき時期',   g['seed']!),
            _detailRow('🌿 植え付け時期', g['plant']!),
            _detailRow('💧 肥料のあげ方', g['fert']!),
            _detailRow('🐛 病害虫対策',   g['pest']!),
          ],
        ),
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

// ===== 作業日誌画面（写真対応版）=====
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<Map<String, String>> _diaries = [];

  StreamSubscription? _diarySub;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  @override
  void dispose() {
    _diarySub?.cancel();
    super.dispose();
  }

  void _loadDiaries() {
    _diarySub?.cancel();
    _diarySub = _sb.from('diaries').stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .listen((data) {
      if (mounted) setState(() => _diaries = List<Map<String, dynamic>>.from(data).map((e) => e.map((k,v) => MapEntry(k, v?.toString() ?? ''))).toList());
    });
  }

  void _saveDiaries() {} // Supabase使用のため不要

  Future<void> _deleteDiary(int index) async {
    final id = _diaries[index]['id'];
    if (id != null) await _sb.from('diaries').delete().eq('id', id);
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
        final ctx = canvas.context2D;
        ctx.drawImageScaled(img, 0, 0, w, h);
        final compressed = canvas.toDataUrl('image/jpeg', 0.7);
        completer.complete(compressed);
      });
      reader.onError.listen((_) => completer.complete(null));
    });
    return completer.future;
  }

  void _showAddDiaryDialog() {
    final cropController = TextEditingController();
    final workController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedImage;
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month}/${now.day}';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('日誌を追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 $dateStr', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 8),
                TextField(controller: cropController,
                    decoration: const InputDecoration(labelText: '作物名', hintText: '例：トマト')),
                const SizedBox(height: 8),
                TextField(controller: workController,
                    decoration: const InputDecoration(labelText: '作業内容', hintText: '例：水やり・追肥・収穫')),
                const SizedBox(height: 8),
                TextField(controller: noteController,
                    decoration: const InputDecoration(labelText: 'メモ（任意）', hintText: '気づいたことなど'),
                    maxLines: 3),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final img = await _pickImage();
                    if (img != null) setDialogState(() => selectedImage = img);
                  },
                  child: Container(
                    width: double.infinity,
                    height: selectedImage != null ? null : 100,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: selectedImage != null
                        ? Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(selectedImage!, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => setDialogState(() => selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ])
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_a_photo, color: Colors.green[400], size: 32),
                            const SizedBox(height: 4),
                            Text('写真を追加（任意）', style: TextStyle(color: Colors.green[600], fontSize: 12)),
                          ]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () async {
                if (cropController.text.isNotEmpty && workController.text.isNotEmpty) {
                  final entry = {
                    'date': dateStr,
                    'crop': cropController.text,
                    'work': workController.text,
                    'note': noteController.text,
                    if (selectedImage != null) 'image': selectedImage!,
                  };
                  await _sb.from('diaries').insert(entry);
                  Navigator.pop(context);
                }
              },
              child: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDiaryConfirm(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('${_diaries[index]["date"]} の「${_diaries[index]["crop"]}」の日誌を削除します'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async { await _deleteDiary(index); Navigator.pop(context); },
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          Center(child: Image.network(imageData, fit: BoxFit.contain)),
          Positioned(top: 16, right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('作業日誌 📖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _showAddDiaryDialog),
        ],
      ),
      body: _diaries.isEmpty
          ? const Center(child: Text('日誌がありません。\n右上の＋ボタンで追加しましょう！',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final d = _diaries[index];
                final hasImage = d['image'] != null && d['image']!.isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: Colors.green[700]!, width: 4)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (hasImage)
                      GestureDetector(
                        onTap: () => _showFullImage(d['image']!),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(12),
                          ),
                          child: Image.network(d['image']!, width: double.infinity, height: 180, fit: BoxFit.cover),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(d['crop'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Row(children: [
                            Text(d['date'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showDeleteDiaryConfirm(index),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            ),
                          ]),
                        ]),
                        const SizedBox(height: 6),
                        Text('作業: ${d["work"]}', style: const TextStyle(fontSize: 13)),
                        if (d['note'] != null && d['note']!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
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

// ===== 肥料管理画面（★新規追加）=====
class FertilizerPage extends StatefulWidget {
  const FertilizerPage({super.key});

  @override
  State<FertilizerPage> createState() => _FertilizerPageState();
}

class _FertilizerPageState extends State<FertilizerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 施肥記録
  List<Map<String, String>> _records = [];

  // 肥料の種類
  List<Map<String, String>> _fertilizers = [
    {'name': '化成肥料 8-8-8', 'type': '化成', 'npk': 'N8-P8-K8', 'note': '万能肥料。元肥・追肥に'},
    {'name': '有機配合肥料',   'type': '有機', 'npk': 'N4-P6-K2', 'note': '土づくりに。元肥向け'},
    {'name': '液肥（ハイポネックス）', 'type': '液肥', 'npk': 'N6-P10-K5', 'note': '水やりと同時に。即効性あり'},
    {'name': '苦土石灰', 'type': 'その他', 'npk': '−', 'note': 'pH調整用。植付2週間前に'},
    {'name': '牛糞堆肥', 'type': '有機', 'npk': 'N1-P1-K1', 'note': '土壌改良・元肥に'},
  ];

  StreamSubscription? _recSub, _fertSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recSub?.cancel();
    _fertSub?.cancel();
    super.dispose();
  }

  void _loadData() {
    _recSub?.cancel();
    _fertSub?.cancel();
    _recSub = _sb.from('fertilizer_records').stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .listen((data) {
      if (mounted) setState(() => _records = List<Map<String, dynamic>>.from(data).map((e) => e.map((k,v) => MapEntry(k, v?.toString() ?? ''))).toList());
    });
    _fertSub = _sb.from('fertilizers').stream(primaryKey: ['id']).listen((data) {
      if (mounted) setState(() => _fertilizers = List<Map<String, dynamic>>.from(data).map((e) => e.map((k,v) => MapEntry(k, v?.toString() ?? ''))).toList());
    });
  }

  void _saveRecords() {} // Supabase使用のため不要
  void _saveFertilizers() {} // Supabase使用のため不要

  // 施肥記録を追加
  void _showAddRecordDialog() {
    final cropController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedFert = _fertilizers.isNotEmpty ? _fertilizers[0]['name']! : '';
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month}/${now.day}';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('施肥を記録'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 $dateStr', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: cropController,
                  decoration: const InputDecoration(labelText: '作物名', hintText: '例：🍅 トマト'),
                ),
                const SizedBox(height: 8),
                const Text('使用した肥料', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                if (_fertilizers.isEmpty)
                  const Text('先に肥料を登録してください', style: TextStyle(color: Colors.red, fontSize: 12))
                else
                  DropdownButtonFormField<String>(
                    value: selectedFert,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: _fertilizers.map((f) => DropdownMenuItem(
                      value: f['name'],
                      child: Text(f['name']!, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedFert = v ?? ''),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: '使用量', hintText: '例：100g、500ml'),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'メモ（任意）', hintText: '気づいたことなど'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
              onPressed: () async {
                if (cropController.text.isNotEmpty && selectedFert.isNotEmpty) {
                  await _sb.from('fertilizer_records').insert({
                    'date': dateStr,
                    'crop': cropController.text,
                    'fert': selectedFert,
                    'amount': amountController.text,
                    'note': noteController.text,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('記録', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 肥料を追加
  void _showAddFertilizerDialog() {
    final nameController = TextEditingController();
    final npkController = TextEditingController();
    final noteController = TextEditingController();
    String selectedType = '化成';
    final types = ['化成', '有機', '液肥', 'その他'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('肥料を登録'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '肥料名', hintText: '例：化成肥料 8-8-8'),
                ),
                const SizedBox(height: 8),
                const Text('種類', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: types.map((t) => GestureDetector(
                    onTap: () => setDialogState(() => selectedType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedType == t ? Colors.orange[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t, style: TextStyle(
                        color: selectedType == t ? Colors.white : Colors.black,
                        fontSize: 12,
                      )),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: npkController,
                  decoration: const InputDecoration(labelText: 'N-P-K（任意）', hintText: '例：N8-P8-K8'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '特徴・メモ', hintText: '例：元肥に最適'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _sb.from('fertilizers').insert({
                    'name': nameController.text,
                    'type': selectedType,
                    'npk': npkController.text.isEmpty ? '−' : npkController.text,
                    'note': noteController.text,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('登録', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(int index) {
    setState(() => _records.removeAt(index));
    _saveRecords();
  }

  void _deleteFertilizer(int index) {
    setState(() => _fertilizers.removeAt(index));
    _saveFertilizers();
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
        title: const Text('肥料管理 🌿', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddRecordDialog();
              } else {
                _showAddFertilizerDialog();
              }
            },
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
        children: [
          _buildRecordList(),
          _buildFertilizerList(),
        ],
      ),
    );
  }

  // 施肥記録タブ
  Widget _buildRecordList() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text('施肥の記録がありません', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('右上の＋ボタンで記録しましょう', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final r = _records[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: Colors.orange[700]!, width: 4)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(r['crop'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Row(children: [
                    Text(r['date'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('削除しますか？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async { await _sb.from('fertilizer_records').delete().eq('id', int.parse(_records[index]['id'] ?? '0')); Navigator.pop(ctx); },
                              child: const Text('削除', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ));
                      },
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.science, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Expanded(child: Text('${r['fert']}${r['amount']!.isNotEmpty ? '　${r['amount']}' : ''}',
                    style: const TextStyle(fontSize: 13))),
              ]),
              if (r['note'] != null && r['note']!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                  child: Text('📝 ${r['note']}', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 肥料の種類タブ
  Widget _buildFertilizerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fertilizers.length,
      itemBuilder: (context, index) {
        final f = _fertilizers[index];
        final color = _typeColor(f['type'] ?? 'その他');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(f['type'] ?? '',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if ((f['npk'] ?? '−') != '−') ...[
                      const SizedBox(height: 2),
                      Text('NPK: ${f['npk']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                    if ((f['note'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(f['note']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('削除しますか？'),
                    content: Text('「${f['name']}」を削除します'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async { await _sb.from('fertilizers').delete().eq('id', int.parse(_fertilizers[index]['id'] ?? '0')); Navigator.pop(ctx); },
                        child: const Text('削除', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ));
                },
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
