import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core (Shared logic, themes, constants)/api_config.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _predictions = [];

  Future<void> _fetchPredictions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/predict/all-baskets');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Backend error ${response.statusCode}: ${response.body}');
      }

      final body = jsonDecode(response.body);
      final List predictions = body['predictions'] ?? [];
      _predictions = predictions.cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Predictions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'API: ${ApiConfig.baseUrl}/predict/all-baskets',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchPredictions,
              child: Text(_isLoading ? 'Loading...' : 'Load Predictions'),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: _predictions.isEmpty
                  ? const Center(child: Text('No predictions loaded yet.'))
                  : ListView.builder(
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final p = _predictions[index];
                        final risk = p['risk_label'] ?? 'Unknown';
                        final stage = p['spoil_stage'];
                        final hours = p['hours_left'];
                        final basket = p['basket_id'];
                        final device = p['device_id'];

                        Color riskColor = AppColors.accentGreen;
                        if (risk.toString().toLowerCase() == 'spoiled') {
                          riskColor = Colors.redAccent;
                        } else if (risk.toString().toLowerCase() == 'warning') {
                          riskColor = Colors.orangeAccent;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text('Basket $basket ($device)'),
                            subtitle: Text('Stage: $stage, Hours: ${hours?.toStringAsFixed(1) ?? '-'}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                risk,
                                style: TextStyle(color: riskColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
