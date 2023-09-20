import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// provider --------------------------------

/// 全todo
final todosProvider = StateNotifierProvider<TodosNotifier, List<Todo>>((ref) {
  return TodosNotifier();
});

/// 完了済みtodo
final completedTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todosProvider);

  return todos.where((todo) => todo.isCompleted).toList();
});

// model --------------------------------

/// todoモデル
class Todo {
  Todo(this.id, this.description, this.isCompleted);
  final int id;
  final bool isCompleted;
  final String description;

  Todo copyWith(int id, String description, bool isCompleted) {
    return Todo(id, description, isCompleted);
  }
}

// StateNotifier --------------------------------

/// todo通知用
class TodosNotifier extends StateNotifier<List<Todo>> {
  TodosNotifier() : super([]);

  /// 追加
  void addTodo(String description) {
    int maxId = 0;

    for (Todo todo in state) {
      if (todo.id > maxId) {
        maxId = todo.id;
      }
    }

    final newTodo = Todo(maxId + 1, description, false);
    state = [...state, newTodo];
  }

  /// 完了状態を更新
  void toggle(int todoId) {
    state = [
      for (Todo todo in state)
        todo.id == todoId
            ? todo.copyWith(todo.id, todo.description, !todo.isCompleted)
            : todo
    ];
  }
}

// view --------------------------------

void main() {
  runApp(
    // アプリをラップしてproviderを伝播させる
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/": (context) => const TodoListPage(),
        "/create": (context) => const TodoCreatePage()
      },
    );
  }
}

/// todo一覧ページ
class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  bool isFiltered = false;

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todosProvider);
    final completedTodos = ref.watch(completedTodosProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/create");
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: Center(
          child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            // height: 80,
            width: double.infinity,
            child: Row(children: [
              Row(children: [
                Checkbox(
                    value: isFiltered,
                    onChanged: (value) {
                      setState(() {
                        isFiltered = value!;
                      });
                    }),
                const Text("completed only"),
              ])
            ]),
          ),
          isFiltered
              ? Expanded(
                  child: ListView.builder(
                      itemCount: completedTodos.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: CheckboxListTile(
                            title: Text(completedTodos[index].description),
                            value: completedTodos[index].isCompleted,
                            onChanged: (value) {
                              ref
                                  .read(todosProvider.notifier)
                                  .toggle(todos[index].id);
                            },
                          ),
                        );
                      }),
                )
              : Expanded(
                  child: ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: CheckboxListTile(
                            title: Text(todos[index].description),
                            value: todos[index].isCompleted,
                            onChanged: (value) {
                              ref
                                  .read(todosProvider.notifier)
                                  .toggle(todos[index].id);
                            },
                          ),
                        );
                      }),
                ),
        ],
      )),
    );
  }
}

/// todo作成ページ
class TodoCreatePage extends ConsumerStatefulWidget {
  const TodoCreatePage({super.key});

  @override
  ConsumerState<TodoCreatePage> createState() => _CreateTodoState();
}

class _CreateTodoState extends ConsumerState<TodoCreatePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Todo"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Description"),
                TextField(
                  controller: _controller,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
              const SizedBox(
                width: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      ref
                          .read(todosProvider.notifier)
                          .addTodo(_controller.text);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text("Create")),
            ],
          )
        ],
      ),
    );
  }
}
