import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _user = FirebaseAuth.instance.currentUser;
  late final _profile = FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .snapshots();
  bool _signingOut = false;

  Future<void> _logout() async {
    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate removes this session's entire navigator.
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 48,
                backgroundImage: AssetImage('assets/icons/profile_avatar.png'),
              ),
            ),
            const SizedBox(height: 24),
            _detail('EMAIL', _user?.email ?? '-'),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profile,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                      'Profil belum dapat dimuat. Periksa koneksi dan coba kembali.');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data();
                if (data == null) {
                  return const Text(
                      'Profil belum tersedia. Silakan login ulang.');
                }
                final mbti = data['lastMbti'] as String? ?? '';
                final date = data['lastMbtiDate'];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _detail('USERNAME', data['username'] as String? ?? '-'),
                    _detail('POIN', '${data['points'] ?? 0}'),
                    _detail('MBTI TERAKHIR',
                        mbti.isEmpty ? 'Belum mengikuti tes' : mbti),
                    _detail(
                      'TANGGAL TES TERAKHIR',
                      mbti.isNotEmpty && date is Timestamp
                          ? DateFormat('yyyy-MM-dd HH:mm').format(date.toDate())
                          : '-',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _signingOut ? null : _logout,
              child: Text(_signingOut ? 'Keluar...' : 'Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
