import 'package:captsone_ui/services/authenticationProvider/authProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final createEventProvider = Provider.autoDispose<CreateEvent>((ref) {
  // Fetch the UserDetailsProvider instance from the provider container
  final userDetails = ref.read(userDetailsProvider);

  // Provide the UserDetailsProvider to the CreateEvent provider
  return CreateEvent(userDetails);
});

class CreateEvent {
  final UserDetailsProvider userDetailsProvider;

  CreateEvent(this.userDetailsProvider);

  set selectedGame(String? selectedGame) {}

  Future<String> createEvent({
    required String eventName,
    String? selectedGame,
    required String eventDescription,
    required String rules,
    required String prizes,
    required int maximumTeams,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
  }) async {
    try {
      // Fetch the localId from the userDetailsProvider
      final localId = userDetailsProvider.localId;

      if (localId == null) {
        return 'Error: Local ID not available';
      }

      const apiUrl =
          'http://192.168.1.5:8000/create_event/'; // Replace with your actual API URL

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final formattedTime = formatTimeOfDay(selectedTime);

      final response = await http.post(
        Uri.parse(apiUrl), // Parse the URL string to Uri
        headers: {
          'Content-Type': 'application/json'
        }, // Set headers if required
        body: jsonEncode({
          'localId': localId,
          'event_name': eventName,
          'selected_game': selectedGame,
          'event_description': eventDescription,
          'rules': rules,
          'prizes': prizes,
          'maximum_teams': maximumTeams.toString(),
          'event_date': formattedDate,
          'event_time': formattedTime,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('message')) {
          return 'Event creation successful';
        } else if (responseData.containsKey('error_message')) {
          return responseData['error_message'];
        } else {
          return 'Unknown error occurred';
        }
      } else {
        return 'Failed to create event: ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}

String formatTimeOfDay(TimeOfDay tod) {
  final format = DateFormat('hh:mm a');
  return format.format(DateTime(0, 1, 1, tod.hour, tod.minute));
}
