import 'package:DreamWedding/menue.dart';
import 'package:flutter/material.dart';

class Impressum extends StatelessWidget {
  const Impressum({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const Menue(),
        appBar: AppBar(
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Text('Impressum & Datenschutz'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Container(
            margin: const EdgeInsets.only(bottom: 25),
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "IMPRESSUM",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Angaben gemäß § 5 TMG:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                const Text(
                  "Verantwortlich für den Inhalt:\n"
                  "4SECRETS-WEDDING\n"
                  "Franziskanerstraße 38\n"
                  "81669 München\n\n"
                  "E-Mail: 4secrets-wedding@gmx.de\n"
                  "Telefon: [TELEFONNUMMER ERGÄNZEN]\n",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "ENTWICKLUNG UND DESIGN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Patrick Schubert"),
                const Text("Elena Koller\n"),

                const SizedBox(height: 20),

                const Text(
                  "STREITBEILEGUNG",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Die Europäische Kommission stellt eine Plattform zur "
                  "Online-Streitbeilegung (OS) bereit: "
                  "https://ec.europa.eu/consumers/odr\n\n"
                  "Wir sind nicht bereit oder verpflichtet, an "
                  "Streitbeilegungsverfahren vor einer "
                  "Verbraucherschlichtungsstelle teilzunehmen.",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "HAFTUNG FÜR INHALTE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Als Diensteanbieter sind wir gemäß § 7 Abs. 1 TMG für "
                  "eigene Inhalte auf diesen Seiten nach den allgemeinen "
                  "Gesetzen verantwortlich. Nach §§ 8 bis 10 TMG sind wir "
                  "als Diensteanbieter jedoch nicht verpflichtet, "
                  "übermittelte oder gespeicherte fremde Informationen zu "
                  "überwachen oder nach Umständen zu forschen, die auf eine "
                  "rechtswidrige Tätigkeit hinweisen.\n\n"
                  "Verpflichtungen zur Entfernung oder Sperrung der Nutzung "
                  "von Informationen nach den allgemeinen Gesetzen bleiben "
                  "hiervon unberührt. Eine diesbezügliche Haftung ist jedoch "
                  "erst ab dem Zeitpunkt der Kenntnis einer konkreten "
                  "Rechtsverletzung möglich.",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "HAFTUNG FÜR LINKS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Unser Angebot enthält Links zu externen Websites Dritter, "
                  "auf deren Inhalte wir keinen Einfluss haben. Deshalb "
                  "können wir für diese fremden Inhalte auch keine Gewähr "
                  "übernehmen. Für die Inhalte der verlinkten Seiten ist "
                  "stets der jeweilige Anbieter oder Betreiber der Seiten "
                  "verantwortlich.",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "URHEBERRECHT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Die durch die Seitenbetreiber erstellten Inhalte und "
                  "Werke auf diesen Seiten unterliegen dem deutschen "
                  "Urheberrecht. Die Vervielfältigung, Bearbeitung, "
                  "Verbreitung und jede Art der Verwertung außerhalb der "
                  "Grenzen des Urheberrechtes bedürfen der schriftlichen "
                  "Zustimmung des jeweiligen Autors bzw. Erstellers.",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 40),

                // DATENSCHUTZERKLÄRUNG
                const Text(
                  "DATENSCHUTZERKLÄRUNG",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "1. VERANTWORTLICHER",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Verantwortlicher für die Datenverarbeitung:\n"
                  "Elena Koller\n"
                  "Franziskanerstraße 38\n"
                  "81669 München\n"
                  "E-Mail: 4secrets-wedding@gmx.de\n"
                  "Telefon: [TELEFONNUMMER ERGÄNZEN]",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "2. ALLGEMEINE INFORMATIONEN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Der Schutz Ihrer persönlichen Daten ist uns wichtig. "
                  "Diese Datenschutzerklärung informiert Sie über die "
                  "Verarbeitung personenbezogener Daten bei der Nutzung "
                  "unserer App 'DreamWedding'.",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "3. ERHOBENE DATEN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Wir erheben und verarbeiten folgende personenbezogene Daten:\n\n"
                  "• Registrierungsdaten (Name, E-Mail-Adresse)\n"
                  "• Hochzeitsdaten (Termine, Gästelisten, Planungsdaten)\n"
                  "• Nutzungsdaten (App-Interaktionen, Funktionsnutzung)\n"
                  "• Technische Daten (Geräte-ID, Betriebssystem, App-Version)\n"
                  "• Eventuell hochgeladene Inhalte (Fotos, Dokumente)",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "4. ZWECKE DER DATENVERARBEITUNG",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ihre Daten verarbeiten wir zu folgenden Zwecken:\n\n"
                  "• Bereitstellung der App-Funktionalitäten\n"
                  "• Verwaltung Ihrer Hochzeitsplanung\n"
                  "• Kommunikation mit Ihnen\n"
                  "• Verbesserung der App-Performance\n"
                  "• Fehleranalyse und technischer Support",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "5. RECHTSGRUNDLAGEN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Die Verarbeitung erfolgt auf Grundlage von:\n\n"
                  "• Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)\n"
                  "• Art. 6 Abs. 1 lit. f DSGVO (berechtigte Interessen)\n"
                  "• Art. 6 Abs. 1 lit. a DSGVO (Einwilligung, soweit eingeholt)",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "6. SPEICHERDAUER",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Wir speichern Ihre Daten nur so lange, wie es für die "
                  "Erfüllung der Zwecke erforderlich ist oder gesetzliche "
                  "Aufbewahrungsfristen bestehen. Nach Löschung Ihres "
                  "Accounts werden alle personenbezogenen Daten gelöscht, "
                  "soweit keine gesetzlichen Aufbewahrungspflichten bestehen.",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "7. WEITERGABE AN DRITTE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Eine Weitergabe Ihrer Daten an Dritte erfolgt nur:\n\n"
                  "• Mit Ihrer ausdrücklichen Einwilligung\n"
                  "• Soweit dies gesetzlich zulässig und erforderlich ist\n"
                  "• An Auftragsverarbeiter (z.B. Hosting-Anbieter) unter "
                  "strikter Beachtung der DSGVO",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "8. IHRE RECHTE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sie haben folgende Rechte:\n\n"
                  "• Recht auf Auskunft (Art. 15 DSGVO)\n"
                  "• Recht auf Berichtigung (Art. 16 DSGVO)\n"
                  "• Recht auf Löschung (Art. 17 DSGVO)\n"
                  "• Recht auf Einschränkung (Art. 18 DSGVO)\n"
                  "• Recht auf Datenübertragbarkeit (Art. 20 DSGVO)\n"
                  "• Recht auf Widerspruch (Art. 21 DSGVO)\n"
                  "• Recht auf Widerruf der Einwilligung (Art. 7 DSGVO)",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "9. BESCHWERDERECHT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sie haben das Recht, sich bei einer Datenschutz-"
                  "Aufsichtsbehörde über die Verarbeitung Ihrer "
                  "personenbezogenen Daten zu beschweren.\n\n"
                  "Zuständige Aufsichtsbehörde für Bayern:\n"
                  "Bayerisches Landesamt für Datenschutzaufsicht\n"
                  "www.lda.bayern.de",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "10. DATENSICHERHEIT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Wir setzen technische und organisatorische Maßnahmen "
                  "ein, um Ihre Daten gegen zufällige oder vorsätzliche "
                  "Manipulationen, Verlust, Zerstörung oder Zugriff "
                  "unberechtigter Personen zu schützen.",
                  style: TextStyle(height: 1.4),
                ),

                const SizedBox(height: 20),

                const Text(
                  "11. ÄNDERUNGEN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Wir behalten uns vor, diese Datenschutzerklärung zu "
                  "aktualisieren, um sie an geänderte Rechtslage oder "
                  "bei Änderungen unseres Service anzupassen. Die "
                  "aktuelle Datenschutzerklärung ist stets in der App abrufbar.\n\n"
                  "Stand: Juni 2025",
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
