import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSearching = false;
  Map<String, dynamic>? _searchResult; // user doc data

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _followUser(String otherUserId) async {
    if (_currentUserId == null || otherUserId == _currentUserId) return;

    final myFollowingRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('following')
        .doc(otherUserId);

    final otherFollowersRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('followers')
        .doc(_currentUserId);

    print('Tentando seguir: currentUid=${FirebaseAuth.instance.currentUser?.uid}, other=$otherUserId');

    // 1) escreve na sua lista "following"
    try {
      await myFollowingRef.set({'since': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Falha ao escrever em users/$_currentUserId/following/$otherUserId : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao seguir (following): $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // 2) escreve na lista "followers" do outro usuário
    try {
      await otherFollowersRef.set({'since': FieldValue.serverTimestamp()});
    } catch (e) {
      // se falhar aqui, revertemos a primeira escrita para manter consistência simples
      print('Falha ao escrever em users/$otherUserId/followers/$_currentUserId : $e');
      try {
        await myFollowingRef.delete();
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao seguir (followers): $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário seguido com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _unfollowUser(String otherUserId) async {
    if (_currentUserId == null) return;

    final myFollowingRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('following')
        .doc(otherUserId);

    final otherFollowersRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('followers')
        .doc(_currentUserId);

    // Tentar remover na sua lista
    try {
      await myFollowingRef.delete();
    } catch (e) {
      print('Falha ao deletar users/$_currentUserId/following/$otherUserId : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deixar de seguir (following): $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Tentar remover na lista de followers do outro usuário
    try {
      await otherFollowersRef.delete();
    } catch (e) {
      // se falhar, a remoção parcial foi feita; informe o erro
      print('Falha ao deletar users/$otherUserId/followers/$_currentUserId : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deixar de seguir (followers): $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário deixado de seguir!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _blockUser(String otherUserId) async {
    if (_currentUserId == null || otherUserId == _currentUserId) return;
    
    try {
      final myBlockedRef = _firestore.collection('users').doc(_currentUserId).collection('blocked').doc(otherUserId);
      
      // 1) Adicionar à lista de bloqueados
      await myBlockedRef.set({'since': FieldValue.serverTimestamp()});
      
      // 2) Verificar se o usuário está sendo seguido e remover o follow
      final myFollowingRef = _firestore.collection('users').doc(_currentUserId).collection('following').doc(otherUserId);
      final followingDoc = await myFollowingRef.get();
      
      if (followingDoc.exists) {
        // Se está seguindo, deixar de seguir
        try {
          await myFollowingRef.delete();
          
          // Remover também da lista de followers do outro usuário
          final otherFollowersRef = _firestore.collection('users').doc(otherUserId).collection('followers').doc(_currentUserId);
          await otherFollowersRef.delete();
        } catch (e) {
          print('Erro ao remover follow ao bloquear: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário bloqueado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao bloquear usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao bloquear usuário: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _unblockUser(String otherUserId) async {
    if (_currentUserId == null) return;
    
    try {
      final myBlockedRef = _firestore.collection('users').doc(_currentUserId).collection('blocked').doc(otherUserId);
      await myBlockedRef.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário desbloqueado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao desbloquear usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao desbloquear usuário: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _searchByEmail(String email) async {
    setState(() {
      _isSearching = true;
      _searchResult = null;
    });

    final q = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (q.docs.isNotEmpty) {
      setState(() {
        _searchResult = {...q.docs.first.data(), 'uid': q.docs.first.id};
      });
    } else {
      setState(() {
        _searchResult = null;
      });
    }

    setState(() {
      _isSearching = false;
    });
  }

  Widget _buildUserTile(Map<String, dynamic> userData, {required bool showBlock}) {
    final uid = userData['uid'] as String?;
    final name = userData['name'] as String? ?? '';
    final email = userData['email'] as String? ?? '';
    final isMe = uid == _currentUserId;

    return ListTile(
      title: Text(name.isNotEmpty ? name : email),
      subtitle: Text(email),
      trailing: SizedBox(
        width: 200, // Aumentar espaço para os dois botões
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (!isMe)
              Flexible(
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(_currentUserId).collection('following').doc(uid).get(),
                  builder: (context, snap) {
                    final isFollowing = snap.hasData && snap.data!.exists;
                    return TextButton(
                      onPressed: () async {
                        if (isFollowing)
                          await _unfollowUser(uid!);
                        else
                          await _followUser(uid!);
                        setState(() {}); // refresh UI
                      },
                      child: Text(isFollowing ? 'Seguindo' : 'Seguir', style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
            if (!isMe && showBlock)
              Flexible(
                child: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(_currentUserId).collection('blocked').doc(uid).get(),
                  builder: (context, snap) {
                    final isBlocked = snap.hasData && snap.data!.exists;
                    return TextButton(
                      onPressed: () async {
                        if (isBlocked)
                          await _unblockUser(uid!);
                        else
                          await _blockUser(uid!);
                        setState(() {});
                      },
                      child: Text(
                        isBlocked ? 'Desbloquear' : 'Bloquear',
                        style: TextStyle(
                          fontSize: 12,
                          color: isBlocked ? Colors.orange : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _followingTab() {
    if (_currentUserId == null) return const Center(child: Text('Usuário não autenticado.'));
    final col = _firestore.collection('users').doc(_currentUserId).collection('following').orderBy('since', descending: true);
    return StreamBuilder<QuerySnapshot>(
      stream: col.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Você não segue ninguém.'));
        return ListView(
          children: docs.map((d) {
            final otherId = d.id;
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(otherId).get(),
              builder: (context, s2) {
                if (!s2.hasData) return const ListTile(title: Text('Carregando...'));
                final data = s2.data!.data() as Map<String, dynamic>? ?? {};
                data['uid'] = s2.data!.id;
                return _buildUserTile(data, showBlock: true);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _followersTab() {
    if (_currentUserId == null) return const Center(child: Text('Usuário não autenticado.'));
    final col = _firestore.collection('users').doc(_currentUserId).collection('followers').orderBy('since', descending: true);
    return StreamBuilder<QuerySnapshot>(
      stream: col.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Ninguém segue você ainda.'));
        return ListView(
          children: docs.map((d) {
            final otherId = d.id;
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(otherId).get(),
              builder: (context, s2) {
                if (!s2.hasData) return const ListTile(title: Text('Carregando...'));
                final data = s2.data!.data() as Map<String, dynamic>? ?? {};
                data['uid'] = s2.data!.id;
                return _buildUserTile(data, showBlock: true);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _blockedTab() {
    if (_currentUserId == null) return const Center(child: Text('Usuário não autenticado.'));
    final col = _firestore.collection('users').doc(_currentUserId).collection('blocked').orderBy('since', descending: true);
    return StreamBuilder<QuerySnapshot>(
      stream: col.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Você não bloqueou ninguém.'));
        return ListView(
          children: docs.map((d) {
            final otherId = d.id;
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(otherId).get(),
              builder: (context, s2) {
                if (!s2.hasData) return const ListTile(title: Text('Carregando...'));
                final data = s2.data!.data() as Map<String, dynamic>? ?? {};
                data['uid'] = s2.data!.id;
                return _buildUserTile(data, showBlock: false); // already blocked: show unblock option only
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seguindo / Seguidores / Bloqueados')),
        body: const Center(child: Text('Você precisa entrar para acessar esta tela.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Seguindo'),
            Tab(text: 'Seguidores'),
            Tab(text: 'Bloqueados'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Procurar por e-mail para seguir...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : () => _searchByEmail(_searchController.text.trim()),
                  child: _isSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buscar'),
                ),
              ],
            ),
          ),
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _searchResult == null
                  ? const Text('Nenhum usuário encontrado.')
                  : Card(child: _buildUserTile(_searchResult!, showBlock: true)),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _followingTab(),
                _followersTab(),
                _blockedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}