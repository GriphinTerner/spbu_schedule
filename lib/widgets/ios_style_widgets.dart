import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/schedule_models.dart';

class IOSStyleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const IOSStyleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.elevation = 0,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardTheme.color,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class IOSStyleLessonCard extends StatefulWidget {
  final ScheduleEvent lesson;
  final bool isActive;
  final bool isStackCard;
  final List<ScheduleEvent>? stackLessons;
  final String? statusIndicator; // Add status indicator property

  const IOSStyleLessonCard({
    super.key,
    required this.lesson,
    this.isActive = false,
    this.isStackCard = false,
    this.stackLessons,
    this.statusIndicator, // Status indicator for showing lesson state (e.g., 'canceled', 'rescheduled')
  });

  @override
  State<IOSStyleLessonCard> createState() => _IOSStyleLessonCardState();
}

class _IOSStyleLessonCardState extends State<IOSStyleLessonCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _isTextOverflowing = false;
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant IOSStyleLessonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.subject != widget.lesson.subject) {
      _checkTextOverflow();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkTextOverflow();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkTextOverflow() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.lesson.subject,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );

    // We need to layout the text painter to get its metrics.
    // A reasonable max width for the subject text, considering padding and time container.
    // This is an approximation, a LayoutBuilder would be more accurate.
    final double maxWidth = MediaQuery.of(context).size.width -
        16 * 2 -
        10 -
        100; // Card padding - time container width
    textPainter.layout(maxWidth: maxWidth);

    final isTextOverflowing = textPainter.didExceedMaxLines;
    if (_isTextOverflowing == isTextOverflowing &&
        (isTextOverflowing || !_expanded)) {
      return;
    }

    setState(() {
      _isTextOverflowing = isTextOverflowing;
      if (!isTextOverflowing) {
        _expanded = false; // Collapse if text no longer overflows
        _controller.reverse();
      }
    });
  }

  void _toggleExpanded() {
    // Toggle if text overflows or it's a stack card
    if (!_isTextOverflowing && !widget.isStackCard) return;

    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Color _getStatusColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Проверяем статус занятия, если он указан
    if (widget.statusIndicator != null) {
      switch (widget.statusIndicator) {
        case 'canceled':
          return isDark ? Colors.red.shade300 : Colors.red;
        case 'rescheduled':
          return isDark ? Colors.orange.shade300 : Colors.orange;
        default:
          return isDark ? Colors.blue.shade300 : Colors.blue;
      }
    }

    // По умолчанию используем синий цвет
    return isDark ? Colors.blue.shade300 : Colors.blue;
  }

  LinearGradient _getCardGradient(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(context);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        statusColor.withOpacity(isDark ? 0.15 : 0.05),
        statusColor.withOpacity(0.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subject = widget.lesson.subject.split('_').first;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: IOSStyleCard(
        backgroundColor: widget.isActive
            ? colorScheme.primary.withOpacity(0.1)
            : theme.cardTheme.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = _buildExpandableText(
                  subject,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: widget.isActive ? colorScheme.primary : null,
                    fontWeight: FontWeight.w600,
                    height: 1.18,
                  ),
                  collapsedMaxLines: 2,
                );
                final timeBadge = _buildTimeBadge(context);

                if (constraints.maxWidth < 380) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 8),
                      timeBadge,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 10),
                    timeBadge,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: CupertinoIcons.location,
              text: widget.lesson.location,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              icon: CupertinoIcons.person,
              text: widget.lesson.educator,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _expanded ? 20 : 0,
              child: Center(
                child: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: _expanded ? 20 : 0,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.isActive
            ? colorScheme.primary
            : colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '${widget.lesson.startTime} - ${widget.lesson.endTime}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: widget.isActive ? Colors.white : colorScheme.primary,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableText(
    String text, {
    TextStyle? style,
    int collapsedMaxLines = 2,
  }) {
    return AnimatedCrossFade(
      firstChild: Text(
        text,
        style: style,
        softWrap: true,
        maxLines: collapsedMaxLines,
        overflow: TextOverflow.ellipsis,
      ),
      secondChild: Text(
        text,
        style: style,
        softWrap: true,
      ),
      crossFadeState:
          _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String text}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary.withOpacity(0.8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildExpandableText(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
            collapsedMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

class IOSStyleDaySelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;
  final List<DateTime> days;
  final Map<int, bool> hasEvents;

  const IOSStyleDaySelector({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.days,
    required this.hasEvents,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const spacing = 8.0;
        final availableWidth = constraints.maxWidth -
            horizontalPadding * 2 -
            spacing * (days.length - 1);
        final itemWidth =
            (availableWidth / days.length).clamp(52.0, 70.0).toDouble();

        return SizedBox(
          height: 96,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                for (var index = 0; index < days.length; index++) ...[
                  _DaySelectorItem(
                    day: days[index],
                    width: itemWidth,
                    isSelected: selectedIndex == index,
                    hasEvent: hasEvents[days[index].weekday] ?? false,
                    onTap: () => onSelected(index),
                  ),
                  if (index != days.length - 1) const SizedBox(width: spacing),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DaySelectorItem extends StatelessWidget {
  final DateTime day;
  final double width;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  const _DaySelectorItem({
    required this.day,
    required this.width,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = isSelected
        ? Colors.white
        : (hasEvent ? theme.colorScheme.onSurface : theme.disabledColor);

    return GestureDetector(
      onTap: hasEvent ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (hasEvent
                  ? theme.cardTheme.color
                  : theme.disabledColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getShortWeekdayName(day.weekday),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              day.day.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _getMonthName(day.month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getShortWeekdayName(int weekday) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return months[month - 1];
  }
}

class IOSStyleSectionHeader extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const IOSStyleSectionHeader({
    super.key,
    required this.title,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: style ??
            theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class IOSStyleErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const IOSStyleErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: onRetry,
              borderRadius: BorderRadius.circular(12),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class IOSStyleEmptyView extends StatelessWidget {
  final String message;
  final IconData? icon;

  const IOSStyleEmptyView({
    super.key,
    required this.message,
    this.icon = CupertinoIcons.calendar_badge_minus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectGroupCard extends StatefulWidget {
  final String subject;
  final List<ScheduleEvent> events;
  final String?
      statusIndicator; // 'canceled', 'rescheduled', or null for normal
  final bool
      isActive; // Добавляем параметр isActive для отображения активной пары

  const SubjectGroupCard({
    super.key,
    required this.subject,
    required this.events,
    this.statusIndicator,
    this.isActive = false, // По умолчанию пара не активна
  });

  @override
  State<SubjectGroupCard> createState() => _SubjectGroupCardState();
}

class _SubjectGroupCardState extends State<SubjectGroupCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _heightFactor;
  late Animation<double> _iconTurn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeOutCubic));
    _iconTurn = Tween<double>(begin: 0.0, end: 0.25).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  // Получение цвета статуса для индикатора
  Color _getStatusColor(BuildContext context, [String? statusOverride]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = statusOverride ?? widget.statusIndicator;

    // Проверяем статус занятия, если он указан
    if (status != null) {
      switch (status) {
        case 'canceled':
          return Colors.red.shade600;
        case 'rescheduled':
          return Colors.orange.shade600;
        default:
          return isDark
              ? Colors.blue.shade300
              : Colors.blue.shade700; // Изменено на синий
      }
    }

    // Проверяем статусы всех событий в группе
    bool hasCanceled = widget.events.any((event) => event.isCancelled);
    bool hasRescheduled = widget.events.any((event) => event.isTimeChanged);

    if (hasCanceled) {
      return Colors.red.shade600;
    } else if (hasRescheduled) {
      return Colors.orange.shade600;
    }

    // По умолчанию используем синий цвет
    return isDark
        ? Colors.blue.shade300
        : Colors.blue.shade700; // Изменено на синий
  }

  // Анимированное построение дополнительных карточек с каскадной анимацией
  Widget _buildAnimatedEventCard(ScheduleEvent event, int index) {
    return AnimatedOpacity(
      opacity: _expanded ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _expanded ? Offset.zero : const Offset(0, 0.1),
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(
                  context,
                  icon: CupertinoIcons.location,
                  text: event.location,
                  iconSize: 14,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  context,
                  icon: CupertinoIcons.person,
                  text: event.educator,
                  iconSize: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Определяем цвет для статуса группы
    Color statusColor = _getStatusColor(context, widget.statusIndicator);

    // Если карточка активна, используем другой цвет фона
    Color backgroundColor = widget.isActive
        ? colorScheme.primary.withOpacity(0.1)
        : theme.cardTheme.color ?? colorScheme.surface;

    if (widget.events.length == 1) {
      // Если только одно событие, отображаем его как IOSStyleLessonCard без группировки
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IOSStyleLessonCard(
          lesson: widget.events.first,
          isActive: widget.isActive, // Используем переданный параметр isActive
          statusIndicator: widget.statusIndicator,
        ),
      );
    } else {
      // Если несколько событий, отображаем как группу с возможностью раскрытия
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: _toggleExpanded,
          child: IOSStyleCard(
            backgroundColor: backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Индикатор статуса (маленькая полоса слева)
                    Container(
                      width: 3,
                      height:
                          20, // Уменьшена высота для соответствия новому размеру шрифта
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subject.split('_').first,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.events.first.startTime} - ${widget.events.first.endTime}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _iconTurn,
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  axisAlignment: 1.0,
                  sizeFactor: _expandAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      ...widget.events.map((event) {
                        int index = widget.events.indexOf(event);
                        return _buildAnimatedEventCard(event, index);
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  String _getLessonsText(int count) {
    if (count == 1) {
      return 'занятие';
    } else if (count >= 2 && count <= 4) {
      return 'занятия';
    } else {
      return 'занятий';
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    double iconSize = 16,
    TextStyle? textStyle,
  }) {
    final theme = Theme.of(context);
    final effectiveTextStyle = textStyle ?? theme.textTheme.bodyMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: theme.colorScheme.primary.withOpacity(0.8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: effectiveTextStyle,
            softWrap: true,
            maxLines: null,
          ),
        ),
      ],
    );
  }
}
