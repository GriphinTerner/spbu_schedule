import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/schedule_models.dart';
import '../widgets/ios_style_widgets.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'package:adoptive_calendar/adoptive_calendar.dart';

class WeekScheduleScreen extends StatefulWidget {
  const WeekScheduleScreen({super.key});

  @override
  State<WeekScheduleScreen> createState() => _WeekScheduleScreenState();
}

class _WeekScheduleScreenState extends State<WeekScheduleScreen> {
  @override
  void initState() {
    super.initState();
  }

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

        final weekSchedule = scheduleProvider.getWeekSchedule();
        final baseDate = scheduleProvider.selectedDate;
        final startOfWeek =
            baseDate.subtract(Duration(days: baseDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final selectedDayIndex = _getSelectedDayIndex(baseDate);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IOSStyleSectionHeader(
                          title: scheduleProvider.studentGroupDisplayName ??
                              'Расписание СПбГУ',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        if (scheduleProvider.isUpdating)
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text(
                              'обновление данных...',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.calendar, size: 24),
                    onPressed: () => _showDatePicker(context, scheduleProvider),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: IOSStyleSectionHeader(
                title:
                    'Учебная неделя с ${app_date_utils.AppDateUtils.formatDate(startOfWeek)} по ${app_date_utils.AppDateUtils.formatDate(endOfWeek)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            _buildDaySelector(
              weekSchedule,
              scheduleProvider,
              startOfWeek,
              selectedDayIndex,
            ),
            Expanded(
              child: _buildDaySchedule(
                weekSchedule,
                startOfWeek,
                selectedDayIndex,
              ),
            ),
          ],
        );
      },
    );
  }

  int _getSelectedDayIndex(DateTime date) {
    return date.weekday == DateTime.sunday ? 0 : date.weekday - 1;
  }

  Widget _buildDaySelector(
    Map<int, List<ScheduleEvent>> weekSchedule,
    ScheduleProvider scheduleProvider,
    DateTime startOfWeek,
    int selectedDayIndex,
  ) {
    final days =
        List.generate(6, (index) => startOfWeek.add(Duration(days: index)));

    // Создаем карту, показывающую, есть ли события в каждый день недели
    Map<int, bool> hasEvents = {};
    for (int i = 1; i <= 6; i++) {
      hasEvents[i] = weekSchedule[i]?.isNotEmpty ?? false;
    }

    return IOSStyleDaySelector(
      selectedIndex: selectedDayIndex,
      onSelected: (index) {
        scheduleProvider.setSelectedDate(days[index]);
      },
      days: days,
      hasEvents: hasEvents,
    );
  }

  // Метод для группировки пар с похожими названиями
  List<Widget> _buildGroupedLessonCards(List<ScheduleEvent> events) {
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

    return lessonGroups;
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

  Widget _buildDaySchedule(
    Map<int, List<ScheduleEvent>> weekSchedule,
    DateTime startOfWeek,
    int selectedDayIndex,
  ) {
    final selectedDay = startOfWeek.add(Duration(days: selectedDayIndex));
    final weekday = selectedDay.weekday;

    // Проверяем, что день недели в допустимом диапазоне (1-7)
    if (weekday < 1 || weekday > 7) {
      return const IOSStyleEmptyView(
        message: 'Некорректный день недели',
        icon: CupertinoIcons.exclamationmark_circle,
      );
    }

    // Проверяем, является ли выбранный день выходным (воскресенье)
    if (weekday == 7) {
      return const IOSStyleEmptyView(
        message: 'Воскресенье - выходной день',
        icon: CupertinoIcons.calendar_badge_minus,
      );
    }

    final events = weekSchedule[weekday] ?? [];

    if (events.isEmpty) {
      return const IOSStyleEmptyView(
        message: 'В этот день нет занятий',
        icon: CupertinoIcons.calendar_badge_minus,
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
              title:
                  'Расписание на ${app_date_utils.AppDateUtils.getWeekdayName(weekday, capitalize: false)}:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._buildGroupedLessonCards(events),
          ],
        ),
      ),
    );
  }

  // Этот метод больше не используется, так как мы используем IOSStyleLessonCard
  // Оставлен для обратной совместимости
  Widget _buildLessonCard(ScheduleEvent lesson) {
    return IOSStyleLessonCard(lesson: lesson);
  }

  // Метод для отображения выбора даты
  void _showDatePicker(
      BuildContext context, ScheduleProvider scheduleProvider) async {
    DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AdoptiveCalendar(
          initialDate: scheduleProvider.selectedDate,
          datePickerOnly: true,
          onSelection: (newDate) {
            Navigator.pop(context, newDate);
          },
        );
      },
    );
    if (picked != null && picked != scheduleProvider.selectedDate) {
      scheduleProvider.setSelectedDate(picked);
    }
  }

  String _getWeekdayName(int weekday) {
    return app_date_utils.AppDateUtils.getWeekdayName(weekday);
  }

  String _getShortWeekdayName(int weekday) {
    return app_date_utils.AppDateUtils.getShortWeekdayName(weekday);
  }
}
