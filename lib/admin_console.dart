import 'dart:io' show File;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'login_page.dart';
import 'models.dart';
import 'pdf_service.dart';
import 'audit_log_service.dart';

// ── Paleta Kiogloss ─────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF7C3AED);
const _kAccent     = Color(0xFFA855F7);
const _kSurface    = Color(0xFFFFFFFF);
const _kBackground = Color(0xFFFAFAFA);
const _kCardBorder = Color(0xFFEDE9FE);
const _kTextMain   = Color(0xFF1E1B4B);
const _kTextSub    = Color(0xFF6B7280);

// ── Modelo interno de PDF cargado ────────────────────────────────────────────
class _UploadedPdf {
  final String name;
  final int sizeBytes;
  final String? sha256Hash;
  final File? file;
  final List<int>? bytes;

  const _UploadedPdf({
    required this.name,
    required this.sizeBytes,
    this.sha256Hash,
    this.file,
    this.bytes,
  });
}

// ── RBAC: pestañas permitidas por rol ────────────────────────────────────────
const _kRolePages = {
  'Admin':      [0, 1, 2, 3, 4],
  'Vendedor':   [0, 2, 3],
  'Supervisora':[0, 1],
};

class AdminConsole extends StatefulWidget {
  final String currentUser;
  final String currentRole;
  const AdminConsole({
    super.key,
    this.currentUser = 'admin',
    this.currentRole = 'Admin',
  });

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  int _idx = 0;
  List<AuditLogEntry> _auditLogs = [];
  String _filterAction = 'all';

  final List<AppUser> _users = [
    AppUser(name: 'María Rodríguez',  email: 'maria.rodriguez@kiogloss.com',  role: 'Vendedora',    active: true),
    AppUser(name: 'Laura Castillo',   email: 'laura.castillo@kiogloss.com',   role: 'Supervisora',  active: true),
    AppUser(name: 'Sofía Herrera',    email: 'sofia.herrera@kiogloss.com',    role: 'Vendedora'),
    AppUser(name: 'Carlos Mejía',     email: 'carlos.mejia@kiogloss.com',     role: 'Gerente',      active: true),
    AppUser(name: 'Valentina Ríos',   email: 'valentina.rios@kiogloss.com',   role: 'Almacenista'),
    AppUser(name: 'Andrés Parra',     email: 'andres.parra@kiogloss.com',     role: 'Vendedor',     active: true),
  ];

  List<AuditLogEntry> get _filteredLogs {
    if (_filterAction == 'all') return _auditLogs;
    return _auditLogs.where((l) => l.action == _filterAction).toList();
  }

  List<_UploadedPdf> _uploadedPdfs = [];

  // Pestañas habilitadas para el rol actual
  List<int> get _allowedIndices =>
      _kRolePages[widget.currentRole] ?? [0];

