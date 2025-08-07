// ignore: must_be_immutable
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/models/wedding_day_schedule_model.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:see_more/see_more_widget.dart';

// ignore: must_be_immutable
class SlidableItemWidget extends StatefulWidget {
  GoogleMapController? mapController;
  final WeddingDayScheduleModel item;
  final int index;
  final double screenWidth;
  final Future<void> Function()? onShare;
  final void Function()? onEdit;
  final Future<void> Function()? onDelete;
  final bool isDeleting;
  final Future<void> Function()? onReload;

  SlidableItemWidget({
    Key? key,
    this.mapController,
    required this.item,
    required this.index,
    required this.screenWidth,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.isDeleting = false,
    this.onReload,
  }) : super(key: key);

  @override
  _SwipeableItemWidgetState createState() => _SwipeableItemWidgetState();
}

class _SwipeableItemWidgetState extends State<SlidableItemWidget> {
  GoogleMapController? mapController;
  bool _isMapLoading = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.screenWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            .copyWith(right: 4),
        title: Row(
          spacing: 6,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.clock, size: 16),
                    const SizedBox(width: 4),
                    CustomTextWidget(
                      text:
                          "${widget.item.time.hour.toString().padLeft(2, '0')}:${widget.item.time.minute.toString().padLeft(2, '0')} "
                          "${widget.item.time.hour >= 12 ? 'Uhr' : 'Uhr'}",
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                  width: 16,
                  child: VerticalDivider(
                    thickness: 2,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.calendar,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    CustomTextWidget(
                      text:
                          "${widget.item.time.day.toString().padLeft(2, '0')},${widget.item.time.month.toString().padLeft(2, '0')},${widget.item.time.year}",
                      fontSize: 12,
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                InkWell(
                  onTap: widget.onShare,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      FontAwesomeIcons.share,
                      size: 20,
                      color: const Color.fromARGB(255, 107, 69, 106),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: widget.onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      FontAwesomeIcons.penToSquare,
                      size: 20,
                      color: const Color.fromARGB(255, 107, 69, 106),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: OutlineInputBorder(borderSide: BorderSide.none),
        childrenPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        children: [
          CustomTextWidget(
            text: widget.item.title,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          SpacerWidget(height: 3),
          if (widget.item.responsiblePerson.isNotEmpty) ...[
            CustomTextWidget(
              text: "Zuständige Person ",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            CustomTextWidget(text: widget.item.responsiblePerson, fontSize: 14),
            SpacerWidget(height: 3),
          ],

          CustomTextWidget(
            text: "Notizen",
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          SpacerWidget(height: 1),
          SeeMoreWidget(
            widget.item.notes,
            textStyle: TextStyle(fontSize: 14, color: Colors.black),
            trimLength: 90,
            seeMoreStyle: TextStyle(
                color: Color.fromARGB(255, 107, 69, 106),
                fontWeight: FontWeight.bold),
            seeLessStyle: TextStyle(
                color: Color.fromARGB(255, 107, 69, 106),
                fontWeight: FontWeight.bold),
          ),
          SpacerWidget(height: 3),
          // if(widget.)
          // SpacerWidget(height: 3),
          if (widget.item.reminderTime != null)
            CustomTextWidget(
              text: "Erinnerung",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          SpacerWidget(height: 2),
          if (widget.item.reminderTime != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(FontAwesomeIcons.clock, size: 18),
                CustomTextWidget(
                  text:
                      " ${widget.item.reminderTime!.hour.toString().padLeft(2, '0')}:${widget.item.reminderTime!.minute.toString().padLeft(2, '0')} Uhr",
                  fontSize: 14,
                ),
                SizedBox(
                  height: 15,
                  child: VerticalDivider(
                    thickness: 2,
                    color: Colors.black,
                  ),
                ),
                Icon(
                  FontAwesomeIcons.calendar,
                  size: 18,
                ),
                CustomTextWidget(
                  text:
                      " ${widget.item.reminderTime!.day.toString().padLeft(2, '0')}-${widget.item.reminderTime!.month.toString().padLeft(2, '0')}-${widget.item.reminderTime!.year}",
                  fontSize: 14,
                ),
              ],
            ),

          if (widget.item.reminderTime != null) SpacerWidget(height: 3),
          if (widget.item.lat != 0 && widget.item.long != 0) ...[
            // if (widget.item.reminderTime != null) SpacerWidget(height: 3),
            CustomTextWidget(
              text: "Ort",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            // SpacerWidget(height: 3),

            //   text: "Ort",
            //   fontSize: 14,
            //   fontWeight: FontWeight.bold,
            // ),
            SpacerWidget(height: 2),

            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Container(
                    height: context.screenHeight * 0.2,
                    width: context.screenWidth,
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: Colors.grey,
                          blurRadius: 10,
                          offset: Offset(10, 0))
                    ]),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.item.lat, widget.item.long),
                        zoom: 14.0,
                      ),
                      onMapCreated: (controller) {
                        mapController = controller;
                        setState(() {
                          _isMapLoading = false;
                        });
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId("selected-location"),
                          position: LatLng(widget.item.lat, widget.item.long),
                        ),
                      },
                    ),
                  ),
                  if (_isMapLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.7),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
            SpacerWidget(height: 4),
          ],
          // CustomTextWidg

          CustomButtonWidget(
            width: widget.screenWidth,
            color: Colors.red.shade300,
            textColor: Colors.white,
            text: "Löschen",
            onPressed: widget.onDelete,
          ),
          SpacerWidget(height: 1),
        ],
      ),
    );
  }
}
