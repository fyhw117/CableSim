import 'package:flutter/material.dart';
export 'storage_service.dart';
import '../models/models.dart';

Color getColorForPortType(PortType type) {
  switch (type) {
    case PortType.hdmi:
      return Colors.blue;
    case PortType.typeC:
      return Colors.green;
    case PortType.typeA:
      return Colors.cyan;
    case PortType.acPower:
      return Colors.blueGrey.shade800;
  }
}

IconData getIconForPortType(PortType type) {
  switch (type) {
    case PortType.hdmi:
      return Icons.settings_input_hdmi;
    case PortType.typeC:
      return Icons.usb_rounded;
    case PortType.typeA:
      return Icons.usb;
    case PortType.acPower:
      return Icons.power; // Clearly represents a power plug
  }
}
