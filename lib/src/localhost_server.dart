import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'mime_type_resolver.dart';

/// A simple HTTP server that serves files from the local file system.
/// This class is borrowed from the `Flutter InAppWebView Plugin`.
class LocalhostServer {
  /// Whether the server should be shared across multiple instances of the
  /// application. If set to `true`, the server will be shared across multiple
  /// instances of the application and will not be destroyed when the
  /// application is closed.
  final bool shared;

  /// The index file to serve when a directory is requested. Default is `index.html`.
  final String directoryIndex;

  /// The root directory where files will be served from. Default is `./`.
  /// This path is relative to the root of the application's assets.
  final String documentRoot;

  LocalhostServer({
    this.shared = false,
    this.directoryIndex = 'index.html',
    this.documentRoot = './',
  });

  int? get port => server?.port;

  bool _started = false;
  HttpServer? server;

  /// Starts the server on the given [port].
  Future<void> start({int port = 0}) async {
    if (_started) {
      throw Exception(
          'Server already started on http://localhost:${this.port}');
    }

    final completer = Completer();

    runZonedGuarded(() {
      HttpServer.bind(InternetAddress.loopbackIPv4, port, shared: shared)
          .then((httpServer) {
        server = httpServer;
        _started = true;

        if (kDebugMode) {
          print('Server running on http://localhost:${this.port}');
        }

        httpServer.listen((HttpRequest request) async {
          var path = request.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? directoryIndex : '';
          if (path == '') {
            // if the path still empty, try to load the index file
            path = directoryIndex;
          }
          path = documentRoot + path;

          Uint8List body;
          try {
            body = (await rootBundle.load(Uri.decodeFull(path)))
                .buffer
                .asUint8List();
          } catch (e) {
            if (kDebugMode) {
              print(Uri.decodeFull(path));
              print(e.toString());
            }
            request.response.statusCode = HttpStatus.notFound;
            request.response.close();
            return;
          }

          var contentType = ContentType('text', 'html', charset: 'utf-8');
          if (!request.requestedUri.path.endsWith('/') &&
              request.requestedUri.pathSegments.isNotEmpty) {
            final mimeType = MimeTypeResolver.lookup(request.requestedUri.path);
            if (mimeType != null) {
              contentType = _getContentTypeFromMimeType(mimeType);
            }
          }

          request.response.headers.contentType = contentType;
          request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

          final total = body.length;
          final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
          if (rangeHeader != null) {
            // HTML5 <video> / streaming clients request byte ranges to seek and
            // progressively load media. Without 206 Partial Content support the
            // video cannot be played.
            final matches =
                RegExp(r'bytes=(\d*)-(\d*)').firstMatch(rangeHeader);
            if (matches != null) {
              final startMatch = matches.group(1)!;
              final endMatch = matches.group(2)!;
              var start = startMatch.isEmpty ? 0 : int.parse(startMatch);
              var end = endMatch.isEmpty ? total - 1 : int.parse(endMatch);

              if (end >= total) {
                end = total - 1;
              }

              if (start > end || start >= total) {
                request.response.statusCode =
                    HttpStatus.requestedRangeNotSatisfiable;
                request.response.headers
                    .set(HttpHeaders.contentRangeHeader, 'bytes */$total');
                request.response.close();
                return;
              }

              final length = end - start + 1;
              request.response.statusCode = HttpStatus.partialContent;
              request.response.headers.set(
                  HttpHeaders.contentRangeHeader, 'bytes $start-$end/$total');
              request.response.headers
                  .set(HttpHeaders.contentLengthHeader, length.toString());
              request.response.add(body.sublist(start, end + 1));
              request.response.close();
              return;
            }
          }

          request.response.headers
              .set(HttpHeaders.contentLengthHeader, total.toString());
          request.response.add(body);
          request.response.close();
        });

        completer.complete();
      });
    }, (e, stackTrace) {
      if (kDebugMode) {
        print('Error: $e $stackTrace');
      }
    });

    return completer.future;
  }

  /// Closes the server.
  Future<void> close() async {
    if (server == null) {
      return;
    }
    final serverPort = port;
    await server!.close(force: true);

    if (kDebugMode) {
      print('Server running on http://localhost:$serverPort closed');
    }

    _started = false;
    server = null;
  }

  /// Returns whether the server is running or not.
  bool isRunning() {
    return server != null;
  }

  /// Returns a [ContentType] object based on the given [mimeType].
  ContentType _getContentTypeFromMimeType(String mimeType) {
    final contentType = mimeType.split('/');
    String? charset;

    if (_isTextFile(mimeType)) {
      charset = 'utf-8';
    }

    return ContentType(contentType[0], contentType[1], charset: charset);
  }

  /// Returns whether the given [mimeType] is a text file or not.
  bool _isTextFile(String mimeType) {
    final textFile = RegExp(r'^text/|^application/(javascript|json)');
    return textFile.hasMatch(mimeType);
  }
}
