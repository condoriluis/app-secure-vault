import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanned = true);
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          _buildOverlay(context, primaryColor),
          _buildTopBar(context),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, Color primaryColor) {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: primaryColor, width: 2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                _ScannerLine(color: primaryColor),
                _buildCorners(primaryColor),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.7,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'Alinea el código QR dentro del recuadro',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorners(Color color) {
    const double size = 30;
    const double width = 4;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: _CornerBorder(
            color: color,
            size: size,
            width: width,
            isTop: true,
            isLeft: true,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _CornerBorder(
            color: color,
            size: size,
            width: width,
            isTop: true,
            isLeft: false,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _CornerBorder(
            color: color,
            size: size,
            width: width,
            isTop: false,
            isLeft: true,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _CornerBorder(
            color: color,
            size: size,
            width: width,
            isTop: false,
            isLeft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Escanear 2FA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer for balance
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.flashlight_on_rounded,
            onPressed: () => controller.toggleTorch(),
          ),
          const SizedBox(width: 30),
          _buildControlButton(
            icon: Icons.flip_camera_ios_rounded,
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}

class _CornerBorder extends StatelessWidget {
  final Color color;
  final double size;
  final double width;
  final bool isTop;
  final bool isLeft;

  const _CornerBorder({
    required this.color,
    required this.size,
    required this.width,
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: width) : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: color, width: width)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: color, width: width)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: color, width: width)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _ScannerLine extends StatefulWidget {
  final Color color;
  const _ScannerLine({required this.color});

  @override
  State<_ScannerLine> createState() => _ScannerLineState();
}

class _ScannerLineState extends State<_ScannerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _controller.value * 240,
          left: 10,
          right: 10,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0),
                  widget.color,
                  widget.color.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
