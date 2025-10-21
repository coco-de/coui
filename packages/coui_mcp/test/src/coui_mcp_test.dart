// Not required for test files
// ignore_for_file: prefer_const_constructors
import 'package:test/test.dart';
import 'package:coui_mcp/simple_server.dart';

void main() {
  group('SimpleCouiServer', () {
    test('can be instantiated', () {
      final server = SimpleCouiServer(docsPath: '/tmp/docs');
      expect(server, isNotNull);
    });

    test('handles initialize request', () async {
      final server = SimpleCouiServer(docsPath: '/tmp/docs');
      final response = await server.handleRequest({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': <String, dynamic>{},
      });

      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 1);
      expect(response['result'], isNotNull);
      expect(response['result']['protocolVersion'], '2024-11-05');
    });

    test('handles resources/list request', () async {
      final server = SimpleCouiServer(docsPath: '/tmp/docs');
      final response = await server.handleRequest({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'resources/list',
        'params': <String, dynamic>{},
      });

      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 2);
      expect(response['result'], isNotNull);
      expect(response['result']['resources'], isList);
    });

    test('handles tools/list request', () async {
      final server = SimpleCouiServer(docsPath: '/tmp/docs');
      final response = await server.handleRequest({
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/list',
        'params': <String, dynamic>{},
      });

      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 3);
      expect(response['result'], isNotNull);
      expect(response['result']['tools'], isList);
    });

    test('handles unknown method with error', () async {
      final server = SimpleCouiServer(docsPath: '/tmp/docs');
      final response = await server.handleRequest({
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'unknown_method',
        'params': <String, dynamic>{},
      });

      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 4);
      expect(response['error'], isNotNull);
      expect(response['error']['code'], -32603);
    });
  });
}
