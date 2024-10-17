import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isDone;

  TodoItem(this.task, {this.isDone = false});

  // JSON 形式に変換するメソッド
  Map<String, dynamic> toJson() => {
        'task': task,
        'isDone': isDone,
      };

  // JSON 形式から TodoItem に変換するファクトリコンストラクタ
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      json['task'] as String,
      isDone: json['isDone'] as bool,
    );
  }
}

class TaskManagerHomePage extends StatefulWidget {
  @override
  _TaskManagerHomePageState createState() => _TaskManagerHomePageState();
}

class _TaskManagerHomePageState extends State<TaskManagerHomePage> {
  List<TodoItem> _tasks = [];

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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新しいタスクを追加'),
          content: TextField(
            controller: taskController,
            decoration: InputDecoration(hintText: 'タスク名'),
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
                  _tasks.add(TodoItem(taskController.text));
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('タスクを編集'),
          content: TextField(
            controller: taskController,
            decoration: InputDecoration(hintText: 'タスク名'),
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
                  _tasks[index] = TodoItem(taskController.text);
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
                    _tasks[index].isDone = value ?? false;
                    if (_tasks[index].isDone) {
                      // タスクをリストの一番下に移動
                      final doneTask = _tasks.removeAt(index);
                      _tasks.add(doneTask);
                    }
                    _saveTasks();
                  });
                },
              ),
              title: Text(_tasks[index].task),
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