  // Todas las definiciones de página (índice global 0‥4)
  static const _allDestinations = [
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
  ];

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
                name: p.basename(f.path),
                sizeBytes: f.lengthSync(),
                file: f,
              ),
            )
            .toList(),
      );
    } catch (_) {}
  }

  String _computeHash(List<int> bytes) =>
      sha256.convert(bytes).toString();

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;
    final picked = result.files.single;
    final name = picked.name;
    final sizeBytes = picked.size;
    final rawBytes = picked.bytes;
    if (rawBytes == null) return;

    final hash = _computeHash(rawBytes);

    if (kIsWeb) {
      if (!mounted) return;
      setState(
        () => _uploadedPdfs.insert(
          0,
          _UploadedPdf(
            name: name,
            sizeBytes: sizeBytes,
            sha256Hash: hash,
            bytes: rawBytes,
          ),
        ),
      );
    } else {
      final src = File(picked.path!);
      final dir = await getApplicationDocumentsDirectory();
      final newPath = '${dir.path}/$name';
      await src.copy(newPath);
      // Recargamos desde disco pero guardamos hash en memoria
      if (!mounted) return;
      await _loadPdfs();
      // Actualizar hash del archivo recién agregado
      setState(() {
        final idx = _uploadedPdfs.indexWhere((f) => f.name == name);
        if (idx != -1) {
          final old = _uploadedPdfs[idx];
          _uploadedPdfs[idx] = _UploadedPdf(
            name: old.name,
            sizeBytes: old.sizeBytes,
            sha256Hash: hash,
            file: old.file,
          );
        }
      });
    }

    await AuditLogService.log(
      'pdf_uploaded',
      actor: widget.currentUser,
      details: {
        'name': name,
        'sizeBytes': sizeBytes,
        'sha256': hash,
      },
    );
    _loadAuditLogs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        content: Text('PDF cargado: $name'),
      ),
    );
  }

  Future<void> _logout() async {
    await AuditLogService.log('logout', actor: widget.currentUser);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _allowedIndices;

    // Mapeo de índice local (barra de nav) → índice global (página)
    final pages = <Widget>[
      _dashboardTab(),
      _usersTab(),
      _reportsTab(),
      _uploadsTab(),
      _auditTab(),
    ];
    final visiblePages = allowed.map((i) => pages[i]).toList();
    final visibleDests = allowed.map((i) => _allDestinations[i]).toList();

    // Índice local seleccionado (nunca fuera de rango)
    final localIdx = _idx.clamp(0, visiblePages.length - 1);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kCardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.spa, color: _kPrimary),
            SizedBox(width: 10),
            Text(
              'Kiogloss',
              style: TextStyle(
                color: _kTextMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withAlpha(60)),
            ),
            child: Text(
              widget.currentRole,
              style: const TextStyle(
                color: _kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _kTextSub),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(localIdx),
          child: visiblePages[localIdx],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: localIdx,
        backgroundColor: _kSurface,
        indicatorColor: _kPrimary.withAlpha(40),
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (i) {
          setState(() => _idx = i);
          // Si navega a Auditoría (índice global 4) la recarga
          if (allowed[i] == 4) _loadAuditLogs();
        },
        destinations: visibleDests,
      ),
    );
  }

  // ─── DASHBOARD ───────────────────────────────────────────────────────────
  Widget _dashboardTab() {
    final total    = _users.length;
    final active   = _users.where((u) => u.active).length;
    final inactive = total - active;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Panel General',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kTextMain),
        ),
        const SizedBox(height: 4),
        Text(
          'Bienvenido, ${widget.currentUser}',
          style: const TextStyle(color: _kTextSub),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _statCard('Empleados', '$total', Icons.group, _kPrimary)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Activos', '$active', Icons.verified_user, Colors.green.shade600)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('Inactivos', '$inactive', Icons.person_off, Colors.orange.shade600)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('PDFs', '${_uploadedPdfs.length}', Icons.picture_as_pdf, _kAccent)),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Accesos rápidos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextMain),
        ),
        const SizedBox(height: 12),
        if (_allowedIndices.contains(1))
          _quickAction(Icons.people, 'Gestionar empleados', () => setState(() => _idx = _allowedIndices.indexOf(1))),
        if (_allowedIndices.contains(2))
          _quickAction(Icons.download, 'Generar informe en PDF', () => setState(() => _idx = _allowedIndices.indexOf(2))),
        if (_allowedIndices.contains(3))
          _quickAction(Icons.upload, 'Cargar PDF al sistema', () => setState(() => _idx = _allowedIndices.indexOf(3))),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _kTextMain)),
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Card(
      color: _kSurface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kCardBorder),
      ),
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: _kPrimary),
        title: Text(label, style: const TextStyle(color: _kTextMain)),
        trailing: const Icon(Icons.chevron_right, color: _kTextSub),
        onTap: onTap,
      ),
    );
  }

  // ─── USUARIOS ────────────────────────────────────────────────────────────
  Widget _usersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Gestión de empleados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextMain),
            ),
          );
        }
        final u = _users[i - 1];
        return Card(
          color: _kSurface,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _kCardBorder),
          ),
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: u.active ? _kPrimary : Colors.grey.shade300,
              child: Text(
                u.name.substring(0, 1),
                style: TextStyle(
                  color: u.active ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(u.name, style: const TextStyle(color: _kTextMain)),
            subtitle: Text(
              '${u.email}\n${u.role}',
              style: const TextStyle(color: _kTextSub),
            ),
            isThreeLine: true,
            trailing: Switch(
              value: u.active,
              activeThumbColor: Colors.white,
              activeTrackColor: _kPrimary,
              onChanged: (v) async {
                setState(() => u.active = v);
                await AuditLogService.log(
                  'user_status_changed',
                  actor: widget.currentUser,
                  details: {'user': u.email, 'name': u.name, 'active': v},
                );
                _loadAuditLogs();
              },
            ),
          ),
        );
      },
    );
  }

  // ─── INFORMES ────────────────────────────────────────────────────────────
  Widget _reportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informes en PDF',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kTextMain),
          ),
          const SizedBox(height: 6),
          const Text('Genera, comparte o descarga los informes.', style: TextStyle(color: _kTextSub)),
          const SizedBox(height: 20),
          _reportCard(
            title: 'Informe de Empleados',
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
              await PdfService.generateSummaryReport(_users, _uploadedPdfs.length);
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
      color: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kCardBorder),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPrimary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(color: _kTextSub, fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }

  // ─── CARGAR ──────────────────────────────────────────────────────────────
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kTextMain),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text('Cargar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
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
                        Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('No hay PDFs cargados aún', style: TextStyle(color: _kTextSub)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _uploadedPdfs.length,
                    itemBuilder: (_, i) {
                      final item = _uploadedPdfs[i];
                      final sizeKb = (item.sizeBytes / 1024).toStringAsFixed(1);
                      final hashShort = item.sha256Hash != null
                          ? '${item.sha256Hash!.substring(0, 16)}…'
                          : null;
                      return Card(
                        color: _kSurface,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _kCardBorder),
                        ),
                        elevation: 0,
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                          title: Text(item.name, style: const TextStyle(color: _kTextMain)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$sizeKb KB', style: const TextStyle(color: _kTextSub, fontSize: 12)),
                              if (hashShort != null)
                                Tooltip(
                                  message: 'SHA-256: ${item.sha256Hash}',
                                  child: Row(
                                    children: [
                                      Icon(Icons.verified_user, size: 12, color: Colors.green.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SHA-256: $hashShort',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade700,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          isThreeLine: hashShort != null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new, color: _kPrimary),
                                tooltip: 'Abrir',
                                onPressed: () async {
                                  await AuditLogService.log(
                                    'pdf_opened',
                                    actor: widget.currentUser,
                                    details: {'name': item.name},
                                  );
                                  _loadAuditLogs();
                                  final bytes = kIsWeb
                                      ? item.bytes
                                      : await item.file?.readAsBytes();
                                  if (bytes != null) {
                                    await PdfService.openPdf(item.name, bytes);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Eliminar',
                                onPressed: () async {
                                  if (kIsWeb) {
                                    if (!mounted) return;
                                    setState(() => _uploadedPdfs.removeAt(i));
                                  } else {
                                    await item.file?.delete();
                                    await _loadPdfs();
                                  }
                                  await AuditLogService.log(
                                    'pdf_deleted',
                                    actor: widget.currentUser,
                                    details: {'name': item.name},
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

  // ─── AUDITORÍA ───────────────────────────────────────────────────────────
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kTextMain),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _loadAuditLogs,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Historial de acciones del sistema', style: TextStyle(color: _kTextSub)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todas', 'all'),
                _filterChip('Logins', 'login_success'),
                _filterChip('Fallidos', 'login_failed'),
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
                        Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _filterAction == 'all'
                              ? 'No hay registros aún'
                              : 'No hay registros para esta actividad',
                          style: const TextStyle(color: _kTextSub),
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
                        color: _kSurface,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _kCardBorder),
                        ),
                        elevation: 0,
                        child: ExpansionTile(
                          title: Text(
                            log.action,
                            style: const TextStyle(color: _kTextMain, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${log.actor} • $time',
                            style: const TextStyle(color: _kTextSub, fontSize: 12),
                          ),
                          leading: _getActionIcon(log.action),
                          trailing: Text(
                            date,
                            style: const TextStyle(color: _kTextSub, fontSize: 11),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Detalles:',
                                    style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  if (log.details != null)
                                    Text(
                                      log.details.toString(),
                                      style: const TextStyle(color: _kTextSub, fontSize: 11, fontFamily: 'monospace'),
                                    )
                                  else
                                    const Text('Sin detalles adicionales', style: TextStyle(color: _kTextSub)),
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
        selectedColor: _kPrimary,
        backgroundColor: _kSurface,
        side: const BorderSide(color: _kCardBorder),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : _kTextSub,
          fontSize: 12,
        ),
      ),
    );
  }

  Icon _getActionIcon(String action) {
    switch (action) {
      case 'login_success':
        return Icon(Icons.login, color: Colors.green.shade600);
      case 'login_failed':
        return Icon(Icons.cancel, color: Colors.red.shade400);
      case 'logout':
        return Icon(Icons.logout, color: Colors.orange.shade400);
      case 'user_status_changed':
        return const Icon(Icons.person_outline, color: _kPrimary);
      case 'report_generated':
        return Icon(Icons.description, color: Colors.blue.shade400);
      case 'pdf_uploaded':
        return const Icon(Icons.upload, color: _kAccent);
      case 'pdf_opened':
        return Icon(Icons.open_in_new, color: Colors.amber.shade600);
      case 'pdf_deleted':
        return Icon(Icons.delete, color: Colors.red.shade600);
      default:
        return Icon(Icons.info, color: Colors.grey.shade400);
    }
  }
}
