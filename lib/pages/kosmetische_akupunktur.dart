import 'package:four_secrets_wedding_app/data/kosmetische_akupunktur_card_items.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

// ignore: must_be_immutable
class KosmetischeAkupunktur extends StatelessWidget {
  KosmetischeAkupunktur({super.key});
  final List items = KosmetischeAkupunkturCardItems.getCardItems();
  final Key key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          // automaticallyImplyLeading: false,
          title: const Text('Kosmetische Akupunktur'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.2,
              image: AssetImage(
                  "assets/images/background/kosmetische_akupunktur_back.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            child: ListView(
              children: [
                ListView.builder(
                  physics: ClampingScrollPhysics(),
                  primary: false, // disable scrolling
                  shrinkWrap: true, // limit height
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return items[index];
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                ),
                FourSecretsDivider(),
                Container(
                  margin: EdgeInsets.only(bottom: 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ExpandableText(
                    "Willkommen in der Welt der Schönheit und Entspannung!\n\n"
                    "Ich bin Regina, deine Heilpraktikerin für Traditionelle Chinesische Medizin (TCM). "
                    "In meiner Praxis liegt der Fokus auf der kosmetischen Akupunktur, "
                    "einer einzigartigen Methode, die nicht nur die äußere Schönheit fördert, "
                    "sondern auch die natürliche Ausstrahlung von innen heraus betont. "
                    "Durch die Akupunktur werden energetische Blockaden gelöst und die Haut revitalisiert. "
                    "Der ganzheitliche Aspekt meiner Behandlungen erstreckt sich über die äußere Erscheinung hinaus – "
                    "ich lege großen Wert auf Entspannung und innere Harmonie.\n\n"
                    "Lass uns gemeinsam auf eine besondere Reise begeben, mit dem exklusiven Hochzeitspaket, "
                    "das dafür sorgt, dass du an deinem großen Tag in voller Power, "
                    "Frische und Anmut erstrahlst.",
                    maxLines: 12,
                    expandText: 'show more',
                    collapseText: 'show less',
                    collapseOnTextTap: true,
                    linkStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 107, 69, 106),
                    ),
                  ),
                ),
                FourSecretsDivider(),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
