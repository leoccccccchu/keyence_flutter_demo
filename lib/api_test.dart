import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'package:dio_smart_retry/dio_smart_retry.dart';

void main() {
  runApp(const ApiTestPage());
}

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

//Common Endpoint for all companies
enum Commonendpoint {
  all, //call all master data realated endpoints
  hhtlogin,
}

//Endpoint for CDN
enum CDNendpoint { hhtitems, hhtbarcodes, hhtlocations, hhtturncodes }

//Endpoint for LL
enum LLendpoint { hhtitems, hhtbarcodes, hhtlocations }

// Simple wrapper so DropdownButton has one type
class EndpointOption {
  final String endpointLabel;
  final String endpointCompany;
  final String endpointValue; // holds enum value
  const EndpointOption(
    this.endpointLabel,
    this.endpointCompany,
    this.endpointValue,
  );

  get name => null;
}

// Build one flat list of all enum values
final options = [
  ...Commonendpoint.values.map(
    (e) => EndpointOption("Common: ${e.name}", '', e.name),
  ),
  ...CDNendpoint.values.map(
    (e) => EndpointOption("CDN: ${e.name}", 'CDN', e.name),
  ),
  ...LLendpoint.values.map(
    (e) => EndpointOption("LL: ${e.name}", 'LL', e.name),
  ),
];

EndpointOption? selected;

final username = 'api';
final password = r'$zQ^$072bf7F';
// final endpoint = selected?.name;
// final fqdn = "bc.cosme.work"; //change to config later
// final port = "7078"; //change to config later
// final fqdn = "bc-dev-ra.cosme.work"; //change to config later
// final port = "2053"; //change to config later
// final instance = "HHTAPI"; //change to config later
final fqdn = "bc-dev.cosme.work"; //change to config later
final port = "7058"; //change to config later
final instance = "BC240"; //change to config later
Dio buildDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json;odata.metadata=none',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
      // Let non-2xx pass so you can parse error bodies yourself
      validateStatus: (_) => true,
    ),
  );

  // Optional: quick logging (turn on as needed)
  dio.interceptors.add(
    LogInterceptor(
      request: false,
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
    ),
  );

  // Backoff with light jitter helper
  List<Duration> backoff({int retries = 3, int baseMs = 800}) {
    final rnd = Random();
    return List.generate(retries, (i) {
      final ms = baseMs * pow(2, i).toInt(); // 0:800ms, 1:1600ms, 2:3200ms
      final jitter = rnd.nextInt(250); // +0~250ms jitter
      return Duration(milliseconds: ms + jitter);
    });
  }

  bool shouldRetry(DioException e, int attempt) {
    // Retry for network/timeout issues
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return true;
    }

    // Retry for 5xx server errors (not 4xx)
    if (e.type == DioExceptionType.badResponse) {
      final code = e.response?.statusCode ?? 0;
      if (code >= 500 && code < 600) return true;
    }

    // Do not retry cancel / 4xx / others
    return false;
  }

  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      retries: 3, // total attempts = 1 (original) + 3
      retryDelays: backoff(retries: 3), // 0.8s, 1.6s, 3.2s (+ jitter)
      retryEvaluator: shouldRetry, // best-practice rules
      logPrint: null, // set to print if you want to log
    ),
  );

  return dio;
}

