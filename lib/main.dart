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

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class DeviceNode {
  final String id;
  final String name;
  Offset position;

  DeviceNode({required this.id, required this.name, required this.position});
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final List<DeviceNode> nodes = [];

  void _addDevice(String name) {
    setState(() {
      nodes.add(
        DeviceNode(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          position: const Offset(100, 100), // Default spawn position
        ),
      );
    });
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
                _buildSidebarButton(
                  'Add Power Strip',
                  Icons.electrical_services,
                  () => _addDevice('Power Strip'),
                ),
                const Divider(height: 48),
                const Text(
                  'Cables (Coming soon)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSidebarButton('HDMI Cable', Icons.cable, null),
                _buildSidebarButton('Type-C Cable', Icons.cable, null),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA), // Soft background color
              child: Stack(
                children: [
                  // This is where lines (cables) will be drawn using CustomPaint

                  // Devices
                  ...nodes.map(
                    (node) {
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
                              border: Border.all(
                                color: Colors.blueGrey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
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
                                // Left Port
                                Positioned(
                                  left: -8,
                                  top: 40,
                                  child: _buildPort(),
                                ),
                                // Right Port
                                Positioned(
                                  right: -8,
                                  top: 40,
                                  child: _buildPort(),
                                ),
                                // Bottom Port
                                Positioned(
                                  bottom: -8,
                                  left: 60,
                                  child: _buildPort(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ), // Use toList to clear iterable mapping warning if present
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
          backgroundColor: onPressed == null ? Colors.grey[300] : Colors.white,
          foregroundColor: onPressed == null
              ? Colors.grey[600]
              : Colors.blueGrey,
          elevation: onPressed == null ? 0 : 2,
        ),
      ),
    );
  }

  Widget _buildPort() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.amber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54, width: 2),
      ),
    );
  }
}
