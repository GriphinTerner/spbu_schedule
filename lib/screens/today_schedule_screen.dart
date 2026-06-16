import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_models.dart';
import '../widgets/ios_style_widgets.dart';
import '../utils/date_utils.dart' as app_date_utils;

class TodayScheduleScreen extends StatelessWidget {
  const TodayScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        if (scheduleProvider.isLoading) {
          return const Center(child: CupertinoActivityIndicator(radius: 14));
        }

        if (scheduleProvider.error != null) {
          return IOSStyleErrorView(
            error: scheduleProvider.error!,
            onRetry: () => scheduleProvider.fetchSchedule(),
          );
        }

        final today = DateTime.now();
        final todayEvents = scheduleProvider.getTodaySchedule();
        
        // Проверяем, суббота ли сегодня и закончились ли пары
        final isSaturday = today.weekday == DateTime.saturday;
        final isWeekend = today.weekday == DateTime.sunday; // Воскресенье
        
        // Если сегодня воскресенье или (суббота и нет пар), показываем расписание на следующий учебный день
        if (isWeekend || (isSaturday && todayEvents.isEmpty)) {
          final nextStudyDayEvents = scheduleProvider.getNextStudyDaySchedule();
          final nextStudyDay = scheduleProvider.getNextStudyDay();
          
          if (nextStudyDayEvents.isEmpty || nextStudyDay == null) {
            return const IOSStyleEmptyView(
              message: 'Нет данных о следующих учебных днях',
              icon: CupertinoIcons.calendar_badge_minus,
            );
          }
          
          // Форматируем дату следующего учебного дня
          final formattedDate = app_date_utils.AppDateUtils.formatDate(nextStudyDay);
          final weekday = app_date_utils.AppDateUtils.getWeekdayName(nextStudyDay.weekday, capitalize: false);
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Сегодня занятий нет',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Показываю расписание на следующий учебный день',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  IOSStyleSectionHeader(
                    title: 'Расписание на $weekday, $formattedDate:',
                  ),
                  const SizedBox(height: 20),
                  _buildScheduleForEvents(nextStudyDayEvents),
                ],
              ),
            ),
          );
        }
        
        // Если сегодня нет занятий (но не суббота и не воскресенье)
        if (todayEvents.isEmpty) {
          return const IOSStyleEmptyView(
            message: 'Сегодня нет занятий',
            icon: CupertinoIcons.calendar_badge_minus,
          );
        }

        final currentDate = DateTime.now();
        final formattedDate = app_date_utils.AppDateUtils.formatDate(currentDate);
        final weekday = app_date_utils.AppDateUtils.getWeekdayName(currentDate.weekday, capitalize: false);

        // Группируем пары по названию предмета И времени начала
        final Map<String, List<ScheduleEvent>> groupedEvents = {};
        
        for (var event in todayEvents) {
          // Используем комбинацию названия предмета и времени начала как ключ группировки
          String groupKey = "${event.subject.trim()}_${event.startTime}";
          
          if (!groupedEvents.containsKey(groupKey)) {
            groupedEvents[groupKey] = [];
          }
          groupedEvents[groupKey]!.add(event);
        }
        
        // Создаем список виджетов для отображения групп
        final List<Widget> lessonGroups = [];
        
        // Сортируем группы по времени начала первого события
        final sortedSubjects = groupedEvents.keys.toList()
          ..sort((a, b) {
            final aFirstEvent = groupedEvents[a]!.first;
            final bFirstEvent = groupedEvents[b]!.first;
            return aFirstEvent.start.compareTo(bFirstEvent.start);
          });
        
        for (var subject in sortedSubjects) {
          final events = groupedEvents[subject]!;
          // Сортируем события по времени начала
          events.sort((a, b) => a.start.compareTo(b.start));
          
          // Используем новый виджет SubjectGroupCard для отображения группы предметов
          lessonGroups.add(
            SubjectGroupCard(
              subject: subject,
              events: events,
              // Определяем статус группы на основе статусов событий
              statusIndicator: _getGroupStatusIndicator(events),
            ),
          );
        }
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IOSStyleSectionHeader(
                  title: 'Расписание на $weekday, $formattedDate:',
                ),
                const SizedBox(height: 20),
                ...lessonGroups,
              ],
            ),
          ),
        );
      },
    );
  }

  // Определяет статус индикатор для группы событий
  String? _getGroupStatusIndicator(List<ScheduleEvent> events) {
    // Если есть отмененные занятия, возвращаем 'canceled'
    if (events.any((event) => event.isCancelled)) {
      return 'canceled';
    }
    // Если есть перенесенные занятия, возвращаем 'rescheduled'
    else if (events.any((event) => event.isTimeChanged)) {
      return 'rescheduled';
    }
    // В противном случае возвращаем null (нормальный статус)
    return null;
  }

  String _getWeekdayName(int weekday) {
    return app_date_utils.AppDateUtils.getWeekdayName(weekday);
  }
  
  // Вспомогательный метод для построения расписания из списка событий
  Widget _buildScheduleForEvents(List<ScheduleEvent> events) {
    // Группируем пары по названию предмета И времени начала
    final Map<String, List<ScheduleEvent>> groupedEvents = {};
    
    for (var event in events) {
      // Используем комбинацию названия предмета и времени начала как ключ группировки
      String groupKey = "${event.subject.trim()}_${event.startTime}";
      
      if (!groupedEvents.containsKey(groupKey)) {
        groupedEvents[groupKey] = [];
      }
      groupedEvents[groupKey]!.add(event);
    }
    
    // Создаем список виджетов для отображения групп
    final List<Widget> lessonGroups = [];
    
    // Сортируем группы по времени начала первого события
    final sortedSubjects = groupedEvents.keys.toList()
      ..sort((a, b) {
        final aFirstEvent = groupedEvents[a]!.first;
        final bFirstEvent = groupedEvents[b]!.first;
        return aFirstEvent.start.compareTo(bFirstEvent.start);
      });
    
    for (var subject in sortedSubjects) {
      final events = groupedEvents[subject]!;
      // Сортируем события по времени начала
      events.sort((a, b) => a.start.compareTo(b.start));
      
      // Используем виджет SubjectGroupCard для отображения группы предметов
      lessonGroups.add(
        SubjectGroupCard(
          subject: subject,
          events: events,
          // Определяем статус группы на основе статусов событий
          statusIndicator: _getGroupStatusIndicator(events),
        ),
      );
    }
    
    return Column(children: lessonGroups);
  }
}