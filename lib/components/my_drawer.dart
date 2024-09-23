import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';
import '../pages/settings_page.dart';
import 'my_drawer_tile.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  // logout
  void logout(BuildContext context) {
    final authService = AuthService();
    authService.signOut();

    // then navigate to initial route (Auth Gate / Login Register Page)
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // app logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 120.0, right: 120, top: 120, bottom: 60),
                  child: Image.asset(
                    'lib/images/message.png',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              // divider line
              Divider(
                color: Theme.of(context).colorScheme.secondary,
                indent: 25,
                endIndent: 25,
              ),

              // home list tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 10),
                child: MyDrawerTile(
                  title: "H O M E",
                  icon: Icons.home,
                  onTap: () => Navigator.pop(context),
                ),
              ),

              // settings list tile
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 0),
                child: MyDrawerTile(
                  title: "S E T T I N G S",
                  icon: Icons.settings,
                  onTap: () {
                    // pop drawer
                    Navigator.pop(context);

                    // go to settings page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // logout list tile
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25),
            child: MyDrawerTile(
              title: "L O G O U T",
              icon: Icons.logout,
              onTap: () => logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
