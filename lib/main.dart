import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:signature/signature.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  runApp(const CabbageAlarmApp());
}

class CabbageAlarmApp extends StatelessWidget {
  const CabbageAlarmApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabbage Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // S24 OLED Black
        primaryColor: const Color(0xFF81C784),
      ),
      home: const CabbageDashboard(),
    );
  }
}

class CabbageDashboard extends StatefulWidget {
  const CabbageDashboard({super.key});
  @override
  State<CabbageDashboard> createState() => _CabbageDashboardState();
}

class _CabbageDashboardState extends State<CabbageDashboard> {
  List<AlarmSettings> alarms = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => alarms = Alarm.getAlarms());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF81C784)),
                      const SizedBox(width: 10),
                      Text("CABBAGE", style: TextStyle(letterSpacing: 3, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                  const Text("Reminders", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Expanded(
              child: alarms.isEmpty 
                ? const Center(child: Text("No Cabbages Planted.", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: alarms.length,
                    itemBuilder: (c, i) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alarms[i].notificationSettings.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(DateFormat('hh:mm a').format(alarms[i].dateTime), style: const TextStyle(color: Color(0xFF81C784))),
                            ],
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => Alarm.stop(alarms[i].id).then((_) => _refresh())),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: const Color(0xFF81C784),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const CabbageEditor(),
        ).then((_) => _refresh()),
        child: const Icon(Icons.add, color: Colors.black, size: 40),
      ),
    );
  }
}

class CabbageEditor extends StatefulWidget {
  const CabbageEditor({super.key});
  @override
  State<CabbageEditor> createState() => _CabbageEditorState();
}

class _CabbageEditorState extends State<CabbageEditor> {
  final _title = TextEditingController();
  final _sPen = SignatureController(penColor: const Color(0xFF81C784), penStrokeWidth: 3);
  DateTime? _time;
  String? _audio;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Color(0xFF111111), borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          TextField(controller: _title, decoration: const InputDecoration(hintText: "What's the reminder?"), style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft, child: Text("S-PEN SKETCH", style: TextStyle(fontSize: 10, color: Colors.white30))),
          const SizedBox(height: 10),
          Container(
            height: 150,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
            child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Signature(controller: _sPen, backgroundColor: Colors.transparent)),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.alarm, color: Color(0xFF81C784)),
            title: Text(_time == null ? "Set Alarm Time" : DateFormat('hh:mm a').format(_time!)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (t != null) setState(() => _time = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, t.hour, t.minute));
            },
          ),
          ListTile(
            leading: const Icon(Icons.music_note, color: Color(0xFF81C784)),
            title: Text(_audio?.split('/').last ?? "Select Custom Sound"),
            onTap: () async {
              final r = await FilePicker.platform.pickFiles(type: FileType.audio);
              if (r != null) setState(() => _audio = r.files.single.path);
            },
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () async {
              if (_time == null) return;
              await Alarm.set(alarmSettings: AlarmSettings(
                id: DateTime.now().millisecond,
                dateTime: _time!,
                assetAudioPath: _audio ?? 'assets/alarm.mp3',
                loopAudio: true,
                notificationSettings: NotificationSettings(title: _title.text, body: "Cabbage Alarm Triggered!", stopButton: "Stop"),
              ));
              Navigator.pop(context);
            },
            child: const Text("PLANT REMINDER", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
