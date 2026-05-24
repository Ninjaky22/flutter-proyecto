import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'login_page.dart';
import 'models.dart';
import 'pdf_service.dart';
import 'audit_log_service.dart';

class _UploadedPdf {
  final String name;
  final int sizeBytes;
  final File? file;
  final List<int>? bytes;

  const _UploadedPdf({
    required this.name,
    required this.sizeBytes,
    this.file,
    this.bytes,
  });
}

class AdminConsole extends StatefulWidget {
  final String currentUser;
  const AdminConsole({super.key, this.currentUser = 'michaelhmontilla'});

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  int _idx = 0;
  List<AuditLogEntry> _auditLogs = [];
  String _filterAction = 'all';

  final List<AppUser> _users = [
    AppUser(name: 'Ana Gómez', email: 'ana.gomez@fet.edu.co', role: 'Estudiante', active: true),
    AppUser(name: 'Carlos Pérez', email: 'carlos.perez@fet.edu.co', role: 'Docente', active: true),
    AppUser(name: 'Diana Ríos', email: 'diana.rios@fet.edu.co', role: 'Estudiante'),
    AppUser(name: 'Esteban Lara', email: 'esteban.lara@fet.edu.co', role: 'Coordinador', active: true),
    AppUser(name: 'Fabiola Mora', email: 'fabiola.mora@fet.edu.co', role: 'Estudiante'),
    AppUser(name: 'Gustavo Niño', email: 'gustavo.nino@fet.edu.co', role: 'Estudiante', active: true),
  ];

  List<AuditLogEntry> get _filteredLogs {
    if (_filterAction == 'all') return _auditLogs;
    return _auditLogs.where((l) => l.action == _filterAction).toList();
  }

  List<_UploadedPdf> _uploadedPdfs = [];

  @override
  void initState() {
    super.initState();
    _loadPdfs();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    final logs = await AuditLogService.getEntries();
    if (!mounted) return;
    setState(() => _auditLogs = logs);
  }

