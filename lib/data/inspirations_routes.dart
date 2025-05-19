import 'package:four_secrets_wedding_app/routes/routes.dart';

class InspirationsRoutes {
  static List getRoutes() {
    final List<String> routes = [
      RouteManager.bachelorettePartyEventPage,
      RouteManager.hairMakeUpPage,
      RouteManager.brauBraeutigamPage,
      RouteManager.locationPage,
      RouteManager.weddingDesignerPage,
      RouteManager.bandDjPage,
      RouteManager.floristPage,
      RouteManager.weddingCakePage,
      RouteManager.weddingCarServicePage,
      RouteManager.fotographPage,
      RouteManager.tanzschulePage,
      RouteManager.kosmetischeAkupunktur,
      RouteManager.personalTraining,
    ];
    return routes;
  }
}
