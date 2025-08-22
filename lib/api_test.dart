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
enum Endpoint {
  all,
  hhtlogin,
  hhtitems,
  hhtbarcodes,
  hhtlocations,
  hhtturncodes,
}

Endpoint _selected = Endpoint.values.first;

extension EndpointLabel on Endpoint {
  String get label {
    switch (this) {
      case Endpoint.all:
        return 'All Master Data';
      case Endpoint.hhtlogin:
        return 'Login';
      case Endpoint.hhtitems:
        return 'Item';
      case Endpoint.hhtbarcodes:
        return 'Barcode';
      case Endpoint.hhtlocations:
        return 'Location';
      case Endpoint.hhtturncodes:
        return 'Turn Code';
    }
  }
}

class _ApiTestPageState extends State<ApiTestPage> {
  final _scroll = ScrollController();
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: const {
        'Accept': 'application/json',
        //change to config later
        'Authorization': 'Basic YXBpOiR6UV4kMDcyYmY3Rg==',
      },
      validateStatus: (_) => true,
    ),
  );
  String statusCode = "";
  int pageCount = 0;
  // String responseBody = "Response Body";
  // NOT shown, never force Flutter to lay out megabytes of text, or else it will crash
  String responseBodyFull = "";
  String responseBodyPreview = ''; // Shown in the scroll box
  static const int kPreviewCap = 40000; // ~40k chars is safe for UI
  final bool _loading = false;
  String elapsed = "00:00.000"; //performance measure

  @override
  void initState() {
    super.initState();
    _selected = Endpoint.values.first; // reset every time page is created
  }

  // Example of using it (e.g., inside your button handler)
  Future<void> onCallPressed() async {
    resetResult();
    final results = await selectEndPointAsync(dio);
    updateResult(results);
  }

  // Call ALL endpoints concurrently
  Future<List<Map<String, dynamic>>> selectEndPointAsync(Dio dio) async {
    //select endpoints based on the dropdown selection
    // If "all" is selected, call all endpoints
    List endpoints = <Endpoint>[];
    switch (_selected) {
      case Endpoint.all:
        endpoints = [
          // Endpoint.hhtlogin,  //login not for master data
          Endpoint.hhtitems,
          Endpoint.hhtbarcodes,
          Endpoint.hhtlocations,
          Endpoint.hhtturncodes,
        ];
      default:
        endpoints = [_selected];
    }

    //for each endpoint on list, call the API and return a list of results
    final futures = endpoints
        .map((endpoint) => _callEndPoint(dio, endpoint))
        .toList();
    return await Future.wait(futures);
  }

  // Call a single endpoint and return the result
  Future<Map<String, dynamic>> _callEndPoint(Dio dio, Endpoint ep) async {
    final sw = Stopwatch()..start(); // mark start
    int page = 0;
    String status = '--';
    try {
      //Build URI
      final firstUrl = _bcUri(ep, qp: _defaultQuery(ep));
      String? url = firstUrl.toString();
      // while (url != null && pageCount <= 5) {
      while (url != null) {
        //fetchAllPages
        // Make API call ****🚀
        final response = await dio.get(
          url,
          options: Options(
            headers: {
              //change to config later
              'Company': 'CDN',
              //change to config later
              'Prefer': 'odata.maxpagesize=5000',
            },
          ),
        );
        page++;
        final data = response.data as Map<String, dynamic>;

        // Get nextLink if exists
        url = data['@odata.nextLink'] as String?;

        //*******aysnc insert to database here if needed  ******

        //only keep preview of the last page
        if (url == null) {
          status = response.statusCode.toString();
          if (_selected != Endpoint.all) {
            responseBodyFull = _prettyJson(
              response.data,
            ); // keep full, off-screen
          }
        }
      }

      sw.stop();

      return {
        'endpoint': ep.name,
        'status': status,
        'duration': fmtMinSecMs(sw.elapsed),
        'page': page,
        'data': responseBodyFull, // keep full data for debugging
      };
    } catch (e) {
      sw.stop();
      return {
        'endpoint': ep.name,
        'status': 'ERR',
        'duration': fmtMinSecMs(sw.elapsed),
        'error': e.toString(),
      };
    }
  }

  final endpoint = _selected.name;
  // final fqdn = "bc.cosme.work"; //change to config later
  // final port = "7078"; //change to config later
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
        return {
          r'$select': //only return needed fields, this can make payload much smaller and faster
              'number,whCode,description,net,color,brand,itemCateCode,itemSubCate1,itemSubCate2,lastModifyDateTime',
        };
      case Endpoint.hhtbarcodes:
        return {
          r'$select': //only return needed fields, this can make payload much smaller and faster
              'number,barcode,lastModifyDateTime',
        };
      case Endpoint.hhtlocations:
        return {};
      case Endpoint.hhtturncodes:
        return {};
      case Endpoint.all:
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

  String fmtMinSecMs(Duration d) {
    final minutes = d.inMinutes; // total minutes
    final seconds = d.inSeconds % 60; // 0–59
    final millis = d.inMilliseconds % 1000; // 0–999
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(3, '0')}';
  }

  void resetResult() {
    if (!mounted) return;
    setState(() {
      statusCode = '--';
      pageCount = 0;
      responseBodyPreview = '';
      elapsed = "00:00.000";
    });
  }

  void updateResult(List<Map<String, dynamic>> results) {
    if (!mounted) return;
    String body = '';
    if (_selected == Endpoint.all) {
      body = results
          .map(
            (r) =>
                '• ${r['endpoint']} -${r['status']} | ${r['page']} | ${r['duration']}',
          )
          .join('\n');
      setState(() {
        responseBodyPreview = body;
      });
    } else {
      final r = results.first; // only one result
      setState(() {
        statusCode = r['status'];
        responseBodyPreview = _toPreview(r['data']);
        elapsed = r['duration'];
        pageCount = r['page'] is int ? r['page'] as int : 0;
      });
    }
  }

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
                    onPressed: _loading ? null : () => onCallPressed(),
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
            const SizedBox(height: 10),
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
                ' Duration: $elapsed',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
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
                'Page Count:  $pageCount',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
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
