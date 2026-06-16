import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_models.dart';
import 'dart:io';

class ScheduleService {
  static const String _baseUrlHttps = 'https://timetable.spbu.ru/api/v1';
  static const String _baseUrlHttp = 'http://timetable.spbu.ru/api/v1';
  static const String _groupId = '428977'; // ID группы
  static const String _cacheKey = 'schedule_cache';
  static const String _cacheTimestampKey = 'schedule_cache_timestamp';
  static const String _weeksKey = 'saved_weeks';
  static const String _eventsKey = 'saved_events';
  static const String _currentWeekCacheKey = 'current_week_cache';
  static const String _currentWeekTimestampKey = 'current_week_timestamp';
  
  // Получаем URL в зависимости от платформы
  String get _baseUrl {
    if (Platform.isAndroid) {
      // На Android пробуем использовать HTTP и IP-адрес вместо доменного имени
      // Это может помочь обойти проблемы с DNS на некоторых устройствах Android
      return _baseUrlHttp;
    } else {
      // На других платформах используем HTTPS
      return _baseUrlHttps;
    }
  }
  
  // Попытка получить IP-адрес сервера
  Future<String?> _getServerIpAddress() async {
    try {
      final result = await InternetAddress.lookup('timetable.spbu.ru');
      if (result.isNotEmpty) {
        final ip = result[0].address;
        print('Resolved timetable.spbu.ru to IP: $ip');
        return ip;
      }
    } catch (e) {
      print('Failed to resolve timetable.spbu.ru: $e');
    }
    return null;
  }

  // Проверка, является ли неделя текущей
  bool _isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    // Начало недели - понедельник
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    // Конец недели - воскресенье
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    // Сравниваем только даты без времени
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOfWeekOnly = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeekOnly = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
    
