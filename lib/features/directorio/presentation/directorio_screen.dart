import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/directorio_model.dart';
import '../providers/directorio_provider.dart';
import 'directorio_form.dart';

class DirectorioScreen extends ConsumerStatefulWidget {
  const DirectorioScreen({super.key});

  @override
  ConsumerState<DirectorioScreen> createState() => _DirectorioScreenState();
}

class _DirectorioScreenState extends ConsumerState<DirectorioScreen> {
  static const _color = Color(0xFF00838F);
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(directorioProvider);
    final filtrados = _busqueda.isEmpty
        ? todos
        : todos
            .where((d) =>
                d.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                d.dni.contains(_busqueda))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de comensales'),
        backgroundColor: _color,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Importar desde Excel',
            onPressed: _importarExcel,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/directorio'),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o DNI…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _busqueda = ''),
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
          ),
          // Conteo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text('${filtrados.length} comensal(es)',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _importarExcel,
                  icon: const Icon(Icons.table_chart_rounded, size: 16),
                  label: const Text('Importar Excel',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: _color),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista
          Expanded(
            child: filtrados.isEmpty
                ? _EmptyState(busqueda: _busqueda, onAdd: _abrirFormulario)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 90),
                    itemCount: filtrados.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) => _DirectorioTile(
                      comensal: filtrados[i],
                      onEdit: () => _abrirFormulario(filtrados[i]),
                      onDelete: () => _confirmarEliminar(filtrados[i]),
                    ),
                  ),
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _color,
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Agregar'),
      ),
    );
  }

  void _abrirFormulario([DirectorioComensal? comensal]) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DirectorioForm(comensal: comensal),
    ));
  }

  void _confirmarEliminar(DirectorioComensal d) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar del directorio'),
        content: Text('¿Eliminar a ${d.nombre} (DNI: ${d.dni})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(directorioProvider.notifier).eliminar(d.dni);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ── Importación desde Excel ────────────────────────────────────────────────

  Future<void> _importarExcel() async {
    // 1. Seleccionar archivo
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
    } catch (e) {
      _mostrarError('Error al abrir el selector de archivos: $e');
      return;
    }

    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;

    // 2. Parsear Excel
    List<DirectorioComensal> encontrados = [];
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      for (final row in sheet.rows) {
        if (row.isEmpty) continue;

        final rawDni = _cellStr(row.isNotEmpty ? row[0]?.value : null).trim();
        final rawNombre = _cellStr(row.length > 1 ? row[1]?.value : null).trim();

        // Saltar encabezado o celdas no numéricas
        final dni = rawDni.replaceAll(RegExp(r'[^0-9]'), '');
        if (dni.length != 8) continue;
        if (rawNombre.isEmpty) continue;

        encontrados.add(DirectorioComensal(dni: dni, nombre: rawNombre));
      }
    } catch (e) {
      _mostrarError('No se pudo leer el archivo Excel: $e');
      return;
    }

    if (encontrados.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se encontraron filas válidas. Formato esperado:\nColumna A: DNI | Columna B: Nombre'),
              duration: Duration(seconds: 4)),
        );
      }
      return;
    }

    // 3. Confirmar
    if (!mounted) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar importación'),
        content: Text(
          'Se encontraron ${encontrados.length} comensales en el archivo.\n\n'
          'Los que ya existen en el directorio serán actualizados.\n\n'
          '¿Importar?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final count =
        await ref.read(directorioProvider.notifier).importar(encontrados);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count comensales importados correctamente'),
          backgroundColor: const Color(0xFF00838F),
        ),
      );
    }
  }

  String _cellStr(CellValue? val) {
    if (val == null) return '';
    if (val is TextCellValue) {
      // TextCellValue.value es un TextSpan; extraemos el texto directamente
      return val.value.text ?? '';
    }
    if (val is IntCellValue) return val.value.toString();
    if (val is DoubleCellValue) return val.value.toStringAsFixed(0);
    return val.toString();
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}

// ── Tile ────────────────────────────────────────────────────────────────────────

class _DirectorioTile extends StatelessWidget {
  final DirectorioComensal comensal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DirectorioTile(
      {required this.comensal, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF00838F).withAlpha(30),
        child: Text(
          comensal.nombre.isNotEmpty
              ? comensal.nombre[0].toUpperCase()
              : comensal.dni[0],
          style: const TextStyle(
              color: Color(0xFF00838F), fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(comensal.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('DNI: ${comensal.dni}',
          style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: const Color(0xFF00838F),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String busqueda;
  final VoidCallback onAdd;
  const _EmptyState({required this.busqueda, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final buscando = busqueda.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            buscando
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            buscando
                ? 'Sin resultados para "$busqueda"'
                : 'El directorio está vacío',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (!buscando)
            Text(
              'Agrega comensales individualmente\no importa desde un archivo Excel',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          if (!buscando) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00838F)),
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Agregar comensal'),
            ),
          ],
        ],
      ),
    );
  }
}
