
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'admin_constants.dart';
import 'admin_helpers.dart' as helpers;

class UsersManagement extends StatelessWidget {
  const UsersManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: helpers.usersReference.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading customers: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('No customer data available.'),
          );
        }

        final users = helpers.getUsers(
          snapshot.data!.snapshot,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Registered Customers: ${users.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: adminBrown,
                ),
              ),
            ),

            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Text('No registered customers.'),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemBuilder: (context, index) {
                        final user = users[index];

                        final name =
                            user['name']?.toString() ?? 'No name';

                        final username =
                            user['username']?.toString() ?? 'N/A';

                        final email =
                            user['email']?.toString() ?? 'N/A';

                        final phone =
                            user['phone']?.toString() ?? 'N/A';

                        final address =
                            user['address']?.toString() ?? 'N/A';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,

                              leading: const CircleAvatar(
                                radius: 25,
                                backgroundColor: adminYellow,
                                child: Icon(
                                  Icons.person,
                                  color: adminBrown,
                                  size: 28,
                                ),
                              ),

                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: adminBrown,
                                  fontSize: 16,
                                ),
                              ),

                              subtitle: Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _userInfo(
                                      Icons.account_circle,
                                      'Username',
                                      username,
                                    ),
                                    const SizedBox(height: 5),
                                    _userInfo(
                                      Icons.email,
                                      'Email',
                                      email,
                                    ),
                                    const SizedBox(height: 5),
                                    _userInfo(
                                      Icons.phone,
                                      'Phone',
                                      phone,
                                    ),
                                    const SizedBox(height: 5),
                                    _userInfo(
                                      Icons.location_on,
                                      'Address',
                                      address,
                                    ),
                                  ],
                                ),
                              ),

                              isThreeLine: true,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _userInfo(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
