import 'package:four_secrets_wedding_app/menue.dart';
import 'package:flutter/material.dart';

class Impressum extends StatelessWidget {
   Impressum({super.key});


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue(),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          // automaticallyImplyLeading: false,
          title: const Text('Impressum'),
          backgroundColor: Color.fromARGB(255, 107, 69, 106),
        ),
        body: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Container(
            margin: EdgeInsets.only(bottom: 25),
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(10),
            child: Wrap(
              children: [
                Text(
                  "ALLE ANGABEN GEMÄSS §5 TMG\n",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "4SECRETS STUDIO MÜNCHEN\n",
                  style: TextStyle(
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                Row(
                  children: [
                    Text("Elena Koller\n"
                        "Baaderstraße 88\n"
                        "80469 München/Glockenbachviertel\n"
                        "info@4-secrets.de\n\n"),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "DESIGN, TECHNIK, UMSETZUNG\n",
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 69, 106),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                ),
                Row(
                  children: [
                    Text("Patrick Schubert\n\n"),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "STREITSCHLICHTUNG\n",
                      style: TextStyle(
                        color: Color.fromARGB(255, 107, 69, 106),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                ),
                Text(
                  "Die Europäische Kommission stellt eine Plattform zur "
                  "Online-Streitbeilegung (OS) bereit:\n"
                  "https://ec.europa.eu/consumers/odr.\n"
                  "Unsere E-Mail-Adresse finden Sie oben im Impressum.\n\n"
                  "Wir sind nicht bereit oder verpflichtet, "
                  "an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.\n\n",
                  softWrap: true,
                ),
                Text(
                  "DISCLAIMER\n",
                  style: TextStyle(
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "Haftung für Inhalte\n",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene Inhalte auf diesen "
                  "Seiten nach den allgemeinen Gesetzen verantwortlich."
                  "Nach §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht verpflichtet, "
                  "übermittelte oder gespeicherte fremde Informationen zu überwachen oder nach "
                  "Umständen zu forschen, die auf eine rechtswidrige Tätigkeit hinweisen.\n",
                  softWrap: true,
                ),
                Text(
                  "Verpflichtungen zur Entfernung oder Sperrung der Nutzung von Informationen "
                  "nach den allgemeinen Gesetzen bleiben hiervon unberührt. Eine diesbezügliche Haftung "
                  "ist jedoch erst ab dem Zeitpunkt der Kenntnis einer konkreten Rechtsverletzung möglich."
                  "Bei Bekanntwerden von entsprechenden Rechtsverletzungen werden wir diese Inhalte umgehend entfernen.\n\n",
                  softWrap: true,
                ),
                Text(
                  "Haftung für Links\n",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
                Text(
                  "Unser Angebot enthält Links zu externen Websites Dritter, auf deren Inhalte wir keinen Einfluss haben. "
                  "Deshalb können wir für diese fremden Inhalte auch keine Gewähr übernehmen. "
                  "Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder "
                  "Betreiber der Seiten verantwortlich. Die verlinkten Seiten wurden zum Zeitpunkt "
                  "der Verlinkung auf mögliche Rechtsverstöße überprüft. Rechtswidrige Inhalte waren "
                  "zum Zeitpunkt der Verlinkung nicht erkennbar.\n",
                  softWrap: true,
                ),
                Text(
                  "Eine permanente inhaltliche Kontrolle der verlinkten Seiten ist jedoch ohne konkrete "
                  "Anhaltspunkte einer Rechtsverletzung nicht zumutbar. Bei Bekanntwerden von Rechtsverletzungen "
                  "werden wir derartige Links umgehend entfernen.\n\n",
                  softWrap: true,
                ),
                Text(
                  "Urheberrecht\n",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
                Text(
                  "Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen "
                  "dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und "
                  "jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der "
                  "schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers."
                  "Downloads und Kopien dieser Seite sind nur für den privaten, "
                  "nicht kommerziellen Gebrauch gestattet.\n",
                  softWrap: true,
                ),
                Text(
                  "Soweit die Inhalte auf dieser Seite nicht vom Betreiber erstellt wurden, "
                  "werden die Urheberrechte Dritter beachtet. Insbesondere werden Inhalte Dritter "
                  "als solche gekennzeichnet. Sollten Sie trotzdem auf eine Urheberrechtsverletzung "
                  "aufmerksam werden, bitten wir um einen entsprechenden Hinweis. "
                  "Bei Bekanntwerden von Rechtsverletzungen werden wir derartige Inhalte umgehend entfernen.",
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
