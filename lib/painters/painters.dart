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
        final portIdx = node.ports.indexWhere((p) => p.id == cable.fromPortId);
        if (portIdx != -1) {
          startPos = node.position + node.ports[portIdx].relativeCenter;
        } else {
          startPos = cable.dragPos1 ?? const Offset(0, 0);
        }
      } else {
        startPos = cable.dragPos1 ?? const Offset(0, 0);
      }

      Offset endPos;
      if (cable.toNodeId != null &&
          cable.toPortId != null &&
          nodes.any((n) => n.id == cable.toNodeId)) {
        final node = nodes.firstWhere((n) => n.id == cable.toNodeId);
        final portIdx = node.ports.indexWhere((p) => p.id == cable.toPortId);
        if (portIdx != -1) {
          endPos = node.position + node.ports[portIdx].relativeCenter;
        } else {
          endPos = cable.dragPos2 ?? const Offset(0, 0);
        }
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
    // cables/nodes are mutable lists passed by reference, so in-place mutations
    // (position changes during drag) are invisible to reference equality checks.
    // We skip repaint only when there's nothing to draw and selection is unchanged.
    if (cables.isEmpty && oldDelegate.cables.isEmpty &&
        selectedCableId == oldDelegate.selectedCableId) {
      return false;
    }
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
      ..color = Colors.grey[300]!
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
      // AC Power: Common 2-prong rounded shape
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(4),
      );
      
      canvas.drawRRect(rrect, paint);
      canvas.drawRRect(rrect, borderPaint);

      if (gender == PortGender.male) {
        // 2 standard pins (no ground)
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width / 2 - 6, size.height / 2 - 3.5, 3, 7),
            const Radius.circular(0.5),
          ),
          pinPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width / 2 + 3, size.height / 2 - 3.5, 3, 7),
            const Radius.circular(0.5),
          ),
          pinPaint,
        );
      } else {
        // 2 Holes
        final holePaint = Paint()..color = Colors.black;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width / 2 - 6, size.height / 2 - 3, 2.5, 6),
            const Radius.circular(0.5),
          ),
          holePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width / 2 + 3.5, size.height / 2 - 3, 2.5, 6),
            const Radius.circular(0.5),
          ),
          holePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PortShapePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.gender != gender;
  }
}
