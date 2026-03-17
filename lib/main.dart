import 'package:flutter/material.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void main() {
  runApp(const MyApp());
}

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
      home: const HomeScreen(),
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

  final List<Widget> _screens = [
    const HomePage(),
    const FieldMapPage(),
    const GuidePage(),
    const DiaryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '畑マップ'),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: '栽培ガイド'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '作業日誌'),
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
  // タスクリスト（localStorageから読み込む）
  List<Map<String, dynamic>> _tasks = [
    {'emoji': '🌱', 'text': 'トマトのキュウリの水やり', 'done': true},
    {'emoji': '🌿', 'text': 'ナスの支柱組み', 'done': false},
    {'emoji': '🌾', 'text': '肥料やり（トマト）', 'done': false},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // localStorageからタスクを読み込む
  void _loadTasks() {
    final data = html.window.localStorage['hatake_tasks'];
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _tasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  // localStorageにタスクを保存する
  void _saveTasks() {
    html.window.localStorage['hatake_tasks'] = jsonEncode(_tasks);
  }

  // タスクの完了状態を切り替え
  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['done'] = !_tasks[index]['done'];
    });
    _saveTasks();
  }

  // 新しいタスクを追加
  void _addTask(String text) {
    setState(() {
      _tasks.add({'emoji': '📝', 'text': text, 'done': false});
    });
    _saveTasks();
  }

  // タスクを削除
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  // タスク追加ダイアログ
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
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTask(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('畑ノート 🌱', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            // 天気カード
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
                  const Text('今週の天気', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _weatherItem('今日', '☀️', '18°'),
                      _weatherItem('明日', '🌥', '15°'),
                      _weatherItem('水', '🌧️', '12°'),
                      _weatherItem('木', '🌧️', '11°'),
                      _weatherItem('金', '☀️', '19°'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 今日の作業タスク
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📋 今日の作業', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_tasks.where((t) => t['done'] == true).length}/${_tasks.length} 完了',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ..._tasks.asMap().entries.map((entry) =>
              _taskItem(entry.key, entry.value['emoji'], entry.value['text'], entry.value['done'])
            ),
            const SizedBox(height: 16),
            // 育てている作物
            const Text('🌿 育てている作物', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _cropCard('🍅', 'トマト', '生育中', Colors.red[100]!),
                _cropCard('🥒', 'キュウリ', '生育中', Colors.green[100]!),
                _cropCard('🍆', 'ナス', '収穫前', Colors.purple[100]!),
                _cropCard('🫑', 'ピーマン', '育苗中', Colors.green[100]!),
                _cropCard('🌽', 'ダイコン', '収穫前', Colors.grey[100]!),
              ],
            ),
            const SizedBox(height: 80), // FABのスペース
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

  Widget _taskItem(int index, String emoji, String text, bool done) {
    return Dismissible(
      key: Key('task_$index\_$text'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTask(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? Colors.grey : Colors.black87,
            ))),
            GestureDetector(
              onTap: () => _toggleTask(index),
              child: Icon(done ? Icons.check_circle : Icons.circle_outlined,
                  color: done ? Colors.green : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cropCard(String emoji, String name, String status, Color color) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(status, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// ===== 畑マップ画面 =====
class FieldMapPage extends StatefulWidget {
  const FieldMapPage({super.key});

  @override
  State<FieldMapPage> createState() => _FieldMapPageState();
}

class _FieldMapPageState extends State<FieldMapPage> {
  Map<String, Map<String, String>> _crops = {
    '0-0': {'emoji': '🍅', 'name': 'トマト'},
    '0-2': {'emoji': '🥒', 'name': 'キュウリ'},
    '1-1': {'emoji': '🍆', 'name': 'ナス'},
    '2-0': {'emoji': '🫑', 'name': 'ピーマン'},
    '2-2': {'emoji': '🌽', 'name': 'ダイコン'},
  };
  String? _selected;

  // 追加できる作物のリスト
  final List<Map<String, String>> _cropOptions = [
    {'emoji': '🍅', 'name': 'トマト'},
    {'emoji': '🥒', 'name': 'キュウリ'},
    {'emoji': '🍆', 'name': 'ナス'},
    {'emoji': '🫑', 'name': 'ピーマン'},
    {'emoji': '🌽', 'name': 'ダイコン'},
    {'emoji': '🥕', 'name': 'ニンジン'},
    {'emoji': '🧅', 'name': 'タマネギ'},
    {'emoji': '🥬', 'name': 'レタス'},
    {'emoji': '🌿', 'name': 'バジル'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  // localStorageから畑マップを読み込む
  void _loadCrops() {
    final data = html.window.localStorage['hatake_crops'];
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      setState(() {
        _crops = decoded.map((k, v) => MapEntry(k, Map<String, String>.from(v)));
      });
    }
  }

  // localStorageに畑マップを保存する
  void _saveCrops() {
    html.window.localStorage['hatake_crops'] = jsonEncode(_crops);
  }

  // 作物を配置するダイアログ
  void _showPlaceCropDialog(String key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('作物を選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            children: _cropOptions.map((crop) => GestureDetector(
              onTap: () {
                setState(() => _crops[key] = crop);
                _saveCrops();
                Navigator.pop(context);
              },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(crop['emoji']!, style: const TextStyle(fontSize: 28)),
                Text(crop['name']!, style: const TextStyle(fontSize: 11)),
              ]),
            )).toList(),
          ),
        ),
        actions: [
          if (_crops[key] != null)
            TextButton(
              onPressed: () {
                setState(() => _crops.remove(key));
                _saveCrops();
                Navigator.pop(context);
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ],
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
            const Text('マスをタップして作物を配置できます', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B6914),
                borderRadius: BorderRadius.circular(16),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final row = index ~/ 3;
                  final col = index % 3;
                  final key = '$row-$col';
                  final crop = _crops[key];
                  final isSelected = _selected == key;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selected = key);
                      _showPlaceCropDialog(key);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.yellow[200] : (crop != null ? Colors.green[100] : Colors.brown[200]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.orange : Colors.transparent, width: 2),
                      ),
                      child: crop != null
                          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(crop['emoji']!, style: const TextStyle(fontSize: 28)),
                              Text(crop['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ])
                          : const Icon(Icons.add, color: Colors.white54),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text('配置した作物は自動で保存されます', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                ],
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
    {'emoji': '🍅', 'name': 'トマト', 'soil': 'pH6.0〜6.5、水はけ良好', 'seed': '2〜3月', 'plant': '4〜5月', 'fert': '2週間に1回、カリ多め', 'pest': 'アブラムシ・疫病に注意'},
    {'emoji': '🥒', 'name': 'キュウリ', 'soil': 'pH6.0〜7.0、保水性高め', 'seed': '4月', 'plant': '5月上旬', 'fert': '週1回、窒素多め', 'pest': 'うどんこ病に注意'},
    {'emoji': '🍆', 'name': 'ナス', 'soil': 'pH6.0〜6.5、深耕が必要', 'seed': '2月', 'plant': '5月中旬', 'fert': '2週間に1回', 'pest': 'テントウムシダマシに注意'},
    {'emoji': '🫑', 'name': 'ピーマン', 'soil': 'pH6.0〜6.5、水はけ良好', 'seed': '2〜3月', 'plant': '5月', 'fert': '2週間に1回', 'pest': 'アブラムシに注意'},
    {'emoji': '🌽', 'name': 'ダイコン', 'soil': 'pH6.0〜7.0、深耕必須', 'seed': '8〜9月', 'plant': '直播き', 'fert': '月1回', 'pest': 'アオムシに注意'},
  ];
  Map<String, String>? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('栽培ガイド 🌿', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: _selected != null ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() => _selected = null)) : null,
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
              boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Text(g['emoji']!, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('種まき: ${g['seed']} / 定植: ${g['plant']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
            Text(g['emoji']!, style: const TextStyle(fontSize: 60)),
            Text(g['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _detailRow('🌍 土づくり', g['soil']!),
            _detailRow('🌱 種まき時期', g['seed']!),
            _detailRow('🌿 植え付け時期', g['plant']!),
            _detailRow('💧 肥料のあげ方', g['fert']!),
            _detailRow('🐛 病害虫対策', g['pest']!),
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

// ===== 作業日誌画面 =====
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<Map<String, String>> _diaries = [
    {'date': '3/12', 'crop': '🍅 トマト', 'work': '支柱立て・誘引', 'note': '成長が良くてきた'},
    {'date': '3/10', 'crop': '🥒 キュウリ', 'work': '追肥', 'note': '液肥を水で薄めて施肥'},
    {'date': '3/8', 'crop': '🍆 ナス', 'work': '収穫', 'note': '5本収穫。大きさ・色ともに良好'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  // localStorageから日誌を読み込む
  void _loadDiaries() {
    final data = html.window.localStorage['hatake_diaries'];
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _diaries = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  // localStorageに日誌を保存する
  void _saveDiaries() {
    html.window.localStorage['hatake_diaries'] = jsonEncode(_diaries);
  }

  // 日誌追加ダイアログ
  void _showAddDiaryDialog() {
    final cropController = TextEditingController();
    final workController = TextEditingController();
    final noteController = TextEditingController();
    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('日誌を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cropController, decoration: const InputDecoration(labelText: '作物名（例：🍅 トマト）')),
            TextField(controller: workController, decoration: const InputDecoration(labelText: '作業内容（例：水やり）')),
            TextField(controller: noteController, decoration: const InputDecoration(labelText: 'メモ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              if (cropController.text.isNotEmpty && workController.text.isNotEmpty) {
                setState(() {
                  _diaries.insert(0, {
                    'date': dateStr,
                    'crop': cropController.text,
                    'work': workController.text,
                    'note': noteController.text,
                  });
                });
                _saveDiaries();
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 日誌を削除
  void _deleteDiary(int index) {
    setState(() => _diaries.removeAt(index));
    _saveDiaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text('作業日誌 📖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _showAddDiaryDialog)],
      ),
      body: _diaries.isEmpty
          ? const Center(child: Text('日誌がありません。＋ボタンで追加しましょう！', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final d = _diaries[index];
                return Dismissible(
                  key: Key('diary_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteDiary(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(left: BorderSide(color: Colors.green[700]!, width: 4)),
                      boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(d['crop']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(d['date']!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ]),
                      const SizedBox(height: 6),
                      Text('作業: ${d['work']}', style: const TextStyle(fontSize: 13)),
                      if (d['note'] != null && d['note']!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                          child: Text('📝 ${d['note']}', style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
