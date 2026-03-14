import 'package:flutter/material.dart';

enum PortType { hdmi, typeC, typeA, acPower }

enum PortGender { male, female }

class DevicePort {
  final String id;
  final PortType type;
  final PortGender gender;
  final Offset relativeCenter;

  DevicePort({
    required this.id,
    required this.type,
    required this.gender,
    required this.relativeCenter,
  });
}

class DeviceTemplate {
  final String id;
  final String name;
  final List<DevicePort> ports;

  DeviceTemplate({required this.id, required this.name, required this.ports});
}

class DeviceNode {
  final String id;
  final String name;
  Offset position;
  final List<DevicePort> ports;
  final String? templateId;

  DeviceNode({
    required this.id,
    required this.name,
    required this.position,
    required this.ports,
    this.templateId,
  });
}

class CableType {
  final String name;
  final PortType end1Type;
  final PortGender end1Gender;
  final PortType end2Type;
  final PortGender end2Gender;
  final Color color;
  final bool isCustom;

  const CableType({
    required this.name,
    required this.end1Type,
    required this.end1Gender,
    required this.end2Type,
    required this.end2Gender,
    required this.color,
    this.isCustom = false,
  });
}

class Cable {
  final String id;
  final CableType type;

  // Endpoint 1
  String? fromNodeId;
  String? fromPortId;
  Offset? dragPos1; // Position when not connected

  // Endpoint 2
  String? toNodeId;
  String? toPortId;
  Offset? dragPos2; // Position when not connected

  Cable({required this.id, required this.type, this.dragPos1, this.dragPos2});
}

// ----------------------------------------------------
// Constants & Presets
// ----------------------------------------------------

List<CableType> availableCables = [
  const CableType(
    name: 'HDMI to HDMI',
    end1Type: PortType.hdmi,
    end1Gender: PortGender.male,
    end2Type: PortType.hdmi,
    end2Gender: PortGender.male,
    color: Colors.blueGrey,
  ),
  const CableType(
    name: 'Type-C to Type-C',
    end1Type: PortType.typeC,
    end1Gender: PortGender.male,
    end2Type: PortType.typeC,
    end2Gender: PortGender.male,
    color: Colors.black87,
  ),
  const CableType(
    name: 'Type-A to Type-C',
    end1Type: PortType.typeA,
    end1Gender: PortGender.male,
    end2Type: PortType.typeC,
    end2Gender: PortGender.male,
    color: Colors.grey,
  ),
  const CableType(
    name: 'AC Power Cord',
    end1Type: PortType.acPower,
    end1Gender: PortGender.male,
    end2Type: PortType.acPower,
    end2Gender: PortGender.female,
    color: Colors.black,
  ),
];
