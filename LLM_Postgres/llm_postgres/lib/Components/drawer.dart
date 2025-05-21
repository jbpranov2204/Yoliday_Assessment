import 'package:flutter/material.dart';

class ResponsiveDrawer extends StatelessWidget {
  ResponsiveDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        height: 40,
                        width: 120,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/Image/logo.png'),
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(child: ListTile(title: Text('Python Code Review'))),
              Container(child: ListTile(title: Text('Debug this code for me'))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: ListTile(
              leading: ClipOval(
                child: CircleAvatar(
                  radius: 25,
                  child: Image.network(
                    'https://th.bing.com/th?id=OIP.PO6DY2_pU6bY1TlbnQdtQQHaHa&w=250&h=250&c=8&rs=1&qlt=90&o=6&dpr=1.3&pid=3.1&rm=2',
                  ),
                ),
              ),
              title: Text(
                'John Doe',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Icon(Icons.more_horiz),
            ),
          ),
        ],
      ),
    );
  }
}
