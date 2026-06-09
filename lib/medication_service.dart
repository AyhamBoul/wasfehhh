import 'dart:convert';
import 'package:http/http.dart' as http;

class InteractionResult {
  final bool found;
  final String drug1;
  final String drug2;
  final String severity; // "none" | "minor" | "moderate" | "major"
  final String description;

  const InteractionResult({
    required this.found,
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
  });

  factory InteractionResult.fromJson(Map<String, dynamic> j) =>
      InteractionResult(
        found: j['found'] as bool,
        drug1: j['drug1'] as String,
        drug2: j['drug2'] as String,
        severity: (j['severity'] as String).toLowerCase(),
        description: j['description'] as String,
      );
}

class MedicationService {
  MedicationService._();
  static final MedicationService instance = MedicationService._();

  // Update this once the API is deployed
  static const _base = 'https://wasfeh.up.railway.app';

  static const _timeout = Duration(seconds: 6);

  Future<List<String>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final uri = Uri.parse('$_base/search')
          .replace(queryParameters: {'q': q, 'limit': '10'});
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return List<String>.from(body['results'] as List);
    } catch (_) {
      return [];
    }
  }

  // Checks every pair in a list and returns all interactions found
  Future<List<InteractionResult>> checkAll(List<String> drugs) async {
    final results = <InteractionResult>[];
    final names = drugs.map((d) => d.trim().toLowerCase()).toList();

    for (int i = 0; i < names.length; i++) {
      for (int j = i + 1; j < names.length; j++) {
        final result = await _checkPair(names[i], names[j]);
        if (result != null && result.found) results.add(result);
      }
    }
    return results;
  }

  Future<InteractionResult?> _checkPair(String d1, String d2) async {
    try {
      final uri = Uri.parse('$_base/check')
          .replace(queryParameters: {'drug1': d1, 'drug2': d2});
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      return InteractionResult.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
