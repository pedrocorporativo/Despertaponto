import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DespertadorPro());
}

class Alarm {
  final int id;
  final TimeOfDay time;
  final bool enabled;
  final List<int> weekdays; // 1=Mon ... 7=Sun
  final String appName;
  final String packageName;
  final String label;
  final String tone;

  const Alarm({
    required this.id,
    required this.time,
    required this.enabled,
    required this.weekdays,
    required this.appName,
    required this.packageName,
    required this.label,
    required this.tone,
  });

  Alarm copyWith({
    TimeOfDay? time,
    bool? enabled,
    List<int>? weekdays,
    String? appName,
    String? packageName,
    String? label,
    String? tone,
  }) => Alarm(
    id: id,
    time: time ?? this.time,
    enabled: enabled ?? this.enabled,
    weekdays: weekdays ?? this.weekdays,
    appName: appName ?? this.appName,
    packageName: packageName ?? this.packageName,
    label: label ?? this.label,
    tone: tone ?? this.tone,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'hour': time.hour,
    'minute': time.minute,
    'enabled': enabled,
    'weekdays': weekdays.join(','),
    'appName': appName,
    'packageName': packageName,
    'label': label,
    'tone': tone,
  };

  static Alarm fromMap(Map<String, dynamic> m) => Alarm(
    id: m['id'] as int,
    time: TimeOfDay(hour: m['hour'] as int, minute: m['minute'] as int),
    enabled: m['enabled'] as bool,
    weekdays: (m['weekdays'] as String)
        .split(',')
        .where((e) => e.isNotEmpty)
        .map(int.parse)
        .toList(),
    appName: m['appName'] as String,
    packageName: m['packageName'] as String,
    label: m['label'] as String,
    tone: m['tone'] as String,
  );
}

class AlarmStore {
  static const key = 'alarms_v1';

  static Future<List<Alarm>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(key) ?? [];
    return raw.map((s) => Alarm.fromMap(
      Map<String, dynamic>.from(Uri.splitQueryString(s).map(
        (k, v) => MapEntry(k, _decode(v)),
      )),
    )).toList();
  }

  static dynamic _decode(String v) {
    if (v == 'true') return true;
    if (v == 'false') return false;
    final n = int.tryParse(v);
    return n ?? v;
  }

  static Future<void> save(List<Alarm> alarms) async {
    final p = await SharedPreferences.getInstance();
    final values = alarms.map((a) {
      final m = a.toMap();
      return m.entries.map((e) =>
        '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}'
      ).join('&');
    }).toList();
    await p.setStringList(key, values);
  }
}

class DespertadorPro extends StatelessWidget {
  const DespertadorPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despertador Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C5CFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF090A10),
        cardTheme: const CardThemeData(
          color: Color(0xFF12141D),
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Alarm> alarms = [];
  Timer? clock;
  DateTime now = DateTime.now();

  static const apps = <String, String>{
    'Spotify': 'com.spotify.music',
    'WhatsApp': 'com.whatsapp',
    'Instagram': 'com.instagram.android',
    'YouTube': 'com.google.android.youtube',
    'Chrome': 'com.android.chrome',
    'TikTok': 'com.zhiliaoapp.musically',
  };

  @override
  void initState() {
    super.initState();
    _load();
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    clock?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await AlarmStore.load();
    if (mounted) setState(() => alarms = loaded);
  }

  Future<void> _save() => AlarmStore.save(alarms);

  String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _days(List<int> days) {
    if (days.length == 7) return 'Todos os dias';
    const names = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days.map((d) => names[d - 1]).join(' • ');
  }

  Future<void> _edit([Alarm? alarm]) async {
    final result = await showModalBottomSheet<Alarm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11131B),
      builder: (_) => AlarmEditor(
        alarm: alarm,
        apps: apps,
      ),
    );
    if (result == null) return;
    setState(() {
      final index = alarms.indexWhere((a) => a.id == result.id);
      if (index == -1) {
        alarms.add(result);
      } else {
        alarms[index] = result;
      }
      alarms.sort((a, b) => (a.time.hour * 60 + a.time.minute)
          .compareTo(b.time.hour * 60 + b.time.minute));
    });
    await _save();
  }

  Future<void> _delete(Alarm a) async {
    setState(() => alarms.removeWhere((x) => x.id == a.id));
    await _save();
  }

  Future<void> _testApp(Alarm a) async {
    try {
      await AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: a.packageName,
        category: 'android.intent.category.LAUNCHER',
      ).launch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${a.appName} não está instalado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
    final active = alarms.where((a) => a.enabled).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despertador Pro',
          style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Despertador Pro',
              applicationVersion: '1.0.0',
              children: const [
                Text('Despertador com alarme em tela cheia e abertura do aplicativo escolhido.'),
              ],
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo alarme'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            Text(_format(TimeOfDay.fromDateTime(now)),
              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800)),
            Text(date[0].toUpperCase() + date.substring(1),
              style: TextStyle(color: Colors.white.withOpacity(.55))),
            const SizedBox(height: 22),
            _summary(active),
            const SizedBox(height: 18),
            if (alarms.isEmpty) _empty() else ...alarms.map(_alarmCard),
          ],
        ),
      ),
    );
  }

  Widget _summary(int active) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1C1A35), Color(0xFF151722)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(.07)),
    ),
    child: Row(children: [
      const Icon(Icons.alarm_rounded, size: 30, color: Color(0xFF9B84FF)),
      const SizedBox(width: 14),
      Expanded(child: Text(
        active == 0 ? 'Nenhum alarme ativo' : '$active alarme${active == 1 ? '' : 's'} ativo${active == 1 ? '' : 's'}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      )),
      Text('$active', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _empty() => Container(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
    child: Column(children: [
      Icon(Icons.bedtime_outlined, size: 58, color: Colors.white.withOpacity(.25)),
      const SizedBox(height: 16),
      const Text('Seu sono começa aqui', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Crie seu primeiro alarme e escolha o aplicativo que será aberto quando você desligá-lo.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.55))),
    ]),
  );

  Widget _alarmCard(Alarm a) => Dismissible(
    key: ValueKey(a.id),
    direction: DismissDirection.endToStart,
    background: Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(color: Colors.red.withOpacity(.18), borderRadius: BorderRadius.circular(22)),
      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
    ),
    onDismissed: (_) => _delete(a),
    child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _edit(a),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_format(a.time), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(a.label.isEmpty ? a.appName : a.label,
                style: TextStyle(color: Colors.white.withOpacity(.8), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${_days(a.weekdays)}  •  Abrir ${a.appName}',
                style: TextStyle(color: Colors.white.withOpacity(.45), fontSize: 12)),
            ])),
            Switch(
              value: a.enabled,
              onChanged: (v) async {
                setState(() {
                  final i = alarms.indexWhere((x) => x.id == a.id);
                  alarms[i] = a.copyWith(enabled: v);
                });
                await _save();
              },
            ),
          ]),
        ),
      ),
    ),
  );
}

