import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/calendar_controller.dart';
import '../data/models/task_model.dart';

class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final selectedTasks = controller.tasksForDay(
          controller.selectedDay.value,
        );

        return Column(
          children: [
            TableCalendar<Task>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: controller.focusedDay.value,
              selectedDayPredicate:
                  (day) => isSameDay(day, controller.selectedDay.value),
              eventLoader: controller.tasksForDay,
              onDaySelected: (selected, focused) {
                controller.selectedDay.value = selected;
                controller.focusedDay.value = focused;
              },
              onPageChanged: (focused) => controller.focusedDay.value = focused,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final events = controller.tasksForDay(day);
                  return DragTarget<Task>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails:
                        (details) => controller.moveTask(details.data, day),
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color:
                              events.isNotEmpty
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1)
                                  : null,
                        ),
                        child: Center(child: Text('${day.day}')),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Long-press and drag tasks to another day',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  selectedTasks.isEmpty
                      ? const Center(child: Text('No tasks for selected date'))
                      : ListView.builder(
                        itemCount: selectedTasks.length,
                        itemBuilder: (context, index) {
                          final task = selectedTasks[index];
                          return LongPressDraggable<Task>(
                            data: task,
                            feedback: Material(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 250,
                                ),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Text(task.title),
                                  ),
                                ),
                              ),
                            ),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(task.title),
                                subtitle: Text(task.category),
                                trailing: Icon(
                                  task.isCompleted
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color:
                                      task.isCompleted
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        );
      }),
    );
  }
}
