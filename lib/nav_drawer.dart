import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:step_on_it/main.dart' show goal, version, buildNumber;
import 'package:step_on_it/settings.dart';

// TEMPORARY
const deviceDescription = "Mobile";

class NavDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var aboutBoxChildren = [
      HtmlWidget("""
<html lang="en">
<h3>You're about to Step On It</h3>
<p>Built by Ian Darwin of Rejminet Group Inc.
We can build all-platform apps for you too.
Contact ian@darwinsys.com.
</p>
<p>Version $version Build $buildNumber<br/>Running on $deviceDescription</p>
<p><b>Step On It</b> - The easy way to track your daily steps
and compare them with your exercise goal.
This app is *soooo* simple we've not felt obliged to offer a training video!
</p>
</html>
      """,
        onTapUrl: (url) {
          print("Tapped $url");
          return true;
        },
      ),
    ];
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text(
              'Step On It Menu',
              style: TextStyle(color: Colors.black, fontSize: 25),
            ),
            decoration: BoxDecoration(
                color: Colors.lightGreen,
                image: DecorationImage(
                    fit: BoxFit.none,
                    image: AssetImage('images/logo.png'))
            ),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            onTap: () {
              Navigator.of(context).pop(); // Dismiss menu
              // Navigator.of(context).pushNamed(ROUTE_PRIVACY);
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
              print("NOT Sending problem email");
              // String recipient = Constants.ISSUES_EMAIL;
              // await Report.sendEmail(context, recipient,
					    //   "step_on_it: issue: [SUMMARY?]",
					    //  "", false, null);
            }
          ),
          AboutListTile(
            icon: const Icon(Icons.info),
            applicationIcon: const FlutterLogo(),
            applicationName: 'Step On It',
            applicationVersion: 'September, 2025',
            applicationLegalese:
              '\u{a9} 2025 Rejminet Group Inc.',
            aboutBoxChildren: aboutBoxChildren,
          ),
          ListTile(
              leading: Icon(Icons.import_export),
              title: Text('Export'),
              onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder:  (context) => AlertDialog(
                          title: const Text("Export failed"),
                          content: Text("Sorry, not written yet"),
                          actions: <Widget> [
                            TextButton(
                                child: Text("OK"),
                                onPressed: () async {
                                  Navigator.of(context).pop(); // Alert
                                  Navigator.of(context).pop(); // Menu
                                }
                            )
                          ])));
                  return;
              }
          ),
        ],
      ),
    );
  }
}
