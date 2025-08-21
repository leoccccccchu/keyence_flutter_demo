import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const ApiTestPage());
}

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

//Endpoint dropdown list
enum Endpoint { hhtlogin, hhtitems, hhtlocations }

Endpoint _selected = Endpoint.values.first;

extension EndpointLabel on Endpoint {
  String get label {
    switch (this) {
      // case Endpoint.jsonplaceholder:
      //   return 'jsonplaceholder';
      case Endpoint.hhtlogin:
        return 'hhtlogin';
      case Endpoint.hhtitems:
        return 'hhtitems';
      case Endpoint.hhtlocations:
        return 'hhtlocations';
    }
  }
}

class _ApiTestPageState extends State<ApiTestPage> {
  final _scroll = ScrollController();
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: const {'Accept': '*/*', 'User-Agent': 'BCApp/1.0 (Flutter Dio)'},
      validateStatus: (_) => true,
    ),
  );
  String statusCode = "";
  // String responseBody = "Response Body";
  // NOT shown, never force Flutter to lay out megabytes of text, or else it will crash
  String responseBodyFull = "";
  String responseBodyPreview = ''; // Shown in the scroll box
  static const int kPreviewCap = 40000; // ~40k chars is safe for UI
  final bool _loading = false;
  Duration elapsed = Duration.zero; //performance measure

  Future<void> _callSelected() async {
    try {
      setState(() {
        statusCode = '-';
        responseBodyFull = '';
        responseBodyPreview = '';
        elapsed = Duration.zero;
      });
      // mark start
      final sw = Stopwatch()..start();

      //Build URI
      final uri = _bcUri(_selected, qp: _defaultQuery(_selected));
      // Make API call
      final response = await dio.get(
        uri.toString(),
        options: Options(
          headers: {
            'Accept': 'application/json;odata.metadata=none',
            'Authorization': 'Basic YXBpOiR6UV4kMDcyYmY3Rg==',
          },
        ),
      );

      if (!mounted) return;
      sw.stop();

      setState(() {
        // // responseBody = _pretty("${response.data}");
        // responseBodyFull = "${response.data}";
        statusCode = "${response.statusCode}";
        responseBodyFull = _prettyJson(response.data); // keep full, off-screen
        responseBodyPreview = _toPreview(response.data); // render only preview
        elapsed = sw.elapsed;
      });
    } catch (e) {
      setState(() {
        statusCode = "Error: $e";
      });
    }
  }

  final endpoint = _selected.name;
  final fqdn = "bc-dev-ra.cosme.work"; //change to config later
  final port = "2053"; //change to config later
  Uri _bcUri(Endpoint e, {Map<String, String>? qp}) {
    return Uri(
      scheme: 'https',
      host: fqdn,
      port: int.parse(port),
      path:
          '/HHTAPI/api/CDN/HHT/v2.0/${e.name}', // <= hhtlogin / hhtitems / hhtlocations
      queryParameters: qp,
    );
  }

  Map<String, String>? _defaultQuery(Endpoint e) {
    switch (e) {
      case Endpoint.hhtlogin:
        return {
          r'$filter':
              "name eq 'ONECOM' and password eq '1234' and hhtId eq 'HHT001'", //change to config later
          r'$expand': 'hhtcompanies', //change to config later
        };
      case Endpoint.hhtitems:
        return {};
      case Endpoint.hhtlocations:
        return {};
    }
  }

  String _prettyJson(dynamic data) {
    try {
      final obj = (data is String) ? json.decode(data) : data;
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return data?.toString() ?? '';
    }
  }

  String _toPreview(dynamic data, {int cap = kPreviewCap}) {
    final s = _prettyJson(data);
    if (s.length <= cap) return s;
    return '${s.substring(0, cap)}\n…(truncated, ${s.length} chars total)';
  }

  String secs(Duration d, {int decimals = 2}) =>
      (d.inMilliseconds / 1000).toStringAsFixed(decimals); // "3.27"

  @override
  void dispose() {
    // Close HTTP client resources and clean up controllers/listeners if added later.
    // Dio supports close(); set force=true to terminate pending connections if any.
    dio.close(force: true);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Call Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Endpoint>(
                    initialValue: _selected,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: Endpoint.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.label)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selected = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _callSelected,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
                color: Theme.of(
                  context,
                  // ignore: deprecated_member_use
                ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
              child: Text(
                'Duration: ${secs(elapsed, decimals: 2)} s',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
                color: Theme.of(
                  context,
                  // ignore: deprecated_member_use
                ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
              child: Text(
                'Status Code:  $statusCode',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        responseBodyPreview.isEmpty
                            ? 'No response body yet'
                            : responseBodyPreview,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
