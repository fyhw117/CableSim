import 'package:flutter/material.dart';
import '../models/models.dart';

/// Shows a dialog to choose a port's type and gender.
/// Returns [DevicePort] if confirmed, or `null` if cancelled.
Future<DevicePort?> showAddPortDialog(BuildContext context) {
  PortType selectedType = PortType.hdmi;
  PortGender selectedGender = PortGender.female;

  return showDialog<DevicePort>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
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
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
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
                      .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedGender = val!),
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
            onPressed: () => Navigator.pop(
              context,
              DevicePort(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: selectedType,
                gender: selectedGender,
                relativeCenter: Offset.zero,
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}

/// Shows a dialog to create or edit a custom device template.
///
/// Returns:
///   - `null` if cancelled
///   - `(deleted: false, template: <template>)` if created or saved
///   - `(deleted: true,  template: null)`       if the template was deleted
Future<({bool deleted, DeviceTemplate? template})?> showCustomDeviceDialog(
  BuildContext context, {
  DeviceTemplate? editingTemplate,
}) {
  String name = editingTemplate?.name ?? '';
  final List<DevicePort> ports = editingTemplate != null
      ? editingTemplate.ports
            .map((p) => DevicePort(
                  id: p.id,
                  type: p.type,
                  gender: p.gender,
                  relativeCenter: p.relativeCenter,
                ))
            .toList()
      : [];

  return showDialog<({bool deleted, DeviceTemplate? template})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(editingTemplate != null ? 'Edit Custom Device' : 'Create Custom Device'),
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
                child: Text('Ports:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...ports.asMap().entries.map((entry) => ListTile(
                    dense: true,
                    title: Text('${entry.value.type.name} (${entry.value.gender.name})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => setDialogState(() => ports.removeAt(entry.key)),
                    ),
                  )),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final newPort = await showAddPortDialog(context);
                  if (newPort != null) setDialogState(() => ports.add(newPort));
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
              onPressed: () =>
                  Navigator.pop(context, (deleted: true, template: null)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final finalName =
                  name.trim().isEmpty ? 'Custom Device' : name.trim();
              final finalPorts = ports
                  .map((p) => DevicePort(
                        id: p.id,
                        type: p.type,
                        gender: p.gender,
                        relativeCenter: Offset.zero,
                      ))
                  .toList();
              final template = editingTemplate != null
                  ? DeviceTemplate(
                      id: editingTemplate.id,
                      name: finalName,
                      ports: finalPorts,
                    )
                  : DeviceTemplate(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: finalName,
                      ports: finalPorts,
                    );
              Navigator.pop(context, (deleted: false, template: template));
            },
            child: Text(editingTemplate != null ? 'Save' : 'Create'),
          ),
        ],
      ),
    ),
  );
}

/// Shows a dialog to create or edit a custom cable type.
///
/// Returns:
///   - `null` if cancelled
///   - `(deleted: false, cableType: <type>)` if created or saved
///   - `(deleted: true,  cableType: null)`   if the cable type was deleted
Future<({bool deleted, CableType? cableType})?> showCustomCableDialog(
  BuildContext context, {
  CableType? editingType,
}) {
  String name = editingType?.name ?? '';
  PortType end1Type = editingType?.end1Type ?? PortType.hdmi;
  PortGender end1Gender = editingType?.end1Gender ?? PortGender.male;
  PortType end2Type = editingType?.end2Type ?? PortType.hdmi;
  PortGender end2Gender = editingType?.end2Gender ?? PortGender.male;
  Color selectedColor = editingType?.color ?? Colors.black;

  const colors = [
    Colors.black, Colors.white, Colors.blue, Colors.red,
    Colors.green, Colors.orange, Colors.purple, Colors.grey,
  ];

  return showDialog<({bool deleted, CableType? cableType})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(editingType != null ? 'Edit Custom Cable' : 'Create Custom Cable'),
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
              const Text('End 1:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  DropdownButton<PortType>(
                    value: end1Type,
                    items: PortType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => end1Type = val!),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<PortGender>(
                    value: end1Gender,
                    items: PortGender.values
                        .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => end1Gender = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('End 2:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  DropdownButton<PortType>(
                    value: end2Type,
                    items: PortType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => end2Type = val!),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<PortGender>(
                    value: end2Gender,
                    items: PortGender.values
                        .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => end2Gender = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors
                    .map((c) => GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selectedColor == c
                                  ? Border.all(color: Colors.blueAccent, width: 3)
                                  : Border.all(color: Colors.grey.shade400, width: 1),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          if (editingType != null)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, (deleted: true, cableType: null)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final finalName =
                  name.trim().isEmpty ? 'Custom Cable' : name.trim();
              final newCableType = CableType(
                name: finalName,
                end1Type: end1Type,
                end1Gender: end1Gender,
                end2Type: end2Type,
                end2Gender: end2Gender,
                color: selectedColor,
                isCustom: true,
              );
              Navigator.pop(context, (deleted: false, cableType: newCableType));
            },
            child: Text(editingType != null ? 'Save' : 'Create'),
          ),
        ],
      ),
    ),
  );
}
