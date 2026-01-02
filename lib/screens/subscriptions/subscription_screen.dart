import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_secrets_wedding_app/services/subscription/revenuecat_purchase_exception.dart';
import 'package:four_secrets_wedding_app/utils/snackbar_helper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/routes.dart';
import '../../services/subscription/revenuecat_subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final RevenueCatService _revenueCatService = RevenueCatService();
  Offerings? _offerings;
  bool _isLoading = true;
  bool _purchasing = false;
  bool _billingUnavailable = false;
  String _selectedPlan = 'monthly'; // 'monthly' or 'yearly'

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await _revenueCatService.getOfferings();
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      if (e.code == 'PurchaseNotAllowedError') {
        setState(() {
          _isLoading = false;
          _billingUnavailable = true;
        });
        SnackBarHelper.showErrorSnackBar(
          context,
          'In-App-Käufe sind auf diesem Gerät nicht verfügbar. Bitte verwenden Sie ein anderes Gerät.',
        );
      } else {
        setState(() => _isLoading = false);
        SnackBarHelper.showErrorSnackBar(
          context,
          'Angebote konnten nicht geladen werden. Bitte versuchen Sie es später erneut.',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarHelper.showErrorSnackBar(
        context,
        'Ein unerwarteter Fehler ist aufgetreten.',
      );
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _purchasing = true);

    try {
      final result = await _revenueCatService.purchasePackage(package);

      if (result.info != null) {
        // Then navigate back or to home

        SnackBarHelper.showSuccessSnackBar(
          context,
          'Vielen Dank für Ihren Kauf! Eine Bestätigungs-E-Mail wurde gesendet.',
        );

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteManager.homePage, (route) => false);
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Vielen Dank für Ihren Kauf! Genießen Sie die App.',
        );
      }
    } on PurchaseException catch (e) {
      SnackBarHelper.showErrorSnackBar(context, e.message);
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        context,
        'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.',
      );
    } finally {
      setState(() => _purchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      await _revenueCatService.restorePurchases();

      final hasActiveSub = await _revenueCatService.hasActiveSubscription();

      if (hasActiveSub) {
        SnackBarHelper.showSuccessSnackBar(
          context,
          'Käufe wurden erfolgreich wiederhergestellt.',
        );
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Es wurden keine aktiven Abos zum Wiederherstellen gefunden.',
        );
      }
    } catch (e) {
      SnackBarHelper.showErrorSnackBar(
        context,
        'Käufe konnten nicht wiederhergestellt werden. Bitte versuchen Sie es erneut.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Extract free trial information from package
  String _getFreeTrialInfo(Package package) {
    return '7 Tage kostenlos testen';
  }

  String _getPlanLabel(Package package) {
    if (package.storeProduct.identifier.contains("monthly"))
      return "Premium monatlich";
    if (package.storeProduct.identifier.contains("yearly"))
      return "Premium jährlich";
    return package.storeProduct.title;
  }

  // Get the appropriate package based on selected plan
  Package? _getSelectedPackage() {
    if (_offerings?.current?.availablePackages == null) return null;

    return _offerings!.current!.availablePackages.firstWhere((package) {
      final identifier = package.identifier.toLowerCase();
      return _selectedPlan == 'monthly'
          ? identifier.contains('month')
          : identifier.contains('year');
    }, orElse: () => _offerings!.current!.availablePackages.first);
  }

  // Build plan toggle buttons
  Widget _buildPlanToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton('Monatlich', 'monthly'),
          _buildToggleButton('Jährlich', 'yearly'),
        ],
      ),
    );
  }

  String? _getDiscountText(Package yearly, Package monthly) {
    final yearlyPrice = yearly.storeProduct.price;
    final monthlyPrice = monthly.storeProduct.price;

    final monthlyYearCost = monthlyPrice * 12;
    final savings = monthlyYearCost - yearlyPrice;
    if (savings <= 0) return null;

    final discountPercent = (savings / monthlyYearCost * 100).round();

    final priceString = yearly.storeProduct.priceString;
    final currencySymbol = priceString.replaceAll(RegExp(r'[0-9.,\s]'), '');

    return 'Spare $currencySymbol${savings.toStringAsFixed(2)} ($discountPercent%) im Vergleich zum Monatsabo';
  }

  Widget _buildToggleButton(String text, String value) {
    final isSelected = _selectedPlan == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6B456A) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Build subscription card
  Widget _buildSubscriptionCard(Package package) {
    // final price = _selectedPlan == 'yearly' ? '€99.00' : '€11.99';

    final freeTrialInfo = _getFreeTrialInfo(package);
    final isYearly = _selectedPlan == 'yearly';
    // Get formatted price directly from RevenueCat
    final price = package.storeProduct.priceString;
    // Find both yearly & monthly packages for discount calculation
    final yearly = _offerings?.current?.annual;
    final monthly = _offerings?.current?.monthly;

    String? discountText;
    if (isYearly && yearly != null && monthly != null) {
      discountText = _getDiscountText(yearly, monthly);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Free trial badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B456A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              freeTrialInfo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Plan title
          Text(
            _getPlanLabel(package),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // Price
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B456A),
                ),
              ),
              SizedBox(width: 12),
              Text(
                isYearly ? 'pro Jahr' : 'pro Monat',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(width: 12),
            ],
          ),

          const SizedBox(height: 8),
          if (discountText != null)
            Text(
              discountText,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B456A),
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 12),

          // Divider
          const Divider(color: Colors.grey, height: 1),

          const SizedBox(height: 12),

          // Features list
          const Text(
            'Enthaltene Funktionen:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          _buildFeature('Alle 11 Hochzeitsfunktionen frei'),
          _buildFeature('Freunde & Familie einladen'),
          _buildFeature('PDFs & Infos mit Dienstlern teilen'),
          _buildFeature('Unbegrenzte Gästeliste'),
          _buildFeature('Budgetplaner & Kostenübersicht'),

          const SizedBox(height: 8),

          // Purchase button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _purchasing ? null : () => _purchasePackage(package),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B456A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('JETZT KAUFEN'),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'inkl. MwSt., länderabhängig',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF6B456A), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_billingUnavailable) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'In-App-Käufe nicht verfügbar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bitte verwenden Sie ein Gerät mit Google Play Services, um Abonnements zu erwerben.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zurück'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selectedPackage = _getSelectedPackage();

    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient and image
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF6B456A).withOpacity(0.9),
                  const Color(0xFF6B456A).withOpacity(0.7),
                  const Color(0xFF6B456A).withOpacity(0.5),
                ],
              ),
            ),
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/background/location_back.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            RouteManager.homePage,
                            (route) => false,
                          );
                        },
                        child: Text(
                          "überspringen",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  // App Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo/secrets-logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  const Text(
                    '4secrets - Wedding Planner',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Planen Sie Ihre Hochzeit mit unserer Premium-App',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // Plan Toggle
                  _buildPlanToggle(),

                  const SizedBox(height: 20),

                  // Subscription Card
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (selectedPackage != null)
                    _buildSubscriptionCard(selectedPackage)
                  else
                    const Text(
                      'Keine Abonnements verfügbar',
                      style: TextStyle(color: Colors.white),
                    ),

                  const SizedBox(height: 12),

                  // Restore purchases
                  TextButton(
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: const Text(
                      'Käufe wiederherstellen',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Privacy and Terms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final url = Uri.parse(
                            'https://www.4secrets-wedding-planner.de/datenschutz-app/',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: const Text(
                          'Datenschutz',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: () async {
                          final url = Uri.parse(
                            'https://www.4secrets-wedding-planner.de/agb/',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: const Text(
                          'AGB',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Mit dem Kauf stimmen Sie unseren Nutzungsbedingungen und unserer Datenschutzrichtlinie zu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Abos verlängern sich automatisch, wenn sie nicht mind. 24 Std. vorher gekündigt werden. Verwaltung & Kündigung über App Store oder Google Play.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const GlassCard({Key? key, required this.child, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}
