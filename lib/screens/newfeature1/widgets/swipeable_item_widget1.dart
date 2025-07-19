// ignore: must_be_immutable
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/file_upload_service1.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:see_more/see_more_widget.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class SlidableItemWidget1 extends StatefulWidget {
  GoogleMapController? mapController;
  final WeddingDayScheduleModel1 item;
  final int index;
  final double screenWidth;
  final Future<void> Function()? onShare;
  final void Function()? onEdit;
  final Future<void> Function()? onDelete;
  final bool isDeleting;
  final Future<void> Function()? onReload;

  SlidableItemWidget1({
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
  _SwipeableItemWidget1State createState() => _SwipeableItemWidget1State();
}

class _SwipeableItemWidget1State extends State<SlidableItemWidget1> {
  GoogleMapController? mapController;
  bool _isMapLoading = true;

  // Helper method to get payment status color
  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'bezahlt':
        return Colors.green;
      case 'teilweise bezahlt':
        return Colors.orange;
      case 'unbezahlt':
      default:
        return Colors.red;
    }
  }

  // Helper method to get payment status icon
  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'bezahlt':
        return Icons.check_circle;
      case 'teilweise bezahlt':
        return Icons.schedule;
      case 'unbezahlt':
      default:
        return Icons.cancel;
    }
  }

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
                    SizedBox(width: 4),
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
                    SizedBox(width: 4),
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
                SizedBox(width: 4),
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
          CustomTextWidget(
            text: "Verantwortliche Person ",
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          SpacerWidget(height: 1),
          CustomTextWidget(text: widget.item.responsiblePerson, fontSize: 14),
          SpacerWidget(height: 3),
          SpacerWidget(height: 4),
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
          SpacerWidget(height: 3),
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
                      "${widget.item.reminderTime!.hour.toString().padLeft(2, '0')}:${widget.item.reminderTime!.minute.toString().padLeft(2, '0')} "
                      "${widget.item.reminderTime!.hour >= 12 ? 'Uhr' : 'Uhr'}",
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
                      "${widget.item.reminderTime!.day.toString().padLeft(2, '0')}-${widget.item.reminderTime!.month.toString().padLeft(2, '0')}-${widget.item.reminderTime!.year}",
                  fontSize: 14,
                ),
              ],
            ),
          SpacerWidget(height: 3),
          CustomTextWidget(
            text: "Ort",
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          SpacerWidget(height: 3),
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
                      color: Colors.white.withValues(alpha: 0.7),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          SpacerWidget(height: 4),

          // Dienstleistername
          if (widget.item.dienstleistername.isNotEmpty) ...[
            CustomTextWidget(
              text: "Dienstleistername",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            CustomTextWidget(text: widget.item.dienstleistername, fontSize: 14),
            SpacerWidget(height: 3),
          ],

          // Kontaktperson
          if (widget.item.kontaktperson.isNotEmpty) ...[
            CustomTextWidget(
              text: "Kontaktperson",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            CustomTextWidget(text: widget.item.kontaktperson, fontSize: 14),
            SpacerWidget(height: 3),
          ],

          // Telefonnummer with call functionality
          if (widget.item.telefonnummer.isNotEmpty) ...[
            CustomTextWidget(
              text: "Telefonnummer",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            Row(
              children: [
                Expanded(
                  child: CustomTextWidget(
                      text: widget.item.telefonnummer, fontSize: 14),
                ),
                IconButton(
                  onPressed: () async {
                    final uri = Uri.parse('tel:${widget.item.telefonnummer}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: Icon(Icons.phone,
                      color: Color.fromARGB(255, 107, 69, 106), size: 20),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            SpacerWidget(height: 3),
          ],

          // E-Mail with email functionality
          if (widget.item.email.isNotEmpty) ...[
            CustomTextWidget(
              text: "E-Mail",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            Row(
              children: [
                Expanded(
                  child:
                      CustomTextWidget(text: widget.item.email, fontSize: 14),
                ),
                IconButton(
                  onPressed: () async {
                    final uri = Uri.parse('mailto:${widget.item.email}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: Icon(Icons.email,
                      color: Color.fromARGB(255, 107, 69, 106), size: 20),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            SpacerWidget(height: 3),
          ],

          // Homepage with web functionality
          if (widget.item.homepage.isNotEmpty) ...[
            CustomTextWidget(
              text: "Homepage",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            Row(
              children: [
                Expanded(
                  child: CustomTextWidget(
                      text: widget.item.homepage, fontSize: 14),
                ),
                IconButton(
                  onPressed: () async {
                    String url = widget.item.homepage;
                    if (!url.startsWith('http://') &&
                        !url.startsWith('https://')) {
                      url = 'https://$url';
                    }
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: Icon(Icons.open_in_browser,
                      color: Color.fromARGB(255, 107, 69, 106), size: 20),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            SpacerWidget(height: 3),
          ],

          // Instagram
          if (widget.item.instagram.isNotEmpty) ...[
            CustomTextWidget(
              text: "Instagram",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            Row(
              children: [
                Expanded(
                  child: CustomTextWidget(
                      text: widget.item.instagram, fontSize: 14),
                ),
                IconButton(
                  onPressed: () async {
                    String url = widget.item.instagram;
                    if (!url.startsWith('http://') &&
                        !url.startsWith('https://')) {
                      if (url.startsWith('@')) {
                        url = 'https://instagram.com/${url.substring(1)}';
                      } else {
                        url = 'https://instagram.com/$url';
                      }
                    }
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: Icon(FontAwesomeIcons.instagram,
                      color: Color.fromARGB(255, 107, 69, 106), size: 20),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            SpacerWidget(height: 3),
          ],

          // Address Details
          if (widget.item.addressDetails.isNotEmpty) ...[
            CustomTextWidget(
              text: "Adresse Details",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            SeeMoreWidget(
              widget.item.addressDetails,
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
          ],

          // Angebot Text
          if (widget.item.angebotText.isNotEmpty) ...[
            CustomTextWidget(
              text: "Angebot Beschreibung",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            SeeMoreWidget(
              widget.item.angebotText,
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
          ],

          // Angebot File
          if (widget.item.angebotFileUrl.isNotEmpty &&
              widget.item.angebotFileName.isNotEmpty) ...[
            CustomTextWidget(
              text: "Angebot Datei",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    FileUploadService1.getFileIcon(widget.item.angebotFileName),
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextWidget(
                          text: widget.item.angebotFileName,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        SizedBox(height: 2),
                        Text(
                          FileUploadService1.isImageFile(
                                  widget.item.angebotFileName)
                              ? 'Bild'
                              : FileUploadService1.isPdfFile(
                                      widget.item.angebotFileName)
                                  ? 'PDF Dokument'
                                  : 'Datei',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final uri = Uri.parse(widget.item.angebotFileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: Icon(Icons.open_in_new,
                        color: Color.fromARGB(255, 107, 69, 106), size: 20),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            SpacerWidget(height: 3),
          ],

          // Zahlungsstatus
          if (widget.item.zahlungsstatus.isNotEmpty) ...[
            CustomTextWidget(
              text: "Zahlungsstatus",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPaymentStatusColor(widget.item.zahlungsstatus),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPaymentStatusIcon(widget.item.zahlungsstatus),
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  CustomTextWidget(
                    text: widget.item.zahlungsstatus,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            SpacerWidget(height: 3),
          ],

          // Probetermin
          if (widget.item.probetermin != null) ...[
            CustomTextWidget(
              text: "Probetermin",
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SpacerWidget(height: 1),
            Row(
              children: [
                Icon(FontAwesomeIcons.calendar,
                    size: 16, color: Color.fromARGB(255, 107, 69, 106)),
                SizedBox(width: 8),
                CustomTextWidget(
                  text:
                      "${widget.item.probetermin!.day.toString().padLeft(2, '0')}.${widget.item.probetermin!.month.toString().padLeft(2, '0')}.${widget.item.probetermin!.year}",
                  fontSize: 14,
                ),
                SizedBox(width: 16),
                Icon(FontAwesomeIcons.clock,
                    size: 16, color: Color.fromARGB(255, 107, 69, 106)),
                SizedBox(width: 8),
                CustomTextWidget(
                  text:
                      "${widget.item.probetermin!.hour.toString().padLeft(2, '0')}:${widget.item.probetermin!.minute.toString().padLeft(2, '0')} Uhr",
                  fontSize: 14,
                ),
              ],
            ),
            SpacerWidget(height: 3),
          ],

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
