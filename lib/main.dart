import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'タスク管理アプリ',
      home: TaskManagerHomePage(),
    );
  }
}

class TodoItem {
  String task;
  DateTime deadline;
  bool isDone;

  TodoItem(this.task, this.deadline, {this.isDone = false});

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      json['task'] ?? '', // null チェックを追加
      DateTime.parse(
          json['deadline'] ?? DateTime.now().toIso8601String()), // null チェックを追加
      isDone: json['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'deadline': deadline.toIso8601String(),
      'isDone': isDone
    };
  }
}

class TaskManagerHomePage extends StatefulWidget {
  @override
  _TaskManagerHomePageState createState() => _TaskManagerHomePageState();
}

class _TaskManagerHomePageState extends State<TaskManagerHomePage> {
  List<TodoItem> _tasks = [];
  final myFormat = DateFormat('yyyy年MM月dd日');

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String> taskStrings = prefs.getStringList('tasks') ?? [];
      _tasks = taskStrings.map((taskString) {
        Map<String, dynamic> taskJson = jsonDecode(taskString);
        return TodoItem.fromJson(taskJson);
      }).toList();
    });
  }

  void _displayAddTaskDialog(BuildContext context) {
    TextEditingController taskController = TextEditingController();
    DateTime _selectedDeadline = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新しいタスクを追加'),
          // content: TextField(
          //   controller: taskController,
          //   decoration: InputDecoration(hintText: 'タスク名'),
          // ),
          content: Column(
            //Columnの長さを最小化する
            mainAxisSize: MainAxisSize.min,
            children: [
              // タスク名を設定
              TextField(
                controller: taskController,
                decoration: InputDecoration(hintText: 'タスク名'),
              ),
              SizedBox(height: 20),
              // 締め切り日を設定
              ListTile(
                title: Text('締切'),
                subtitle:
                    Text('${myFormat.format(_selectedDeadline.toLocal())}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  // 締め切り日をカレンダーから選択
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    // 締め切り日の初期値
                    initialDate: _selectedDeadline.toLocal(),
                    // 締切日に指定できるのは2024年〜2100年
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDeadline = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('追加'),
              onPressed: () {
                setState(() {
                  _tasks.add(TodoItem(taskController.text, _selectedDeadline));
                  _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                  _saveTasks();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('タスクを削除しますか？'),
          content: Text('タスク「${_tasks[index].task}」を削除してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('削除'),
              onPressed: () {
                setState(() {
                  _tasks.removeAt(index);
                  _saveTasks();
                });
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, int index) {
    TextEditingController taskController =
        TextEditingController(text: _tasks[index].task);
    DateTime _selectedDeadline = _tasks[index].deadline;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('タスクを編集'),
          // content: TextField(
          //   controller: taskController,
          //   decoration: InputDecoration(hintText: 'タスク名'),
          // ),
          content: Column(
            //Columnの長さを最小化する
            mainAxisSize: MainAxisSize.min,
            children: [
              // タスク名を設定
              TextField(
                controller: taskController,
                decoration: InputDecoration(labelText: 'タスク名'),
              ),
              SizedBox(height: 20),
              // 締め切り日を設定
              ListTile(
                title: Text('締切'),
                subtitle:
                    Text('${myFormat.format(_selectedDeadline.toLocal())}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  // 締め切り日をカレンダーから選択
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    // 締め切り日の初期値
                    initialDate: _selectedDeadline,
                    // 締切日に指定できるのは2024年〜2100年
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDeadline = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('保存'),
              onPressed: () {
                setState(() {
                  _tasks[index] =
                      TodoItem(taskController.text, _selectedDeadline);
                  _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                  _saveTasks();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings =
        _tasks.map((task) => jsonEncode(task.toJson())).toList();
    prefs.setStringList('tasks', taskStrings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タスク管理アプリ'),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
              leading: Checkbox(
                value: _tasks[index].isDone,
                onChanged: (bool? value) {
                  setState(() {
                    _tasks[index].isDone = !_tasks[index].isDone;
                    if (_tasks[index].isDone) {
                      // タスクをリストの一番下に移動
                      final doneTask = _tasks.removeAt(index);
                      _tasks.add(doneTask);
                    } else {
                      // タスクを作成日時の昇順に並べ替え
                      _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
                      // 完了済みのタスクをリストの一番下に移動
                      _tasks.sort((a, b) => a.isDone ? 1 : -1);
                    }
                    _saveTasks();
                  });
                },
              ),
              title: Text(_tasks[index].task),
              subtitle: Text(myFormat.format(_tasks[index].deadline)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _showEditTaskDialog(context, index);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _showDeleteConfirmationDialog(context, index);
                    },
                  ),
                ],
              ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _displayAddTaskDialog(context);
        },
        child: Icon(Icons.add),
        tooltip: 'タスクを追加',
      ),
    );
  }
}
