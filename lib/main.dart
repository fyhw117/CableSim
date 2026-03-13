import 'package:flutter/material.dart';

void main() {
  runApp(const CableSimApp());
}

class CableSimApp extends StatelessWidget {
  const CableSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CableSim',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C3E50)),
        useMaterial3: true,
      ),
      home: const WorkspaceScreen(),
    );
  }
}

// ----------------------------------------------------
// Data Models
// ----------------------------------------------------

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

class DeviceNode {
  final String id;
  final String name;
  Offset position;
  final List<DevicePort> ports;

  DeviceNode({
    required this.id,
    required this.name,
    required this.position,
    required this.ports,
  });
}

class CableType {
  final String name;
  final PortType end1Type;
  final PortGender end1Gender;
  final PortType end2Type;
  final PortGender end2Gender;
  final Color color;

  const CableType({
    required this.name,
    required this.end1Type,
    required this.end1Gender,
    required this.end2Type,
    required this.end2Gender,
    required this.color,
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

  Cable({
    required this.id,
    required this.type,
    this.dragPos1,
    this.dragPos2,
  });
}

// ----------------------------------------------------
// Constants & Presets
// ----------------------------------------------------

final List<CableType> availableCables = [
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

Color _getColorForPortType(PortType type) {
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

// ----------------------------------------------------
// UI
// ----------------------------------------------------

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final List<DeviceNode> nodes = [];
  final List<Cable> cables = [];
  
  // Dragging state for cables
  String? draggingCableId;
  int? draggingEndpoint; // 1 or 2

  void _addDevice(String name) {
    List<DevicePort> presetPorts = [];
    if (name == 'PC') {
      presetPorts = [
        DevicePort(id: 'p1', type: PortType.typeC, gender: PortGender.female, relativeCenter: const Offset(0, 30)),
        DevicePort(id: 'p2', type: PortType.typeA, gender: PortGender.female, relativeCenter: const Offset(0, 70)),
        DevicePort(id: 'p3', type: PortType.hdmi, gender: PortGender.female, relativeCenter: const Offset(140, 50)),
        DevicePort(id: 'p4', type: PortType.acPower, gender: PortGender.male, relativeCenter: const Offset(70, 100)),
      ];
    } else if (name == 'Monitor') {
       presetPorts = [
        DevicePort(id: 'p1', type: PortType.hdmi, gender: PortGender.female, relativeCenter: const Offset(0, 50)),
        DevicePort(id: 'p2', type: PortType.acPower, gender: PortGender.male, relativeCenter: const Offset(70, 100)),
      ];
    } else {
       presetPorts = [
        DevicePort(id: 'left', type: PortType.typeC, gender: PortGender.female, relativeCenter: const Offset(0, 50)),
        DevicePort(id: 'right', type: PortType.typeA, gender: PortGender.female, relativeCenter: const Offset(140, 50)),
      ];
    }

    setState(() {
      nodes.add(
        DeviceNode(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          position: const Offset(100, 100),
          ports: presetPorts,
        ),
      );
    });
  }

  void _addCable(CableType type) {
    setState(() {
      cables.add(
        Cable(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          dragPos1: const Offset(200, 200), // Default spawn position
          dragPos2: const Offset(300, 200),
        ),
      );
    });
  }

  bool _canConnect(PortType cableType, PortGender cableGender, DevicePort port) {
    // Basic logic: Port types must match. Genders must be opposite.
    if (cableType != port.type) return false;
    if (cableGender == port.gender) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CableSim - Prototype',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                _buildSidebarButton('Add PC', Icons.computer, () => _addDevice('PC')),
                _buildSidebarButton('Add Monitor', Icons.monitor, () => _addDevice('Monitor')),
                _buildSidebarButton('Add USB Hub', Icons.hub, () => _addDevice('USB Hub')),
                const Divider(height: 48),
                const Text('Cables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                ...availableCables.map((type) => _buildCableButton(type)),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Devices Layer
                  ...nodes.map((node) {
                      return Positioned(
                        left: node.position.dx,
                        top: node.position.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              node.position += details.delta;
                            });
                          },
                          child: Container(
                            width: 140,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.blueGrey, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Center(child: Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                ...node.ports.map((p) => _buildPortWidget(node, p)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Cables Layer
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CablePainter(nodes: nodes, cables: cables),
                      ),
                    ),
                  ),

                  // Cable Interactive Endpoints Layer
                  ..._buildCableEndpoints(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(String label, IconData icon, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey,
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildCableButton(CableType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _addCable(type),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
        ),
        child: Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: type.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(type.name, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildPortWidget(DeviceNode node, DevicePort port) {
    return Positioned(
      left: port.relativeCenter.dx - 16,
      top: port.relativeCenter.dy - 12,
      child: Tooltip(
        message: '${port.type.name} (${port.gender.name})',
        child: Container(
          width: 32,
          height: 24,
          decoration: BoxDecoration(
            color: _getColorForPortType(port.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _getColorForPortType(port.type).withOpacity(0.5), width: 1),
          ),
          child: Center(
            child: SizedBox(
               width: 24,
               height: 16,
               child: CustomPaint(
                 painter: PortShapePainter(type: port.type, gender: port.gender, baseColor: _getColorForPortType(port.type)),
               ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCableEndpoints() {
    List<Widget> widgets = [];
    for (var cable in cables) {
      Offset pos1;
      bool isConnected1 = false;
      if (cable.fromNodeId != null && cable.fromPortId != null) {
        final node = nodes.firstWhere((n) => n.id == cable.fromNodeId);
        final port = node.ports.firstWhere((p) => p.id == cable.fromPortId);
        pos1 = node.position + port.relativeCenter;
        isConnected1 = true;
      } else {
        pos1 = cable.dragPos1 ?? const Offset(0, 0);
      }
      widgets.add(_buildEndpointDraggable(cable, 1, pos1, isConnected1));

      Offset pos2;
      bool isConnected2 = false;
      if (cable.toNodeId != null && cable.toPortId != null) {
        final node = nodes.firstWhere((n) => n.id == cable.toNodeId);
        final port = node.ports.firstWhere((p) => p.id == cable.toPortId);
        pos2 = node.position + port.relativeCenter;
        isConnected2 = true;
      } else {
        pos2 = cable.dragPos2 ?? const Offset(0, 0);
      }
      widgets.add(_buildEndpointDraggable(cable, 2, pos2, isConnected2));
    }
    return widgets;
  }

  Widget _buildEndpointDraggable(Cable cable, int endpointIndex, Offset position, bool isConnected) {
    final cableType = endpointIndex == 1 ? cable.type.end1Type : cable.type.end2Type;
    final cableGender = endpointIndex == 1 ? cable.type.end1Gender : cable.type.end2Gender;

    return Positioned(
      left: position.dx - 18,
      top: position.dy - 14,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            draggingCableId = cable.id;
            draggingEndpoint = endpointIndex;
            // Detach if it was connected
            if (endpointIndex == 1) {
              if (cable.fromNodeId != null) cable.dragPos1 = position;
              cable.fromNodeId = null;
              cable.fromPortId = null;
            } else {
              if (cable.toNodeId != null) cable.dragPos2 = position;
              cable.toNodeId = null;
              cable.toPortId = null;
            }
          });
        },
        onPanUpdate: (details) {
          if (draggingCableId == cable.id) {
            setState(() {
              if (endpointIndex == 1) {
                cable.dragPos1 = cable.dragPos1! + details.delta;
              } else {
                cable.dragPos2 = cable.dragPos2! + details.delta;
              }
            });
          }
        },
        onPanEnd: (details) {
          final currentPos = endpointIndex == 1 ? cable.dragPos1! : cable.dragPos2!;
          _handleEndpointDrop(cable, endpointIndex, currentPos);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
             width: 36,
             height: 28,
             decoration: BoxDecoration(
               color: isConnected ? Colors.lightGreen.shade50 : Colors.white,
               borderRadius: BorderRadius.circular(6),
               border: Border.all(
                 color: isConnected ? Colors.green : _getColorForPortType(cableType), 
                 width: isConnected ? 3 : 2
               ),
               boxShadow: isConnected
                   ? [const BoxShadow(color: Colors.greenAccent, blurRadius: 8, spreadRadius: 1)]
                   : const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
             ),
             child: Center(
               child: SizedBox(
                 width: 24,
                 height: 16,
                 child: CustomPaint(
                   painter: PortShapePainter(type: cableType, gender: cableGender, baseColor: _getColorForPortType(cableType)),
                 ),
               ),
             ),
          ),
        ),
      ),
    );
  }

  void _handleEndpointDrop(Cable cable, int endpointIndex, Offset currentPos) {
    DevicePort? targetPort;
    DeviceNode? targetNode;
    double minDistance = 40.0;

    final cType = endpointIndex == 1 ? cable.type.end1Type : cable.type.end2Type;
    final cGen = endpointIndex == 1 ? cable.type.end1Gender : cable.type.end2Gender;

    for (var n in nodes) {
      for (var p in n.ports) {
        // Prevent connecting both ends to identical port
        if (endpointIndex == 1 && cable.toNodeId == n.id && cable.toPortId == p.id) continue;
        if (endpointIndex == 2 && cable.fromNodeId == n.id && cable.fromPortId == p.id) continue;

        final portAbsPos = n.position + p.relativeCenter;
        final distance = (portAbsPos - currentPos).distance;
        
        if (distance < minDistance) {
            // Check compatibility
            if (_canConnect(cType, cGen, p)) {
              minDistance = distance;
              targetPort = p;
              targetNode = n;
            } else {
               // Show snackbar for invalid connection
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Cannot connect: Incompatible ports (Type or Gender mismatch)'), duration: const Duration(seconds: 2))
               );
            }
        }
      }
    }

    setState(() {
      if (targetPort != null && targetNode != null) {
        if (endpointIndex == 1) {
          cable.fromNodeId = targetNode.id;
          cable.fromPortId = targetPort.id;
        } else {
          cable.toNodeId = targetNode.id;
          cable.toPortId = targetPort.id;
        }
      }
      draggingCableId = null;
      draggingEndpoint = null;
    });
  }
}

class CablePainter extends CustomPainter {
  final List<DeviceNode> nodes;
  final List<Cable> cables;

  CablePainter({required this.nodes, required this.cables});

  @override
  void paint(Canvas canvas, Size size) {
    for (var cable in cables) {
      final paint = Paint()
        ..color = cable.type.color
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      Offset startPos;
      if (cable.fromNodeId != null && cable.fromPortId != null && nodes.any((n) => n.id == cable.fromNodeId)) {
        final node = nodes.firstWhere((n) => n.id == cable.fromNodeId);
        final port = node.ports.firstWhere((p) => p.id == cable.fromPortId);
        startPos = node.position + port.relativeCenter;
      } else {
        startPos = cable.dragPos1 ?? const Offset(0, 0);
      }

      Offset endPos;
      if (cable.toNodeId != null && cable.toPortId != null && nodes.any((n) => n.id == cable.toNodeId)) {
        final node = nodes.firstWhere((n) => n.id == cable.toNodeId);
        final port = node.ports.firstWhere((p) => p.id == cable.toPortId);
        endPos = node.position + port.relativeCenter;
      } else {
        endPos = cable.dragPos2 ?? const Offset(0, 0);
      }

      // Draw curved line
      final path = Path();
      path.moveTo(startPos.dx, startPos.dy);
      
      final dx = (endPos.dx - startPos.dx).abs();
      // Ensure there's always a bit of curve even for vertical lines
      final controlOffset = dx * 0.5 + 40.0;
      
      path.cubicTo(
        startPos.dx + controlOffset, startPos.dy,
        endPos.dx - controlOffset, endPos.dy,
        endPos.dx, endPos.dy,
      );

      // Add a slight shadow to make cables pop
      canvas.drawPath(path, Paint()..color=Colors.black26..strokeWidth=8..style=PaintingStyle.stroke..maskFilter=const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawPath(path, paint);
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

  PortShapePainter({required this.type, required this.gender, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gender == PortGender.female ? Colors.black87 : Colors.grey[300]!
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = gender == PortGender.female ? Colors.grey[700]! : Colors.grey[600]!
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
        canvas.drawRect(Rect.fromLTWH(size.width/2 - 4, size.height/2 - 1, 8, 2), pinPaint);
      }
    } else if (type == PortType.typeC) {
      // Type-C: Oval
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 4, size.width - 4, size.height - 8),
        const Radius.circular(6)
      );
      canvas.drawRRect(rrect, paint);
      canvas.drawRRect(rrect, borderPaint);
      
      if (gender == PortGender.male) {
         canvas.drawRect(Rect.fromLTWH(size.width/2 - 3, size.height/2 - 1, 6, 2), pinPaint);
      }
    } else if (type == PortType.typeA) {
      // Type-A: Rectangle
      final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 8);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
      
      if (gender == PortGender.male) {
        // Top block in Type A
        canvas.drawRect(Rect.fromLTWH(2, 2, size.width - 4, (size.height - 8) / 2), Paint()..color = Colors.white);
      } else {
        // Bottom block in Type A female
        canvas.drawRect(Rect.fromLTWH(4, 2 + (size.height - 8) / 2, size.width - 8, (size.height - 8) / 2 - 1), Paint()..color = Colors.white24);
      }
    } else if (type == PortType.acPower) {
      // AC Power: 2 or 3 prongs
      final rect = Rect.fromLTWH(4, 2, size.width - 8, size.height - 4);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
      
      if (gender == PortGender.male) {
        // 2 Prongs sticking out
        canvas.drawRect(Rect.fromLTWH(size.width/2 - 6, size.height/2 - 4, 3, 8), pinPaint);
        canvas.drawRect(Rect.fromLTWH(size.width/2 + 3, size.height/2 - 4, 3, 8), pinPaint);
      } else {
        // 2 Holes
        canvas.drawRect(Rect.fromLTWH(size.width/2 - 6, size.height/2 - 3, 3, 6), Paint()..color = Colors.black);
        canvas.drawRect(Rect.fromLTWH(size.width/2 + 3, size.height/2 - 3, 3, 6), Paint()..color = Colors.black);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PortShapePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.gender != gender;
  }
}

