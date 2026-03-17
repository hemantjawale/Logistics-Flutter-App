import 'package:flutter/material.dart';
import '../services/api_client.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final drivers = await ApiClient.fetchDrivers();
      final customers = await ApiClient.fetchCustomers();
      setState(() {
        _drivers = drivers;
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drivers'),
              Tab(text: 'Customers'),
            ],
            indicatorColor: Colors.indigoAccent,
            labelColor: Colors.indigoAccent,
            unselectedLabelColor: Colors.white54,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _UserList(users: _drivers, role: 'driver', onUpdate: _loadUsers),
                  _UserList(users: _customers, role: 'customer', onUpdate: _loadUsers),
                ],
              ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String role;
  final VoidCallback onUpdate;

  const _UserList({required this.users, required this.role, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final id = user['_id'] ?? '';
        final status = user['status'] ?? 'Active';

        return Card(
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigoAccent.withOpacity(0.1),
              child: Text(user['name']?[0] ?? '?', style: const TextStyle(color: Colors.indigoAccent)),
            ),
            title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white54)),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) async {
                if (val == 'toggle') {
                  // Mock toggle status
                  await ApiClient.updateUser(id, {'status': status == 'Active' ? 'Suspended' : 'Active'});
                  onUpdate();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(status == 'Active' ? 'Suspend User' : 'Activate User'),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