  Future<void> _loadPdfs() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList();
      if (!mounted) return;
      setState(
        () => _uploadedPdfs = files
            .map(
              (f) => _UploadedPdf(
                name: f.path.split('/').last,
                sizeBytes: f.lengthSync(),
                file: f,
              ),
            )
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (result == null) return;
    if (!kIsWeb && result.files.single.path == null) return;

    final picked = result.files.single;
    final name = picked.name;
    final sizeBytes = picked.size;

    if (kIsWeb) {
      final bytes = picked.bytes;
      if (bytes == null) return;
      if (!mounted) return;
      setState(
        () => _uploadedPdfs.insert(
          0,
          _UploadedPdf(name: name, sizeBytes: sizeBytes, bytes: bytes),
        ),
      );
    } else {
      final src = File(picked.path!);
      final dir = await getApplicationDocumentsDirectory();
      final newPath = '${dir.path}/$name';
      await src.copy(newPath);
      await _loadPdfs();
    }

    await AuditLogService.log(
      'pdf_uploaded',
      actor: widget.currentUser,
      details: {
        'name': name,
        'sizeBytes': sizeBytes,
      },
    );
    _loadAuditLogs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        content: Text('PDF cargado: $name ${kIsWeb ? '(Web)' : ''}'),
      ),
    );
  }

  void _logout() {
    AuditLogService.log('logout', actor: widget.currentUser);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _dashboardTab(),
      _usersTab(),
      _reportsTab(),
      _uploadsTab(),
      _auditTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.shield, color: Colors.cyan.shade300),
            const SizedBox(width: 10),
            const Text('Consola FET'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_idx),
          child: pages[_idx],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: Colors.cyan.withOpacity(0.25),
        onDestinationSelected: (i) {
          setState(() => _idx = i);
          if (i == 4) _loadAuditLogs();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.picture_as_pdf_outlined),
            selectedIcon: Icon(Icons.picture_as_pdf),
            label: 'Informes',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Cargar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Auditoría',
          ),
        ],
      ),
    );
  }

  // ---------------- INICIO ----------------
  Widget _dashboardTab() {
    final total = _users.length;
    final active = _users.where((u) => u.active).length;
    final inactive = total - active;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Panel General',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bienvenido, ${widget.currentUser}',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _statCard('Usuarios', '$total', Icons.group, Colors.cyan)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Activos', '$active', Icons.verified_user, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('Inactivos', '$inactive', Icons.person_off, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('PDFs', '${_uploadedPdfs.length}', Icons.picture_as_pdf, Colors.purpleAccent)),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Accesos rápidos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _quickAction(Icons.people, 'Gestionar usuarios', () => setState(() => _idx = 1)),
        _quickAction(Icons.download, 'Generar informe en PDF', () => setState(() => _idx = 2)),
        _quickAction(Icons.upload, 'Cargar PDF al sistema', () => setState(() => _idx = 3)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyan.shade300),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  // ---------------- USUARIOS ----------------
  Widget _usersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Validación y activación de perfiles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        }
        final u = _users[i - 1];
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: u.active ? Colors.green : Colors.grey.shade600,
              child: Text(
                u.name.substring(0, 1),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(u.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${u.email}\n${u.role}',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            isThreeLine: true,
            trailing: Switch(
              value: u.active,
              activeColor: Colors.green,
              onChanged: (v) async {
                setState(() => u.active = v);
                await AuditLogService.log(
                  'user_status_changed',
                  actor: widget.currentUser,
                  details: {
                    'user': u.email,
                    'name': u.name,
                    'active': v,
                  },
                );
                _loadAuditLogs();
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------- INFORMES ----------------
  Widget _reportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informes en PDF',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Genera, comparte o descarga los informes.',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          _reportCard(
            title: 'Informe de Usuarios',
            desc: 'Listado completo con estado de activación',
            icon: Icons.group,
            onTap: () async {
              await AuditLogService.log(
                'report_generated',
                actor: widget.currentUser,
                details: {'type': 'users'},
              );
              _loadAuditLogs();
              await PdfService.generateUsersReport(_users);
            },
          ),
          const SizedBox(height: 12),
          _reportCard(
            title: 'Informe Resumido',
            desc: 'Estadísticas generales del sistema',
            icon: Icons.bar_chart,
            onTap: () async {
              await AuditLogService.log(
                'report_generated',
                actor: widget.currentUser,
                details: {'type': 'summary'},
              );
              _loadAuditLogs();
              await PdfService.generateSummaryReport(
                _users,
                _uploadedPdfs.length,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reportCard({
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.cyan.shade300),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- CARGAR ----------------
  Widget _uploadsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'PDFs cargados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text('Cargar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _pickPdf,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _uploadedPdfs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay PDFs cargados aún',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _uploadedPdfs.length,
                    itemBuilder: (_, i) {
                        final item = _uploadedPdfs[i];
                        final name = item.name;
                        final sizeKb =
                          (item.sizeBytes / 1024).toStringAsFixed(1);
                      return Card(
                        color: const Color(0xFF1E293B),
                        child: ListTile(
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '$sizeKb KB',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.open_in_new,
                                  color: Colors.cyan.shade300,
                                ),
                                tooltip: 'Abrir',
                                onPressed: () async {
                                  await AuditLogService.log(
                                    'pdf_opened',
                                    actor: widget.currentUser,
                                    details: {'name': name},
                                  );
                                  _loadAuditLogs();
                                  if (kIsWeb) {
                                    final bytes = item.bytes;
                                    if (bytes != null) {
                                      await PdfService.openPdf(name, bytes);
                                    }
                                  } else {
                                    final file = item.file;
                                    if (file != null) {
                                      await PdfService.openPdf(
                                        name,
                                        await file.readAsBytes(),
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Eliminar',
                                onPressed: () async {
                                  if (kIsWeb) {
                                    if (!mounted) return;
                                    setState(() => _uploadedPdfs.removeAt(i));
                                  } else {
                                    final file = item.file;
                                    if (file != null) {
                                      await file.delete();
                                    }
                                    await _loadPdfs();
                                  }
                                  await AuditLogService.log(
                                    'pdf_deleted',
                                    actor: widget.currentUser,
                                    details: {'name': name},
                                  );
                                  _loadAuditLogs();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------- AUDITORÍA ----------------
  Widget _auditTab() {
    final filtered = _filteredLogs;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Registro de Auditoría',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loadAuditLogs,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Historial de acciones del sistema',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todas', 'all'),
                _filterChip('Logins', 'login_success'),
                _filterChip('Usuarios', 'user_status_changed'),
                _filterChip('Informes', 'report_generated'),
                _filterChip('Cargas', 'pdf_uploaded'),
                _filterChip('Eliminaciones', 'pdf_deleted'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterAction == 'all'
                              ? 'No hay registros aún'
                              : 'No hay registros para esta actividad',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final log = filtered[i];
                      final time =
                          '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}';
                      final date =
                          '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}';

                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          title: Text(
                            log.action,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${log.actor} • $time',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          leading: _getActionIcon(log.action),
                          trailing: Text(
                            date,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detalles:',
                                    style: TextStyle(
                                      color: Colors.cyan.shade300,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (log.details != null)
                                    Text(
                                      log.details.toString(),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    )
                                  else
                                    Text(
                                      'Sin detalles adicionales',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterAction == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (v) {
          if (v) setState(() => _filterAction = value);
        },
        selectedColor: Colors.cyan.shade700,
        backgroundColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }

  Icon _getActionIcon(String action) {
    switch (action) {
      case 'login_success':
        return Icon(Icons.login, color: Colors.green.shade400);
      case 'login_failed':
        return Icon(Icons.cancel, color: Colors.red.shade400);
      case 'logout':
        return Icon(Icons.logout, color: Colors.orange.shade400);
      case 'user_status_changed':
        return Icon(Icons.person_outline, color: Colors.cyan.shade300);
      case 'report_generated':
        return Icon(Icons.description, color: Colors.blue.shade400);
      case 'pdf_uploaded':
        return Icon(Icons.upload, color: Colors.purple.shade400);
      case 'pdf_opened':
        return Icon(Icons.open_in_new, color: Colors.yellow.shade600);
      case 'pdf_deleted':
        return Icon(Icons.delete, color: Colors.red.shade600);
      default:
        return Icon(Icons.info, color: Colors.grey.shade400);
    }
  }
}
