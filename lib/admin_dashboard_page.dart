import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'admin_user_edit_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<PendingUser> _pending = [];
  List<AuthUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AuthService().getPendingUsers(),
      AuthService().getAllUsers(),
    ]);
    if (mounted) {
      setState(() {
        _pending = (results[0] as List<PendingUser>)
            .where((p) => p.status == 'pending')
            .toList();
        _users = (results[1] as List<AuthUser>)
            .where((u) => u.role != 'SuperAdmin')
            .toList();
        _loading = false;
      });
    }
  }

  Future<void> _approve(PendingUser p) async {
    await AuthService().approvePendingUser(p.nationalId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.fullName} approved.'),
        backgroundColor: kSuccess,
      ),
    );
    _load();
  }

  Future<void> _deny(PendingUser p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Deny Request'),
        content:
            Text('Deny account request for ${p.fullName} (${p.nationalId})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: kDanger),
            child: const Text('Deny',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().denyPendingUser(p.nationalId);
    _load();
  }

  Future<void> _deleteUser(AuthUser u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete User'),
        content: Text(
            'Permanently delete ${u.fullName} (${u.nationalId})?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: kDanger),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().deleteUser(u.nationalId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${u.fullName} deleted.'),
          backgroundColor: kDanger),
    );
    _load();
  }

  void _editUser(AuthUser u) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AdminUserEditPage(user: u)),
    );
    _load();
  }

  void _createUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const AdminUserEditPage(user: null)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final admin = AuthService().currentUser;

    return Scaffold(
      backgroundColor: kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(child: _header(admin)),
                SliverToBoxAdapter(
                  child: Container(
                    color: kCardBg,
                    child: TabBar(
                      controller: _tabs,
                      labelColor: kPrimary,
                      unselectedLabelColor: kTextSecondary,
                      indicatorColor: kPrimary,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Pending'),
                              if (_pending.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kWarning,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_pending.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('All Users'),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_users.length}',
                                  style: const TextStyle(
                                      color: kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabs,
                children: [
                  _PendingTab(
                    pending: _pending,
                    onApprove: _approve,
                    onDeny: _deny,
                    onRefresh: _load,
                  ),
                  _UsersTab(
                    users: _users,
                    onEdit: _editUser,
                    onDelete: _deleteUser,
                    onRefresh: _load,
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createUser,
        backgroundColor: kPrimary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('New User',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _header(AuthUser? admin) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 52, 22, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin?.fullName ?? 'Super Admin',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'System Administrator',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  AuthService().signOut();
                  Navigator.pushReplacementNamed(context, '/signin');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Logout',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pending tab ────────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  final List<PendingUser> pending;
  final Future<void> Function(PendingUser) onApprove;
  final Future<void> Function(PendingUser) onDeny;
  final Future<void> Function() onRefresh;

  const _PendingTab({
    required this.pending,
    required this.onApprove,
    required this.onDeny,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 52, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text('No pending approvals.',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary)),
            SizedBox(height: 4),
            Text('All account requests have been reviewed.',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final p = pending[i];
          return _PendingCard(
              user: p, onApprove: onApprove, onDeny: onDeny);
        },
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingUser user;
  final Future<void> Function(PendingUser) onApprove;
  final Future<void> Function(PendingUser) onDeny;

  const _PendingCard(
      {required this.user, required this.onApprove, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_roleIcon(user.role), color: roleColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: kTextPrimary)),
                    Text(user.nationalId,
                        style: const TextStyle(
                            fontSize: 12, color: kTextSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(user.role,
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.email_outlined,
                  size: 13, color: kTextSecondary),
              const SizedBox(width: 4),
              Text(user.email,
                  style: const TextStyle(
                      fontSize: 12, color: kTextSecondary)),
            ],
          ),
          if (user.licenseNumber != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.verified_outlined,
                    size: 13, color: kTextSecondary),
                const SizedBox(width: 4),
                Text(user.licenseNumber!,
                    style: const TextStyle(
                        fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 13, color: kTextSecondary),
              const SizedBox(width: 4),
              Text(_fmtDate(user.requestedAt),
                  style: const TextStyle(
                      fontSize: 12, color: kTextSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onDeny(user),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Deny'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kDanger,
                    side: const BorderSide(color: kDanger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onApprove(user),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuccess,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Users tab ──────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final List<AuthUser> users;
  final void Function(AuthUser) onEdit;
  final Future<void> Function(AuthUser) onDelete;
  final Future<void> Function() onRefresh;

  const _UsersTab({
    required this.users,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Text('No users yet.',
            style: TextStyle(color: kTextSecondary, fontSize: 14)),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final u = users[i];
          return _UserCard(user: u, onEdit: onEdit, onDelete: onDelete);
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AuthUser user;
  final void Function(AuthUser) onEdit;
  final Future<void> Function(AuthUser) onDelete;

  const _UserCard(
      {required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_roleIcon(user.role), color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kTextPrimary)),
                Text('${user.nationalId} · ${user.role}',
                    style: const TextStyle(
                        fontSize: 11, color: kTextSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onEdit(user),
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: kTextSecondary),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => onDelete(user),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: kDanger),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

Color _roleColor(String role) {
  switch (role) {
    case 'Doctor':
      return const Color(0xFF0F766E);
    case 'Pharmacist':
      return const Color(0xFF7C3AED);
    case 'SuperAdmin':
      return const Color(0xFF1E293B);
    default:
      return kPrimary;
  }
}

IconData _roleIcon(String role) {
  switch (role) {
    case 'Doctor':
      return Icons.medical_services_rounded;
    case 'Pharmacist':
      return Icons.local_pharmacy_rounded;
    case 'SuperAdmin':
      return Icons.admin_panel_settings_rounded;
    default:
      return Icons.person_rounded;
  }
}

String _fmtDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m $ampm';
}
