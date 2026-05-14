/// 编辑资料页 —— 修改头像 / 昵称 / 个性签名。
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../constants/app_constants.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _localStorage = LocalStorageService();
  final _nameController = TextEditingController();
  final _signatureController = TextEditingController();
  String _avatarUrl = '';
  bool _isLoading = true;

  final _presetAvatars = [
    'https://api.dicebear.com/9.x/avataaars/png?seed=traveler1',
    'https://api.dicebear.com/9.x/avataaars/png?seed=explorer2',
    'https://api.dicebear.com/9.x/avataaars/png?seed=wanderer3',
    'https://api.dicebear.com/9.x/avataaars/png?seed=adventurer4',
    'https://api.dicebear.com/9.x/avataaars/png?seed=voyager5',
    'https://api.dicebear.com/9.x/avataaars/png?seed=pilot6',
    'https://api.dicebear.com/9.x/avataaars/png?seed=sailor7',
    'https://api.dicebear.com/9.x/avataaars/png?seed=captain8',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await _localStorage.getUsername() ?? '';
    final sig = await _localStorage.getSignature();
    final avt = await _localStorage.getAvatar();
    _nameController.text = name;
    _signatureController.text = sig;
    if (mounted) setState(() { _avatarUrl = avt; _isLoading = false; });
  }

  Future<void> _saveProfile() async {
    await _localStorage.setUsername(_nameController.text.trim());
    await _localStorage.setSignature(_signatureController.text.trim());
    await _localStorage.setAvatar(_avatarUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资料已保存'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('编辑资料')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppConstants.scaffoldBg,
      appBar: AppBar(
        title: const Text('编辑资料'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── 头像 ──
          const Text('选择头像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
          const SizedBox(height: 4),
          Text('点击选择你喜欢的头像风格', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 12, children: _presetAvatars.map((url) {
            final selected = _avatarUrl == url;
            return GestureDetector(
              onTap: () => setState(() => _avatarUrl = url),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppConstants.primaryColor : Colors.transparent, width: 3),
                  boxShadow: selected ? [BoxShadow(color: AppConstants.primaryColor.withValues(alpha: 0.3), blurRadius: 8)] : [],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(url),
                ),
              ),
            );
          }).toList(),
          ),

          const SizedBox(height: 8),
          // 自定义 URL
          TextButton.icon(
            onPressed: () => _showUrlDialog(),
            icon: const Icon(Icons.link, size: 16),
            label: const Text('使用自定义图片链接'),
          ),

          const SizedBox(height: 28),

          // ── 昵称 ──
          const Text('昵称', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 15, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: '输入你的昵称',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 24),

          // ── 个性签名 ──
          const Text('个性签名', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
          const SizedBox(height: 10),
          TextField(
            controller: _signatureController,
            maxLines: 2,
            maxLength: 50,
            style: const TextStyle(fontSize: 15, color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: '写一句话介绍自己...',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 32),

          // ── 保存按钮 ──
          GestureDetector(
            onTap: _saveProfile,
            child: Container(height: AppConstants.buttonHeight,
              decoration: BoxDecoration(gradient: AppConstants.primaryGradient, borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: const Center(child: Text('保存修改', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2))),
            ),
          ),
        ]),
      ),
    );
  }

  void _showUrlDialog() {
    final controller = TextEditingController(text: _avatarUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('自定义头像链接'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: '输入图片URL', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () {
            setState(() => _avatarUrl = controller.text.trim());
            Navigator.pop(ctx);
          }, child: const Text('确定')),
        ],
      ),
    );
  }
}
