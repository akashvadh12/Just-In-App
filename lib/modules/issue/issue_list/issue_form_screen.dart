import 'package:flutter/material.dart';
import 'package:security_guard/modules/issue/issue_list/issue_model/issue_modl.dart';
import 'package:uuid/uuid.dart';

class IssueFormScreen extends StatefulWidget {
  const IssueFormScreen({super.key});

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}


class _IssueFormScreenState extends State<IssueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  void _submitIssue() {
    if (_formKey.currentState!.validate()) {
      final newIssue = Issue(
        id: const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        time: 'Now',
        status: IssueStatus.new_issue,
        imageUrl: 'https://via.placeholder.com/150',
      );
      Navigator.pop(context, newIssue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Issue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value!.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitIssue,
                child: const Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
