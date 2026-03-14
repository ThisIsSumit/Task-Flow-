import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/models/task_model.dart';

void main() {
  group('Task model', () {
    test('copyWith updates selected fields and keeps others', () {
      final original = Task(
        id: '1',
        title: 'Write tests',
        description: 'Add task model test',
        category: 'Work',
        priority: 2,
        dueDate: DateTime(2026, 3, 10),
        isCompleted: false,
        createdAt: DateTime(2026, 3, 1),
        userId: 'user-1',
      );

      final updated = original.copyWith(
        title: 'Write better tests',
        isCompleted: true,
        recurrence: RecurrenceType.weekly,
      );

      expect(updated.id, original.id);
      expect(updated.title, 'Write better tests');
      expect(updated.isCompleted, isTrue);
      expect(updated.category, 'Work');
      expect(updated.recurrence, RecurrenceType.weekly);
    });

    test('fromMap parses DateTime/string fields and nested lists', () {
      final dueDate = DateTime(2026, 3, 15);
      final createdAt = DateTime(2026, 3, 5);
      final reminderAt = DateTime(2026, 3, 14, 9, 0);

      final map = {
        'id': 'task-10',
        'title': 'Plan sprint',
        'description': 'Plan with team',
        'category': 'Team',
        'priority': 1,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': false,
        'createdAt': createdAt,
        'userId': 'user-1',
        'notes': 'Bring reports',
        'reminderEnabled': true,
        'reminderAt': reminderAt.toIso8601String(),
        'recurrence': 'monthly',
        'subtasks': [
          {'id': 's1', 'title': 'Draft agenda', 'isDone': true},
        ],
        'attachments': [
          {
            'id': 'a1',
            'label': 'Doc',
            'url': 'https://example.com/doc',
            'type': 'link',
          },
        ],
      };

      final task = Task.fromMap(map);

      expect(task.id, 'task-10');
      expect(task.notes, 'Bring reports');
      expect(task.recurrence, RecurrenceType.monthly);
      expect(task.reminderEnabled, isTrue);
      expect(task.reminderAt, reminderAt);
      expect(task.subtasks, hasLength(1));
      expect(task.subtasks.first.isDone, isTrue);
     
    });

    test('toMap writes recurrence and nested collections', () {
      final task = Task(
        id: 'task-1',
        title: 'Task',
        description: 'Desc',
        category: 'General',
        priority: 3,
        dueDate: DateTime(2026, 3, 30),
        isCompleted: false,
        createdAt: DateTime(2026, 3, 1),
        userId: 'u1',
        recurrence: RecurrenceType.daily,
        subtasks: [SubTask(id: 's1', title: 'Sub')],
       
      );

      final map = task.toMap();

      expect(map['recurrence'], 'daily');
      expect((map['subtasks'] as List).length, 1);
      expect((map['attachments'] as List).length, 1);
    });
  });
}
