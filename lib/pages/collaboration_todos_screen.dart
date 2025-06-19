import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/model/collaboration_todo_model.dart';
import 'package:four_secrets_wedding_app/services/collaboration_todo_service.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborationTodosScreen extends StatefulWidget {
  const CollaborationTodosScreen({super.key});

  @override
  State<CollaborationTodosScreen> createState() =>
      _CollaborationTodosScreenState();
}

class _CollaborationTodosScreenState extends State<CollaborationTodosScreen> {
  final CollaborationTodoService _collaborationTodoService =
      CollaborationTodoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration Todos'),
        backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('collaboration_todos')
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No collaboration todos found'));
          }
          final todos = docs
              .map<CollaborationTodoModel>(
                  (doc) => CollaborationTodoModel.fromFirestore(doc))
              .toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    todo.todoName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Owner: ${todo.ownerName}\nCollaborators: ${todo.collaborators.length}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Todo Items:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SpacerWidget(height: 8),
                          ...todo.toDoItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item['isChecked'] ?? false,
                                      onChanged: (bool? value) async {
                                        await _collaborationTodoService
                                            .updateTodoItems(
                                          todo.id,
                                          todo.toDoItems
                                              .map((item) => {
                                                    'name':
                                                        item['name'] as String,
                                                    'isChecked': value ?? false,
                                                  })
                                              .toList(),
                                        );
                                      },
                                      activeColor: const Color.fromARGB(
                                          255, 107, 69, 106),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(item['name']),
                                    ),
                                  ],
                                ),
                              )),
                          SpacerWidget(height: 16),
                          const Text(
                            'Comments:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SpacerWidget(height: 8),
                          ...todo.comments.map((comment) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${comment['userName']}:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(comment['comment']),
                                  ],
                                ),
                              )),
                          SpacerWidget(height: 16),
                          ElevatedButton(
                            onPressed: () => _addComment(todo.id),
                            child: const Text('Add Comment'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addComment(String todoId) async {
    final TextEditingController commentController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Enter your comment',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (commentController.text.trim().isNotEmpty) {
                try {
                  await _collaborationTodoService.addComment(
                    todoId,
                    commentController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    SnackBarHelper.showSuccessSnackBar(
                      context,
                      'Comment added successfully',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    SnackBarHelper.showErrorSnackBar(
                      context,
                      'Error adding comment: $e',
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
