import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_models.dart';
import '../widgets/ios_style_widgets.dart';
import '../utils/date_utils.dart' as app_date_utils;

class NextLessonScreen extends StatelessWidget {
  const NextLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        // Всегда показываем основной интерфейс, даже если данные загружаются
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IOSStyleSectionHeader(
                  title: 'Актуальное расписание',
                ),
                const SizedBox(height: 20),
                // Показываем индикатор загрузки внутри контента, а не вместо него
                if (scheduleProvider.scheduleData != null) 
                  Builder(
                    builder: (context) {
                      try {
                        final (status, events) = scheduleProvider.getScheduleStatus();
                        return _buildStatusContent(status, events, context);
                      } catch (e) {
                        // В случае ошибки показываем сообщение об ошибке
                        return IOSStyleErrorView(
                          error: 'Произошла ошибка при обработке расписания: ${e.toString()}',
                          onRetry: () => scheduleProvider.fetchSchedule(),
                        );
                      }
                    },
                  )
                else if (scheduleProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CupertinoActivityIndicator(radius: 14),
                    ),
                  )
                else if (scheduleProvider.error != null)
                  IOSStyleErrorView(
                    error: scheduleProvider.error!,
                    onRetry: () => scheduleProvider.fetchSchedule(),
                  )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Загрузка данных...'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusContent(ScheduleStatus status, List<ScheduleEvent> events, BuildContext context) {
    switch (status) {
      case ScheduleStatus.firstLesson:
        return _buildFirstLessonView(events.first, context);
      case ScheduleStatus.currentLesson:
        return _buildCurrentLessonView(events[0], events.length > 1 ? events[1] : null, context);
      case ScheduleStatus.break_:
        return _buildBreakView(events.first, context);
      case ScheduleStatus.lastLesson:
        return _buildLastLessonView(events.first, context);
      case ScheduleStatus.nextDay:
        return _buildNextDayView(events, context);
      case ScheduleStatus.lessonsOver:
        return _buildLessonsOverView(events, context);
    }
  }

  Widget _buildFirstLessonView(ScheduleEvent lesson, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IOSStyleSectionHeader(
          title: 'Первая пара:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        IOSStyleLessonCard(lesson: lesson, isActive: true),
      ],
    );
  }

  Widget _buildCurrentLessonView(ScheduleEvent currentLesson, ScheduleEvent? nextLesson, BuildContext context) {
    // Получаем все текущие пары с тем же временем начала
    final currentLessons = Provider.of<ScheduleProvider>(context, listen: false)
        .getCurrentLessons(currentLesson.start);
    
    // Группируем текущие пары по названию предмета И времени начала
    final Map<String, List<ScheduleEvent>> groupedCurrentEvents = {};
    for (var event in currentLessons) {
      // Используем комбинацию названия предмета и времени начала как ключ группировки
      String groupKey = "${event.subject.trim()}_${event.startTime}";
      if (!groupedCurrentEvents.containsKey(groupKey)) {
        groupedCurrentEvents[groupKey] = [];
      }
      groupedCurrentEvents[groupKey]!.add(event);
    }
    
    // Создаем список виджетов для отображения групп текущих пар
    final List<Widget> currentLessonGroups = [];
    
    // Сортируем группы по названию предмета
    final sortedCurrentSubjects = groupedCurrentEvents.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (var subject in sortedCurrentSubjects) {
      final events = groupedCurrentEvents[subject]!;
      events.sort((a, b) => a.start.compareTo(b.start));
      
      currentLessonGroups.add(
        SubjectGroupCard(
          subject: subject,
          events: events,
          statusIndicator: _getGroupStatusIndicator(events),
          isActive: true,
        ),
      );
    }
    
    // Обрабатываем следующую пару, если она есть
    List<Widget> nextLessonGroups = [];
    if (nextLesson != null) {
      // Получаем все следующие пары, которые начинаются позже текущих
      final nextLessons = Provider.of<ScheduleProvider>(context, listen: false)
          .getNextLessons();
      
      // Группируем следующие пары по названию предмета
      final Map<String, List<ScheduleEvent>> groupedNextEvents = {};
      for (var event in nextLessons) {
        String groupKey = event.subject.trim();
        if (!groupedNextEvents.containsKey(groupKey)) {
          groupedNextEvents[groupKey] = [];
        }
        groupedNextEvents[groupKey]!.add(event);
      }
      
      // Сортируем группы по названию предмета
      final sortedNextSubjects = groupedNextEvents.keys.toList()
        ..sort((a, b) => a.compareTo(b));
      
      for (var subject in sortedNextSubjects) {
        final events = groupedNextEvents[subject]!;
        events.sort((a, b) => a.start.compareTo(b.start));
        
        nextLessonGroups.add(
          SubjectGroupCard(
            subject: subject,
            events: events,
            statusIndicator: _getGroupStatusIndicator(events),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IOSStyleSectionHeader(
          title: 'Текущая пара:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...currentLessonGroups,
        if (nextLessonGroups.isNotEmpty) ...[  
          const SizedBox(height: 20),
          const IOSStyleSectionHeader(
            title: 'Следующая пара:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...nextLessonGroups,
        ],
      ],
    );
  }

  Widget _buildBreakView(ScheduleEvent nextLesson, BuildContext context) {
    final theme = Theme.of(context);
    
    // Получаем все следующие пары, которые начинаются позже текущих
    final nextLessons = Provider.of<ScheduleProvider>(context, listen: false)
        .getNextLessons();
    
    // Группируем следующие пары по названию предмета И времени начала
    final Map<String, List<ScheduleEvent>> groupedNextEvents = {};
    for (var event in nextLessons) {
      // Используем комбинацию названия предмета и времени начала как ключ группировки
      String groupKey = "${event.subject.trim()}_${event.startTime}";
      if (!groupedNextEvents.containsKey(groupKey)) {
        groupedNextEvents[groupKey] = [];
      }
      groupedNextEvents[groupKey]!.add(event);
    }
    
    // Создаем список виджетов для отображения групп
    final List<Widget> nextLessonGroups = [];
    
    // Сортируем группы по названию предмета
    final sortedNextSubjects = groupedNextEvents.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (var subject in sortedNextSubjects) {
      final events = groupedNextEvents[subject]!;
      events.sort((a, b) => a.start.compareTo(b.start));
      
      nextLessonGroups.add(
        SubjectGroupCard(
          subject: subject,
          events: events,
          statusIndicator: _getGroupStatusIndicator(events),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IOSStyleSectionHeader(
          title: 'Сейчас перерыв',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.time,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Следующая пара начнется в ${nextLesson.startTime}',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const IOSStyleSectionHeader(
          title: 'Следующая пара:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...nextLessonGroups,
      ],
    );
  }

  Widget _buildLastLessonView(ScheduleEvent lesson, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IOSStyleSectionHeader(
          title: 'Последняя пара:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        IOSStyleLessonCard(lesson: lesson, isActive: true),
      ],
    );
  }

  Widget _buildNextDayView(List<ScheduleEvent> events, BuildContext context) {
    if (events.isEmpty) {
      return const IOSStyleEmptyView(message: 'Нет данных о следующих парах');
    }

    // Дополнительная проверка на пустые данные
    if (events.isEmpty) {
      return const IOSStyleEmptyView(message: 'Нет данных о следующих парах');
    }

    final firstEvent = events.first;
    final formattedDate = app_date_utils.AppDateUtils.formatDate(firstEvent.start);
    final weekday = app_date_utils.AppDateUtils.getWeekdayName(firstEvent.start.weekday, capitalize: false);

    // Сначала группируем пары по времени начала
    final Map<String, List<ScheduleEvent>> timeGroups = {};
    
    for (var event in events) {
      String timeKey = app_date_utils.AppDateUtils.formatTime(event.start);
      
      if (!timeGroups.containsKey(timeKey)) {
        timeGroups[timeKey] = [];
      }
      timeGroups[timeKey]!.add(event);
    }
    
    // Создаем список виджетов для отображения временных групп
    final List<Widget> timeGroupWidgets = [];
    
    // Сортируем временные группы по времени
    final sortedTimes = timeGroups.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (var time in sortedTimes) {
      final timeEvents = timeGroups[time]!;
      
      // Теперь группируем события внутри временной группы по предмету
      final Map<String, List<ScheduleEvent>> subjectGroups = {};
      
      for (var event in timeEvents) {
        String subjectKey = event.subject.trim();
        
        if (!subjectGroups.containsKey(subjectKey)) {
          subjectGroups[subjectKey] = [];
        }
        subjectGroups[subjectKey]!.add(event);
      }
      
      // Создаем список виджетов для отображения групп по предмету
      final List<Widget> subjectGroupWidgets = [];
      
      // Сортируем группы по предмету (для стабильного порядка)
      final sortedSubjects = subjectGroups.keys.toList()
        ..sort((a, b) => a.compareTo(b));
      
      for (var subject in sortedSubjects) {
        final subjectEvents = subjectGroups[subject]!;
        
        subjectGroupWidgets.add(
          SubjectGroupCard(
            subject: subject,
            events: subjectEvents,
            statusIndicator: _getGroupStatusIndicator(subjectEvents),
            isActive: true, // Текущая пара активна
          ),
        );
      }
      
      // Добавляем временную группу в общий список
      timeGroupWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...subjectGroupWidgets,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IOSStyleSectionHeader(
          title: 'Расписание на $weekday, $formattedDate:',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        ...timeGroupWidgets,
      ],
    );
  }

  Widget _buildLessonsOverView(List<ScheduleEvent> events, BuildContext context) {
    if (events.isEmpty) {
      return const IOSStyleEmptyView(message: 'Нет данных о следующих парах');
    }

    // Дополнительная проверка на пустые данные
    if (events.isEmpty) {
      return const IOSStyleEmptyView(message: 'Нет данных о следующих парах');
    }

    final firstEvent = events.first;
    final formattedDate = app_date_utils.AppDateUtils.formatDate(firstEvent.start);
    final weekday = app_date_utils.AppDateUtils.getWeekdayName(firstEvent.start.weekday, capitalize: false);

    // Сначала группируем пары по времени начала
    final Map<String, List<ScheduleEvent>> timeGroups = {};
    
    for (var event in events) {
      String timeKey = app_date_utils.AppDateUtils.formatTime(event.start);
      
      if (!timeGroups.containsKey(timeKey)) {
        timeGroups[timeKey] = [];
      }
      timeGroups[timeKey]!.add(event);
    }
    
    // Создаем список виджетов для отображения временных групп
    final List<Widget> timeGroupWidgets = [];
    
    // Сортируем временные группы по времени
    final sortedTimes = timeGroups.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    for (var time in sortedTimes) {
      final timeEvents = timeGroups[time]!;
      
      // Теперь группируем события внутри временной группы по предмету
      final Map<String, List<ScheduleEvent>> subjectGroups = {};
      
      for (var event in timeEvents) {
        String subjectKey = event.subject.trim();
        
        if (!subjectGroups.containsKey(subjectKey)) {
          subjectGroups[subjectKey] = [];
        }
        subjectGroups[subjectKey]!.add(event);
      }
      
      // Создаем список виджетов для отображения групп по предмету
      final List<Widget> subjectGroupWidgets = [];
      
      // Сортируем группы по предмету (для стабильного порядка)
      final sortedSubjects = subjectGroups.keys.toList()
        ..sort((a, b) => a.compareTo(b));
      
      for (var subject in sortedSubjects) {
        final subjectEvents = subjectGroups[subject]!;
        
        subjectGroupWidgets.add(
          SubjectGroupCard(
            subject: subject,
            events: subjectEvents,
            statusIndicator: _getGroupStatusIndicator(subjectEvents),
          ),
        );
      }
      
      // Добавляем временную группу в общий список
      timeGroupWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...subjectGroupWidgets,
          ],
        ),
      );
    }

    return Column(
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
                CupertinoIcons.checkmark_circle_fill,
                color: Theme.of(context).colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Сегодня пар больше не будет',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Вывожу расписание на следующий учебный день',
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        ...timeGroupWidgets,
      ],
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

  // Этот метод больше не используется, так как мы используем IOSStyleLessonCard
  // Оставлен для обратной совместимости
  Widget _buildLessonCard(ScheduleEvent lesson, BuildContext context) {
    return IOSStyleLessonCard(lesson: lesson);
  }

  String _getWeekdayName(int weekday) {
    return app_date_utils.AppDateUtils.getWeekdayName(weekday);
  }
}