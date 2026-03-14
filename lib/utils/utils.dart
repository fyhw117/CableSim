import 'package:flutter/material.dart';
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
      return Colors.redAccent;
  }
}
