import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ShowStoragePath extends StatefulWidget {
  const ShowStoragePath({super.key});

  @override
  State<ShowStoragePath> createState() => _ShowStoragePathState();
}

class _ShowStoragePathState extends State<ShowStoragePath> {
  late bool _storagePermission;
  late String _currentPath;
  late bool downloading;
  late bool downloadSuccess;

  @override
  void initState() {
    super.initState();
    _storagePermission = false;
    _currentPath = '';
    downloading = false;
    downloadSuccess = false;
    checkAndUpdateStoragePermission();
  }

    /// make a function that launch the url the path of the file
  Future<void> openFile(Uri filePath) async {
    await launchUrl(filePath, mode: LaunchMode.externalApplication);
  }

  Future<void> checkAndUpdateStoragePermission() async {
    final storagePermission = await Permission.storage.status;
    if (storagePermission.isGranted) {
      final currentPath =
          await path_provider.getApplicationDocumentsDirectory();
      setState(() {
        _storagePermission = true;
        _currentPath = currentPath.path;
      });
    }

    if (!_storagePermission) {
      final storagePermission = await Permission.storage.request();
      if (storagePermission.isGranted) {
        final currentPath =
            await path_provider.getApplicationDocumentsDirectory();
        setState(() {
          _storagePermission = true;
          _currentPath = currentPath.path;
        });
      }
    }
  }

  /// function that download pdf from
  /// https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf
  /// return Response

  Future<List<int>?> downloadFile() async {
    setState(() {
      downloading = true;
    });
    final url = Uri(
      scheme: 'https',
      host: 'www.w3.org',
      path: '/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    );
    try {
      setState(() {
        downloading = true;
      });
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          downloading = false;
          downloadSuccess = true;
        });
      }
      return response.bodyBytes;
    } catch (e) {
      return null;
    }
  }

  /// Function that save the file to the path
  /// and open the file
  Future<void> saveFile(String filePath) async {
    final downloadFileAt = File('$filePath/dummy.pdf');

    if (downloadFileAt.existsSync()) {
      /// open the file
      await openFile(downloadFileAt.uri);
      return;
    }
    final fileBytes = await downloadFile();
    if (fileBytes == null) {
      return;
    }
    downloadFileAt.create(recursive: true).then((_) {
      downloadFileAt.writeAsBytes(fileBytes).then((_) async {
        /// open the file
        await openFile(downloadFileAt.uri);
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text.rich(
          TextSpan(
            text: 'Permission to the storage is: ',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
            children: <TextSpan>[
              TextSpan(
                text: _storagePermission ? 'granted' : 'denied',
                style: const TextStyle(
                  color: Colors.lightBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '\n\nCurrent path is: ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: _currentPath,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          checkAndUpdateStoragePermission();

          /// download the file
          saveFile(_currentPath);
        },
        child: Icon(
          downloading
              ? Icons.downloading
              : downloadSuccess
                  ? Icons.download_done_rounded
                  : Icons.download,
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Learning Storage Permission',
    home: const ShowStoragePath(),
    theme: ThemeData(
      primarySwatch: Colors.lightBlue,
    ),
  ));
}
