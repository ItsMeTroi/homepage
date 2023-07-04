import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:captsone_ui/Screens/Scrimmagespage.dart';
import 'package:captsone_ui/widgets/drawer.dart';
import 'package:captsone_ui/widgets/events_leaderboards_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final currentIndexProvider = StateNotifierProvider<CurrentIndexNotifier, int>(
    (ref) => CurrentIndexNotifier());

class CurrentIndexNotifier extends StateNotifier<int> {
  CurrentIndexNotifier() : super(0);

  void setCurrentIndex(int index) {
    state = index;
  }
}

final scaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

class Homepage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);
    final scaffoldKey = ref.watch(scaffoldKeyProvider);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'Logo.png',
              width: 40,
              height: 40,
            ),
            SizedBox(width: 10),
            Text(
              'CebuArena',
              style: GoogleFonts.metalMania(fontSize: 30),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none),
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
      drawer: SidebarMenu(username: 'Your username'),
      body: _buildPage(currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentIndexProvider.notifier).setCurrentIndex(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Scrimmages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.5),
        selectedLabelStyle: GoogleFonts.montserrat(),
        unselectedLabelStyle: GoogleFonts.montserrat(),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return EventsLeaderboardsPage();
      case 1:
        return ScrimmagesPage();
      // case 2:
      //   return ProfilePage();
      // case 3:
      //   return SettingsPage();
      default:
        return Container();
    }
  }
}
