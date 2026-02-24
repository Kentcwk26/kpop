import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'about.dart';
import 'utils/image_responsive.dart';
import 'utils/snackbar_helper.dart';
import 'widgets/color_picker.dart';

class SettingsScreen extends StatefulWidget {
  final UserData user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserData _user;
  bool loading = false;

  String _theme = 'Default';
  String _language = 'en';
  Color _primaryColor = Colors.amber;
  Color _secondaryColor = Colors.pink;
  Color _appBarColor = Colors.blue;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("resetAllData".tr()),
        content: Text(
          'This will delete all your creations and reset all settings. This action cannot be undone.'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SnackBarHelper.showError(context, 'All data has been reset'.tr());
            },
            child: Text(
              "resetAllData".tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    const shareUrl = 'https://test-92558.web.app/';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${"shareApp".tr()} K-Hub'),
        content: Row(
          children: [
            Expanded(child: Text(shareUrl, style: const TextStyle(color: Colors.blue))),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: shareUrl));
                SnackBarHelper.showSuccess(context, 'Copied to clipboard!'.tr());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await launchUrl(Uri.parse(shareUrl));
            },
            child: Text('Open Page'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorSelected) {
    showDialog(
      context: context,
      builder: (_) => ColorPickerDialog(currentColor: currentColor, onColorSelected: onColorSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("settings".tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 30),

            _sectionTitle("appearance".tr()),
            _buildThemeSection(),
            _buildLanguageSection(),

            _buildSectionHeader("support".tr()),
            _buildSettingItem("faq".tr(), Icons.help, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FAQScreen()))),
            _buildSettingItem("contactUs".tr(), Icons.email, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactScreen()))),

            _buildSettingItem(
              "rateApp".tr(),
              Icons.star,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RateAppWebViewPage(),
                  ),
                );
              },
            ),

            _buildSettingItem("shareApp".tr(), Icons.share, onTap: _showShareDialog),

            _buildSectionHeader("about".tr()),
            _buildSettingItem("aboutKHub".tr(), Icons.info, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen()))),
            _buildSettingItem("privacyPolicy".tr(), Icons.privacy_tip, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()))),
            _buildSettingItem("termsOfService".tr(), Icons.description, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TermsOfServiceScreen()))),

            _buildSectionHeader("dangerZone".tr()),
            _buildDangerItem("resetAllData".tr(), Icons.warning, onTap: _showResetDialog),

            const SizedBox(height: 20),
            Center(child: Text('${"appVersion".tr()} v1.0.0', style: const TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              child: ResponsiveZoomableImage(
                imagePath: _user.photoUrl.isNotEmpty ? _user.photoUrl : 'assets/images/defaultprofile.jpg',
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          child: SafeAvatar(url: _user.photoUrl, size: 100),
        ),
        const SizedBox(height: 12),
        Text(_user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _buildSettingItem(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  Widget _buildDangerItem(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  Widget _buildLanguageSection() {
    return _buildSettingItem(
      "language".tr(),
      Icons.language,
      onTap: () async {
        final newLang = await showDialog<String>(
          context: context,
          builder: (_) => SimpleDialog(
            title: Text('Select Language'.tr()),
            children: [
              SimpleDialogOption(child: Text('English'), onPressed: () => Navigator.pop(context, 'en')),
              SimpleDialogOption(child: Text('Korean'), onPressed: () => Navigator.pop(context, 'ko')),
            ],
          ),
        );
        if (newLang != null) setState(() => _language = newLang);
      },
    );
  }

  Widget _buildThemeSection() {
    return _buildSettingItem(
      "theme".tr(),
      Icons.color_lens,
      onTap: () {
        _showColorPicker(_primaryColor, (color) => setState(() => _primaryColor = color));
      },
    );
  }
}

class UserData {
  final String name;
  final String photoUrl;
  UserData({required this.name, required this.photoUrl});
}

class RateAppWebViewPage extends StatefulWidget {
  const RateAppWebViewPage({super.key});

  @override
  State<RateAppWebViewPage> createState() => _RateAppWebViewPageState();
}

class _RateAppWebViewPageState extends State<RateAppWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://forms.gle/PTnbYBC9wKxKuvJy5'),
      );

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate App"),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
