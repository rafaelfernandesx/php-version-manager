import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';

class StateManager {
  final progressNotifier = ValueNotifier<double?>(0);

  void startDownloading(String url, void Function()? callback) async {
    progressNotifier.value = null;

    final request = Request('GET', Uri.parse(url));
    final StreamedResponse response = await Client().send(request);

    final contentLength = response.contentLength;
    // final contentLength = double.parse(response.headers['x-decompressed-content-length']);

    progressNotifier.value = 0;

    List<int> bytes = [];

    final file = await _getFile(url.split('/').last);
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        progressNotifier.value = downloadedLength / contentLength!;
      },
      onDone: () async {
        progressNotifier.value = 0;
        await file.writeAsBytes(bytes);
      },
      onError: (e) {
        debugPrint(e);
      },
      cancelOnError: true,
    );
    if (callback != null) {
      callback();
    }
  }

  Future<File> _getFile(String filename) async {
    final dir = Directory('${Directory.current.path}/versions');
    dir.createSync();

    return File(join(dir.path, filename));
  }
}
