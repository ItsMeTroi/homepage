import 'dart:convert';
import 'package:captsone_ui/services/teamsProvider/createTeam.dart';
import 'package:captsone_ui/services/authenticationProvider/authProvider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

Widget buildPendingRequestsSection(
    BuildContext context, WidgetRef ref, Map<String, dynamic>? teamData) {
  final dynamic pendingRequestsData = teamData?['pending_requests'];
  final List<Map<String, dynamic>> pendingRequests =
      pendingRequestsData is List ? List.from(pendingRequestsData) : [];
  return Padding(
    padding: const EdgeInsets.all(10),
    child: SingleChildScrollView(
      child: Column(
        children: [
          for (final request in pendingRequests)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage('assets/Slider1.jpg'),
                      radius: 25,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['username'],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Email: ${request['email']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        _showConfirmationDialog(context, ref, request, true,
                            teamData); // Add teamData here
                      },
                      icon: Icon(Icons.check),
                      color: Colors.green,
                    ),
                    IconButton(
                      onPressed: () {
                        _showConfirmationDialog(context, ref, request, false,
                            teamData); // Add teamData here
                      },
                      icon: Icon(Icons.clear),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Future<void> _showConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> request,
  bool accept,
  Map<String, dynamic>? teamData, // add teamData parameter here
) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmation'),
        content: Text(accept
            ? 'Accept the request from ${request['username']}?'
            : 'Reject the request from ${request['username']}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              await _respondToRequest(request, accept, ref,
                  teamData?['game']); // pass teamData here
            },
            child: Text('Confirm'),
          ),
        ],
      );
    },
  );
}

Future<void> _respondToRequest(
  Map<String, dynamic> request,
  bool accept,
  WidgetRef ref,
  String? game, // change game parameter type here
) async {
  final managerId = ref.watch(userDetailsProvider).localId;
  final url = Uri.parse('http://172.28.0.6:8000/respond_to_request/');

  final teamId = request['team_id'];
  final localId = request['localId'];

  print(teamId);
  print(localId);
  print(managerId);

  if (teamId == null || localId == null || managerId == null || game == null) {
    // check if game is null
    print('Invalid parameters');
    return;
  }

  try {
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'team_id': teamId,
        'localId': localId,
        'accept': accept.toString(),
        'manager_id': managerId,
        'game': game, // Include the game data
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print(responseData['message']); // Process the response data as needed
      ref.read(teamProvider.notifier).fetchTeams();
    } else {
      print('Failed to process the request: ${response.body}');
    }
  } catch (e) {
    print('Failed to connect to the server: $e');
  }
}
