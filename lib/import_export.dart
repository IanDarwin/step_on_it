import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'date_count.dart';
import 'main.dart';
import 'nav_drawer.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  ImportExportState createState() => ImportExportState();
}

class ImportExportState extends State<ImportExportPage> {

  ImportExportState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Counter'),
      ),
      drawer: NavDrawer(),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Import/Output"),
              const Text("Uses a fixed filename displayed when saving."),
              TextButton(
                  onPressed: null,  // Not written yet
                  child: const Text("Import")
              ),
              TextButton(
                onPressed: () async {
                  print("Exporting...");
                  await exportToFile();
                },
                child: const Text("Export JSON"),
              ),

            ]),
      ),
    );
  }

  Future<bool> importFromFile() async {
    return false;
  }

  Future<bool> exportToFile() async {
    Directory androidNiceDir = Directory("/sdcard/Download/step_on_it");
    Directory appDir = Platform.isIOS ?
    await getApplicationDocumentsDirectory() :
    (
        await Directory("/sdcard/Download").exists() ?
        androidNiceDir :
        await getExternalStorageDirectory() as Directory
    );
    await appDir.create(recursive: true);
    var file = File("${appDir.path}/step_on_it.json");
    await Clipboard.setData(ClipboardData(text: file.path));
    List<DateCount> all = await stepCountDB.findAll();
    var fd = file.openWrite();
    fd.write("{");
    bool first = true;
    for (DateCount dc in all) {
      fd.write(dc.toJSON());
      if (!first) {
        fd.write(",\n");
      }
      first = false;
    }
    fd.write("}\n");
    fd.close();
    if (!mounted) {
      return false;
    }
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                AlertDialog(
                    title: const Text("Export Complete"),
                    content: Text(
                        "Exported ${all.length} readings to file $file. Path copied to clipboard."
                    ),
                    actions: <Widget>[
                      TextButton(
                          child: Text("OK"),
                          onPressed: () async {
                            Navigator.of(context).pop(); // Alert
                            Navigator.of(context).pop(); // Export Page
                            Navigator.of(context).pop(); // Nav Drawer
                          }
                      )
                    ]
                )
        )
    );
    return true;
  }
}