class _ApiTestPageState extends State<ApiTestPage> {
  final _scroll = ScrollController();
  final dio = buildDio();
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
    // 👇 pre-select the first option
    selected = options.first;
  }

  /// Define a unique key for an endpoint (adjust to your type)
  final Set<String> _inFlight = <String>{};
  //API CalL
  // Example of using it (e.g., inside your button handler)
  Future<void> onCallPressed() async {
    final key =
        (selected?.endpointCompany ?? '') + (selected?.endpointValue ?? '');
    if (_inFlight.contains(key)) {
      // already running, ignore this tap
      return;
    }
    _inFlight.add(key);

    try {
      resetResult();
      await selectEndPointAsync(dio);
      //Make end for "all"
      if (selected?.endpointValue == "all") {
        updateResultEnd();
      }
    } finally {
      _inFlight.remove(key);
    }
  }

  // Call ALL endpoints concurrently
  Future<void> selectEndPointAsync(Dio dio) async {
    //select endpoints based on the dropdown selection
    // If "all" is selected, call all endpoints
    List endpoints = <EndpointOption>[];
    switch (selected?.endpointValue) {
      case 'all':
        endpoints = [
          //fill in multiple endpoints
          EndpointOption("", 'CDN', 'hhtitems'),
          EndpointOption("", 'CDN', 'hhtbarcodes'),
          EndpointOption("", 'CDN', 'hhtlocations'),
          EndpointOption("", 'CDN', 'hhtturncodes'),
          EndpointOption("", 'LL', 'hhtitems'),
          EndpointOption("", 'LL', 'hhtbarcodes'),
          EndpointOption("", 'LL', 'hhtlocations'),
        ];
      default:
        endpoints = [selected];
    }

    //for each endpoint on list, call the API and return a list of results
    final futures = endpoints
        .map((endpoint) => _callEndPoint(dio, endpoint))
        .toList();
    // 3) Wait for *all* to complete
    await Future.wait(futures); // ← this ensures we wait before returning
  }

  // Call a single endpoint and return the result
  Future<void> _callEndPoint(Dio dio, EndpointOption ep) async {
    Map<String, dynamic> result = {};
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
            // extra: {'retry': false}, // dio_smart_retry respects this flag, disable retry for a call
            headers: {
              //change to config later
              'Company': ep.endpointCompany,
              //change to config later
              'Prefer': 'odata.maxpagesize=5000',
            },
          ),
        );
        page++;

        if (isOk(response)) {
          final data = response.data as Map<String, dynamic>;
          // Get nextLink if exists
          url = data['@odata.nextLink'] as String?;

          //*******aysnc insert to database here if needed  ******

          //only keep preview of the last page
          if (url == null) {
            status = response.statusCode.toString();
            if (selected?.endpointValue != "all") {
              responseBodyFull = _prettyJson(
                response.data,
              ); // keep full, off-screen
            }
          }
        } else {
          //error
          status = response.statusCode.toString();
          url = null; //stop loop on error
          responseBodyFull = response.statusMessage.toString();
        }
      }

      sw.stop();
      result = {
        'endpoint': ep.endpointValue,
        'company': ep.endpointCompany,
        'status': status,
        'duration': fmtMinSecMs(sw.elapsed),
        'page': page,
        'data': responseBodyFull, // keep full data for debugging
      };
      // listReult = [result];
      updateResult([result]);
    } catch (e) {
      sw.stop();
      result = {
        'endpoint': ep.endpointValue,
        'company': ep.endpointCompany,
        'status': 'ERR',
        'duration': fmtMinSecMs(sw.elapsed),
        'page': page,
        'data': e.toString(),
      };
      updateResult([result]);
    }
  }

  Uri _bcUri(EndpointOption e, {Map<String, String>? qp}) {
    return Uri(
      scheme: 'https',
      host: fqdn,
      port: int.parse(port),
      path:
          '/$instance/api/CDN/HHT/v2.0/${e.endpointValue}', // <= hhtlogin / hhtitems / hhtlocations
      queryParameters: qp,
    );
  }

  Map<String, String>? _defaultQuery(EndpointOption e) {
    Map<String, String> filter = {};
    switch (e.endpointValue) {
      //only return needed fields, this can make payload much smaller and faster
      case "hhtlogin":
        filter = {
          r'$filter':
              "name eq 'ONECOM' and password eq '1234' and hhtId eq 'HHT001'", //change to config later
          r'$expand': 'hhtcompanies', //change to config later
        };
      case "hhtitems":
        switch (e.endpointCompany) {
          case 'CDN':
            filter = {
              r'$select':
                  'number,whCode,description,net,color,brand,itemCateCode,itemSubCate1,itemSubCate2,lastModifyDateTime',
            };
          case 'LL':
            filter = {
              r'$select':
                  'number,llmsCode,description,net,color,brand,itemCD,power,axis,dia,cy,bc,packing,addition,cooSetID,lastModifyDateTime',
            };
        }
      case "hhtbarcodes":
        filter = {
          r'$select': //only return needed fields, this can make payload much smaller and faster
              'number,barcode,lastModifyDateTime',
        };
      case "hhtlocations":
        filter = {};
      case "hhtturncodes":
        filter = {};
      case "all":
        filter = {};
    }
    return filter;
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
    if (selected?.endpointValue == "all") {
      body = results
          .map((r) {
            final base =
                '• ${r['company']} ${r['endpoint']} -${r['status']} | ${r['page']} | ${r['duration']}';

            if (r['status'] == 'ERR') {
              final errMsg = r['data']?.toString();
              return '$base\n   ↳ $errMsg';
            } else {
              return base;
            }
          })
          .join('\n');

      setState(() {
        responseBodyPreview += '$body\n';
      });
    } else {
      final r = results.first; // only one result
      setState(() {
        statusCode = r['status'];
        responseBodyPreview = _toPreview(r['data']);
        elapsed = r['duration'];
        pageCount = r['page'] is int ? r['page'] as int : 0;
        // responseBodyPreview = r['error'];
      });
    }
  }

  void updateResultEnd() {
    if (!mounted) return;
    setState(() {
      responseBodyPreview += '\n End';
    });
  }

  bool isOk(Response res) =>
      res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300;

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
                  child: DropdownButton<EndpointOption>(
                    value: selected,
                    hint: const Text("Select endpoint"),
                    items: options.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(opt.endpointLabel),
                      );
                    }).toList(),
                    onChanged: (opt) {
                      setState(() => selected = opt);
                      debugPrint(
                        "Label: ${opt?.endpointLabel} |Name: ${opt?.endpointCompany}|Value: ${opt?.endpointValue}",
                      );
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
