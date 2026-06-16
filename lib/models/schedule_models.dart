class ScheduleEvent {
  final DateTime start;
  final DateTime end;
  final String subject;
  final String location;
  final String educator;
  final bool isCancelled;
  final bool isTimeChanged;
  final String? statusIndicator; // 'canceled', 'rescheduled', or null for normal

  ScheduleEvent({
    required this.start,
    required this.end,
    required this.subject,
    required this.location,
    required this.educator,
    this.isCancelled = false,
    this.isTimeChanged = false,
    this.statusIndicator,
  });

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    // Проверяем наличие полей IsCancelled и TimeWasChanged, как в Swift проекте
    final bool isCancelled = json['IsCancelled'] == true;
    final bool isTimeChanged = json['TimeWasChanged'] == true;
    
    // Определяем статус индикатора на основе полей
    String? statusIndicator;
    if (isCancelled) {
      statusIndicator = 'canceled';
    } else if (isTimeChanged) {
      statusIndicator = 'rescheduled';
    }
    
    return ScheduleEvent(
      start: DateTime.parse(json['Start']),
      end: DateTime.parse(json['End']),
      subject: json['Subject'] ?? '',
      location: json['LocationsDisplayText'] ?? '',
      educator: json['EducatorsDisplayText'] ?? '',
      isCancelled: isCancelled,
      isTimeChanged: isTimeChanged,
      statusIndicator: statusIndicator,
    );
  }

  String get startTime => '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  String get endTime => '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  
  Map<String, dynamic> toJson() {
    return {
      'Start': start.toIso8601String(),
      'End': end.toIso8601String(),
      'Subject': subject,
      'LocationsDisplayText': location,
      'EducatorsDisplayText': educator,
      'IsCancelled': isCancelled,
      'TimeWasChanged': isTimeChanged,
    };
  }
}

class ScheduleDay {
  final DateTime day;
  final List<ScheduleEvent> events;

  ScheduleDay({
    required this.day,
    required this.events,
  });

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    return ScheduleDay(
      day: DateTime.parse(json['Day']),
      events: (json['DayStudyEvents'] as List)
          .map((event) => ScheduleEvent.fromJson(event))
          .toList(),
    );
  }

  String get weekdayName {
    final weekdays = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
    return weekdays[day.weekday - 1];
  }

  String get shortWeekdayName {
    final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[day.weekday - 1];
  }

  String get formattedDate => '${day.day}.${day.month}';
}

class ScheduleResponse {
  final List<ScheduleDay> days;
  final String? studentGroupDisplayName;

  ScheduleResponse({
    required this.days,
    this.studentGroupDisplayName,
  });

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json.containsKey('Days') && json['Days'] is List) {
        // Стандартный формат ответа API
        return ScheduleResponse(
          days: (json['Days'] as List)
              .map((day) => ScheduleDay.fromJson(day))
              .toList(),
        );
      } else if (json.containsKey('Day') && json.containsKey('DayStudyEvents')) {
        // Если это один день (как в примере needed_output.json)
        return ScheduleResponse(
          days: [ScheduleDay.fromJson(json)],
        );
      } else {
        // Если структура не соответствует ожиданиям
        print('Unexpected JSON structure: $json');
        return ScheduleResponse(days: []);
      }
    } catch (e) {
      print('Error parsing schedule: $e');
      return ScheduleResponse(days: []);
    }
  }
}

enum ScheduleStatus {
  firstLesson,
  currentLesson,
  break_,
  lastLesson,
  nextDay,
  lessonsOver,
}