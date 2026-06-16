import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/schedule_service.dart';
import 'package:flutter/services.dart';
import 'package:restart_app/restart_app.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки темы',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Выбор темы
            ListTile(
              title: const Text('Светлая тема'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
            ),
            
            ListTile(
              title: const Text('Темная тема'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
            ),
            
            ListTile(
              title: const Text('Системная тема'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                },
              ),
            ),
            
            const Divider(),
            const SizedBox(height: 16),
            
            // Кнопка очистки кэша
            const Text(
              'Управление данными',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: () async {
                // Показываем диалог подтверждения
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Очистить кэш'),
                    content: const Text(
                      'Вы уверены, что хотите очистить кэш и перезапустить приложение? '
                      'Это может помочь при проблемах с отображением расписания.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Очистить'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  // Показываем индикатор загрузки
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  // Очищаем кэш
                  final scheduleService = ScheduleService();
                  await scheduleService.clearCache();
                  
                  // Небольшая задержка для визуального эффекта
                  await Future.delayed(const Duration(milliseconds: 500));
                  
                  // Перезапускаем приложение
                  Restart.restartApp();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Очистить кэш и перезапустить'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}