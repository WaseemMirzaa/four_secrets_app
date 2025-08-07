// ignore: must_be_immutable
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:four_secrets_wedding_app/constants/app_constants.dart';
import 'package:four_secrets_wedding_app/extension.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/models/wedding_day_schedule_model1.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/services/file_upload_service1.dart';
import 'package:four_secrets_wedding_app/screens/newfeature1/screens/file_preview_screen1.dart';
import 'package:four_secrets_wedding_app/widgets/custom_button_widget.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
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

  // Helper method to launch URLs with error handling
  Future<void> _launchUrl(String url,
      {LaunchMode mode = LaunchMode.externalApplication}) async {
    try {
      print('🔗 Attempting to launch URL: $url');
      final uri = Uri.parse(url);

      // First try with the specified mode
      if (await canLaunchUrl(uri)) {
        try {
          print('✅ URL can be launched, trying with mode: $mode');
          await launchUrl(uri, mode: mode);
          print('✅ Successfully launched URL with mode: $mode');
          return;
        } catch (e) {
          print('❌ Failed with mode $mode: $e');
          // If external application fails, try platform default
          if (mode != LaunchMode.platformDefault) {
            try {
              print('🔄 Retrying with platform default mode');
              await launchUrl(uri, mode: LaunchMode.platformDefault);
              print('✅ Successfully launched URL with platform default');
              return;
            } catch (e2) {
              print('❌ Failed with platform default: $e2');
            }
          }
        }
      } else {
        print('❌ canLaunchUrl returned false for: $url');
      }

      // If all else fails, try in-app web view for web URLs
      if (url.startsWith('http')) {
        try {
          print('🔄 Trying in-app web view as last resort');
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          print('✅ Successfully launched URL with in-app web view');
          return;
        } catch (e) {
          print('❌ Failed with in-app web view: $e');
        }
      }

      print('❌ All launch attempts failed for URL: $url');
      _showErrorMessage('Kann URL nicht öffnen: $url');
    } catch (e) {
      print('❌ Exception in _launchUrl: $e');
      _showErrorMessage('Fehler beim Öffnen der URL: $e');
    }
  }

  // Helper method to launch email with Gmail app priority
  Future<void> _launchEmail(String email) async {
    try {
      print('📧 Attempting to launch email: $email');

      // Try multiple Gmail app schemes for Android (clean compose with only recipient)
      final gmailSchemes = [
        'googlegmail://co?to=$email', // Primary Gmail scheme - clean compose
        'gmail://co?to=$email', // Alternative Gmail scheme - clean compose
        'intent://compose?to=$email#Intent;scheme=mailto;package=com.google.android.gm;end', // Android intent - clean compose
      ];

      for (String scheme in gmailSchemes) {
        try {
          final gmailAppUri = Uri.parse(scheme);
          print('📱 Trying Gmail scheme: $scheme');

          if (await canLaunchUrl(gmailAppUri)) {
            print('✅ Gmail app available with scheme: $scheme');
            await launchUrl(gmailAppUri, mode: LaunchMode.externalApplication);
            print('✅ Successfully launched Gmail app');
            return;
          } else {
            print('❌ Gmail scheme not available: $scheme');
          }
        } catch (e) {
          print('❌ Gmail scheme failed: $scheme - $e');
        }
      }

      // Try Android-specific Gmail package intent (clean compose with only recipient)
      try {
        final androidGmailIntent =
            'intent://compose?to=$email#Intent;scheme=mailto;package=com.google.android.gm;end';
        final intentUri = Uri.parse(androidGmailIntent);
        print(
            '📱 Trying Android Gmail intent (clean compose): $androidGmailIntent');

        if (await canLaunchUrl(intentUri)) {
          print('✅ Android Gmail intent available');
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
          print(
              '✅ Successfully launched Gmail via Android intent (clean compose)');
          return;
        }
      } catch (e) {
        print('❌ Android Gmail intent failed: $e');
      }

      // Try standard mailto with external application mode first (forces app picker)
      final uri = Uri.parse('mailto:$email');

      if (await canLaunchUrl(uri)) {
        try {
          print(
              '✅ Email URI can be launched, trying external application mode');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('✅ Successfully launched email with external application');
          return;
        } catch (e) {
          print('❌ Failed with external application: $e');

          // Try platform default as fallback
          try {
            print('🔄 Retrying with platform default mode');
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            print('✅ Successfully launched email with platform default');
            return;
          } catch (e2) {
            print('❌ Failed with platform default: $e2');
          }
        }
      } else {
        print('❌ canLaunchUrl returned false for email: $email');
      }

      // If mailto fails, try Gmail web interface as fallback (clean compose)
      print('🔄 Trying Gmail web interface as fallback');
      try {
        final gmailWebUrl =
            'https://mail.google.com/mail/?view=cm&fs=1&to=$email';
        print('🌐 Trying Gmail web interface (clean compose): $gmailWebUrl');
        await _launchUrl(gmailWebUrl, mode: LaunchMode.inAppWebView);
        print('✅ Successfully opened Gmail web interface (clean compose)');
        return;
      } catch (e) {
        print('❌ Gmail web interface failed: $e');
      }

      print('❌ All email launch attempts failed');
      _showErrorMessage('Keine E-Mail-App gefunden. E-Mail-Adresse: $email');
    } catch (e) {
      print('❌ Exception in _launchEmail: $e');
      _showErrorMessage('Fehler beim Öffnen der E-Mail: $e');
    }
  }

  // Helper method to launch phone call
  Future<void> _launchPhone(String phone) async {
    try {
      print('📞 Attempting to launch phone: $phone');
      final uri = Uri.parse('tel:$phone');

      // First try with platform default (best for phone calls)
      if (await canLaunchUrl(uri)) {
        try {
          print('✅ Phone URI can be launched, trying platform default');
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          print('✅ Successfully launched phone with platform default');
          return;
        } catch (e) {
          print('❌ Failed with platform default: $e');

          // Try external application mode
          try {
            print('🔄 Retrying with external application mode');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            print('✅ Successfully launched phone with external application');
            return;
          } catch (e2) {
            print('❌ Failed with external application: $e2');
          }
        }
      } else {
        print('❌ canLaunchUrl returned false for phone: $phone');
      }

      print('❌ All phone launch attempts failed');
      _showErrorMessage('Keine Telefon-App gefunden. Telefonnummer: $phone');
    } catch (e) {
      print('❌ Exception in _launchPhone: $e');
      _showErrorMessage('Fehler beim Öffnen der Telefon-App: $e');
    }
  }

  // Helper method to format Instagram URL
  String _formatInstagramUrl(String instagram) {
    String url = instagram.trim();

    // If it's already a full URL, clean it up
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Remove any www. from Instagram URLs as it's not needed
      url = url.replaceAll('www.', '');
      // Ensure it's pointing to instagram.com
      if (!url.contains('instagram.com')) {
        // Extract the username part and rebuild the URL
        String username = url.split('/').last;
        if (username.startsWith('@')) {
          username = username.substring(1);
        }
        return 'https://instagram.com/$username';
      }
      return url;
    }

    // Handle @username format
    if (url.startsWith('@')) {
      return 'https://instagram.com/${url.substring(1)}';
    }

    // Handle plain username
    return 'https://instagram.com/$url';
  }

  // Helper method to format website URL
  String _formatWebsiteUrl(String website) {
    String url = website.trim();

    // If it already has a protocol, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Add https:// if no protocol is present
    return 'https://$url';
  }

  // Helper method to launch Instagram URLs with app preference
  Future<void> _launchInstagram(String instagram) async {
    print('📱 Launching Instagram for: $instagram');
    String webUrl = _formatInstagramUrl(instagram);
    String username = webUrl.split('/').last;

    print('🔗 Formatted web URL: $webUrl');
    print('👤 Extracted username: $username');

    try {
      // Try Instagram app first (instagram://user?username=)
      final appUri = Uri.parse('instagram://user?username=$username');
      print('📱 Trying Instagram app with URI: $appUri');

      if (await canLaunchUrl(appUri)) {
        print('✅ Instagram app available, launching...');
        await launchUrl(appUri);
        print('✅ Successfully launched Instagram app');
        return;
      } else {
        print('❌ Instagram app not available');
      }
    } catch (e) {
      print('❌ Instagram app launch failed: $e');
    }

    // Fall back to web browser
    print('🌐 Falling back to web browser');
    await _launchUrl(webUrl);
  }

  // Helper method to copy text to clipboard
  Future<void> _copyToClipboard(String text, String type) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      SnackBarHelper.showSuccessSnackBar(
          context, '$type in Zwischenablage kopiert: $text');
    } catch (e) {
      _showErrorMessage('Fehler beim Kopieren: $e');
    }
  }

  // Helper method to show error messages
  void _showErrorMessage(String message) {
    SnackBarHelper.showErrorSnackBar(context, message);
  }

  // Helper method to open file preview
  void _openFilePreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilePreviewScreen1(
          fileUrl: widget.item.angebotFileUrl,
          fileName: widget.item.angebotFileName,
          title: widget.item.title,
        ),
      ),
    );
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
          Row(
            children: [
              CustomTextWidget(
                text: '${AppConstants.kategorie}: ',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              SpacerWidget(height: 1),
              CustomTextWidget(text: widget.item.title, fontSize: 14),
            ],
          ),

          if (widget.item.reminderTime != null) SpacerWidget(height: 3),
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
                  child: GestureDetector(
                    onLongPress: () => _copyToClipboard(
                        widget.item.telefonnummer, 'Telefonnummer'),
                    child: CustomTextWidget(
                        text: widget.item.telefonnummer, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () => _launchPhone(widget.item.telefonnummer),
                  onLongPress: () => _copyToClipboard(
                      widget.item.telefonnummer, 'Telefonnummer'),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.phone,
                        color: Color.fromARGB(255, 107, 69, 106), size: 20),
                  ),
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
                  child: GestureDetector(
                    onLongPress: () =>
                        _copyToClipboard(widget.item.email, 'E-Mail'),
                    child:
                        CustomTextWidget(text: widget.item.email, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () => _launchEmail(widget.item.email),
                  onLongPress: () =>
                      _copyToClipboard(widget.item.email, 'E-Mail'),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.email,
                        color: Color.fromARGB(255, 107, 69, 106), size: 20),
                  ),
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
                  onPressed: () =>
                      _launchUrl(_formatWebsiteUrl(widget.item.homepage)),
                  icon: Icon(Icons.language,
                      color: Color.fromARGB(255, 107, 69, 106), size: 20),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Website öffnen',
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
                  onPressed: () => _launchInstagram(widget.item.instagram),
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
              text: "Adressdetails",
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
          // SpacerWidget(height: 4),
          if (widget.item.lat != 0 && widget.item.long != 0) ...[
            // SpacerWidget(height: 3),
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
          ],
          // CustomTextWidget(
          //   text: "Zuständige Person ",
          //   fontSize: 14,
          //   fontWeight: FontWeight.bold,
          // ),
          // SpacerWidget(height: 1),
          // CustomTextWidget(text: widget.item.responsiblePerson, fontSize: 14),
          // SpacerWidget(height: 3),
          // SpacerWidget(height: 4),
          if (widget.item.notes.isNotEmpty) ...[
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
          ],

          // Angebot Text
          if (widget.item.angebotText.isNotEmpty) ...[
            CustomTextWidget(
              text: "Angebot",
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
              text: "Angebotsdatei",
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextWidget(
                          text: widget.item.angebotFileName,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: 2),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _openFilePreview,
                        icon: Icon(Icons.visibility,
                            color: Color.fromARGB(255, 107, 69, 106), size: 20),
                        padding: EdgeInsets.all(4),
                        constraints:
                            BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Vorschau',
                      ),
                      // IconButton(
                      //   onPressed: () => _launchUrl(widget.item.angebotFileUrl),
                      //   icon: Icon(Icons.download,
                      //       color: Color.fromARGB(255, 107, 69, 106), size: 20),
                      //   padding: EdgeInsets.all(4),
                      //   constraints:
                      //       BoxConstraints(minWidth: 32, minHeight: 32),
                      //   tooltip: 'Herunterladen',
                      // ),
                    ],
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
                  const SizedBox(width: 4),
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
                const SizedBox(width: 8),
                CustomTextWidget(
                  text:
                      "${widget.item.probetermin!.day.toString().padLeft(2, '0')}.${widget.item.probetermin!.month.toString().padLeft(2, '0')}.${widget.item.probetermin!.year}",
                  fontSize: 14,
                ),
                const SizedBox(width: 16),
                Icon(FontAwesomeIcons.clock,
                    size: 16, color: Color.fromARGB(255, 107, 69, 106)),
                const SizedBox(width: 8),
                CustomTextWidget(
                  text:
                      "${widget.item.probetermin!.hour.toString().padLeft(2, '0')}:${widget.item.probetermin!.minute.toString().padLeft(2, '0')} Uhr",
                  fontSize: 14,
                ),
              ],
            ),
            SpacerWidget(height: 3),
          ],

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
                      " ${widget.item.reminderTime!.hour.toString().padLeft(2, '0')}:${widget.item.reminderTime!.minute.toString().padLeft(2, '0')} "
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
                      " ${widget.item.reminderTime!.day.toString().padLeft(2, '0')},${widget.item.reminderTime!.month.toString().padLeft(2, '0')},${widget.item.reminderTime!.year}",
                  fontSize: 14,
                ),
              ],
            ),
          SpacerWidget(height: 3),

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
