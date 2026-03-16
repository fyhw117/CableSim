import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../painters/painters.dart';

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
      setState(() {
        nodes.clear();
        nodes.addAll(data['devices'] as List<DeviceNode>);
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
          relativeCenter: const Offset(0, 30),
        ),
        DevicePort(
          id: 'p2',
          type: PortType.typeA,
          gender: PortGender.female,
          relativeCenter: const Offset(0, 70),
        ),
        DevicePort(
          id: 'p3',
          type: PortType.hdmi,
          gender: PortGender.female,
          relativeCenter: const Offset(140, 50),
        ),
        DevicePort(
          id: 'p4',
          type: PortType.acPower,
          gender: PortGender.male,
          relativeCenter: const Offset(70, 100),
        ),
      ];
    } else if (name == 'Monitor') {
      presetPorts = [
        DevicePort(
          id: 'p1',
          type: PortType.hdmi,
          gender: PortGender.female,
          relativeCenter: const Offset(0, 50),
        ),
        DevicePort(
          id: 'p2',
          type: PortType.acPower,
          gender: PortGender.male,
          relativeCenter: const Offset(70, 100),
        ),
      ];
    } else {
      presetPorts = [
        DevicePort(
          id: 'left',
          type: PortType.typeC,
          gender: PortGender.female,
          relativeCenter: const Offset(0, 50),
        ),
        DevicePort(
          id: 'right',
          type: PortType.typeA,
          gender: PortGender.female,
          relativeCenter: const Offset(140, 50),
        ),
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
    setState(() {
      nodes.add(
        DeviceNode(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: template.name,
          position: const Offset(100, 100),
          ports: template.ports
              .map(
                (p) => DevicePort(
                  id: DateTime.now().microsecondsSinceEpoch.toString() + p.id,
                  type: p.type,
                  gender: p.gender,
                  relativeCenter: p.relativeCenter,
                ),
              )
              .toList(),
          templateId: template.id,
        ),
      );
    });
  }

  void _editDeviceTemplate(DeviceTemplate tpl) {
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
    _showCustomDeviceDialog(editingTemplate: tpl);
  }

  void _editCableType(CableType type) {
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
    _showCustomCableDialog(editingType: type);
  }

  Future<DevicePort?> _showAddPortDialog() async {
    PortType selectedType = PortType.hdmi;
    PortGender selectedGender = PortGender.female;

    return showDialog<DevicePort>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Port'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Type: '),
                      const SizedBox(width: 8),
                      DropdownButton<PortType>(
                        value: selectedType,
                        items: PortType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedType = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Gender: '),
                      const SizedBox(width: 8),
                      DropdownButton<PortGender>(
                        value: selectedGender,
                        items: PortGender.values
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedGender = val!),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DevicePort(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        type: selectedType,
                        gender: selectedGender,
                        relativeCenter: Offset.zero,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCustomDeviceDialog({
    DeviceTemplate? editingTemplate,
  }) async {
    String name = editingTemplate?.name ?? '';
    List<DevicePort> ports = editingTemplate != null
        ? editingTemplate.ports
              .map(
                (p) => DevicePort(
                  id: p.id,
                  type: p.type,
                  gender: p.gender,
                  relativeCenter: p.relativeCenter,
                ),
              )
              .toList()
        : [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                editingTemplate != null
                    ? 'Edit Custom Device'
                    : 'Create Custom Device',
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController(text: name),
                      decoration: const InputDecoration(
                        labelText: 'Device Name (e.g., Target PC)',
                      ),
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ports:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...ports.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final port = entry.value;
                      return ListTile(
                        dense: true,
                        title: Text('${port.type.name} (${port.gender.name})'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () =>
                              setDialogState(() => ports.removeAt(idx)),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newPort = await _showAddPortDialog();
                        if (newPort != null) {
                          setDialogState(() => ports.add(newPort));
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Port'),
                    ),
                  ],
                ),
              ),
              actions: [
                if (editingTemplate != null)
                  TextButton(
                    onPressed: () {
                      setState(
                        () => customDevices.removeWhere(
                          (tpl) => tpl.id == editingTemplate.id,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final finalName = name.trim().isEmpty
                        ? 'Custom Device'
                        : name.trim();
                    final List<DevicePort> finalPorts = [];
                    for (int i = 0; i < ports.length; i++) {
                      finalPorts.add(
                        DevicePort(
                          id: ports[i].id,
                          type: ports[i].type,
                          gender: ports[i].gender,
                          relativeCenter: Offset(
                            i % 2 == 0 ? 0 : 140,
                            50.0 + (i ~/ 2) * 50.0,
                          ),
                        ),
                      );
                    }
                    setState(() {
                      if (editingTemplate != null) {
                        final idx = customDevices.indexWhere(
                          (t) => t.id == editingTemplate.id,
                        );
                        if (idx != -1) {
                          customDevices[idx] = DeviceTemplate(
                            id: editingTemplate.id,
                            name: finalName,
                            ports: finalPorts,
                          );
                        }
                      } else {
                        customDevices.add(
                          DeviceTemplate(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            name: finalName,
                            ports: finalPorts,
                          ),
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(editingTemplate != null ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCustomCableDialog({CableType? editingType}) async {
    String name = editingType?.name ?? '';
    PortType end1Type = editingType?.end1Type ?? PortType.hdmi;
    PortGender end1Gender = editingType?.end1Gender ?? PortGender.male;
    PortType end2Type = editingType?.end2Type ?? PortType.hdmi;
    PortGender end2Gender = editingType?.end2Gender ?? PortGender.male;
    Color selectedColor = editingType?.color ?? Colors.black;

    final colors = [
      Colors.black,
      Colors.white,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.grey,
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                editingType != null
                    ? 'Edit Custom Cable'
                    : 'Create Custom Cable',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: TextEditingController(text: name),
                      decoration: const InputDecoration(
                        labelText: 'Cable Name (e.g., Custom USB)',
                      ),
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'End 1:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        DropdownButton<PortType>(
                          value: end1Type,
                          items: PortType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => end1Type = val!),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<PortGender>(
                          value: end1Gender,
                          items: PortGender.values
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => end1Gender = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'End 2:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        DropdownButton<PortType>(
                          value: end2Type,
                          items: PortType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => end2Type = val!),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<PortGender>(
                          value: end2Gender,
                          items: PortGender.values
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => end2Gender = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Color:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors
                          .map(
                            (c) => GestureDetector(
                              onTap: () =>
                                  setDialogState(() => selectedColor = c),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: selectedColor == c
                                      ? Border.all(
                                          color: Colors.blueAccent,
                                          width: 3,
                                        )
                                      : Border.all(
                                          color: Colors.grey.shade400,
                                          width: 1,
                                        ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (editingType != null)
                  TextButton(
                    onPressed: () {
                      setState(() => availableCables.remove(editingType));
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final finalName = name.trim().isEmpty
                        ? 'Custom Cable'
                        : name.trim();
                    setState(() {
                      final newCableType = CableType(
                        name: finalName,
                        end1Type: end1Type,
                        end1Gender: end1Gender,
                        end2Type: end2Type,
                        end2Gender: end2Gender,
                        color: selectedColor,
                        isCustom: true,
                      );
                      if (editingType != null) {
                        final idx = availableCables.indexOf(editingType);
                        if (idx != -1) availableCables[idx] = newCableType;
                      } else {
                        availableCables.add(newCableType);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(editingType != null ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
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
            data: Theme.of(context).copyWith(
              canvasColor: Theme.of(context).colorScheme.primary,
            ),
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
                items: availableWorkspaces.map<DropdownMenuItem<String>>((String value) {
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
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SingleChildScrollView(
              child: SizedBox(
                width: 250,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Devices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSidebarButton(
                        'Add PC',
                        Icons.computer,
                        () => _addDevice('PC'),
                      ),
                      _buildSidebarButton(
                        'Add Monitor',
                        Icons.monitor,
                        () => _addDevice('Monitor'),
                      ),
                      _buildSidebarButton(
                        'Add USB Hub',
                        Icons.hub,
                        () => _addDevice('USB Hub'),
                      ),
                      ...customDevices.map(
                        (tpl) => _buildDeviceTemplateButton(tpl),
                      ),
                      const SizedBox(height: 8),
                      _buildSidebarButton(
                        'Create Custom Device',
                        Icons.add_box,
                        _showCustomDeviceDialog,
                      ),
                      const Divider(height: 48),
                      const Text(
                        'Cables',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...availableCables.map((type) => _buildCableButton(type)),
                      const SizedBox(height: 8),
                      _buildSidebarButton(
                        'Create Custom Cable',
                        Icons.add_circle_outline,
                        _showCustomCableDialog,
                      ),
                    ],
                  ),
                ),
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
                          width: 140,
                          height: 100,
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
                              Center(
                                child: Text(
                                  node.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
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

  Widget _buildSidebarButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
  ) {
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

  Widget _buildDeviceTemplateButton(DeviceTemplate tpl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _addDeviceFromTemplate(tpl),
              icon: const Icon(Icons.devices_other, size: 20),
              label: Text(tpl.name),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueGrey,
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueGrey),
            onPressed: () => _editDeviceTemplate(tpl),
            tooltip: 'Edit Custom Device',
          ),
        ],
      ),
    );
  }

  Widget _buildCableButton(CableType type) {
    final btn = ElevatedButton(
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
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: type.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(type.name, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );

    if (type.isCustom) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: btn),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.blueGrey),
              onPressed: () => _editCableType(type),
              tooltip: 'Edit Custom Cable',
            ),
          ],
        ),
      );
    } else {
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: btn);
    }
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
            color: getColorForPortType(port.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: getColorForPortType(port.type).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 16,
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
          cursor: SystemMouseCursors.grab,
          child: Tooltip(
            message: 'Drag to connect / Click to select',
            child: Container(
              width: 36,
              height: 28,
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
                  width: 24,
                  height: 16,
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
    double minDistance = 40.0;
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
