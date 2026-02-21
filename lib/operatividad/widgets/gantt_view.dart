import 'package:flutter/material.dart';
import '../models/oper_activity.dart';

class GanttView extends StatelessWidget {
  final List<OperActivity> activities;
  final void Function(OperActivity) onTapActivity;

  const GanttView({
    super.key,
    required this.activities,
    required this.onTapActivity,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(child: Text('No hay actividades para mostrar.'));
    }

    final minStart = activities
        .map((a) => a.plannedStartAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final maxEnd = activities
        .map((a) => a.plannedEndAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final totalDays = maxEnd.difference(minStart).inDays + 1;
    final dayWidth = 34.0; // ancho de cada día en la timeline
    final timelineWidth = totalDays * dayWidth;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Columna fija (títulos)
            SizedBox(
              width: 220,
              child: ListView.builder(
                itemCount: activities.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Actividad',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );
                  }
                  final a = activities[i - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),

            const VerticalDivider(width: 1),

            // Timeline scrollable
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: timelineWidth.clamp(400, double.infinity),
                  child: Column(
                    children: [
                      _TimelineHeader(
                        minStart: minStart,
                        totalDays: totalDays,
                        dayWidth: dayWidth,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: activities.length,
                          itemBuilder: (context, i) {
                            final a = activities[i];

                            final startOffsetDays = a.plannedStartAt
                                .difference(minStart)
                                .inDays;
                            final durationDays =
                                (a.plannedEndAt
                                            .difference(a.plannedStartAt)
                                            .inDays +
                                        1)
                                    .clamp(1, 3650);

                            final left = startOffsetDays * dayWidth;
                            final width = durationDays * dayWidth;

                            return SizedBox(
                              height: 44,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Row(
                                      children: List.generate(
                                        totalDays,
                                        (d) => Container(
                                          width: dayWidth,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: left,
                                    top: 10,
                                    width: width,
                                    height: 24,
                                    child: InkWell(
                                      onTap: () => onTapActivity(a),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: _statusColor(
                                            context,
                                            a.status,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '${a.progress}%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, OperStatus status) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      OperStatus.planned => cs.secondaryContainer,
      OperStatus.inProgress => Colors.orange.shade300,
      OperStatus.done => Colors.green.shade300,
      OperStatus.verified => Colors.teal.shade300,
      OperStatus.blocked => Colors.red.shade300,
    };
  }
}

class _TimelineHeader extends StatelessWidget {
  final DateTime minStart;
  final int totalDays;
  final double dayWidth;

  const _TimelineHeader({
    required this.minStart,
    required this.totalDays,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');

    return SizedBox(
      height: 44,
      child: Row(
        children: List.generate(totalDays, (i) {
          final d = DateTime(
            minStart.year,
            minStart.month,
            minStart.day,
          ).add(Duration(days: i));
          final label = '${two(d.day)}/${two(d.month)}';
          return Container(
            width: dayWidth,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }),
      ),
    );
  }
}
