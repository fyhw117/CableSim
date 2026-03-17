import 'package:flutter/material.dart';
import '../models/models.dart';

class CablePainter extends CustomPainter {
  final List<DeviceNode> nodes;
  final List<Cable> cables;
  final String? selectedCableId;

  CablePainter({
    required this.nodes,
    required this.cables,
    this.selectedCableId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var cable in cables) {
      final isSelected = selectedCableId == cable.id;
      final paint = Paint()
        ..color = isSelected ? Colors.blue : cable.type.color
        ..strokeWidth = isSelected ? 8 : 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      Offset startPos;
      if (cable.fromNodeId != null &&
          cable.fromPortId != null &&
          nodes.any((n) => n.id == cable.fromNodeId)) {
        final node = nodes.firstWhere((n) => n.id == cable.fromNodeId);
        final port = node.ports.firstWhere((p) => p.id == cable.fromPortId);
        startPos = node.position + port.relativeCenter;
      } else {
        startPos = cable.dragPos1 ?? const Offset(0, 0);
      }

      Offset endPos;
      if (cable.toNodeId != null &&
          cable.toPortId != null &&
          nodes.any((n) => n.id == cable.toNodeId)) {
        final node = nodes.firstWhere((n) => n.id == cable.toNodeId);
        final port = node.ports.firstWhere((p) => p.id == cable.toPortId);
        endPos = node.position + port.relativeCenter;
      } else {
        endPos = cable.dragPos2 ?? const Offset(0, 0);
      }

      // Add a slight shadow to make cables pop
      canvas.drawLine(
        startPos,
        endPos,
        Paint()
          ..color = Colors.black26
          ..strokeWidth = isSelected ? 10 : 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Draw straight line
      canvas.drawLine(startPos, endPos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CablePainter oldDelegate) {
    return true;
  }
}

class PortShapePainter extends CustomPainter {
  final PortType type;
  final PortGender gender;
  final Color baseColor;

  PortShapePainter({
    required this.type,
    required this.gender,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gender == PortGender.female ? Colors.black87 : Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = gender == PortGender.female
          ? Colors.grey[700]!
          : Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pinPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    if (type == PortType.hdmi) {
      // HDMI: D-shape (Trapezoid-like)
      final path = Path();
      path.moveTo(2, 2);
      path.lineTo(size.width - 2, 2);
      path.lineTo(size.width - 2, size.height - 6);
      path.lineTo(size.width - 6, size.height - 2);
      path.lineTo(6, size.height - 2);
      path.lineTo(2, size.height - 6);
      path.close();

      canvas.drawPath(path, paint);
      canvas.drawPath(path, borderPaint);

      if (gender == PortGender.male) {
        // Draw pins
        canvas.drawRect(
          Rect.fromLTWH(size.width / 2 - 4, size.height / 2 - 1, 8, 2),
          pinPaint,
        );
      }
    } else if (type == PortType.typeC) {
      // Type-C: Oval
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 4, size.width - 4, size.height - 8),
        const Radius.circular(6),
      );
      canvas.drawRRect(rrect, paint);
      canvas.drawRRect(rrect, borderPaint);

      if (gender == PortGender.male) {
        canvas.drawRect(
          Rect.fromLTWH(size.width / 2 - 3, size.height / 2 - 1, 6, 2),
          pinPaint,
        );
      }
    } else if (type == PortType.typeA) {
      // Type-A: Rectangle
      final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 8);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      if (gender == PortGender.male) {
        // Top block in Type A
        canvas.drawRect(
          Rect.fromLTWH(2, 2, size.width - 4, (size.height - 8) / 2),
          Paint()..color = Colors.white,
        );
      } else {
        // Bottom block in Type A female
        canvas.drawRect(
          Rect.fromLTWH(
            4,
            2 + (size.height - 8) / 2,
            size.width - 8,
            (size.height - 8) / 2 - 1,
          ),
          Paint()..color = Colors.white24,
        );
      }
    } else if (type == PortType.acPower) {
      // AC Power: 2 or 3 prongs
      final rect = Rect.fromLTWH(4, 2, size.width - 8, size.height - 4);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      if (gender == PortGender.male) {
        // 2 Prongs sticking out
        canvas.drawRect(
          Rect.fromLTWH(size.width / 2 - 6, size.height / 2 - 4, 3, 8),
          pinPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(size.width / 2 + 3, size.height / 2 - 4, 3, 8),
          pinPaint,
        );
      } else {
        // 2 Holes
        canvas.drawRect(
          Rect.fromLTWH(size.width / 2 - 6, size.height / 2 - 3, 3, 6),
          Paint()..color = Colors.black,
        );
        canvas.drawRect(
          Rect.fromLTWH(size.width / 2 + 3, size.height / 2 - 3, 3, 6),
          Paint()..color = Colors.black,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PortShapePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.gender != gender;
  }
}
