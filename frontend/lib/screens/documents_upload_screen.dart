import 'package:flutter/material.dart';

class DocumentsUploadScreen extends StatelessWidget {
  final String declarationId;
  final List<dynamic> documents;

  const DocumentsUploadScreen({
    Key? key,
    required this.declarationId,
    required this.documents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Declaration ID: $declarationId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Document ${index + 1}'),
                    subtitle: Text(documents[index].toString()),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle document upload logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Documents uploaded successfully!')),
                );
              },
              child: const Text('Upload Documents'),
            ),
          ],
        ),
      ),
    );
  }
}