class AlarmEditor extends StatefulWidget {
  final Alarm? alarm;
  final Map<String, String> apps;
  const AlarmEditor({super.key, this.alarm, required this.apps});

  @override
  State<AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<AlarmEditor> {
  late TimeOfDay time;
  late Set<int> days;
  late String app;
  late String label;
  late String tone;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    time = a?.time ?? TimeOfDay.now();
    days = {...(a?.weekdays ?? [1,2,3,4,5])};
    app = a?.appName ?? widget.apps.keys.first;
    label = a?.label ?? '';
    tone = a?.tone ?? 'Clássico';
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(context: context, initialTime: time);
    if (t != null) setState(() => time = t);
  }

  void save() {
    if (days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha pelo menos um dia.')),
      );
      return;
    }
    final id = widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch;
    Navigator.pop(context, Alarm(
      id: id,
      time: time,
      enabled: true,
      weekdays: days.toList()..sort(),
      appName: app,
      packageName: widget.apps[app]!,
      label: label.trim(),
      tone: tone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const names = ['S','T','Q','Q','S','S','D'];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 20),
            Text(widget.alarm == null ? 'Novo alarme' : 'Editar alarme',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Center(child: InkWell(
              onTap: pickTime,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A182B),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF7C5CFF).withOpacity(.4)),
                ),
                child: Text(
                  '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',
                  style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w800),
                ),
              ),
            )),
            const SizedBox(height: 22),
            const Text('Repetir', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final d = i + 1;
                final selected = days.contains(d);
                return InkWell(
                  onTap: () => setState(() {
                    selected ? days.remove(d) : days.add(d);
                  }),
                  borderRadius: BorderRadius.circular(50),
                  child: CircleAvatar(
                    radius: 21,
                    backgroundColor: selected ? const Color(0xFF7C5CFF) : Colors.white.withOpacity(.08),
                    child: Text(names[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: label),
              onChanged: (v) => label = v,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Nome do alarme (opcional)',
                hintText: 'Ex.: Acordar para faculdade',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: app,
              decoration: const InputDecoration(
                labelText: 'Abrir depois de desligar',
                prefixIcon: Icon(Icons.apps_rounded),
                border: OutlineInputBorder(),
              ),
              items: widget.apps.keys.map((x) =>
                DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => app = v!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: tone,
              decoration: const InputDecoration(
                labelText: 'Toque',
                prefixIcon: Icon(Icons.music_note_outlined),
                border: OutlineInputBorder(),
              ),
              items: const ['Clássico', 'Digital', 'Suave', 'Urgente'].map((x) =>
                DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => tone = v!),
            ),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: save,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Salvar alarme'),
              ),
            )),
          ]),
        ),
      ),
    );
  }
}
