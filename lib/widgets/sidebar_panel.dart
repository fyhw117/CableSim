import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/utils.dart';

/// The sidebar panel displayed on the left side of the workspace.
/// Stateless — all actions are passed in as callbacks.
class SidebarPanel extends StatelessWidget {
  final List<CableType> availableCables;
  final List<DeviceTemplate> customDevices;

  /// Called with preset device name: 'PC', 'Monitor', or 'USB Hub'
  final void Function(String name) onAddPresetDevice;
  final void Function(CableType type) onAddCable;
  final void Function(DeviceTemplate tpl) onAddFromTemplate;
  final void Function(DeviceTemplate tpl) onEditTemplate;
  final void Function(CableType type) onEditCableType;
  final VoidCallback onCreateCustomDevice;
  final VoidCallback onCreateCustomCable;

  const SidebarPanel({
    super.key,
    required this.availableCables,
    required this.customDevices,
    required this.onAddPresetDevice,
    required this.onAddCable,
    required this.onAddFromTemplate,
    required this.onEditTemplate,
    required this.onEditCableType,
    required this.onCreateCustomDevice,
    required this.onCreateCustomCable,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              _SidebarButton(label: 'Add PC', icon: Icons.computer, onPressed: () => onAddPresetDevice('PC')),
              _SidebarButton(label: 'Add Monitor', icon: Icons.monitor, onPressed: () => onAddPresetDevice('Monitor')),
              _SidebarButton(label: 'Add USB Hub', icon: Icons.hub, onPressed: () => onAddPresetDevice('USB Hub')),
              ...customDevices.map((tpl) => _TemplateButton(
                    tpl: tpl,
                    onAdd: () => onAddFromTemplate(tpl),
                    onEdit: () => onEditTemplate(tpl),
                  )),
              const SizedBox(height: 8),
              _SidebarButton(
                label: 'Create Custom Device',
                icon: Icons.add_box,
                onPressed: onCreateCustomDevice,
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
              ...availableCables.map((type) => _CableButton(
                    type: type,
                    onAdd: () => onAddCable(type),
                    onEdit: type.isCustom ? () => onEditCableType(type) : null,
                  )),
              const SizedBox(height: 8),
              _SidebarButton(
                label: 'Create Custom Cable',
                icon: Icons.add_circle_outline,
                onPressed: onCreateCustomCable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _SidebarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SidebarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _TemplateButton extends StatelessWidget {
  final DeviceTemplate tpl;
  final VoidCallback onAdd;
  final VoidCallback onEdit;

  const _TemplateButton({
    required this.tpl,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.devices_other, size: 20),
              label: Text(tpl.name),
              style: ElevatedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueGrey,
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueGrey),
            onPressed: onEdit,
            tooltip: 'Edit Custom Device',
          ),
        ],
      ),
    );
  }
}

class _CableButton extends StatelessWidget {
  final CableType type;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;

  const _CableButton({
    required this.type,
    required this.onAdd,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: onAdd,
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      child: Row(
        children: [
          Icon(
            getIconForPortType(type.end1Type),
            size: 20,
            color: type.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(type.name, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );

    if (onEdit != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: btn),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.blueGrey),
              onPressed: onEdit,
              tooltip: 'Edit Custom Cable',
            ),
          ],
        ),
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: btn);
  }
}
