import 'package:country_flags/country_flags.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _domainController = TextEditingController();

  // FocusNodes for each input field
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _domainFocusNode = FocusNode();

  // List of languages
  String _selectedLanguage = 'Language';

  final List<Map<String, dynamic>> _languages = [
    {
      'name': 'English',
      'flag': 'gb',
      'code1': 'en',
      'code2': 'US',
    },
    {
      'name': 'Deutsch',
      'flag': 'de',
      'code1': 'de',
      'code2': 'DE',
    },
    {
      'name': 'Türkçe',
      'flag': 'tr',
      'code1': 'tr',
      'code2': 'TR',
    },
    {
      'name': 'Italiano',
      'flag': 'it',
      'code1': 'it',
      'code2': 'IT',
    },
    {
      'name': 'Español',
      'flag': 'es',
      'code1': 'es',
      'code2': 'ES',
    },
  ];

  String _selectedProtocol = 'https';

  // List of protocol options
  final List<String> _protocolOptions = ['https', 'http', 'localhost'];


  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  void _tryAutoLogin() async {
    AuthProvider provider = Provider.of<AuthProvider>(context, listen: false);

    _selectedProtocol = provider.selectedProtocol;

    await provider.tryAutoLogin();
    if (Provider.of<AuthProvider>(context, listen: false).token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/projects');
    }
  }

  // Helper function to check for empty fields and focus on the first empty one
  bool _validateAndFocusFields() {
    if (_usernameController.text.isEmpty) {
      FocusScope.of(context).requestFocus(_usernameFocusNode);
      return false;
    }
    if (_passwordController.text.isEmpty) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
      return false;
    }
    if (_domainController.text.isEmpty) {
      FocusScope.of(context).requestFocus(_domainFocusNode);
      return false;
    }
    return true;
  }

  void _login() async {
    // Check if all fields are filled, focus on the first empty field
    if (_validateAndFocusFields()) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _selectedProtocol,
          _usernameController.text,
          _passwordController.text,
          _domainController.text,
          context,
        );
        Navigator.of(context).pushReplacementNamed('/projects');
      } catch (error) {
        debugPrint(error.toString());
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    _usernameController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _domainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    ///Init SelectedLanguage with current real language
    _selectedLanguage = _languages.firstWhere(
          (lang) => lang['code1'] == context.locale.languageCode && lang['code2'] == context.locale.countryCode,
    )['name'] as String;

    return Scaffold(
      appBar: AppBar(title: Text('login'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'login_fields.0'.tr()),
              focusNode: _usernameFocusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _login(), // Submit when Enter is pressed
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'login_fields.1'.tr()),
              obscureText: true,
              focusNode: _passwordFocusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _login(),
            ),
            TextField(
              controller: _domainController,
              decoration: InputDecoration(labelText: 'login_fields.2'.tr()),
              focusNode: _domainFocusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (result) => _login(),
            ),

            DropdownButton<String>(
              value: _selectedProtocol,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(color: Colors.black),
              underline: Container(
                height: 2,
                color: Colors.indigo,
              ),
              onChanged: (String? newProtocol) {
                setState(() {
                  _selectedProtocol = newProtocol!;
                });
              },
              items: _protocolOptions.map<DropdownMenuItem<String>>((protocol) {
                return DropdownMenuItem<String>(
                  value: protocol,
                  child: Text(protocol.toUpperCase()),
                );
              }).toList(),
            ),

            // Language dropdown
            DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(color: Colors.black),
              underline: Container(
                height: 2,
                color: Colors.indigo,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;

                  // Find the selected language's locale codes
                  final selectedLanguageData = _languages.firstWhere(
                        (lang) => lang['name'] == _selectedLanguage,
                  );

                  // Set the locale using the found language and region codes
                  context.setLocale(Locale(selectedLanguageData['code1'], selectedLanguageData['code2']));
                });
              },
              items: _languages.map<DropdownMenuItem<String>>((language) {
                return DropdownMenuItem<String>(
                  value: language['name'],
                  child: Row(
                    children: [
                      CountryFlag.fromLanguageCode(
                        language['code1'],
                        // shape: const Circle(),
                        shape: const RoundedRectangle(6),
                        height: 20,
                        width: 30,
                      ),
                      const SizedBox(width: 10),
                      Text(language['name']),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _login,
              child: Text('login'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}