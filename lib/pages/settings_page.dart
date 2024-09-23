import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/my_app_bar.dart';
import '../components/my_settings_list_tile.dart';
import '../services/auth/auth_service.dart';
import '../theme/theme_provider.dart';
import 'blocked_users_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // confirm user wants to delete account
  void userWantsToDeleteAccount(BuildContext context) async {
    // store user's decision in this boolean
    bool confirm = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirm Delete"),
              content: const Text(
                  "This will delete your account permanently. Are you sure you want to proceed?"),
              actions: [
                // cancel button
                MaterialButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  color: Theme.of(context).colorScheme.inversePrimary,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.background),
                  ),
                ),

                // confirm button
                MaterialButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  color: Theme.of(context).colorScheme.inversePrimary,
                  child: Text(
                    'Delete',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.background),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    // if the user confirmed, proceed with deletion
    if (confirm) {
      try {
        Navigator.pop(context);
        await AuthService().deleteAccount();
      } catch (e) {
        // handle any errors
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const MyAppBar(
        title: "S E T T I N G S",
        actions: [],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // dark mode
              MySettingsListTile(
                title: "Dark Mode",
                action: CupertinoSwitch(
                  onChanged: (value) =>
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme(),
                  value: Provider.of<ThemeProvider>(context, listen: false)
                      .isDarkMode,
                ),
                color: Theme.of(context).colorScheme.secondary,
                textColor: Theme.of(context).colorScheme.inversePrimary,
              ),

              // blocked users
              MySettingsListTile(
                title: "Blocked Users",
                action: IconButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BlockedUsersPage())),
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                color: Theme.of(context).colorScheme.secondary,
                textColor: Theme.of(context).colorScheme.inversePrimary,
              ),

              // delete account
              MySettingsListTile(
                title: "Delete Account",
                action: IconButton(
                  onPressed: () => userWantsToDeleteAccount(context),
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                color: Colors.red.shade400,
                textColor: Theme.of(context).colorScheme.tertiary,
              )
            ],
          ),
        ),
      ),
    );
  }
}