    return (dateOnly.isAtSameMomentAs(startOfWeekOnly) || dateOnly.isAfter(startOfWeekOnly)) && 
           (dateOnly.isAtSameMomentAs(endOfWeekOnly) || dateOnly.isBefore(endOfWeekOnly));
  }
  
  // Проверка, является ли неделя следующей
  bool _isNextWeek(DateTime date) {
    final now = DateTime.now();
    // Начало текущей недели - понедельник
    final startOfCurrentWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    // Начало следующей недели - следующий понедельник
    final startOfNextWeek = startOfCurrentWeek.add(const Duration(days: 7));
    // Конец следующей недели - следующее воскресенье
    final endOfNextWeek = startOfNextWeek.add(const Duration(days: 6));
    
    // Сравниваем только даты без времени
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOfNextWeekOnly = DateTime(startOfNextWeek.year, startOfNextWeek.month, startOfNextWeek.day);
    final endOfNextWeekOnly = DateTime(endOfNextWeek.year, endOfNextWeek.month, endOfNextWeek.day);
    
    return (dateOnly.isAtSameMomentAs(startOfNextWeekOnly) || dateOnly.isAfter(startOfNextWeekOnly)) && 
           (dateOnly.isAtSameMomentAs(endOfNextWeekOnly) || dateOnly.isBefore(endOfNextWeekOnly));
  }
  
  // Сохранение расписания текущей недели в кэш
  Future<void> _saveCurrentWeekToCache(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentWeekCacheKey, data);
    await prefs.setInt(_currentWeekTimestampKey, DateTime.now().millisecondsSinceEpoch);
    print('Current week schedule saved to cache');
  }
  
  // Получение расписания текущей недели из кэша (приватный метод)
  Future<ScheduleResponse?> _getCachedCurrentWeekSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_currentWeekCacheKey);
    
    if (cachedData != null) {
      try {
        final jsonData = json.decode(cachedData);
        final scheduleResponse = ScheduleResponse.fromJson(jsonData);
        print('Loaded current week schedule from cache');
        return scheduleResponse;
      } catch (e) {
        print('Error parsing cached current week data: $e');
        return null;
      }
    }
    return null;
  }
  
  // Публичный метод для получения кэшированного расписания текущей недели
  Future<ScheduleResponse?> getCachedCurrentWeekSchedule() async {
    return _getCachedCurrentWeekSchedule();
  }
  
  // Метод для получения времени последнего обновления кэша расписания текущей недели
  Future<int?> getCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentWeekTimestampKey);
  }
  
  // Метод для очистки кэша расписания
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_currentWeekCacheKey);
    await prefs.remove(_currentWeekTimestampKey);
    await prefs.remove(_weeksKey);
    await prefs.remove(_eventsKey);
    print('Schedule cache cleared');
  }

  // Получение расписания для группы по диапазону дат
  Future<ScheduleResponse> getScheduleForDateRange(DateTime from, DateTime to) async {
    try {
      // Форматируем даты для API
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
      
      // Определяем параметры недели
      final now = DateTime.now();
      final isWeekend = (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday);
      final isCurrentWeek = _isCurrentWeek(from) && _isCurrentWeek(to);
      final isNextWeek = _isNextWeek(from) && _isNextWeek(to);
      
      // Определяем, нужно ли проверять кэш
      
      // Проверяем кэш в следующих случаях:
      // 1. Текущая недель (как раньше)
      // 2. Следующая неделя, если сегодня суббота или воскресенье
      if (isCurrentWeek) {
        print('Current week detected - checking cache first for week: $fromStr to $toStr');
        final cachedData = await _getCachedCurrentWeekSchedule();
        if (cachedData != null) {
          print('Using cached current week schedule');
          return cachedData;
        }
      } else if (isWeekend && isNextWeek) {
        // В субботу и воскресенье проверяем кэш для следующей недели
        print('Weekend + next week detected - checking cache first for week: $fromStr to $toStr');
        final cachedData = await _getCachedCurrentWeekSchedule();
        if (cachedData != null) {
          print('Using cached next week schedule (weekend mode)');
          return cachedData;
        }
      } else {
        // Для любой другой недели всегда запрашиваем свежие данные
        print('Non-current week detected - forcing fresh data request for week: $fromStr to $toStr');
      }
      
      // Проверяем наличие интернет-соединения
      bool hasInternet = await _checkInternetConnection();
      
      // Если есть интернет, пытаемся получить свежие данные
      if (hasInternet) {
        // Формируем URL с диапазоном дат
        var url = '$_baseUrl/groups/$_groupId/events/$fromStr/$toStr';
        print('Fetching schedule from: $url');
        
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 10), onTimeout: () {
            print('Request timed out after 10 seconds');
            throw TimeoutException('Request timed out');
          });
          
          if (response.statusCode == 200) {
            print('Request successful with date range URL');
            final data = response.body;
            final jsonData = json.decode(data);
            
            // Извлекаем название группы
            final studentGroupDisplayName = jsonData['StudentGroupDisplayName'] as String?;
            
            // Преобразуем данные в формат ScheduleResponse
            final days = _parseDaysFromJson(jsonData);
            
            final scheduleResponse = ScheduleResponse(
              days: days,
              studentGroupDisplayName: studentGroupDisplayName,
            );
            
            // Определяем, нужно ли кэшировать расписание
            
            // Кэшируем в следующих случаях:
            // 1. Текущая неделя (как раньше)
            // 2. Следующая неделя, если сегодня суббота или воскресенье
            if (isCurrentWeek) {
              await _saveCurrentWeekToCache(data);
              print('Current week schedule saved to cache');
            } else if (isWeekend && isNextWeek) {
              // В субботу и воскресенье кэшируем следующую неделю
              await _saveCurrentWeekToCache(data);
              print('Next week schedule saved to cache (weekend mode)');
            } else {
              print('Non-current week schedule fetched successfully - not caching');
            }
            
            return scheduleResponse;
          }
          throw Exception('Failed with status code: ${response.statusCode}');
        } catch (e) {
          print('Connection failed: $e');
          
          // Пробуем использовать кэш при ошибке
          if (isCurrentWeek) {
            final cachedData = await _getCachedCurrentWeekSchedule();
            if (cachedData != null) {
              print('Using cached current week schedule after connection failure');
              return cachedData;
            }
          } else if (isWeekend && isNextWeek) {
            // В субботу и воскресенье пробуем использовать кэш для следующей недели
            final cachedData = await _getCachedCurrentWeekSchedule();
            if (cachedData != null) {
              print('Using cached next week schedule after connection failure (weekend mode)');
              return cachedData;
            }
          } else {
            print('Failed to fetch non-current week schedule - no cache available');
          }
          
          throw Exception('Failed to connect to server: $e');
        }
      } else {
        // Если нет интернета, пробуем использовать кэш
        if (isCurrentWeek) {
          final cachedData = await _getCachedCurrentWeekSchedule();
          if (cachedData != null) {
            print('Using cached current week schedule (no internet connection)');
            return cachedData;
          }
        } else if (isWeekend && isNextWeek) {
          // В субботу и воскресенье пробуем использовать кэш для следующей недели
          final cachedData = await _getCachedCurrentWeekSchedule();
          if (cachedData != null) {
            print('Using cached next week schedule (no internet connection, weekend mode)');
            return cachedData;
          }
        }
        
        throw Exception('No internet connection available');
      }
    } catch (e) {
      print('Error in getScheduleForDateRange: $e');
      rethrow;
    }
  }
  
  // Парсинг дней из JSON ответа API
  List<ScheduleDay> _parseDaysFromJson(Map<String, dynamic> json) {
    final List<ScheduleDay> days = [];
    final List<dynamic> events = json['Days'] as List<dynamic>;
    
    for (var event in events) {
      final day = ScheduleDay.fromJson(event);
      days.add(day);
    }
    
    return days;
  }
  
  // Получение расписания для группы с кэшированием (обновлено по аналогии со Swift-проектом)
  Future<ScheduleResponse> getSchedule() async {
    try {
      // Проверяем наличие интернет-соединения
      bool hasInternet = await _checkInternetConnection();
      
      // Получаем данные из кэша
      final cachedData = await _getCachedSchedule();
      Map<DateTime, List<ScheduleEvent>> cachedEvents = await loadEvents();
      
      // Если есть кэшированные события, сразу используем их (как в Swift-проекте)
      if (cachedEvents.isNotEmpty) {
        print('Using cached events data');
      }
      
      // Если нет интернета и есть кэш, используем кэш
      if (!hasInternet && cachedData != null) {
        print('Using cached schedule data (no internet connection)');
        return cachedData;
      }
      
      // Если есть интернет, пытаемся получить свежие данные
      if (hasInternet) {
        // Сначала пробуем использовать стандартный URL
        var url = '$_baseUrl/groups/$_groupId/events';
        print('Fetching schedule from: $url');
        
        try {
          // Первая попытка с обычным URL
          try {
            final response = await http.get(
              Uri.parse(url),
              headers: {'Accept': 'application/json'},
            ).timeout(const Duration(seconds: 10), onTimeout: () {
              print('Request timed out after 10 seconds');
              throw TimeoutException('Request timed out');
            });
            
            // Если запрос успешен, сохраняем в кэш и возвращаем данные
             if (response.statusCode == 200) {
               print('Request successful with standard URL');
               final data = response.body;
               await _saveToCache(data);
               final jsonData = json.decode(data);
               final scheduleResponse = ScheduleResponse.fromJson(jsonData);
               
               // Обновляем кэш событий (как в Swift-проекте)
               await _updateEventsCache(scheduleResponse);
               
               return scheduleResponse;
             }
            throw Exception('Failed with status code: ${response.statusCode}');
          } catch (e) {
            // Если на Android произошла ошибка, пробуем использовать IP-адрес
            if (Platform.isAndroid) {
              print('Standard URL failed on Android, trying with IP address: $e');
              final ipAddress = await _getServerIpAddress();
              if (ipAddress != null) {
                // Формируем URL с IP-адресом вместо доменного имени
                final ipUrl = 'http://$ipAddress/api/v1/groups/$_groupId/events';
                print('Retrying with IP address URL: $ipUrl');
                
                final ipResponse = await http.get(
                  Uri.parse(ipUrl),
                  headers: {'Accept': 'application/json'},
                ).timeout(const Duration(seconds: 15), onTimeout: () {
                  print('IP address request timed out after 15 seconds');
                  throw TimeoutException('IP address request timed out');
                });
                
                if (ipResponse.statusCode == 200) {
                   print('Request successful with IP address URL');
                   // Сохраняем данные в кэш
                   final data = ipResponse.body;
                   await _saveToCache(data);
                   final jsonData = json.decode(data);
                   final scheduleResponse = ScheduleResponse.fromJson(jsonData);
                   
                   // Обновляем кэш событий (как в Swift-проекте)
                   await _updateEventsCache(scheduleResponse);
                   
                   return scheduleResponse;
                 }
              }
            }
            // Если все попытки не удались, пробрасываем исключение
            rethrow;
          }
        } catch (e) {
          print('All connection attempts failed: $e');
          rethrow;
        }
        
        // Если все попытки не удались и у нас есть кэш, используем его
        if (cachedData != null) {
          print('Using cached data due to all connection failures');
          return cachedData;
        }
        
        // Если нет кэша и все попытки соединения не удались
        throw Exception('Failed to connect to server and no cache available');
      } else if (cachedData != null) {
        // Если нет интернета, но есть кэш
        return cachedData;
      } else {
        // Если нет ни интернета, ни кэша
        throw Exception('No internet connection and no cached data available');
      }
    } catch (e) {
      // Проверяем, есть ли кэш в случае ошибки
      final cachedData = await _getCachedSchedule();
      if (cachedData != null) {
        print('Using cached schedule data (error occurred: $e)');
        return cachedData;
      }
      throw Exception('Error fetching schedule: $e');
    }
  }
  
  // Обновление кэша событий из полученного расписания
  Future<void> _updateEventsCache(ScheduleResponse response) async {
    try {
      // Получаем текущий кэш событий
      final cachedEvents = await loadEvents();
      
      // Преобразуем события из ответа API в формат для кэша
      final Map<DateTime, List<ScheduleEvent>> newEvents = {};
      
      for (var day in response.days) {
        for (var event in day.events) {
          final date = DateTime(event.start.year, event.start.month, event.start.day);
          if (!newEvents.containsKey(date)) {
            newEvents[date] = [];
          }
          newEvents[date]!.add(event);
        }
      }
      
      // Объединяем с существующим кэшем, отдавая приоритет новым данным
      cachedEvents.addAll(newEvents);
      
      // Сохраняем обновленный кэш
      await saveEvents(cachedEvents);
      
      // Обновляем кэш недель
      await _updateWeeksCache(response);
      
      print('Events cache updated successfully');
    } catch (e) {
      print('Error updating events cache: $e');
    }
  }
  
  // Обновление кэша недель из полученного расписания
  Future<void> _updateWeeksCache(ScheduleResponse response) async {
    try {
      // Получаем текущий кэш недель
      final cachedWeeks = await loadWeeks();
      
      // Создаем список дат из ответа API
      final Set<DateTime> dates = {};
      for (var day in response.days) {
        for (var event in day.events) {
          dates.add(DateTime(event.start.year, event.start.month, event.start.day));
        }
      }
      
      // Группируем даты по неделям
      final Map<int, List<DateTime>> weekMap = {};
      for (var date in dates) {
        // Определяем номер недели (можно использовать любую логику группировки)
        final weekNumber = date.difference(DateTime(date.year, 1, 1)).inDays ~/ 7;
        if (!weekMap.containsKey(weekNumber)) {
          weekMap[weekNumber] = [];
        }
        weekMap[weekNumber]!.add(date);
      }
      
      // Преобразуем в список недель
      final List<List<DateTime>> newWeeks = weekMap.values.toList();
      
      // Добавляем новые недели, которых еще нет в кэше
      for (var newWeek in newWeeks) {
        bool weekExists = false;
        for (var cachedWeek in cachedWeeks) {
          // Проверяем, есть ли уже такая неделя в кэше
          if (cachedWeek.isNotEmpty && newWeek.isNotEmpty && 
              _isSameWeek(cachedWeek.first, newWeek.first)) {
            weekExists = true;
            break;
          }
        }
        
        if (!weekExists) {
          cachedWeeks.add(newWeek);
        }
      }
      
      // Сохраняем обновленный кэш недель
      await saveWeeks(cachedWeeks);
      
      print('Weeks cache updated successfully');
    } catch (e) {
      print('Error updating weeks cache: $e');
    }
  }
  
  // Проверка, относятся ли две даты к одной неделе
  bool _isSameWeek(DateTime date1, DateTime date2) {
    // Начало недели (понедельник)
    final monday1 = date1.subtract(Duration(days: date1.weekday - 1));
    final monday2 = date2.subtract(Duration(days: date2.weekday - 1));
    
    return monday1.year == monday2.year && 
           monday1.month == monday2.month && 
           monday1.day == monday2.day;
  }
  
  // Проверка интернет-соединения
  Future<bool> _checkInternetConnection() async {
    // Сначала пробуем проверить соединение с сервером расписания
    try {
      final host = Platform.isAndroid ? 'timetable.spbu.ru' : 'timetable.spbu.ru';
      print('Checking connection to: $host');
      final result = await InternetAddress.lookup(host);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Connection to $host successful');
        return true;
      }
    } on SocketException catch (e) {
      print('Socket exception during connectivity check to timetable.spbu.ru: $e');
    } catch (e) {
      print('Error during connectivity check to timetable.spbu.ru: $e');
    }
    
    // Если не удалось подключиться к серверу расписания, пробуем общий интернет
    try {
      print('Checking connection to google.com as fallback');
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Connection to google.com successful, but timetable.spbu.ru failed');
        // Есть интернет, но нет доступа к серверу расписания
        return true;
      }
    } on SocketException catch (e) {
      print('Socket exception during fallback connectivity check: $e');
    } catch (e) {
      print('Error during fallback connectivity check: $e');
    }
    
    print('No internet connection detected');
    return false;
  }
  
  // Сохранение данных в кэш
  Future<void> _saveToCache(String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, data);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('Schedule data saved to cache');
    } catch (e) {
      print('Error saving data to cache: $e');
    }
  }
  
  // Проверка наличия кэшированных данных
  Future<bool> _hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_cacheKey) && prefs.getString(_cacheKey)?.isNotEmpty == true;
    } catch (e) {
      print('Error checking cached data: $e');
      return false;
    }
  }
  
  // Получение данных из кэша напрямую
  Future<dynamic> _getFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final jsonData = json.decode(cachedJson);
        return ScheduleResponse.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('Error getting data from cache: $e');
      return null;
    }
  }
  
  // Получение данных из кэша
  Future<ScheduleResponse?> _getCachedSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final jsonData = json.decode(cachedJson);
        return ScheduleResponse.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('Error reading from cache: $e');
      return null;
    }
  }
  
  // Сохранение данных в кэш
  Future<void> _cacheSchedule(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      
      // Сохраняем данные и временную метку
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('Schedule data cached successfully');
    } catch (e) {
      print('Error caching schedule data: $e');
    }
  }
  
  // Сохранение недель в кэш (как в Swift-проекте)
  Future<void> saveWeeks(List<List<DateTime>> weeks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(weeks.map((week) => 
        week.map((day) => day.toIso8601String()).toList()
      ).toList());
      
      await prefs.setString(_weeksKey, jsonString);
      print('Weeks data saved to cache');
    } catch (e) {
      print('Error saving weeks to cache: $e');
    }
  }
  
  // Загрузка недель из кэша (как в Swift-проекте)
  Future<List<List<DateTime>>> loadWeeks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_weeksKey);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> jsonData = json.decode(cachedJson);
        return jsonData.map((weekData) => 
          (weekData as List<dynamic>).map((dayString) => 
            DateTime.parse(dayString as String)
          ).toList()
        ).toList();
      }
      return [];
    } catch (e) {
      print('Error loading weeks from cache: $e');
      return [];
    }
  }
  
  // Сохранение событий в кэш (как в Swift-проекте)
  Future<void> saveEvents(Map<DateTime, List<ScheduleEvent>> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, List<dynamic>> encodableMap = {};
      
      events.forEach((date, eventsList) {
        final dateString = date.toIso8601String();
        encodableMap[dateString] = eventsList.map((e) => e.toJson()).toList();
      });
      
      final jsonString = json.encode(encodableMap);
      await prefs.setString(_eventsKey, jsonString);
      print('Events data saved to cache');
    } catch (e) {
      print('Error saving events to cache: $e');
    }
  }
  
  // Загрузка событий из кэша (как в Swift-проекте)
  Future<Map<DateTime, List<ScheduleEvent>>> loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_eventsKey);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> jsonData = json.decode(cachedJson);
        final Map<DateTime, List<ScheduleEvent>> result = {};
        
        jsonData.forEach((dateString, eventsList) {
          final date = DateTime.parse(dateString);
          result[date] = (eventsList as List<dynamic>).map((eventJson) => 
            ScheduleEvent.fromJson(eventJson)
          ).toList();
        });
        
        return result;
      }
      return {};
    } catch (e) {
      print('Error loading events from cache: $e');
      return {};
    }
  }
}