class AutomationSettings {
  final int cycles;
  final List<String> scheduledTimes;
  final bool pauseIfRaining;

  const AutomationSettings({
    required this.cycles,
    required this.scheduledTimes,
    required this.pauseIfRaining,
  });

  AutomationSettings copyWith({
    int? cycles,
    List<String>? scheduledTimes,
    bool? pauseIfRaining,
  }) {
    return AutomationSettings(
      cycles: cycles ?? this.cycles,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      pauseIfRaining: pauseIfRaining ?? this.pauseIfRaining,
    );
  }
}
