import 'package:four_secrets_wedding_app/data/parsonal_training_card_items.dart';
import 'package:four_secrets_wedding_app/model/four_secrets_divider.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/menue.dart';

class PersonalTraining extends StatelessWidget {
  PersonalTraining({super.key});
  final List items = PersonalTrainingCardItems.getCardItems();
  final Key key = GlobalKey<MenueState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Menue.getInstance(key),
        appBar: AppBar(
          // automaticallyImplyLeading: false,
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
          title: const Text('Personal Training'),
          backgroundColor: const Color.fromARGB(255, 107, 69, 106),
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.2,
              image: AssetImage(
                  "assets/images/background/personal_training_back.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: ListView(
            physics: ClampingScrollPhysics(),
            children: [
              ListView.builder(
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
                  "Hi, mein Name ist Phillip Schmitt.\n\n"
                  "Als zertifizierter Personal Trainer mit A-Lizenz sowie Ausbildungen in "
                  "Rehabilitationstraining und Ernährungsberatung entwickle ich maßgeschneiderte Trainingspläne, "
                  "die mühelos in deinen Alltag integriert werden können. "
                  "Speziell für deinen besonderen Tag habe ich Hochzeitspakete zusammengestellt, "
                  "um dich sowohl körperlich als auch mental strahlen zu lassen.\n\n"
                  "Jeder Plan wird individuell auf deine Ziele zugeschnitten und problemlos "
                  "in deinen Tagesablauf integriert. Keine Diäten oder Hungern – stattdessen "
                  "erwartet dich ein bewusst gestalteter Ernährungsplan in Kombination mit effektivem Training, "
                  "um dich optimal auf den Hochzeitstag vorzubereiten. "
                  "Ich freue mich darauf, dich kennenzulernen!",
                  maxLines: 10,
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
    );
  }
}
