import 'dart:io';
import 'package:flutter/material.dart';
import 'package:four_secrets_wedding_app/widgets/custom_text_widget.dart';
import 'package:four_secrets_wedding_app/widgets/spacer_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:photo_view/photo_view.dart';

class FilePreviewScreen1 extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final String title;

  const FilePreviewScreen1({
    Key? key,
    required this.fileUrl,
    required this.fileName,
    required this.title,
  }) : super(key: key);

  @override
  State<FilePreviewScreen1> createState() => _FilePreviewScreen1State();
}

class _FilePreviewScreen1State extends State<FilePreviewScreen1> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _localFilePath;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _downloadAndPreviewFile();
  }

  Future<void> _downloadAndPreviewFile() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Download file to temporary directory
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${widget.fileName}');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _localFilePath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Fehler beim Laden der Datei: $e';
      });
    }
  }

  bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  bool _isPdfFile(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  Future<void> _shareFile() async {
    if (_localFilePath != null) {
      try {
        await Share.shareXFiles(
          [XFile(_localFilePath!)],
          text: 'Angebot: ${widget.title} - 4secrets - Wedding Planner',
        );
      } catch (e) {
        _showErrorSnackBar('Fehler beim Teilen der Datei: $e');
      }
    }
  }

  Future<void> _downloadFile() async {
    try {
      if (await canLaunchUrl(Uri.parse(widget.fileUrl))) {
        await launchUrl(
          Uri.parse(widget.fileUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar('Kann Datei nicht öffnen');
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Öffnen der Datei: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_localFilePath == null) return Container();

    if (_isImageFile(widget.fileName)) {
      return _buildImagePreview();
    } else if (_isPdfFile(widget.fileName)) {
      return _buildPdfPreview();
    } else {
      return _buildUnsupportedFilePreview();
    }
  }

  Widget _buildImagePreview() {
    return PhotoView(
      imageProvider: FileImage(File(_localFilePath!)),
      backgroundDecoration: BoxDecoration(color: Colors.white),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      heroAttributes: PhotoViewHeroAttributes(tag: widget.fileName),
    );
  }

  Widget _buildPdfPreview() {
    return SfPdfViewer.file(
      File(_localFilePath!),
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Fehler beim Laden der PDF: ${details.error}';
        });
      },
    );
  }

  Widget _buildUnsupportedFilePreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 80,
            color: Colors.grey[400],
          ),
          SpacerWidget(height: 2),
          CustomTextWidget(
            text: 'Vorschau nicht verfügbar',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          SpacerWidget(height: 1),
          CustomTextWidget(
            text: 'Dateiname: ${widget.fileName}',
            fontSize: 14,
            color: Colors.grey[600],
          ),
          // SpacerWidget(height: 3),
          // ElevatedButton.icon(
          //   onPressed: _downloadFile,
          //   icon: Icon(Icons.download),
          //   label: Text('Datei öffnen'),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Color.fromARGB(255, 107, 69, 106),
          //     foregroundColor: Colors.white,
          //   ),
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: CustomTextWidget(
          text: widget.title,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: Color.fromARGB(255, 107, 69, 106),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareFile,
            icon: Icon(Icons.share),
            tooltip: 'Teilen',
          ),
          // IconButton(
          //   onPressed: _downloadFile,
          //   icon: Icon(Icons.download),
          //   tooltip: 'Herunterladen',
          // ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromARGB(255, 107, 69, 106),
                  ),
                  SpacerWidget(height: 2),
                  CustomTextWidget(
                    text: 'Datei wird geladen...',
                    fontSize: 16,
                  ),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red[400],
                      ),
                      SpacerWidget(height: 2),
                      CustomTextWidget(
                        text: 'Fehler beim Laden',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      SpacerWidget(height: 1),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: CustomTextWidget(
                          text: _errorMessage,
                          fontSize: 14,
                          color: Colors.grey[600],
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SpacerWidget(height: 3),
                      ElevatedButton.icon(
                        onPressed: _downloadAndPreviewFile,
                        icon: Icon(Icons.refresh),
                        label: Text('Erneut versuchen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 107, 69, 106),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      SpacerWidget(height: 1),
                      TextButton.icon(
                        onPressed: _downloadFile,
                        icon: Icon(Icons.open_in_new),
                        label: Text('Extern öffnen'),
                        style: TextButton.styleFrom(
                          foregroundColor: Color.fromARGB(255, 107, 69, 106),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildPreviewContent(),
    );
  }
}
