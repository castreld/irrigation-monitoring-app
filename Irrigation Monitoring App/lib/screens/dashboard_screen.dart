import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/irrigation_provider.dart';
import '../models/sensor_data.dart';
import '../models/weather_data.dart';
import 'analytics_screen.dart';
import 'automation_settings_screen.dart';
import 'tutorial_screen.dart';
import 'device_setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<IrrigationProvider>(context, listen: false);
      provider.fetchStatus();
      provider.startPolling();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<IrrigationProvider>().stopPolling();
      }
    });
    super.dispose();
  }

  IconData _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('drizzle')) return Icons.grain_rounded;
    if (cond.contains('cloud')) return Icons.cloud_rounded;
    if (cond.contains('snow')) return Icons.ac_unit_rounded;
    if (cond.contains('thunderstorm')) return Icons.thunderstorm_rounded;
    return Icons.wb_sunny_rounded;
  }

  String _getIndonesianCondition(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain')) return 'Hujan';
    if (cond.contains('cloud')) return 'Berawan';
    if (cond.contains('clear')) return 'Cerah';
    if (cond.contains('drizzle')) return 'Gerimis';
    if (cond.contains('thunderstorm')) return 'Badai Guntur';
    if (cond.contains('snow')) return 'Bersalju';
    if (cond.contains('mist') || cond.contains('fog')) return 'Berkabut';
    return condition;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<IrrigationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.grass_rounded, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Irigasi Pintar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  provider.hasData ? 'Sistem Terhubung' : 'Menghubungkan...',
                  style: TextStyle(
                    fontSize: 11,
                    color: provider.hasData ? const Color(0xFF10B981) : Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF334155)),
            tooltip: 'Panduan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TutorialScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_input_component_rounded, color: Color(0xFF334155)),
            tooltip: 'Token Blynk',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceSetupScreen(isInitialSetup: false),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_rounded, color: Color(0xFF334155)),
            tooltip: 'Analisis',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          if (provider.isActionInProgress || (provider.isLoading && provider.hasData))
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
              tooltip: 'Segarkan',
              onPressed: () => provider.fetchStatus(),
            ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (provider.isLoading && !provider.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Menghubungkan ke node sensor...',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (provider.errorMessage != null && !provider.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal Menghubungkan',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => provider.fetchStatus(),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (provider.hasData) {
              final data = provider.data!;
              return _buildDashboardContent(context, provider, data);
            }

            return const Center(
              child: Text(
                'Data tidak tersedia.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    IrrigationProvider provider,
    SensorData data,
  ) {
    final hasBackgroundError = provider.errorMessage != null;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (hasBackgroundError)
          Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                  onPressed: () => provider.fetchStatus(showLoading: false),
                )
              ],
            ),
          ),

        _buildWeatherForecastCard(provider.weather),
        const SizedBox(height: 16),

        _buildSystemOverviewCard(data),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth > 600;
            if (isTablet) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSensorCard(
                      title: 'Suhu',
                      value: '${data.temperature}°C',
                      icon: Icons.thermostat_rounded,
                      colors: [const Color(0xFFEA580C), const Color(0xFFF97316)],
                      subtitle: 'Suhu lingkungan',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSensorCard(
                      title: 'Kelembaban',
                      value: '${data.humidity}%',
                      icon: Icons.water_drop_rounded,
                      colors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                      subtitle: 'Rasio kelembaban udara',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSensorCard(
                      title: 'Kelembaban Tanah',
                      value: '${data.soilMoisture}%',
                      icon: Icons.yard_rounded,
                      colors: [const Color(0xFF059669), const Color(0xFF34D399)],
                      subtitle: data.soilMoisture < 35.0 ? 'Kering - Butuh Air' : 'Kelembaban Optimal',
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildSensorCard(
                    title: 'Kelembaban Tanah',
                    value: '${data.soilMoisture}%',
                    icon: Icons.yard_rounded,
                    colors: [const Color(0xFF059669), const Color(0xFF34D399)],
                    subtitle: data.soilMoisture < 35.0
                        ? 'Kering - Butuh Air (Pemicu Irigasi)'
                        : (data.soilMoisture > 65.0 ? 'Basah - Air Cukup' : 'Kelembaban Optimal'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(
                          title: 'Suhu',
                          value: '${data.temperature}°C',
                          icon: Icons.thermostat_rounded,
                          colors: [const Color(0xFFEA580C), const Color(0xFFF97316)],
                          subtitle: 'Suhu sekitar',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSensorCard(
                          title: 'Kelembaban',
                          value: '${data.humidity}%',
                          icon: Icons.water_drop_rounded,
                          colors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                          subtitle: 'Kelembaban relatif',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
        
        const SizedBox(height: 20),
        
        _buildControlsCard(provider, data),
      ],
    );
  }

  Widget _buildWeatherForecastCard(WeatherData? weather) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                weather != null ? _getWeatherIcon(weather.condition) : Icons.wb_cloudy_rounded,
                color: const Color(0xFF10B981),
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perkiraan Cuaca',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    weather != null
                        ? '${_getIndonesianCondition(weather.condition)} • Lembang, Jawa Barat'
                        : 'Memuat data cuaca Lembang...',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (weather != null)
            Text(
              '${weather.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemOverviewCard(SensorData data) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.relayStatus ? const Color(0xFF10B981) : Colors.blueGrey,
                      boxShadow: data.relayStatus
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.6),
                                blurRadius: 4 + _pulseController.value * 8,
                                spreadRadius: _pulseController.value * 3,
                              )
                            ]
                          : [],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Pompa Air',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  Text(
                    data.relayStatus ? 'AKTIF (Menyiram)' : 'STANDBY',
                    style: TextStyle(
                      color: data.relayStatus ? const Color(0xFF10B981) : const Color(0xFF334155),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: data.autoMode 
                  ? Colors.teal.withOpacity(0.1) 
                  : Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.autoMode 
                    ? Colors.teal.withOpacity(0.3) 
                    : Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  data.autoMode ? Icons.auto_mode_rounded : Icons.touch_app_rounded,
                  size: 14,
                  color: data.autoMode ? Colors.teal.shade700 : Colors.amber.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  data.autoMode ? 'OTOMATIS' : 'MANUAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: data.autoMode ? Colors.teal.shade700 : Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
    required String subtitle,
  }) {
    return Container(
      height: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ColorExt.whiteEE,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ColorExt.whiteB3,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard(IrrigationProvider provider, SensorData data) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            'Pusat Kontrol',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, color: Colors.teal),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Otomatisasi (Mode Auto)',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.settings_rounded, size: 18, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AutomationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Text(
                        'Menyalakan pompa saat kelembaban < 35%',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: data.autoMode,
                activeColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                onChanged: provider.isActionInProgress
                    ? null
                    : (val) => provider.toggleAutoMode(val),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: data.autoMode ? const Color(0xFFCBD5E1) : Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pompa Irigasi (Relay)',
                        style: TextStyle(
                          color: data.autoMode ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data.autoMode 
                            ? 'Tidak aktif dalam mode Otomatis'
                            : 'Nyalakan/matikan pompa secara manual',
                        style: TextStyle(
                          color: data.autoMode ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: data.relayStatus,
                activeColor: Colors.amber,
                activeTrackColor: Colors.amber.withOpacity(0.3),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                onChanged: (provider.isActionInProgress || data.autoMode)
                    ? null
                    : (val) => provider.toggleRelay(val),
              ),
            ],
          ),
          
          if (provider.isActionInProgress)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NavigatorSizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Mengirim perintah...',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class NavigatorSizedBox extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const NavigatorSizedBox({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}

extension ColorExt on Color {
  static const Color whiteEE = Color(0xFFEEEEEE);
  static const Color whiteB3 = Color(0xFFB3B3B3);
}
