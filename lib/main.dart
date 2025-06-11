import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const QuestionPaperGeneratorApp());
}

class QuestionPaperGeneratorApp extends StatelessWidget {
  const QuestionPaperGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Question Paper Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const QuestionPaperHomePage(),
    );
  }
}

class QuestionPaperHomePage extends StatefulWidget {
  const QuestionPaperHomePage({super.key});

  @override
  State<QuestionPaperHomePage> createState() => _QuestionPaperHomePageState();
}

class _QuestionPaperHomePageState extends State<QuestionPaperHomePage> {
  final TextEditingController _topicController = TextEditingController();
  List<String> _generatedQuestions = [];
  bool _isLoading = false;

  // Google Custom Search API credentials
  final String apiKey = 'AIzaSyAGXHoQhq5Vx0rDTbTuq0sjsztJdgI1E4o.'; // Replace with your Google API key
  final String searchEngineId = 'f2cd078a4a1e343c5'; // Your provided CSE ID

  // Function to fetch search results and generate questions
  Future<void> _generateQuestions(String topic) async {
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedQuestions = [];
    });

    try {
      // Make API call to Google Custom Search
      final String url =
          'https://www.googleapis.com/customsearch/v1?key=$apiKey&cx=$searchEngineId&q=${Uri.encodeQueryComponent(topic)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];

        // Generate questions from search result snippets
        List<String> questions = [];
        for (var item in items.take(5)) { // Limit to first 5 results
          String snippet = item['snippet'] ?? '';
          String title = item['title'] ?? '';
          // Simple question generation
          if (snippet.isNotEmpty) {
            questions.add('What is $title?');
            questions.add('How does $topic relate to "${snippet.substring(0, snippet.length > 50 ? 50 : snippet.length)}..."?');
          }
        }

        setState(() {
          _generatedQuestions = questions;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch search results: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Paper Generator'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Enter Topic to Search',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                hintText: 'e.g., Artificial Intelligence',
              ),
              onSubmitted: (value) => _generateQuestions(value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _generateQuestions(_topicController.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Questions'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Generated Questions:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _generatedQuestions.isEmpty
                  ? const Center(
                child: Text(
                  'Enter a topic and press "Generate Questions" to see results.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _generatedQuestions.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Text(
                        '${index + 1}.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      title: Text(_generatedQuestions[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }
}