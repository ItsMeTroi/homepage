import 'package:captsone_ui/Screens/navbar/eventScreen.dart';
import 'package:captsone_ui/Screens/navbar/messages/inboxPage.dart';
import 'package:captsone_ui/Screens/navbar/messages/userList.dart';
import 'package:captsone_ui/Screens/navbar/scrimmagesPage.dart';
import 'package:captsone_ui/services/EventsProvider/fetchEvents.dart';
import 'package:captsone_ui/services/authenticationProvider/authProvider.dart';
import 'package:captsone_ui/services/teamsProvider/fetchTeams.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:captsone_ui/widgets/Homepage/drawer.dart';
import 'package:captsone_ui/widgets/Homepage/eventLeaderboards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:captsone_ui/Screens/navbar/teamlist.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final currentIndexProvider = ChangeNotifierProvider<CurrentIndexNotifier>(
  (ref) => CurrentIndexNotifier(),
);

class CurrentIndexNotifier extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

class Homepage extends HookConsumerWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    checkUserLoggedIn();
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final currentIndex = ref.watch(currentIndexProvider);
    final username = ref.watch(userDetailsProvider).username;

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        key: UniqueKey(),
        leading: IconButton(
          color: Colors.black,
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/blackLogo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'CebuArena',
              style: GoogleFonts.metalMania(fontSize: 30, color: Colors.black),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            color: Colors.black,
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
        ),
        elevation: 20,
        titleSpacing: 20,
      ),
      drawer: SidebarMenu(
        username: username,
      ),
      body: _buildPage(ref, currentIndex.currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.currentIndex,
        onTap: (index) {
          currentIndex.setCurrentIndex(index);
          if (index == 3) {
            ref.read(eventsProvider.notifier).refreshEvents();
          }
          if (index == 2) {
            ref.read(teamsProvider.notifier).refreshTeams();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Scrimmages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.5),
        selectedLabelStyle: GoogleFonts.montserrat(),
        unselectedLabelStyle: GoogleFonts.montserrat(),
      ),
    );
  }

  Widget _buildPage(WidgetRef ref, int index) {
    switch (index) {
      case 0:
        return HomeView();
      case 1:
        return ScrimmagesPage();
      case 2:
        return TeamsList();
      case 3:
        return EventsPage();
      case 4:
        return InboxPage();

      default:
        return Container();
    }
  }
}
