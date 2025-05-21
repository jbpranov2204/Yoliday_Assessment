import 'package:flutter/material.dart';
import 'package:llm_postgres/Components/drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DesktopPage extends StatefulWidget {
  DesktopPage({super.key});

  @override
  _DesktopPageState createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  String? fileContent;
  String? codeReviewOutput;
  String? casualResponse;
  String? formalResponse;
  bool isTyping = false;
  final List<String> prompt = ["Casual and Creative", "Formal and Analytical"];
  final TextEditingController _textController = TextEditingController();

  // Track selected prompts by index
  final Set<int> _selectedPrompts = {};

  // Add Gemini API configuration
  final String _geminiApiKey = 'AIzaSyDJpW9h_UIh7xYPOnki-2GAY0mLn6xGcWQ';
  final String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-lite:generateContent';

  // Replace _callPromptApi with Gemini implementation
  Future<void> _callPromptApi() async {
    if (_textController.text.trim().isEmpty || _selectedPrompts.isEmpty) return;

    setState(() {
      isTyping = true;
      casualResponse = null;
      formalResponse = null;
    });

    try {
      String userQuery = _textController.text.trim();
      String promptStyle = prompt[_selectedPrompts.first];

      print('Sending request to Gemini API...');
      print('Query: $userQuery');
      print('Style: $promptStyle');

      // Prepare Gemini request body
      final geminiBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    promptStyle == "Casual and Creative"
                        ? "Respond in a casual and creative way to this query: $userQuery. Be friendly and use simple language."
                        : "Provide a formal and analytical response to this query: $userQuery. Use professional language and structured analysis.",
              },
            ],
          },
        ],
      };

      print('Request body: ${jsonEncode(geminiBody)}');

      final geminiResponse = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_geminiApiKey',
        },
        body: jsonEncode(geminiBody),
      );

      print('Response status: ${geminiResponse.statusCode}');
      print('Response body: ${geminiResponse.body}');

      if (geminiResponse.statusCode == 200) {
        final geminiData = jsonDecode(geminiResponse.body);
        String generatedText =
            geminiData['candidates'][0]['content']['parts'][0]['text'];

        // Send to backend for storage
        final backendResponse = await http.post(
          Uri.parse('http://localhost:8000/prompt'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': 'user123',
            'query': userQuery,
            'casual_response':
                promptStyle == "Casual and Creative" ? generatedText : "",
            'formal_response':
                promptStyle == "Formal and Analytical" ? generatedText : "",
          }),
        );

        if (backendResponse.statusCode == 200) {
          setState(() {
            if (promptStyle == "Casual and Creative") {
              casualResponse = generatedText;
            } else {
              formalResponse = generatedText;
            }
          });
        }
      } else {
        throw Exception(
          'Failed to get response: ${geminiResponse.statusCode} ${geminiResponse.body}',
        );
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      setState(() {
        casualResponse = 'Error: $e';
        formalResponse = 'Failed to get response from AI';
      });
    } finally {
      setState(() {
        isTyping = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          ResponsiveDrawer(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 200),
                  Center(
                    child: SizedBox(
                      height: 400,
                      width: 500,
                      child: Scrollbar(
                        child:
                            fileContent == null
                                ? GridView.builder(
                                  padding: const EdgeInsets.all(10.0),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 2.5,
                                      ),
                                  itemCount: prompt.length,
                                  itemBuilder: (context, index) {
                                    final selected = prompt[index];
                                    final isSelected = _selectedPrompts
                                        .contains(index);
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedPrompts.remove(index);
                                          } else {
                                            _selectedPrompts.add(index);
                                          }
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? Colors.blue.shade700
                                                  : Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Colors.blue,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            selected,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : SingleChildScrollView(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      fileContent!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ),
                  ),
                  if (_selectedPrompts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10.0,
                        left: 50,
                        right: 50,
                      ),
                      child: Wrap(
                        spacing: 8,
                        children:
                            _selectedPrompts.map((index) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  prompt[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50.0,
                      vertical: 15,
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Enter your text here',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon:
                              isTyping
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue,
                                    ),
                                  )
                                  : const Icon(Icons.send, color: Colors.blue),
                          onPressed:
                              isTyping || _textController.text.trim().isEmpty
                                  ? null
                                  : _callPromptApi, // Change this line
                          tooltip: 'Send',
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          codeReviewOutput = null;
                          casualResponse = null;
                          formalResponse = null;
                        });
                      },
                      onSubmitted: (_) {
                        if (!isTyping &&
                            _textController.text.trim().isNotEmpty) {
                          _callPromptApi(); // Change this line
                        }
                      },
                    ),
                  ),
                  // Show both responses
                  if (casualResponse != null || formalResponse != null)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (casualResponse != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Casual/Creative:\n$casualResponse",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          if (formalResponse != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Formal/Analytical:\n$formalResponse",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
