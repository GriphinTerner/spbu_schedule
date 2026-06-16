import 'package:flutter/material.dart';
import '../models/schedule_models.dart';
import '../services/schedule_service.dart';
import 'package:intl/intl.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _scheduleService = ScheduleService();
  ScheduleResponse? _scheduleData;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String? _studentGroupDisplayName;

  ScheduleResponse? get scheduleData => _scheduleData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  String? get studentGroupDisplayName => _studentGroupDisplayName;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  ScheduleProvider() {
    // Сначала загружаем кэшированные данные без индикатора загрузки
    _loadCachedData();
    // Затем обновляем данные в фоне
    _updateDataInBackground();
  }
  
  // Загрузка кэшированных данных мгновенно
  Future<void> _loadCachedData() async {
    try {
      final today = DateTime.now();
      final isSaturday = today.weekday == DateTime.saturday;
      final isSunday = today.weekday == DateTime.sunday;
      
      final cachedData = await _scheduleService.getCachedCurrentWeekSchedule();
      
      if (cachedData != null) {
        // ПРОСТАЯ ЛОГИКА: Если сегодня суббота или воскресенье, ВСЕГДА обновляем кэш
        if (isSaturday || isSunday) {
          print('Суббота/Воскресенье: АВТОМАТИЧЕСКИ обновляем кэш на следующую неделю');
          
          // Очищаем кэш
          await _scheduleService.clearCache();
          
          // Устанавливаем дату на следующий понедельник
          final nextMonday = today.subtract(Duration(days: today.weekday - 1)).add(const Duration(days: 7));
          _selectedDate = nextMonday;
          
          // Сбрасываем данные
          _scheduleData = null;
          _studentGroupDisplayName = null;
          notifyListeners();
          
          // ЗАПУСКАЕМ ОБНОВЛЕНИЕ НА СЛЕДУЮЩУЮ НЕДЕЛЮ
          fetchSchedule(showUpdateIndicator: false);
          return;
        }
        
        // Для других дней недели используем кэш
        _scheduleData = cachedData;
        _studentGroupDisplayName = cachedData.studentGroupDisplayName;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }
  
  // Обновление данных в фоновом режиме
  Future<void> _updateDataInBackground() async {
    // Небольшая задержка, чтобы дать интерфейсу отрисоваться
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Проверяем, нужно ли обновить расписание для новой недели
    final today = DateTime.now();
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    
    // Проверяем, нужно ли принудительно обновить кэш на следующую неделю
    bool shouldForceUpdateNextWeek = false;
    bool shouldLoadNextWeek = false;
    
    // Если сегодня суббота после пар или воскресенье, загружаем расписание на следующую неделю
    final isSaturday = today.weekday == DateTime.saturday;
    final isSunday = today.weekday == DateTime.sunday;
    
    // Проверяем, есть ли пары в субботу и закончились ли они
    if (isSaturday) {
      final saturdaySchedule = getDaySchedule(today);
      final hasSaturdayLessons = saturdaySchedule != null && saturdaySchedule.events.isNotEmpty;
      
      if (hasSaturdayLessons) {
        // Проверяем, закончились ли все пары в субботу
        final now = DateTime.now();
        final sortedEvents = List<ScheduleEvent>.from(saturdaySchedule!.events)
          ..sort((a, b) => a.start.compareTo(b.start));
        
        // Если все пары закончились, принудительно обновляем кэш на следующую неделю
        if (sortedEvents.isNotEmpty && now.isAfter(sortedEvents.last.end)) {
          shouldForceUpdateNextWeek = true;
          print('Суббота: все пары закончились, ПРИНУДИТЕЛЬНО обновляем кэш на следующую неделю');
        }
      } else {
        // Если в субботу нет пар, загружаем расписание на следующую неделю
        shouldLoadNextWeek = true;
        print('Суббота: нет пар, загружаем расписание на следующую неделю');
      }
    } else if (isSunday) {
      // В воскресенье всегда загружаем расписание на следующую неделю
      shouldLoadNextWeek = true;
      print('Воскресенье: загружаем расписание на следующую неделю');
    }
    
    // ГАРАНТИРОВАННОЕ обновление кэша на следующую неделю после окончания пар в субботу или в воскресенье
    if (shouldForceUpdateNextWeek || shouldLoadNextWeek) {
      // ОБЯЗАТЕЛЬНО очищаем кэш старого расписания
      await _scheduleService.clearCache();
      print('КЭШ ОЧИЩЕН АВТОМАТИЧЕСКИ!');
      
      // Устанавливаем дату на следующий понедельник
      final nextMonday = currentWeekStart.add(const Duration(days: 7));
      _selectedDate = nextMonday;
      
      print('Загружаем расписание на неделю с ${DateFormat('dd.MM.yyyy').format(nextMonday)}');
      
      // Загружаем новое расписание БЕЗ индикатора загрузки для плавного обновления
      fetchSchedule(showUpdateIndicator: false);
      return; // Выходим, чтобы не вызывать fetchSchedule дважды
    }
    
    // Обычное обновление расписания (если не суббота/воскресенье)
    fetchSchedule(showUpdateIndicator: true);
  }
  
  // Метод для установки выбранной даты и обновления расписания
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchSchedule();
  }

  // Получение начала и конца недели для выбранной даты
  (DateTime, DateTime) getWeekBoundaries(DateTime date) {
    // Находим ближайший понедельник (начало недели)
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    // Находим ближайшее воскресенье (конец недели)
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return (startOfWeek, endOfWeek);
  }

  Future<void> fetchSchedule({bool showUpdateIndicator = false}) async {
    _isLoading = !showUpdateIndicator; // Если показываем индикатор обновления, не показываем загрузку
    _isUpdating = showUpdateIndicator; // Показываем индикатор обновления, если нужно
    _error = null;
    notifyListeners();

    try {
      // Получаем границы недели для выбранной даты
      final (startOfWeek, endOfWeek) = getWeekBoundaries(_selectedDate);
      
      // Используем обновленный метод getScheduleForDateRange из ScheduleService
      _scheduleData = await _scheduleService.getScheduleForDateRange(
        startOfWeek, 
        endOfWeek
      );
      
      // Получаем название группы
      _studentGroupDisplayName = _scheduleData?.studentGroupDisplayName;
      
      if (_scheduleData == null || _scheduleData!.days.isEmpty) {
        _error = 'Не удалось загрузить расписание. Пожалуйста, попробуйте позже.';
      }
    } catch (e) {
      print('Error in fetchSchedule: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Получение расписания на конкретный день
  ScheduleDay? getDaySchedule(DateTime date) {
    if (_scheduleData == null) return null;

    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return _scheduleData!.days.firstWhere(
      (day) => day.day.toString().startsWith(dateString),
      orElse: () => ScheduleDay(day: date, events: []),
    );
  }
  
  // Получение расписания на следующий учебный день
  List<ScheduleEvent> getNextStudyDaySchedule() {
    if (_scheduleData == null) return [];
    
    final today = DateTime.now();
    
    // Проверяем следующие 14 дней (2 недели)
    for (int i = 1; i <= 14; i++) {
      final nextDate = today.add(Duration(days: i));
      final daySchedule = getDaySchedule(nextDate);
      
      // Если нашли день с парами, возвращаем его расписание
      if (daySchedule != null && daySchedule.events.isNotEmpty) {
        return daySchedule.events;
      }
    }
    
    return []; // Если не нашли дней с парами в ближайшие 2 недели
  }
  
  // Получение даты следующего учебного дня
  DateTime? getNextStudyDay() {
    if (_scheduleData == null) return null;
    
    final today = DateTime.now();
    
    // Проверяем следующие 14 дней (2 недели)
    for (int i = 1; i <= 14; i++) {
      final nextDate = today.add(Duration(days: i));
      final daySchedule = getDaySchedule(nextDate);
      
      // Если нашли день с парами, возвращаем его дату
      if (daySchedule != null && daySchedule.events.isNotEmpty) {
        return nextDate;
      }
    }
    
    return null; // Если не нашли дней с парами в ближайшие 2 недели
  }

  // Получение расписания на сегодня
  List<ScheduleEvent> getTodaySchedule() {
    final today = getDaySchedule(DateTime.now());
    return today?.events ?? [];
  }

  // Получение расписания на завтра
  ScheduleDay? getTomorrowSchedule() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return getDaySchedule(tomorrow);
  }

  // Получение расписания на неделю
  Map<int, List<ScheduleEvent>> getWeekSchedule() {
    if (_scheduleData == null) return {};

    // Используем выбранную дату вместо текущей, чтобы отображать корректную неделю
    final baseDate = _selectedDate;
    final weekStart = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    
    Map<int, List<ScheduleEvent>> weekSchedule = {};
    
    for (int i = 0; i < 6; i++) { // Понедельник - Суббота
      final date = weekStart.add(Duration(days: i));
      final weekday = date.weekday;
      final daySchedule = getDaySchedule(date);
      weekSchedule[weekday] = daySchedule?.events ?? [];
    }
    
    return weekSchedule;
  }

  // Определение статуса расписания
  (ScheduleStatus, List<ScheduleEvent>) getScheduleStatus() {
    final now = DateTime.now();
    final todaySchedule = getTodaySchedule();

    if (todaySchedule.isEmpty) {
      // Проверяем, есть ли у нас данные расписания
      if (_scheduleData == null || _scheduleData!.days.isEmpty) {
        return (ScheduleStatus.nextDay, []); // Возвращаем пустой список, если нет данных
      }
      
      var nextDay = now.add(const Duration(days: 1));
      var nextDaySchedule = getDaySchedule(nextDay);
      
      // Ограничиваем количество итераций, чтобы избежать бесконечного цикла
      int maxIterations = 14; // Максимум 2 недели
      int currentIteration = 0;
      
      while ((nextDaySchedule == null || nextDaySchedule.events.isEmpty) && currentIteration < maxIterations) {
        nextDay = nextDay.add(const Duration(days: 1));
        nextDaySchedule = getDaySchedule(nextDay);
        currentIteration++;
      }
      
      // Проверяем, нашли ли мы день с парами
      if (nextDaySchedule == null || nextDaySchedule.events.isEmpty) {
        return (ScheduleStatus.nextDay, []); // Возвращаем пустой список, если не нашли
      }
      
      return (ScheduleStatus.nextDay, nextDaySchedule.events);
    }

    final sortedEvents = List<ScheduleEvent>.from(todaySchedule)
      ..sort((a, b) => a.start.compareTo(b.start));

    if (now.isBefore(sortedEvents.first.start)) {
      return (ScheduleStatus.firstLesson, [sortedEvents.first]);
    }

    if (now.isAfter(sortedEvents.last.end)) {
      // Проверяем, есть ли у нас данные расписания
      if (_scheduleData == null || _scheduleData!.days.isEmpty) {
        return (ScheduleStatus.lessonsOver, []); // Возвращаем пустой список, если нет данных
      }
      
      var nextDay = now.add(const Duration(days: 1));
      var nextDaySchedule = getDaySchedule(nextDay);
      
      // Ограничиваем количество итераций, чтобы избежать бесконечного цикла
      int maxIterations = 14; // Максимум 2 недели
      int currentIteration = 0;
      
      while ((nextDaySchedule == null || nextDaySchedule.events.isEmpty) && currentIteration < maxIterations) {
        nextDay = nextDay.add(const Duration(days: 1));
        nextDaySchedule = getDaySchedule(nextDay);
        currentIteration++;
      }
      
      // Проверяем, нашли ли мы день с парами
      if (nextDaySchedule == null || nextDaySchedule.events.isEmpty) {
        return (ScheduleStatus.lessonsOver, []); // Возвращаем пустой список, если не нашли
      }
      
      return (ScheduleStatus.lessonsOver, nextDaySchedule.events);
    }

    for (int i = 0; i < sortedEvents.length; i++) {
      final event = sortedEvents[i];
      
      if (now.isAfter(event.start) && now.isBefore(event.end)) {
        if (i == sortedEvents.length - 1) {
          return (ScheduleStatus.lastLesson, [event]);
        } else {
          return (ScheduleStatus.currentLesson, [event, sortedEvents[i + 1]]);
        }
      }
      
      if (i < sortedEvents.length - 1) {
        final nextEvent = sortedEvents[i + 1];
        if (now.isAfter(event.end) && now.isBefore(nextEvent.start)) {
          return (ScheduleStatus.break_, [nextEvent]);
        }
      }
    }

    return (ScheduleStatus.lastLesson, [sortedEvents.last]);
  }
  
  // Получение всех текущих пар
  List<ScheduleEvent> getCurrentLessons([DateTime? startTime]) {
    final todaySchedule = getTodaySchedule();
    if (todaySchedule.isEmpty) return [];
    
    // Если время начала не указано, находим текущие пары
    if (startTime == null) {
      final now = DateTime.now();
      return todaySchedule.where((event) => 
        now.isAfter(event.start) && now.isBefore(event.end)
      ).toList();
    }
    
    // Форматируем время начала для сравнения
    final startTimeStr = DateFormat('HH:mm').format(startTime);
    
    // Фильтруем события, которые начинаются в то же время
    return todaySchedule.where((event) {
      final eventStartTimeStr = DateFormat('HH:mm').format(event.start);
      return eventStartTimeStr == startTimeStr;
    }).toList();
  }
  
  // Получение всех следующих пар, которые начинаются позже текущих
  List<ScheduleEvent> getNextLessons() {
    final now = DateTime.now();
    final todaySchedule = getTodaySchedule();
    
    // Если сегодня нет пар или все пары закончились, ищем в следующем учебном дне
    if (todaySchedule.isEmpty || now.isAfter(todaySchedule.last.end)) {
      // Проверяем, есть ли у нас данные расписания
      if (_scheduleData == null || _scheduleData!.days.isEmpty) {
        return []; // Возвращаем пустой список, если нет данных
      }
      
      var nextDay = now.add(const Duration(days: 1));
      var nextDaySchedule = getDaySchedule(nextDay);
      
      // Ограничиваем количество итераций, чтобы избежать бесконечного цикла
      int maxIterations = 14; // Максимум 2 недели
      int currentIteration = 0;
      
      while ((nextDaySchedule == null || nextDaySchedule.events.isEmpty) && currentIteration < maxIterations) {
        nextDay = nextDay.add(const Duration(days: 1));
        nextDaySchedule = getDaySchedule(nextDay);
        currentIteration++;
      }
      
      // Проверяем, нашли ли мы день с парами
      if (nextDaySchedule == null || nextDaySchedule.events.isEmpty) {
        return []; // Возвращаем пустой список, если не нашли
      }
      
      // Возвращаем первую пару следующего дня
      final sortedEvents = List<ScheduleEvent>.from(nextDaySchedule.events)
        ..sort((a, b) => a.start.compareTo(b.start));
      
      if (sortedEvents.isNotEmpty) {
        final firstStartTime = sortedEvents.first.start;
        return nextDaySchedule.events.where((event) => 
          event.start.hour == firstStartTime.hour && 
          event.start.minute == firstStartTime.minute
        ).toList();
      }
      return [];
    }
    
    // Находим текущие пары
    final currentLessons = getCurrentLessons();
    
    // Если нет текущих пар, находим ближайшую следующую пару
    if (currentLessons.isEmpty) {
      final sortedEvents = List<ScheduleEvent>.from(todaySchedule)
        ..sort((a, b) => a.start.compareTo(b.start));
      
      // Находим первую пару, которая еще не началась
      final nextEvent = sortedEvents.firstWhere(
        (event) => now.isBefore(event.start),
        orElse: () => sortedEvents.last
      );
      
      // Возвращаем все пары с таким же временем начала
      return todaySchedule.where((event) => 
        event.start.hour == nextEvent.start.hour && 
        event.start.minute == nextEvent.start.minute
      ).toList();
    }
    
    // Если есть текущие пары, находим следующие пары, которые начинаются позже
    final currentStartTime = currentLessons.first.start;
    final sortedEvents = List<ScheduleEvent>.from(todaySchedule)
      ..sort((a, b) => a.start.compareTo(b.start));
    
    // Находим первую пару, которая начинается позже текущих
    for (final event in sortedEvents) {
      if (event.start.isAfter(currentStartTime)) {
        // Возвращаем все пары с таким же временем начала
        return todaySchedule.where((e) => 
          e.start.hour == event.start.hour && 
          e.start.minute == event.start.minute
        ).toList();
      }
    }
    
    return [];
  }
}