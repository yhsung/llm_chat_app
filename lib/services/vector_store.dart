import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'llm_service.dart';

class DocumentChunk {
  final String id;
  final String text;
  final List<double> embedding;

  DocumentChunk({
    required this.id,
    required this.text,
    required this.embedding,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'embedding': embedding,
  };

  factory DocumentChunk.fromJson(Map<String, dynamic> json) {
    return DocumentChunk(
      id: json['id'],
      text: json['text'],
      embedding: (json['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class VectorStore {
  VectorStore._internal();
  static final VectorStore instance = VectorStore._internal();

  final Map<String, DocumentChunk> _chunks = {};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/doc_index.json');
    if (await file.exists()) {
      final data = jsonDecode(await file.readAsString());
      for (final item in data) {
        final chunk = DocumentChunk.fromJson(item);
        _chunks[chunk.id] = chunk;
      }
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/doc_index.json');
    await file.writeAsString(
      jsonEncode(_chunks.values.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> upsertDocument(
    String text,
    LlmService llmService, {
    int chunkSize = 1000,
  }) async {
    await _load();
    final chunks = _splitIntoChunks(text, chunkSize);
    for (final chunk in chunks) {
      final id = _fingerprint(chunk);
      if (!_chunks.containsKey(id)) {
        final embedding = await llmService.embedText(chunk);
        _chunks[id] = DocumentChunk(id: id, text: chunk, embedding: embedding);
      }
    }
    await _save();
  }

  Future<List<String>> search(
    String query,
    LlmService llmService, {
    int topK = 3,
  }) async {
    await _load();
    if (_chunks.isEmpty) return [];
    final queryEmbedding = await llmService.embedText(query);
    final scores = <DocumentChunk, double>{};
    for (final chunk in _chunks.values) {
      final score = _cosineSimilarity(queryEmbedding, chunk.embedding);
      scores[chunk] = score;
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topK).map((e) => e.key.text).toList();
  }

  List<String> _splitIntoChunks(String text, int size) {
    final regex = RegExp('.{1,$size}', dotAll: true);
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  String _fingerprint(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    double normA = 0;
    double normB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
}
