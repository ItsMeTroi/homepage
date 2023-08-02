import 'package:captsone_ui/Screens/navbar/messages/chatPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> getCurrentUserId() async {
  return FirebaseAuth.instance.currentUser?.uid;
}

class UserListPage extends HookWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _searchController = useTextEditingController();
    final _users = useState<List<dynamic>>([]);
    final _filteredUsers = useState<List<dynamic>>([]);
    final currentUserId = useState<String?>(null);

    useEffect(() {
      getCurrentUserId().then((userId) {
        currentUserId.value = userId;
      });
      _fetchUsers(currentUserId.value, _users, _filteredUsers);
      return _searchController.dispose;
    }, []);

    _searchController.addListener(() {
      final searchText = _searchController.text.toLowerCase();
      final filteredUsers = _users.value
          .where((user) => user['username'].toLowerCase().contains(searchText))
          .toList();
      _filteredUsers.value = filteredUsers;
    });

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25.0),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<String?>(
              future: getCurrentUserId(),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  if (currentUserId.value == null) {
                    return Center(child: Text('User not logged in'));
                  }
                  return ListView.builder(
                    itemCount: _filteredUsers.value.length,
                    itemBuilder: (context, index) {
                      final userData = _filteredUsers.value[index];
                      return Container(
                        margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0,
                            5.0), // Add left and right margin here
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              userData['username']?[0].toUpperCase() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          title: Text(
                            userData['username'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            userData['email'] ?? '',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            _navigateToChatPage(context, userData['id'] ?? '',
                                userData['username'] ?? '');
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUsers(
    String? currentUserId,
    ValueNotifier<List<dynamic>> users,
    ValueNotifier<List<dynamic>> filteredUsers,
  ) async {
    try {
      final response =
          await http.get(Uri.parse('http://172.28.0.6:8000/all_users/'));
      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isNotEmpty) {
          final List<dynamic> usersData = json.decode(responseBody);
          if (currentUserId != null) {
            usersData.removeWhere((user) => user['id'] == currentUserId);
          }
          users.value = usersData;
          filteredUsers.value = usersData;
        }
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _navigateToChatPage(
      BuildContext context, String userId, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(userId: userId, username: username),
      ),
    );
  }
}
