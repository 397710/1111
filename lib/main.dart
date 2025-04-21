import 'dart:io';  // 添加这行以使用File和Directory
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 添加这行确保插件初始化
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const MyHomePage(title: '何文鑫小猪猪'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late SharedPreferences _prefs;
  Timer? _longPressTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _initAudio();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCounter();
  }

  Future<void> _initAudio() async {
    try {
      // 方法1：验证资源文件可访问性
      final byteData = await rootBundle.load('assets/sounds/click2.mp3');
      debugPrint('✅ 资源文件大小: ${byteData.lengthInBytes} bytes');

      // 方法2：设置音频源（确保使用正确的路径格式）
      await _audioPlayer.setSource(AssetSource('assets/sounds/click2.mp3'));

    } catch (e) {
      debugPrint('❌ 初始化失败: $e');

      // 备用方案：使用绝对路径（需要dart:io）
      try {
        final file = File('${Directory.current.path}/assets/sounds/click2.mp3');
        if (await file.exists()) {
          await _audioPlayer.setSource(DeviceFileSource(file.path));
          debugPrint('✅ 使用绝对路径初始化成功');
        }
      } catch (e) {
        debugPrint('❌ 绝对路径初始化失败: $e');
      }
    }
  }

  Future<void> _loadCounter() async {
    setState(() => _counter = _prefs.getInt('counter') ?? 0);
  }

  Future<void> _playSound() async {
    try {
      // 优先尝试资源路径
      await _audioPlayer.setVolume(2.0); // 设置为最大音量（范围0.0-1.0）
      await _audioPlayer.play(AssetSource('sounds/click2.mp3'));
      return;
    } catch (e) {
      debugPrint('资源路径播放失败: $e');
    }

    // 备用方案：绝对路径
    try {
      final file = File('${Directory.current.path}/sounds/click2.mp3');
      if (await file.exists()) {
        await _audioPlayer.play(DeviceFileSource(file.path));
        return;
      }
    } catch (e) {
      debugPrint('绝对路径播放失败: $e');
    }

    // 最终回退
    await SystemSound.play(SystemSoundType.click);
  }


  void _incrementCounter() async {
    await _playSound();
    setState(() => _counter++);
    await _prefs.setInt('counter', _counter);
  }

  void _decrementCounter() async {
    await _playSound();
    setState(() => _counter--);
    await _prefs.setInt('counter', _counter);
  }

  void _resetCounter() async {
    await _playSound();
    setState(() => _counter = 0);
    await _prefs.remove('counter');
  }

  void _startIncrementing() async {
    await _playSound();
    _longPressTimer = Timer.periodic(
      const Duration(milliseconds: 200),
          (timer) async {
        await _playSound();
        setState(() => _counter++);
        await _prefs.setInt('counter', _counter);
      },
    );
  }

  void _stopIncrementing() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _incrementCounter,
              onLongPressStart: (_) => _startIncrementing(),
              onLongPressEnd: (_) => _stopIncrementing(),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.favorite, size: 50, color: Colors.pink),
                    const Text('是猪', style: TextStyle(fontSize: 16, color: Colors.pink)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                '$_counter',
                key: ValueKey<int>(_counter),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: _counter >= 0 ? Colors.pink : Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _decrementCounter,
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text('不是猪', style: TextStyle(fontSize: 16, color: Colors.blue)),
                    Transform.rotate(
                      angle: 3.14159,
                      child: const Icon(Icons.favorite, size: 50, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}