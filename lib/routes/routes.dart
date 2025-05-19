import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/pages/add_edit_guest_page.dart';
import 'package:four_secrets_wedding_app/pages/edit_profile_page.dart';
import 'package:four_secrets_wedding_app/pages/gaestelist.dart';
import 'package:four_secrets_wedding_app/pages/impressum.dart';
import 'package:four_secrets_wedding_app/pages/kontakt.dart';
import 'package:four_secrets_wedding_app/pages/parsonal_training.dart';
import 'package:four_secrets_wedding_app/pages/about_me.dart';
import 'package:four_secrets_wedding_app/screens/budget.dart';
import 'package:four_secrets_wedding_app/pages/bachelorette_party.dart';
import 'package:four_secrets_wedding_app/pages/band_dj.dart';
import 'package:four_secrets_wedding_app/pages/braut_braeutigam_atelier.dart';
import 'package:four_secrets_wedding_app/pages/checklist.dart';
import 'package:four_secrets_wedding_app/pages/florist.dart';
import 'package:four_secrets_wedding_app/pages/fotograph.dart';
import 'package:four_secrets_wedding_app/pages/kosmetische_akupunktur.dart';
import 'package:four_secrets_wedding_app/pages/hair_makeup.dart';
import 'package:four_secrets_wedding_app/pages/home.dart';
import 'package:four_secrets_wedding_app/pages/inspirations.dart';
import 'package:four_secrets_wedding_app/pages/location.dart';
import 'package:four_secrets_wedding_app/pages/showroom_event.dart';
import 'package:four_secrets_wedding_app/pages/splash_screen.dart';
import 'package:four_secrets_wedding_app/pages/tanzschule.dart';
import 'package:four_secrets_wedding_app/pages/wedding_cake.dart';
import 'package:four_secrets_wedding_app/pages/wedding_car_service.dart';
import 'package:four_secrets_wedding_app/pages/wedding_designer.dart';
import 'package:four_secrets_wedding_app/screens/email_verification_screen.dart';
import 'package:four_secrets_wedding_app/screens/forgot_password_screen.dart';
import 'package:four_secrets_wedding_app/screens/signin_screen.dart';
import 'package:four_secrets_wedding_app/screens/signup_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:four_secrets_wedding_app/model/video_player.dart';
import 'package:four_secrets_wedding_app/model/video_player2.dart';
import 'package:four_secrets_wedding_app/pages/tables_management_page.dart';

class RouteManager {
  static const String splashScreen = '/';
  static const String homePage = '/home';
  static const String signinPage = '/signin';
  static const String signupPage = '/signup';
  static const String forgotPasswordPage = '/forgot-password';
  static const String emailVerificationPage = '/email-verification';
  static const String inspirationsPage = '/inspirations';
  static const String aboutMePage = '/aboutMe';
  static const String checklistPage = '/checklist';
  static const String budgetPage = '/budget';
  static const String gaestelistPage = '/gaestelist';
  static const String showroomEventPage = '/showroom_event';
  static const String hairMakeUpPage = '/hair_makeup';
  static const String bachelorettePartyEventPage = '/bachelorette_party';
  static const String brauBraeutigamPage = '/braut_braeutigam_atelier';
  static const String locationPage = '/location';
  static const String weddingDesignerPage = '/wedding_designer';
  static const String bandDjPage = '/band_dj';
  static const String floristPage = '/florist';
  static const String weddingCakePage = '/weddingCake';
  static const String weddingCarServicePage = '/wedding_car_service';
  static const String fotographPage = '/fotograph';
  static const String tanzschulePage = '/tanzschule';
  static const String kosmetischeAkupunktur = '/kosmetische_akupunktur';
  static const String personalTraining = '/personal_training';
  static const String videoPlayer = '/video_player';
  static const String videoPlayer2 = '/video_player2';
  static const String kontakt = '/kontakt';
  static const String impressum = '/impressum';
  static const String editProfilePage = '/edit-profile';
  static const String guestsPage = '/guests';
  static const String tablesManagementPage = '/tables-management';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashScreen:
        return PageTransition(
          child: const SplashScreen(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case signinPage:
        return PageTransition(
          child: const SignInScreen(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case signupPage:
        return PageTransition(
          child: const SignUpScreen(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case forgotPasswordPage:
        return PageTransition(
          child: const ForgotPasswordScreen(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case homePage:
        return PageTransition(
          child: const HomePage(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case inspirationsPage:
        return PageTransition(
          child: Inspirations(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case aboutMePage:
        return PageTransition(
          child: const AboutMe(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case checklistPage:
        return PageTransition(
          child: const Checklist(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case gaestelistPage:
        return PageTransition(
          child: const Gaestelist(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );
      case showroomEventPage:
        return PageTransition(
          child: ShowroomEvent(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case budgetPage:
        return PageTransition(
          child: Budget(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case hairMakeUpPage:
        return PageTransition(
          child: HairMakeUp(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case bachelorettePartyEventPage:
        return PageTransition(
          child: BacheloretteParty(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case brauBraeutigamPage:
        return PageTransition(
          child: const BrautBraeutigam(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case locationPage:
        return PageTransition(
          child: Location(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case weddingDesignerPage:
        return PageTransition(
          child: WeddingDesigner(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case bandDjPage:
        return PageTransition(
          child: BandDj(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case floristPage:
        return PageTransition(
          child: Florist(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case weddingCakePage:
        return PageTransition(
          child: const WeddingCake(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case weddingCarServicePage:
        return PageTransition(
          child: const WeddingCarService(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case fotographPage:
        return PageTransition(
          child: Fotograph(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case tanzschulePage:
        return PageTransition(
          child: Tanzschule(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case kosmetischeAkupunktur:
        return PageTransition(
          child: KosmetischeAkupunktur(), // Placeholder
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case videoPlayer:
        return PageTransition(
          child: VideoPlayerWidget(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case videoPlayer2:
        return PageTransition(
          child: VideoPlayer2(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case kontakt:
        return PageTransition(
          child: Kontakt(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case impressum:
        return PageTransition(
          child: Impressum(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case personalTraining:
        return PageTransition(
          child: PersonalTraining(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      case editProfilePage:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EditProfilePage(
            currentName: args['currentName'],
            currentProfilePicUrl: args['currentProfilePicUrl'],
          ),
        );

      case emailVerificationPage:
        return MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
        );

      case tablesManagementPage:
        return PageTransition(
          child: const TablesManagementPage(),
          settings: settings,
          duration: const Duration(milliseconds: 250),
          type: PageTransitionType.rightToLeft,
        );

      default:
        throw const FormatException('Route not found! Check routes.dart File.');
    }
  }
}
