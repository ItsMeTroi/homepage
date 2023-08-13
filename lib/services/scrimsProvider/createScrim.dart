import 'dart:collection';

import 'package:captsone_ui/services/authenticationProvider/authProvider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

final scrimIdProvider = StateProvider<String?>((ref) => null);

final createScrimProvider =
    FutureProvider.family<Map<String, dynamic>, CreateScrimParams>(
  (ref, params) async {
    final userDetails = ref.watch(userDetailsProvider);
    final managerId = userDetails.localId;

    print('ManagerId: $managerId');

    await http.get(
      Uri.parse('http://192.168.1.5:8000/get_team_info/$managerId/'),
    );

    final url = Uri.parse('http://192.168.1.5:8000/create_scrim/');

    final response = await http.post(
      url,
      body: {
        'manager_id': managerId,
        'game': params.dropdownValue,
        'date': DateFormat('yyyy-MM-dd').format(params.selectedDate),
        'time': formatTimeOfDay(params.selectedTime),
        'preferences': params.preferences,
        'contact': params.contactDetails,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      print('Server response: $responseBody'); // <- added this line

      final scrimId = responseBody['scrim_id'];
      if (scrimId == null) {
        throw Exception('MISSING KUNO ANG SCRIM ID');
      }

      final scrimmageResponse = await http.get(
        Uri.parse(
            'http://192.168.1.5:8000/get_scrim_details/${params.dropdownValue}/$scrimId'),
      );

      if (scrimmageResponse.statusCode == 200) {
        final completeScrimmageData = jsonDecode(scrimmageResponse.body);
        return completeScrimmageData;
      } else {
        throw Exception(
            'Failed to fetch scrimmage info: ${scrimmageResponse.body}');
      }
    } else {
      throw Exception(response.body);
    }
  },
);

class CreateScrimParams {
  final String? dropdownValue;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String? preferences;
  final String? contactDetails;

  CreateScrimParams(
    this.dropdownValue,
    this.selectedDate,
    this.selectedTime,
    this.preferences,
    this.contactDetails,
  );
}

String formatTimeOfDay(TimeOfDay tod) {
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  final format = DateFormat('hh:mm a');
  return format.format(dt);
}
