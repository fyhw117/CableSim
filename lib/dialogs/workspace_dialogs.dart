import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/utils.dart';

/// Shows a dialog to choose a port's type and gender.
/// Returns [DevicePort] if confirmed, or `null` if cancelled.
Future<DevicePort?> showAddPortDialog(BuildContext context) {
  PortType selectedType = PortType.hdmi;
  PortGender selectedGender = PortGender.female;

  return showDialog<DevicePort>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_box_outlined, color: Colors.blue),
            SizedBox(width: 12),
            Text('Add New Port'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Port Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PortType>(
                  isExpanded: true,
                  value: selectedType,
                  items: PortType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(
                                getIconForPortType(t),
                                size: 16,
                                color: getColorForPortType(t),
                              ),
                              const SizedBox(width: 12),
                              Text(t.name.toUpperCase()),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gender',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PortGender>(
                  isExpanded: true,
                  value: selectedGender,
                  items: PortGender.values
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged:
                      (val) => setDialogState(() => selectedGender = val!),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(
              context,
              DevicePort(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: selectedType,
                gender: selectedGender,
                relativeCenter: Offset.zero,
              ),
            ),
            child: const Text('Add Port'),
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

  final nameController = TextEditingController(text: name);

  return showDialog<({bool deleted, DeviceTemplate? template})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name (e.g., Target PC)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.layers, size: 20, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text(
                      'Ports:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ports.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No ports added yet.',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      : Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: ports.length,
                            padding: EdgeInsets.zero,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final port = ports[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  getIconForPortType(port.type),
                                  size: 18,
                                  color: getColorForPortType(port.type),
                                ),
                                title: Text(
                                  port.type.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  port.gender.name,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => setDialogState(() => ports.removeAt(index)),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final newPort = await showAddPortDialog(context);
                    if (newPort != null) setDialogState(() => ports.add(newPort));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Port'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
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
              final finalName = name.trim().isEmpty
                  ? 'Custom Device'
                  : name.trim();
              final finalPorts = ports
                  .map(
                    (p) => DevicePort(
                      id: p.id,
                      type: p.type,
                      gender: p.gender,
                      relativeCenter: Offset.zero,
                    ),
                  )
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
    Colors.black,
    Colors.white,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.grey,
  ];

  final nameController = TextEditingController(text: name);

  return showDialog<({bool deleted, CableType? cableType})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          editingType != null ? 'Edit Custom Cable' : 'Create Custom Cable',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Cable Name (e.g., Custom USB)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cable),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 24),
              const Text(
                'End 1:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PortType>(
                          value: end1Type,
                          items: PortType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setDialogState(() => end1Type = val!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PortGender>(
                          value: end1Gender,
                          items: PortGender.values
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setDialogState(() => end1Gender = val!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'End 2:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PortType>(
                          value: end2Type,
                          items: PortType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setDialogState(() => end2Type = val!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PortGender>(
                          value: end2Gender,
                          items: PortGender.values
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setDialogState(() => end2Gender = val!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Cable Color:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors
                    .map(
                      (c) => GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: selectedColor == c
                                ? Border.all(color: Colors.blue, width: 3)
                                : Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                            boxShadow: [
                              if (selectedColor == c)
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: selectedColor == c
                              ? Icon(
                                  Icons.check,
                                  color: c.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  size: 18,
                                )
                              : null,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final finalName = name.trim().isEmpty
                  ? 'Custom Cable'
                  : name.trim();
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
