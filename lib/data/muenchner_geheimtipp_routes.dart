import 'package:four_secrets_wedding_app/routes/routes.dart';

class MuenchnerGeheimtippRoutes {
  static List getRoutes() {
    final List<String> routes = [
      RouteManager.bachelorettePartyPage,
      RouteManager.hairMakeUpPage,
      RouteManager.brauBraeutigamPage,
      RouteManager.locationPage,
      RouteManager.gesangPage,
      RouteManager.bandDjPage,
      RouteManager.floristPage,
      RouteManager.patiseriePage,
      RouteManager.traurednerPage,
      RouteManager.fotographPage,
      RouteManager.tanzschulePage,
      RouteManager.kosmetischeAkupunkturPage,
      RouteManager.personalTrainingPage,
      RouteManager.papeteriePage,
      RouteManager.unterhaltungPage,
      RouteManager.trauringePage,
    ];
    return routes;
  }
}
