import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  const ProfilePage({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    int coins = userInfo['gaming_points'][0]['points'];
    int gems = userInfo['gaming_points'][1]['points'];
    int totalPoints = coins + gems;

    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo['full_name'] ?? 'Profile Page'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('ТопМани: $totalPoints'),
                          SizedBox(width: 10),
                          Image.asset(
                            'assets/images/top-money.png',
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('ТопКоины: $coins'),
                          SizedBox(width: 10),
                          Image.asset(
                            'assets/images/top-coin.png',
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('ТопГемы: $gems'),
                          SizedBox(width: 10),
                          Image.asset(
                            'assets/images/top-gem.png',
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Settings'),
              onTap: () {
                // Handle settings tap
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                // Handle logout tap
              },
            ),
          ],
        ),
      ),
      drawerScrimColor: Colors.black.withOpacity(0.5),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.7,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('This is the profile page'), SizedBox(height: 20)],
        ),
      ),
    );
  }
}
