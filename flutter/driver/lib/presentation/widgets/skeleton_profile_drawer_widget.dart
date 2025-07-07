import 'package:driver/presentation/screens/dashboard_screen.dart';
import 'package:driver/presentation/widgets/earnings_widget/earnings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';

class ProfileDrawer extends ConsumerWidget {
  ProfileDrawer({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(context),
            _buildDrawerBody(context),
            Divider(
              color: Colors.grey[300],
              height: 5,
              thickness: 1,
            ),
            _buildDrawerBottom(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: Colors.black87,
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage('assets/images/profile_picture.jpg'),
            ),
            title: const Text('User Name'),
            subtitle: Row(
                children: [
                  Icon(Icons.star, size: 16,),
                  Text("4.89",style: TextStyle(color: Colors.black87),)
                ],
              ),
            onTap: () {
              // Handle support tap
            },
          ),
          
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining Driving Time',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  )),
                Text(
                  '2h 30m',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  )),
              ],
            ),
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
    );
  }

  Widget _buildDrawerBody(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          ListTile(
            title: const Text('Inbox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('Refer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BonusesPromotionsSection()),
              );
            },
          ),
          ListTile(
            title: const Text('Earnings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {
              // Handle history tap
            },
          ),
          ListTile(
            iconColor: Colors.yellow,
            leading: const Icon(Icons.brightness_2_rounded),
            title: const Text('B A N A N A', style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              // Handle support tap
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerBottom(BuildContext context, WidgetRef ref){
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
              title: const Text('Banana'),
              onTap: () {
                showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout from your account?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          debugPrint("authService.logout");
                          await _authService.logout(ref);

                          // Use outer `context`, which is still valid
                          if (context.mounted) {
                            debugPrint("Mounted");
                            context.go('/auth');
                          } else{
                            debugPrint("NotMounted");
                          }
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
              },
            ),
      ],
    );
  }
}
