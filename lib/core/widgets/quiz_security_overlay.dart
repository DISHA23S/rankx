import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Security overlay for quiz screen
/// Shows watermark on web to discourage screenshots
class QuizSecurityOverlay extends StatelessWidget {
  final Widget child;
  final String userIdentifier; // Email or roll number
  final bool showWatermark;
  
  const QuizSecurityOverlay({
    super.key,
    required this.child,
    required this.userIdentifier,
    this.showWatermark = true,
  });
  
  @override
  Widget build(BuildContext context) {
    // Only show watermark on web
    if (!kIsWeb || !showWatermark) {
      return child;
    }
    
    return Stack(
      children: [
        child,
        // Watermark overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: WatermarkPainter(
                userIdentifier: userIdentifier,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for watermark
class WatermarkPainter extends CustomPainter {
  final String userIdentifier;
  
  WatermarkPainter({required this.userIdentifier});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Current time
    final now = DateTime.now();
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    
    // Watermark text
    final watermarkText = '$userIdentifier\n$timeStr';
    
    final textSpan = TextSpan(
      text: watermarkText,
      style: TextStyle(
        color: Colors.grey.withOpacity(0.15),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw watermarks in a grid pattern
    final spacing = 200.0;
    final rows = (size.height / spacing).ceil() + 1;
    final cols = (size.width / spacing).ceil() + 1;
    
    canvas.save();
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * spacing;
        final y = row * spacing;
        
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.3); // Slight rotation
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) {
    return userIdentifier != oldDelegate.userIdentifier;
  }
}

/// Warning dialog for security violations
class QuizSecurityWarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onContinue;
  final bool canDismiss;
  
  const QuizSecurityWarningDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onContinue,
    this.canDismiss = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canDismiss,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onContinue,
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

/// Auto-submit dialog
class QuizAutoSubmitDialog extends StatelessWidget {
  final String message;
  
  const QuizAutoSubmitDialog({
    super.key,
    required this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Quiz Submitted'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
