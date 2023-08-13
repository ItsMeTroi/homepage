import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Event {
  final String eventId;
  final String selectedGame;
  final Map<String, dynamic> eventData;

  Event({
    required this.eventId,
    required this.selectedGame,
    required this.eventData,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'],
      selectedGame: json['selected_game'],
      eventData: json,
    );
  }
}

class EventsState extends StateNotifier<AsyncValue<List<Event>>> {
  EventsState() : super(AsyncValue.loading()) {
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      state = AsyncValue.loading();
      final events = await _getEvents();
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Event>> _getEvents() async {
    final url = Uri.parse('http://192.168.1.5:8000/get_all_events/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> eventsData = responseData;
        final List<Event> events =
            eventsData.map((json) => Event.fromJson(json)).toList();
        return events;
      } else {
        throw Exception('Failed to fetch events');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<void> refreshEvents() async {
    await fetchEvents();
  }
}

final eventsProvider =
    StateNotifierProvider<EventsState, AsyncValue<List<Event>>>(
        (ref) => EventsState());
