/// 登录 / 注册页面 —— 沉浸式渐变背景 + 半透明卡片 + 校验逻辑。
///
/// 核心功能：
/// - 用户名 / 密码 / 确认密码表单
/// - 登录态本地持久化（LocalStorageService）
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../constants/app_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  bool _obscurePassword = true;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;

  final _localStorage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    final listeners = [_usernameFocus, _passwordFocus, _confirmFocus];
    for (final node in listeners) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// 处理登录/注册提交
  ///
  /// 1. 校验用户名密码非空
  /// 2. 注册模式下校验两次密码一致
  /// 3. 调用 [LocalStorageService.saveUserInfo] 持久化
  /// 4. 跳转到主页并销毁登录页
  void _handleSubmit() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户名和密码不能为空')),
      );
      return;
    }

    if (!_isLogin && password != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的密码不一致')),
      );
      return;
    }

    setState(() => _isLoading = true);

    _localStorage.saveUserInfo(username).then((_) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ========== 渐变背景 ==========
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppConstants.primaryGradient),
          ),

          // ========== 装饰性半透明圆形 ==========
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ========== 安全区域内容 ==========
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isLogin ? Icons.flight_takeoff : Icons.person_add,
                        size: 40,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.gapLarge),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textWhite,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppConstants.gapSmall),
                    Text(
                      AppConstants.appSlogan,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ========== 半透明白色卡片 ==========
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? AppConstants.loginTitle : AppConstants.registerTitle,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLogin ? AppConstants.loginSubtitle : AppConstants.registerSubtitle,
                              style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary),
                            ),
                            const SizedBox(height: AppConstants.gapLarge),

                            _buildInputField(
                              controller: _usernameController,
                              focusNode: _usernameFocus,
                              label: '用户名',
                              hint: '请输入用户名',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: AppConstants.gapMedium),

                            _buildInputField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              label: '密码',
                              hint: '请输入密码',
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            const SizedBox(height: AppConstants.gapMedium),

                            if (!_isLogin) ...[
                              _buildInputField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmFocus,
                                label: '确认密码',
                                hint: '请再次输入密码',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: AppConstants.gapMedium),
                            ],

                            const SizedBox(height: 4),

                            // 主按钮
                            GestureDetector(
                              onTap: _isLoading ? null : _handleSubmit,
                              child: Container(
                                height: AppConstants.buttonHeight,
                                decoration: BoxDecoration(
                                  gradient: AppConstants.primaryGradient,
                                  borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? AppConstants.btnLogin : AppConstants.btnRegister,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppConstants.textWhite,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 切换登录/注册
                            Center(
                              child: TextButton(
                                onPressed: _toggleMode,
                                child: Text(
                                  _isLogin ? AppConstants.toggleToRegister : AppConstants.toggleToLogin,
                                  style: const TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    final isFocused = focusNode.hasFocus;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppConstants.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isFocused ? AppConstants.primaryColor : AppConstants.textSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: isFocused ? AppConstants.primaryColor : Colors.grey[400]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400], size: 22),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusInput),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusInput),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
