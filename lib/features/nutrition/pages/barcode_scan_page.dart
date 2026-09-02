import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../models/meal_entry.dart';
import '../providers/nutrition_providers.dart';
import '../services/open_food_facts_service.dart';
import 'custom_food_form_page.dart';
import 'food_search_page.dart';
import 'serving_confirm_page.dart';

enum _ScanStatus { scanning, lookingUp, notFound, error }

class BarcodeScanPage extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime? initialDate;

  const BarcodeScanPage({
    super.key,
    required this.mealType,
    this.initialDate,
  });

  @override
  ConsumerState<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends ConsumerState<BarcodeScanPage> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  _ScanStatus _status = _ScanStatus.scanning;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_status != _ScanStatus.scanning) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    await _controller.stop();
    setState(() => _status = _ScanStatus.lookingUp);

    try {
      final food = await ref
          .read(foodDatabaseServiceProvider)
          .getFoodByBarcode(code);
      if (!mounted) return;
      if (food == null) {
        setState(() => _status = _ScanStatus.notFound);
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => ServingConfirmPage(
                food: food,
                mealType: widget.mealType,
                sourceOverride: MealEntrySource.barcode,
                initialDate: widget.initialDate,
              ),
        ),
      );
    } on FoodSearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _retry() async {
    setState(() => _status = _ScanStatus.scanning);
    await _controller.start();
  }

  void _searchInstead() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => FoodSearchPage(
              mealType: widget.mealType,
              initialDate: widget.initialDate,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder:
                (context, error) => _StatusOverlay(
                  icon: Icons.camera_alt_outlined,
                  message: error.errorCode.message,
                  actions: [
                    FilledButton(onPressed: _retry, child: const Text('Retry')),
                    TextButton(
                      onPressed: _searchInstead,
                      child: const Text('Search instead'),
                    ),
                  ],
                ),
          ),
          if (_status == _ScanStatus.scanning)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Point your camera at a barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _searchInstead,
                      child: const Text("Can't scan? Search instead"),
                    ),
                  ],
                ),
              ),
            ),
          if (_status == _ScanStatus.lookingUp)
            const _StatusOverlay(
              icon: null,
              loading: true,
              message: 'Looking up product…',
              actions: [],
            ),
          if (_status == _ScanStatus.notFound)
            _StatusOverlay(
              icon: Icons.search_off,
              message: "We couldn't find this product in Open Food Facts.",
              actions: [
                FilledButton(onPressed: _retry, child: const Text('Try again')),
                TextButton(
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomFoodFormPage(),
                        ),
                      ),
                  child: const Text('Create custom food'),
                ),
              ],
            ),
          if (_status == _ScanStatus.error)
            _StatusOverlay(
              icon: Icons.error_outline,
              message: _errorMessage ?? 'Something went wrong.',
              actions: [
                FilledButton(onPressed: _retry, child: const Text('Retry')),
                TextButton(
                  onPressed: _searchInstead,
                  child: const Text('Search instead'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  final IconData? icon;
  final String message;
  final List<Widget> actions;
  final bool loading;

  const _StatusOverlay({
    required this.icon,
    required this.message,
    required this.actions,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator(color: Colors.white)
              else if (icon != null)
                Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
