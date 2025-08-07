import 'dart:async';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';
import 'package:four_secrets_wedding_app/routes/routes.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  bool isPressedBtn1 = false;
  final key = GlobalKey<MenueState>();

  @override
  void initState() {
    super.initState();

    // Preload menu data when home page initializes
    Menue.preloadUserData();
  }

  void buttonIsPressed(int id) {
    setState(() {
      if (id == 1) {
        isPressedBtn1 = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key), // Use the singleton instance
        body: CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: <Widget>[
            const SliverAppBar(
              foregroundColor: Color.fromARGB(255, 255, 255, 255),
              title: Text('Home'),
              pinned: false,
              floating: true,
              backgroundColor: Color.fromARGB(255, 107, 69, 106),
            ),
            SliverPersistentHeader(
              pinned: true,
              // floating: true,
              delegate: _HeaderSliver(),
            ),
            SliverToBoxAdapter(
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  'assets/images/home/welcome_home.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: const SizedBox(
                height: 30,
              ),
            ),
            const SliverToBoxAdapter(
              child: const SizedBox(
                height: 10,
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Color.fromARGB(255, 107, 69, 106),
                      padding: const EdgeInsets.all(15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 5,
                      backgroundColor: isPressedBtn1
                          ? Color.fromARGB(255, 204, 145, 203)
                          : Colors.white,
                    ),
                    onPressed: () {
                      buttonIsPressed(1);
                      Timer(
                        const Duration(milliseconds: 100),
                        () {
                          Navigator.of(context)
                              .pushNamed(RouteManager.muenchnerGeheimtippPage);
                        },
                      );
                    },
                    label: const Text(
                      'let´s go',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios_sharp),
                  ),
                ],
              ),
            ),

            // Test button for swipeable card
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            //     child: ElevatedButton(
            //       style: ElevatedButton.styleFrom(
            //         foregroundColor: Colors.white,
            //         backgroundColor: Color.fromARGB(255, 107, 69, 106),
            //         padding: const EdgeInsets.all(12.0),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(8),
            //         ),
            //       ),
            //       onPressed: () {
            //         Navigator.of(context)
            //             .pushNamed(RouteManager.swipeableCardTestPage);
            //       },
            //       child: Text('Test Swipeable Card Widget'),
            //     ),
            //   ),
            // ),

            // SliverToBoxAdapter(
            //   child: NotificationTestWidget(),
            // ),

            const SliverToBoxAdapter(
              child: const SizedBox(
                height: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _maxExtendHeader = 70.0;
const _minExtendHeader = 70.0;

class _HeaderSliver extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      height: _maxExtendHeader,
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.heart,
              color: Color.fromARGB(255, 107, 69, 106),
              size: 32,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.5),
            ),
            Text(
              "LICH WILLKOMMEN",
              textAlign: TextAlign.center,
              style: GoogleFonts.ptSerif(color: Colors.grey[700], fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => _maxExtendHeader;

  @override
  double get minExtent => _minExtendHeader;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
