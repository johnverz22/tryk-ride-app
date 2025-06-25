import 'package:driver/features/driver/presentation/pages/screens/navigation/dashboard_screen.dart';
import 'package:driver/features/earnings/presentation/widgets/earnings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(context),
            _buildDrawerBody(context),
            Spacer(),
            Divider(
              color: Colors.grey[300],
              height: 5,
              thickness: 1,
            ),
            _buildDrawerBottom(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return SizedBox(
      height: 300,
      child: DrawerHeader(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/profile_picture.jpg'),
            ),
            const SizedBox(height: 10),
            const Text(
              'User Name',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text("Rating",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                )),
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StarRating(
                rating: 4.5,
                size: 20.0,
                color: const Color.fromARGB(255, 255, 235, 59),
                borderColor: Colors.grey,
                starCount: 5,
                allowHalfRating: true,
                onRatingChanged: (rating) {
                  // Handle rating change if needed
                },
              ),
            ]),
            const SizedBox(height: 5),
            Text("120 Reviews",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
              )
            ),
            Spacer(),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,     // 🔹 No padding
                minimumSize: Size(0, 0),      // 🔹 Removes default minimum size
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 🔹 Shrinks tap area
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
              child: Text(
                'View analytics',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerBody(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          ListTile(
            title: const Text('Inbox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('Bonuses & Promotions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BonusesPromotionsSection()),
              );
            },
          ),
          ListTile(
            title: const Text('Pay Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
              // Handle history tap
            },
          ),
          ListTile(
            iconColor: Colors.yellow,
            leading: const Icon(Icons.brightness_2_rounded),
            title: const Text('B A N A N A'),
            onTap: () {
              // Handle support tap
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerBottom(BuildContext context){
    return Column(
      children: [
        ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
      ],
    );
  }
}