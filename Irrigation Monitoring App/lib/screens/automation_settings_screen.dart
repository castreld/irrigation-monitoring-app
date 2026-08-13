import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../models/automation_settings.dart';

class AutomationSettingsScreen extends StatefulWidget {
  const AutomationSettingsScreen({super.key});

  @override
  State<AutomationSettingsScreen> createState() => _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState extends State<AutomationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cyclesController = TextEditingController();
  late int _cycles;
  late List<String> _scheduledTimes;
  late bool _pauseIfRaining;

  @override
  void initState() {
    super.initState();
    final provider = context.read<IrrigationProvider>();
    _cycles = provider.settings.cycles;
    _scheduledTimes = List.from(provider.settings.scheduledTimes);
    _pauseIfRaining = provider.settings.pauseIfRaining;

    _cyclesController.text = _cycles.toString();
    _cyclesController.addListener(_onCyclesChanged);
  }

  @override
  void dispose() {
    _cyclesController.removeListener(_onCyclesChanged);
    _cyclesController.dispose();
    super.dispose();
  }

  void _onCyclesChanged() {
    final val = int.tryParse(_cyclesController.text);
    if (val != null && val >= 1) {
      setState(() {
        _cycles = val;
        if (_scheduledTimes.length < _cycles) {
          while (_scheduledTimes.length < _cycles) {
            String newTime = '06:00';
            if (_scheduledTimes.isNotEmpty) {
              final lastParts = _scheduledTimes.last.split(':');
              final lastH = int.parse(lastParts[0]);
              final lastM = int.parse(lastParts[1]);
              int newH = lastH + 1;
              int newM = lastM;
              if (newH >= 24) {
                newH = 23;
                newM = 59;
              }
              newTime = '${newH.toString().padLeft(2, '0')}:${newM.toString().padLeft(2, '0')}';
            }
            _scheduledTimes.add(newTime);
          }
        } else if (_scheduledTimes.length > _cycles) {
          _scheduledTimes = _scheduledTimes.sublist(0, _cycles);
        }
      });
    }
  }

  int _timeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _selectTimeForIndex(BuildContext context, int index) async {
    final currentTime = _scheduledTimes[index];
    final parts = currentTime.split(':');
    final initialHour = int.parse(parts[0]);
    final initialMinute = int.parse(parts[1]);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF10B981),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final hour = selectedTime.hour.toString().padLeft(2, '0');
      final minute = selectedTime.minute.toString().padLeft(2, '0');
      final newTimeStr = '$hour:$minute';
      final newMinutes = _timeToMinutes(newTimeStr);

      if (index > 0) {
        final prevMinutes = _timeToMinutes(_scheduledTimes[index - 1]);
        if (newMinutes <= prevMinutes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Waktu siklus tidak boleh lebih awal dari siklus sebelumnya.'),
              ),
            );
          }
          return;
        }
      }

      if (index < _scheduledTimes.length - 1) {
        final nextMinutes = _timeToMinutes(_scheduledTimes[index + 1]);
        if (newMinutes >= nextMinutes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Waktu siklus tidak boleh lebih awal dari siklus sebelumnya.'),
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _scheduledTimes[index] = newTimeStr;
      });
    }
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newSettings = AutomationSettings(
        cycles: _cycles,
        scheduledTimes: _scheduledTimes,
        pauseIfRaining: _pauseIfRaining,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menyimpan pengaturan ke Blynk Cloud...'),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        await context.read<IrrigationProvider>().updateAutomationSettings(newSettings);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengaturan berhasil disimpan.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = context.watch<IrrigationProvider>().isActionInProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan Otomatisasi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parameter Penyiraman',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cyclesController,
                    keyboardType: TextInputType.number,
                    enabled: !isPending,
                    decoration: const InputDecoration(
                      labelText: 'Siklus Penyiraman',
                      labelStyle: TextStyle(color: Color(0xFF64748B)),
                      hintText: 'Jumlah pengulangan per hari',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nilai siklus harus diisi';
                      }
                      final n = int.tryParse(value);
                      if (n == null) {
                        return 'Nilai siklus harus berupa angka';
                      }
                      if (n < 1) {
                        return 'Siklus minimal 1 kali';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  const Text(
                    'Jadwal Waktu Setiap Siklus',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: List.generate(_scheduledTimes.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Waktu Siklus Ke-${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: isPending ? null : () => _selectTimeForIndex(context, index),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _scheduledTimes[index],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Color(0xFF10B981),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jeda Otomatis Saat Hujan',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Menangguhkan pompa jika cuaca hujan',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _pauseIfRaining,
                        activeColor: const Color(0xFF10B981),
                        onChanged: isPending
                            ? null
                            : (val) {
                                setState(() {
                                  _pauseIfRaining = val;
                                });
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: isPending ? null : _saveSettings,
              child: isPending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Pengaturan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
