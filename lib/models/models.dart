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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'gender': gender.index,
      'relativeCenter': {'dx': relativeCenter.dx, 'dy': relativeCenter.dy},
    };
  }

  factory DevicePort.fromMap(Map<String, dynamic> map) {
    return DevicePort(
      id: map['id'],
      type: PortType.values[map['type']],
      gender: PortGender.values[map['gender']],
      relativeCenter: Offset(map['relativeCenter']['dx'], map['relativeCenter']['dy']),
    );
  }
}

class DeviceTemplate {
  final String id;
  final String name;
  final List<DevicePort> ports;

  DeviceTemplate({required this.id, required this.name, required this.ports});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ports': ports.map((p) => p.toMap()).toList(),
    };
  }

  factory DeviceTemplate.fromMap(Map<String, dynamic> map) {
    return DeviceTemplate(
      id: map['id'],
      name: map['name'],
      ports: (map['ports'] as List).map((p) => DevicePort.fromMap(p)).toList(),
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': {'dx': position.dx, 'dy': position.dy},
      'ports': ports.map((p) => p.toMap()).toList(),
      'templateId': templateId,
    };
  }

  factory DeviceNode.fromMap(Map<String, dynamic> map) {
    return DeviceNode(
      id: map['id'],
      name: map['name'],
      position: Offset(map['position']['dx'], map['position']['dy']),
      ports: (map['ports'] as List).map((p) => DevicePort.fromMap(p)).toList(),
      templateId: map['templateId'],
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'end1Type': end1Type.index,
      'end1Gender': end1Gender.index,
      'end2Type': end2Type.index,
      'end2Gender': end2Gender.index,
      'color': color.toARGB32(),
      'isCustom': isCustom,
    };
  }

  factory CableType.fromMap(Map<String, dynamic> map) {
    return CableType(
      name: map['name'],
      end1Type: PortType.values[map['end1Type']],
      end1Gender: PortGender.values[map['end1Gender']],
      end2Type: PortType.values[map['end2Type']],
      end2Gender: PortGender.values[map['end2Gender']],
      color: Color(map['color']),
      isCustom: map['isCustom'] ?? false,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toMap(),
      'fromNodeId': fromNodeId,
      'fromPortId': fromPortId,
      'dragPos1': dragPos1 != null ? {'dx': dragPos1!.dx, 'dy': dragPos1!.dy} : null,
      'toNodeId': toNodeId,
      'toPortId': toPortId,
      'dragPos2': dragPos2 != null ? {'dx': dragPos2!.dx, 'dy': dragPos2!.dy} : null,
    };
  }

  factory Cable.fromMap(Map<String, dynamic> map) {
    final cable = Cable(
      id: map['id'],
      type: CableType.fromMap(map['type']),
      dragPos1: map['dragPos1'] != null ? Offset(map['dragPos1']['dx'], map['dragPos1']['dy']) : null,
      dragPos2: map['dragPos2'] != null ? Offset(map['dragPos2']['dx'], map['dragPos2']['dy']) : null,
    );
    cable.fromNodeId = map['fromNodeId'];
    cable.fromPortId = map['fromPortId'];
    cable.toNodeId = map['toNodeId'];
    cable.toPortId = map['toPortId'];
    return cable;
  }
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
