import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../painters/painters.dart';
import '../widgets/sidebar_panel.dart';
import '../dialogs/workspace_dialogs.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final List<DeviceNode> nodes = [];
  final List<Cable> cables = [];
  final List<DeviceTemplate> customDevices = [];

  // Dragging state for cables
  String? draggingCableId;
  int? draggingEndpoint; // 1 or 2

  // Selection state
  String? selectedNodeId;
  String? selectedCableId;

  // Sidebar state
  bool isSidebarOpen = true;

  // Available cable types. Kept as state (not global) to prevent
  // cross-instance contamination when custom cables are added/removed.
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

  final StorageService _storageService = StorageService();
  String currentWorkspace = 'Workspace A';
  final List<String> availableWorkspaces = ['Workspace A', 'Workspace B'];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load default workspace on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelectedWorkspace(currentWorkspace);
    });
  }

  Future<void> _saveCurrentWorkspace() async {
    setState(() => _isSaving = true);
    final customCableTypes = availableCables.where((c) => c.isCustom).toList();
    await _storageService.saveWorkspace(
      fileName: currentWorkspace,
      devices: nodes,
      cables: cables,
      customTemplates: customDevices,
      customCableTypes: customCableTypes,
    );
    // Mimic processing time for smooth animation if it's too fast
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _loadSelectedWorkspace(String name) async {
    final data = await _storageService.loadWorkspace(name);
    if (data != null && mounted) {
      // Recalculate port positions before setState so build() never needs to mutate state.
      final loadedDevices = data['devices'] as List<DeviceNode>;
      for (final node in loadedDevices) {
        _recalculatePortPositions(node);
      }
      setState(() {
        nodes.clear();
        nodes.addAll(loadedDevices);
        cables.clear();
        cables.addAll(data['cables'] as List<Cable>);

        customDevices.clear();
        if (data['customTemplates'] != null) {
          customDevices.addAll(data['customTemplates'] as List<DeviceTemplate>);
        }

        if (data['customCableTypes'] != null) {
          final loadedCustoms = data['customCableTypes'] as List<CableType>;
          availableCables.removeWhere((c) => c.isCustom);
          availableCables.addAll(loadedCustoms);
        }

        selectedNodeId = null;
        selectedCableId = null;
      });
    } else {
      // If it doesn't exist yet, just clear the current view to start fresh
      setState(() {
        nodes.clear();
        cables.clear();
        selectedNodeId = null;
        selectedCableId = null;
      });
    }
  }

  Future<void> _switchWorkspace(String newName) async {
    if (currentWorkspace == newName) return;

    // Show loading or just do it
    await _saveCurrentWorkspace();
    setState(() {
      currentWorkspace = newName;
    });
    await _loadSelectedWorkspace(newName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to $newName'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _addDevice(String name) {
    List<DevicePort> presetPorts = [];
    if (name == 'PC') {
      presetPorts = [
        DevicePort(
          id: 'p1',
          type: PortType.typeC,
          gender: PortGender.female,
          relativeCenter: const Offset(0, 20),
        ),
        DevicePort(
          id: 'p2',
          type: PortType.typeA,
          gender: PortGender.female,
          relativeCenter: const Offset(0, 50),
        ),
        DevicePort(
          id: 'p3',
          type: PortType.hdmi,
          gender: PortGender.female,
          relativeCenter: const Offset(100, 35),
        ),
        DevicePort(
          id: 'p4',
          type: PortType.acPower,
          gender: PortGender.male,
          relativeCenter: const Offset(50, 70),
        ),
      ];
    } else if (name == 'Monitor') {
      presetPorts = [
        DevicePort(
          id: 'p1',
          type: PortType.hdmi,
          gender: PortGender.female,
          relativeCenter: const Offset(0, 35),
        ),
        DevicePort(
          id: 'p2',
          type: PortType.acPower,
          gender: PortGender.male,
          relativeCenter: const Offset(50, 70),
        ),
      ];
    } else {
      presetPorts = [
        DevicePort(
          id: 'left',
          type: PortType.typeC,
          gender: PortGender.female,
          relativeCenter: const Offset(0, 35),
        ),
        DevicePort(
          id: 'right',
          type: PortType.typeA,
          gender: PortGender.female,
          relativeCenter: const Offset(100, 35),
        ),
      ];
    }

    final newNode = DeviceNode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      position: const Offset(100, 100),
      ports: presetPorts,
    );
    _recalculatePortPositions(newNode);
    setState(() {
      nodes.add(newNode);
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

  bool _canConnect(
    PortType cableType,
    PortGender cableGender,
    DevicePort port,
  ) {
    // Basic logic: Port types must match. Genders must be opposite.
    if (cableType != port.type) return false;
    if (cableGender == port.gender) return false;
    return true;
  }

  void _removeDevice(String id) {
    setState(() {
      try {
        final nodeToRemove = nodes.firstWhere((n) => n.id == id);
        for (var cable in cables) {
          if (cable.fromNodeId == id) {
            final port = nodeToRemove.ports.firstWhere(
              (p) => p.id == cable.fromPortId,
            );
            cable.dragPos1 = nodeToRemove.position + port.relativeCenter;
            cable.fromNodeId = null;
            cable.fromPortId = null;
          }
          if (cable.toNodeId == id) {
            final port = nodeToRemove.ports.firstWhere(
              (p) => p.id == cable.toPortId,
            );
            cable.dragPos2 = nodeToRemove.position + port.relativeCenter;
            cable.toNodeId = null;
            cable.toPortId = null;
          }
        }
      } catch (e) {
        // Ignored
      }
      nodes.removeWhere((n) => n.id == id);
    });
  }

  void _removeCable(String id) {
    setState(() {
      cables.removeWhere((c) => c.id == id);
    });
  }

  void _addDeviceFromTemplate(DeviceTemplate template) {
    final newNode = DeviceNode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: template.name,
      position: const Offset(100, 100),
      ports: template.ports
          .map(
            (p) => DevicePort(
              id: DateTime.now().microsecondsSinceEpoch.toString() + p.id,
              type: p.type,
              gender: p.gender,
              relativeCenter: Offset.zero,
            ),
          )
          .toList(),
      templateId: template.id,
    );
    _recalculatePortPositions(newNode);
    setState(() {
      nodes.add(newNode);
    });
  }

  Future<void> _onCreateCustomDevice() async {
    final result = await showCustomDeviceDialog(context);
    if (result == null || result.deleted) return;
    setState(() => customDevices.add(result.template!));
  }

  Future<void> _onCreateCustomCable() async {
    final result = await showCustomCableDialog(context);
    if (result == null || result.deleted) return;
    setState(() => availableCables.add(result.cableType!));
  }

  Future<void> _editDeviceTemplate(DeviceTemplate tpl) async {
    if (nodes.any((n) => n.templateId == tpl.id)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please delete all instances of this device from the canvas before editing/deleting.',
          ),
        ),
      );
      return;
    }
    final result = await showCustomDeviceDialog(context, editingTemplate: tpl);
    if (result == null) return;
    setState(() {
      if (result.deleted) {
        customDevices.removeWhere((t) => t.id == tpl.id);
      } else {
        final idx = customDevices.indexWhere((t) => t.id == tpl.id);
        if (idx != -1) customDevices[idx] = result.template!;
      }
    });
  }

  Future<void> _editCableType(CableType type) async {
    if (cables.any((c) => c.type == type)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please delete all instances of this cable from the canvas before editing/deleting.',
          ),
        ),
      );
      return;
    }
    final result = await showCustomCableDialog(context, editingType: type);
    if (result == null) return;
    setState(() {
      if (result.deleted) {
        availableCables.remove(type);
      } else {
        final idx = availableCables.indexOf(type);
        if (idx != -1) availableCables[idx] = result.cableType!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CableSim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isSidebarOpen ? Icons.menu_open : Icons.menu,
            color: Colors.white,
          ),
          tooltip: 'Toggle Sidebar',
          onPressed: () {
            setState(() {
              isSidebarOpen = !isSidebarOpen;
            });
          },
        ),
        actions: [
          if (selectedNodeId != null || selectedCableId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Delete selected',
              onPressed: () {
                if (selectedNodeId != null) {
                  _removeDevice(selectedNodeId!);
                  setState(() => selectedNodeId = null);
                } else if (selectedCableId != null) {
                  _removeCable(selectedCableId!);
                  setState(() => selectedCableId = null);
                }
              },
            ),
          Theme(
            data: Theme.of(
              context,
            ).copyWith(canvasColor: Theme.of(context).colorScheme.primary),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentWorkspace,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _switchWorkspace(newValue);
                  }
                },
                items: availableWorkspaces.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: _isSaving ? 0.8 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: IconButton(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, color: Colors.white),
                  tooltip: 'Manual Save',
                  onPressed: _isSaving ? null : _saveCurrentWorkspace,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isSidebarOpen ? 250 : 0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: 250,
              maxWidth: 250,
              child: SidebarPanel(
                availableCables: availableCables,
                customDevices: customDevices,
                onAddPresetDevice: _addDevice,
                onAddCable: _addCable,
                onAddFromTemplate: _addDeviceFromTemplate,
                onEditTemplate: _editDeviceTemplate,
                onEditCableType: _editCableType,
                onCreateCustomDevice: _onCreateCustomDevice,
                onCreateCustomCable: _onCreateCustomCable,
              ),
            ),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background tap to deselect
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedNodeId = null;
                          selectedCableId = null;
                        });
                      },
                      behavior: HitTestBehavior.translucent,
                    ),
                  ),

                  // Devices Layer
                  ...nodes.map((node) {
                    // Constants for Grid Layout
                    const double minWidth = 100.0;
                    const double minHeight = 70.0;
                    const double portCellWidth = 28.0;
                    const double portCellHeight = 25.0;
                    const int columns = 3;
                    const double sidePadding = 8.0;

                    // Calculate text height dynamically
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: node.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                    )..layout(maxWidth: minWidth - (sidePadding * 2));

                    double textHeight = textPainter.height;
                    double topPadding =
                        12.0 + textHeight + 8.0; // Margin + Text + Gap

                    // Calculate rows needed
                    int rowsNeeded = (node.ports.length / columns).ceil();
                    if (rowsNeeded < 1) rowsNeeded = 1;

                    // Dynamic sizing
                    double nodeWidth =
                        (columns * portCellWidth) + (sidePadding * 2);
                    if (nodeWidth < minWidth) nodeWidth = minWidth;

                    double nodeHeight =
                        topPadding + (rowsNeeded * portCellHeight) + 10.0;
                    if (nodeHeight < minHeight) nodeHeight = minHeight;

                    // Port positions are pre-calculated by _recalculatePortPositions()
                    // when a node is created or loaded. No mutation in build().

                    return Positioned(
                      left: node.position.dx,
                      top: node.position.dy,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedNodeId = node.id;
                            selectedCableId = null;
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            node.position += details.delta;
                          });
                        },
                        child: Container(
                          width: nodeWidth,
                          height: nodeHeight,
                          decoration: BoxDecoration(
                            color: selectedNodeId == node.id
                                ? Colors.blue.shade50
                                : Colors.white,
                            border: Border.all(
                              color: selectedNodeId == node.id
                                  ? Colors.blue
                                  : Colors.blueGrey,
                              width: selectedNodeId == node.id ? 3 : 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: selectedNodeId == node.id
                                    ? Colors.blue.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: selectedNodeId == node.id ? 15 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    left: 8,
                                    right: 8,
                                  ),
                                  child: Text(
                                    node.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              ...node.ports.map(
                                (p) => _buildPortWidget(node, p),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Cables Layer
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CablePainter(
                          nodes: nodes,
                          cables: cables,
                          selectedCableId: selectedCableId,
                        ),
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

  /// Calculates and stores grid-based port positions for a device node.
  /// Call this when a node is created or loaded — never inside build().
  void _recalculatePortPositions(DeviceNode node) {
    const double minWidth = 100.0;
    const double portCellWidth = 28.0;
    const double portCellHeight = 25.0;
    const int columns = 3;
    const double sidePadding = 8.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: node.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: minWidth - (sidePadding * 2));

    final double topPadding = 12.0 + textPainter.height + 8.0;

    for (int i = 0; i < node.ports.length; i++) {
      final int row = i ~/ columns;
      final int col = i % columns;
      node.ports[i] = DevicePort(
        id: node.ports[i].id,
        type: node.ports[i].type,
        gender: node.ports[i].gender,
        relativeCenter: Offset(
          sidePadding + (col * portCellWidth) + (portCellWidth / 2),
          topPadding + (row * portCellHeight) + (portCellHeight / 2),
        ),
      );
    }
  }

  // Sidebar UI is handled by SidebarPanel (lib/widgets/sidebar_panel.dart).
  // Dialogs are handled by workspace_dialogs.dart functions.

  Widget _buildPortWidget(DeviceNode node, DevicePort port) {
    return Positioned(
      left: port.relativeCenter.dx - 16,
      top: port.relativeCenter.dy - 12,
      child: Tooltip(
        message: '${port.type.name} (${port.gender.name})',
        child: Container(
          width: 24,
          height: 18,
          decoration: BoxDecoration(
            color: getColorForPortType(port.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: getColorForPortType(port.type).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 12,
              child: CustomPaint(
                painter: PortShapePainter(
                  type: port.type,
                  gender: port.gender,
                  baseColor: getColorForPortType(port.type),
                ),
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
        final nodeIdx = nodes.indexWhere((n) => n.id == cable.fromNodeId);
        if (nodeIdx != -1) {
          final node = nodes[nodeIdx];
          final portIdx = node.ports.indexWhere(
            (p) => p.id == cable.fromPortId,
          );
          if (portIdx != -1) {
            pos1 = node.position + node.ports[portIdx].relativeCenter;
            isConnected1 = true;
          } else {
            pos1 = cable.dragPos1 ?? const Offset(0, 0);
          }
        } else {
          pos1 = cable.dragPos1 ?? const Offset(0, 0);
        }
      } else {
        pos1 = cable.dragPos1 ?? const Offset(0, 0);
      }
      widgets.add(_buildEndpointDraggable(cable, 1, pos1, isConnected1));

      Offset pos2;
      bool isConnected2 = false;
      if (cable.toNodeId != null && cable.toPortId != null) {
        final nodeIdx = nodes.indexWhere((n) => n.id == cable.toNodeId);
        if (nodeIdx != -1) {
          final node = nodes[nodeIdx];
          final portIdx = node.ports.indexWhere((p) => p.id == cable.toPortId);
          if (portIdx != -1) {
            pos2 = node.position + node.ports[portIdx].relativeCenter;
            isConnected2 = true;
          } else {
            pos2 = cable.dragPos2 ?? const Offset(0, 0);
          }
        } else {
          pos2 = cable.dragPos2 ?? const Offset(0, 0);
        }
      } else {
        pos2 = cable.dragPos2 ?? const Offset(0, 0);
      }
      widgets.add(_buildEndpointDraggable(cable, 2, pos2, isConnected2));
    }
    return widgets;
  }

  Widget _buildEndpointDraggable(
    Cable cable,
    int endpointIndex,
    Offset position,
    bool isConnected,
  ) {
    final cableType = endpointIndex == 1
        ? cable.type.end1Type
        : cable.type.end2Type;
    final cableGender = endpointIndex == 1
        ? cable.type.end1Gender
        : cable.type.end2Gender;

    final isSelected = selectedCableId == cable.id;
    final isDragging =
        draggingCableId == cable.id && draggingEndpoint == endpointIndex;
    return Positioned(
      left: position.dx - 18,
      top: position.dy - 14,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCableId = cable.id;
            selectedNodeId = null;
          });
        },
        onPanStart: (details) {
          setState(() {
            draggingCableId = cable.id;
            draggingEndpoint = endpointIndex;
            selectedCableId = cable.id;
            selectedNodeId = null;
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
          final currentPos = endpointIndex == 1
              ? cable.dragPos1!
              : cable.dragPos2!;
          _handleEndpointDrop(cable, endpointIndex, currentPos);
        },
        child: MouseRegion(
          cursor: isDragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: Tooltip(
            message: 'Drag to connect / Click to select',
            child: Container(
              width: 28,
              height: 22,
              decoration: BoxDecoration(
                color: isConnected ? Colors.lightGreen.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue
                      : (isConnected
                            ? Colors.green
                            : getColorForPortType(cableType)),
                  width: isSelected || isConnected ? 3 : 2,
                ),
                boxShadow: [
                  if (isSelected)
                    const BoxShadow(
                      color: Colors.blueAccent,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  else if (isConnected)
                    const BoxShadow(
                      color: Colors.greenAccent,
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  else
                    const BoxShadow(
                      color: Colors.black38,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 12,
                  child: CustomPaint(
                    painter: PortShapePainter(
                      type: cableType,
                      gender: cableGender,
                      baseColor: getColorForPortType(cableType),
                    ),
                  ),
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
    double minDistance = 30.0;
    String? errorMessage;

    final cType = endpointIndex == 1
        ? cable.type.end1Type
        : cable.type.end2Type;
    final cGen = endpointIndex == 1
        ? cable.type.end1Gender
        : cable.type.end2Gender;

    for (var n in nodes) {
      for (var p in n.ports) {
        // Prevent connecting both ends to identical port
        if (endpointIndex == 1 &&
            cable.toNodeId == n.id &&
            cable.toPortId == p.id) {
          continue;
        }
        if (endpointIndex == 2 &&
            cable.fromNodeId == n.id &&
            cable.fromPortId == p.id) {
          continue;
        }

        final portAbsPos = n.position + p.relativeCenter;
        final distance = (portAbsPos - currentPos).distance;

        if (distance < minDistance) {
          bool isOccupied = cables.any(
            (c) =>
                (c.fromNodeId == n.id && c.fromPortId == p.id) ||
                (c.toNodeId == n.id && c.toPortId == p.id),
          );

          if (isOccupied) {
            errorMessage = 'Cannot connect: Port is already occupied';
            continue;
          }

          // Check compatibility
          if (_canConnect(cType, cGen, p)) {
            minDistance = distance;
            targetPort = p;
            targetNode = n;
            errorMessage = null; // Clear error if valid port is found closer
          } else {
            errorMessage ??=
                'Cannot connect: Incompatible ports (Type or Gender mismatch)';
          }
        }
      }
    }

    if (targetPort != null && targetNode != null) {
      setState(() {
        if (endpointIndex == 1) {
          cable.fromNodeId = targetNode!.id;
          cable.fromPortId = targetPort!.id;
        } else {
          cable.toNodeId = targetNode!.id;
          cable.toPortId = targetPort!.id;
        }
        draggingCableId = null;
        draggingEndpoint = null;
      });
    } else {
      if (errorMessage != null) {
        // Clear previous tooltips to avoid stacking the same message repeatedly
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        draggingCableId = null;
        draggingEndpoint = null;
      });
    }
  }
}
