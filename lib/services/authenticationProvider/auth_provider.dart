import 'package:captsone_ui/services/chatProvider/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userDetailsProvider =
    ChangeNotifierProvider<UserDetailsProvider>((ref) => UserDetailsProvider());

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final authRegisProvider = Provider<AuthRegis>((ref) => AuthRegis());

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthRegis extends ChangeNotifier {
  static const String API_ENDPOINT = "http://10.0.2.2:8000/register/";

  Future<String> signUpWithEmail(
    String firstname,
    String lastname,
    String username,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$API_ENDPOINT/register/"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'firstname': firstname,
        'lastname': lastname,
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return 'Registration successful';
    } else {
      throw Exception('Failed to register');
    }
  }
}

class UserDetailsProvider with ChangeNotifier {
  String? _email;
  String? _username;
  String? _firstname;
  String? _lastname;
  String? _localId;
  bool _isManager = false;
  String? _teamName;

  String? get email => _email;
  String? get username => _username;
  String? get firstname => _firstname;
  String? get lastname => _lastname;
  String? get localId => _localId;
  bool get isManager => _isManager;
  String? get teamName => _teamName;

  void updateUser(User? user) async {
    if (user != null) {
      await fetchUserDetails(user);
      print(
          'User is logged in: ${user.email}'); // prints user's email on the console
    } else {
      print('No user logged in');
    }
  }

  Future<void> fetchUserDetails(User user) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      } else {
        print(
            'User Logged in: ${user.email}'); // prints user's email on the console
      }
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/current_user/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _username = data['username'];
        _firstname = data['firstname'];
        _email = data['email'];
        _lastname = data['lastname'];
        _localId = data['localId'];
        _teamName = data['team_name'];
        _isManager = data['is_manager'] ?? false;

        notifyListeners();
      } else {
        throw Exception('Failed to fetch user details');
      }
    } catch (error) {
      print('Error occurred while fetching user details: $error');
      throw Exception('An error occurred while fetching user details');
    }
  }

  Future<String?> loginWithEmailAPI({
    required String email,
    required String password,
  }) async {
    String url = 'http://10.0.2.2:8000/login/';

    Map<String, String> data = {
      'email': email,
      'password': password,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _username = responseData['username'];
        _localId = responseData['localId'];
        _firstname = responseData['firstname'];
        _email = responseData['email'];
        _lastname = responseData['lastname'];
        _isManager = responseData['is_manager'] ?? false;

        print('EMAIL: $_email');
        print('Local ID: $_localId');
        print('Username: $_username');
        print('First Name: $_firstname');
        print('Last Name: $_lastname');
        print('isManager: $_isManager');

        // Notify listeners that user details have been updated
        notifyListeners();

        // Return null to indicate no error
        return null;
      } else {
        var responseBody = json.decode(response.body);
        var errorMessage = responseBody['error_message'];

        // Return the error message to indicate there was an error
        return errorMessage;
      }
    } catch (error) {
      print('Error occurred while logging in: $error');
      return 'An error occurred. Please try again.';
    }
  }
}

void checkUserLoggedIn() {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('No user is currently logged in.');
  } else {
    print('User is logged in. User id: ${user.uid}, email: ${user.email}');
  }
}

final authProvider = ChangeNotifierProvider<UserDetailsProvider>((ref) {
  return UserDetailsProvider();
});
