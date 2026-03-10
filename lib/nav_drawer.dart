import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:step_on_it/main.dart' show version, buildNumber;
import 'package:step_on_it/settings.dart';

import 'constants.dart';
import 'debug_panel.dart';
import 'import_export.dart';

// TEMPORARY
const deviceDescription = "Mobile";

class NavDrawer extends StatelessWidget {

  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    image: DecorationImage(
                        fit: BoxFit.none,
                        image: AssetImage('images/soi-logo.png'))
                ),
                child: const Text(
                  'Step On It Menu',
                  style: TextStyle(color: Colors.black, fontSize: 25),
                ),
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Privacy Policy'),
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AlertDialog(
                                  title: const Text("Privacy Policy"),
                                  content: const Text(
                                      "We do not upload any data, at all, ever.\n"
                                          "For more details: https://steponit.darwinsys.com/privacy.html"),
                                  actions: <Widget>[
                                    TextButton(
                                        child: Text("OK"),
                                        onPressed: () async {
                                          Navigator.of(context).pop(); // Alert
                                          Navigator.of(context).pop(); // Menu
                                        }
                                    )
                                  ])));
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop(); // Dismiss menu
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => const SettingsPage()));
                },
              ),
              ListTile(
                  leading: Icon(Icons.mood),
                  title: Text('Feedback: Like (Rate in Store)'),
                  onTap: () {
                    Navigator.of(context).pop(); // Dismiss menu
                    InAppReview.instance.openStoreListing();
                  }
              ),
              ListTile(
                  leading: Icon(Icons.mood_bad),
                  title: Text('Feedback: Contact/Issue'),
                  onTap: () async {
                    print("Sending 'problem' email");
                    // We don't prompt for the message body; instead
                    // this should pop open the user's chosen mail
                    // client and let them enter the message
                    final Email email = Email(
                      subject: "step_on_it: issue: [SUMMARY?]",
                      recipients: [Constants.ISSUES_EMAIL],
                      isHTML: false,
                    );

                    try {
                      print("calling FlutterEmailSender");
                      await FlutterEmailSender.send(email);
                      print("Mail sent!");
                    } catch (exception) {
                      print("Failure: ${exception.toString()}");
                      MaterialPageRoute(builder: (context) =>
                          AlertDialog(
                              title: const Text("Failed to send"),
                              content: Text("Mail sending failed: ${exception
                                  .toString()}"),
                              actions: [
                                TextButton(
                                    child: Text("OK"),
                                    onPressed: () async {
                                      Navigator
                                          .of(context)
                                          .pop(); // Dismiss the dialog
                                    }
                                ),
                              ]
                          ));
                    }
                  }
              ),

              ListTile(
                leading: Icon(Icons.import_export),
                title: Text('Export Data to File'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => (const ImportExportPage())));
                },
              ),
              AboutListTile(
                icon: const Icon(Icons.info),
                applicationIcon: const FlutterLogo(),
                applicationName: 'Step On It',
                applicationVersion: 'September, 2025',
                applicationLegalese:
                '\u{a9} 2025 Rejminet Group Inc.',
                aboutBoxChildren: [
                  HtmlWidget("""
              <html lang="en">
              <h3>You're about to Step On It</h3>
              <p><b>Step On It</b> - The easy way to <em>get up to speed</em> tracking your daily steps
              as you work towards your exercise steps goal today!
              </p><p>
              This app is <em>soooo simple</em> we've not felt obliged to offer a training video!
              </p>
              <p>Built by Ian Darwin of Rejminet Group Inc.
              We stand ready to build all-platform apps for you too.
              Contact ian@darwinsys.com.
              </p>
              <p>Version $version Build $buildNumber<br/>Running on $deviceDescription</p>
              </html>
              """,
                    onTapUrl: (url) {
                      print("Tapped $url");
                      return true;
                    },
                  ),
                ],
              ),
              Constants.debug ?
              ListTile(
                  leading: Icon(Icons.bug_report),
                  title: const Text("Debug"),
                  onTap: () {
                    Navigator.of(context).pop(); // Dismiss menu
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => const DebugPanel()));
                  }, // Tap-ability disabled if !debug
              ) : Divider(),
            ],
          )
      );
    } catch(e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

}
