import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:phpvm/model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<PhpVersion> listPhpVersion = [];
  String? globalVersion;

  void getConfig() {
    try {
      // Lê o conteúdo do arquivo JSON
      final file = File('${Directory.current.path}/config.json');
      String conteudo = file.readAsStringSync();

      // Faz o parsing do conteúdo JSON para um objeto Dart
      dynamic objetoJson = jsonDecode(conteudo);

      // Exemplo: Acessando uma propriedade do objeto JSON
      globalVersion = objetoJson['globalVersion'];
    } catch (e) {
      print('Erro ao ler o arquivo JSON: $e');
    }
  }

  void unzipFile(String filePath, String outputPath) {
    final inputStream = InputFileStream(filePath);
    // Decode the zip from the InputFileStream. The archive will have the contents of the
    // zip, without having stored the data in memory.
    final archive = ZipDecoder().decodeBuffer(inputStream);
    // For all of the entries in the archive
    for (var file in archive.files) {
      // If it's a file and not a directory
      if (file.isFile) {
        // Write the file content to a directory called 'out'.
        // In practice, you should make sure file.name doesn't include '..' paths
        // that would put it outside of the extraction directory.
        // An OutputFileStream will write the data to disk.
        final outputStream = OutputFileStream('$outputPath/${file.name}');
        // The writeContent method will decompress the file content directly to disk without
        // storing the decompressed data in memory.
        file.writeContent(outputStream);
        // Make sure to close the output stream so the File is closed.
        outputStream.close();
      }
    }
  }

  void setConfig(String? data) {
    try {
      final file = File('${Directory.current.path}/config.json');
      file.writeAsStringSync(jsonEncode({"globalVersion": data}));
      final dir = Directory('${Directory.current.path}/default');
      if (dir.existsSync()) {
        final res = dir.deleteSync(recursive: true);
      }
      dir.createSync();
      unzipFile('${Directory.current.path}/versions/$data', '${Directory.current.path}/default');
      globalVersion = data;
      getPhp();
    } catch (e) {
      print('Erro ao escrever o arquivo JSON: $e');
    }
  }

  void deleteVersion(String data) {
    try {
      final file = File('${Directory.current.path}/versions/$data');

      if (file.existsSync()) {
        file.deleteSync(recursive: true);
      }
      if (globalVersion == data) {
        globalVersion = null;
        final directory = Directory('${Directory.current.path}/default');
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      }
      getPhp();
    } catch (e) {
      print('Erro ao escrever o arquivo JSON: $e');
    }
  }

  Future<void> getPhp() async {
    final dio = Dio();
    final response = await dio.get<String>('https://windows.php.net/downloads/releases/archives/');
    setState(() {
      listPhpVersion = response.data!
          .split('<br>')
          .where((element) => element.contains('.zip'))
          .where((element) => !element.contains('src.zip'))
          .where((element) => element.contains(RegExp(r'php-\d+')))
          .map((e) {
            String name = RegExp(r">(.*?)<").firstMatch(e)?.group(1) ?? '-----------------';
            String downloadLink = RegExp(r'"(.*?)"').firstMatch(e)?.group(1) ?? '-----------------';
            String releaseDate = RegExp(r"^(.*?)PM").firstMatch(e)?.group(1) ?? '-----------------';
            String size = RegExp(r'PM\s+(.*?)<').firstMatch(e)?.group(1) ?? '-----------------';
            bool isGlobal = false;
            bool downloaded = false;
            final file = File('${Directory.current.path}/versions/$name');
            if (file.existsSync()) {
              if (globalVersion != null && globalVersion == name) {
                isGlobal = true;
              }
              downloaded = true;
            }
            return PhpVersion(name: name, downloadLink: 'https://windows.php.net$downloadLink', releaseDate: releaseDate.trim(), size: size.trim(), isGlobal: isGlobal, downloaded: downloaded);
          })
          .toList()
          .reversed
          .toList();
    });
  }

  @override
  void initState() {
    getConfig();
    getPhp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Text(
                '${listPhpVersion.length} PHP versions found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: IconButton(
                  onPressed: getPhp,
                  icon: const Icon(Icons.replay_outlined),
                ),
              )
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: listPhpVersion.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide.none)),
                          ),
                          child: Row(
                            children: [
                              Text(listPhpVersion[index].name),
                              const Expanded(child: SizedBox()),
                              listPhpVersion[index].isGlobal == false && listPhpVersion[index].downloaded == true
                                  ? IconButton(
                                      onPressed: () => setConfig(listPhpVersion[index].name),
                                      icon: const Icon(Icons.check_box_outline_blank),
                                    )
                                  : listPhpVersion[index].downloaded == true && listPhpVersion[index].isGlobal == true
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.check_box),
                                        )
                                      // ? IconButton(
                                      //     onPressed: () => setConfig(null),
                                      //     icon: const Icon(Icons.check_box),
                                      //   )
                                      : const SizedBox(),
                              listPhpVersion[index].downloaded == false
                                  ? IconButton(
                                      onPressed: () => listPhpVersion[index].stateManager.startDownloading(listPhpVersion[index].downloadLink, getPhp),
                                      icon: const Icon(Icons.download),
                                    )
                                  : IconButton(
                                      onPressed: () => deleteVersion(listPhpVersion[index].name),
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red.shade400,
                                    ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<double?>(
                          valueListenable: listPhpVersion[index].stateManager.progressNotifier,
                          builder: (context, percent, child) {
                            if (percent == null || percent == 0) {
                              return const SizedBox();
                            }
                            return LinearProgressIndicator(
                              color: Colors.red,
                              value: percent,
                            );
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
