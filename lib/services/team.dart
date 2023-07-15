import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:captsone_ui/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final createTeamProvider =
    FutureProvider.family<Map<String, dynamic>, CreateTeamParams>(
  (ref, params) async {
    final userDetails = ref.watch(userDetailsProvider);
    final managerId = userDetails.localId;

    if (managerId == null) {
      throw Exception('User is not signed in.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/create_team/'),
    );

    request.fields['manager_id'] = managerId;
    request.fields['team_name'] = params.teamName;
    request.fields['game'] = params.selectedGame ?? params.game;

    // if (params.logo != null) {
    //   final file = await http.MultipartFile.fromPath('logo', params.logo!.path);
    //   request.files.add(file);
    // }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final teamResponse = await http.get(
        Uri.parse('http://10.0.2.2:8000/get_team_info/$managerId/'),
      );

      if (teamResponse.statusCode == 200) {
        var completeTeamData = jsonDecode(teamResponse.body);
        return completeTeamData;
      } else {
        throw Exception('Failed to fetch team info: ${teamResponse.body}');
      }
    } else {
      throw Exception('Failed to create team: ${response.body}');
    }
  },
);

class CreateTeamParams {
  final String teamName;
  final String game;
  final String? selectedGame;
  final File? logo;

  CreateTeamParams(this.teamName, this.game, [this.selectedGame, this.logo]);
}

final teamProvider =
    StateNotifierProvider<TeamNotifier, List<Map<String, dynamic>>>(
  (ref) => TeamNotifier(ref.watch(userDetailsProvider)),
);

class TeamNotifier extends StateNotifier<List<Map<String, dynamic>>>
    with IterableMixin<Map<String, dynamic>> {
  final UserDetailsProvider userDetails;

  TeamNotifier(this.userDetails) : super([]) {
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    try {
      final managerId = userDetails.localId;
      if (managerId == null) {
        print('No user logged in');
        return;
      }
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/get_team_info/$managerId/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> &&
            data.containsKey('team_name') &&
            data.containsKey('members')) {
          final teamData = {
            'team_name': data['team_name'],
            'members': data['members'],
            'logo': data['logo'],
          };
          state = [teamData];
        } else {
          print('Invalid response data: $data');
        }
      } else {
        print('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Network request failed: $e');
    }
  }

  @override
  Iterator<Map<String, dynamic>> get iterator => state.iterator;
}
