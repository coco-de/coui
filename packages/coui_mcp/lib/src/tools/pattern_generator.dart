import 'dart:convert';

import 'package:coui_mcp/src/tools/jaspr/jaspr_pattern_templates.dart';
import 'package:coui_mcp/src/tools/platform_target.dart';

/// Pattern-based screen and layout generator.
///
/// Supports both `coui_flutter` and `coui_web` (Jaspr) targets via
/// the `target` argument. Defaults to `flutter` when omitted.
class PatternGenerator {
  /// Generate a complete screen from a pattern
  static Map<String, dynamic> generatePattern(Map<String, dynamic> args) {
    final patternName = args['pattern_name'] as String;
    final customization = args['customization'] as Map<String, dynamic>? ?? {};
    final target = PlatformTarget.parse(args['target'] as String?);

    String code;
    String? note;
    if (target == PlatformTarget.jaspr) {
      final jasprCode = JasprPatternTemplates.generate(
        patternName,
        customization,
      );
      if (jasprCode != null) {
        code = jasprCode;
      } else {
        // Fall back to Flutter code with a clear note so callers
        // can decide whether to port or use a different pattern.
        code = _generatePatternCode(patternName, customization);
        note =
            'Pattern "$patternName" is not yet ported to Jaspr; '
            'returning Flutter code. Supported Jaspr patterns: '
            'login, form, dashboard.';
      }
    } else {
      code = _generatePatternCode(patternName, customization);
    }

    final body = <String, dynamic>{
      'target': target.name,
      'pattern': patternName,
      'code': code,
      'description': _getPatternDescription(patternName),
    };
    if (note != null) body['note'] = note;

    return {
      'content': [
        {'type': 'text', 'text': json.encode(body)},
      ],
    };
  }

  /// List all available patterns
  static Map<String, dynamic> listPatterns(Map<String, dynamic> args) {
    final patterns = _getAllPatterns();

    return {
      'content': [
        {
          'type': 'text',
          'text': json.encode({
            'patterns': patterns,
            'count': patterns.length,
          }),
        },
      ],
    };
  }

  static String _generatePatternCode(
    String patternName,
    Map<String, dynamic> customization,
  ) {
    switch (patternName.toLowerCase()) {
      case 'login':
        return _generateLoginPattern(customization);
      case 'profile':
        return _generateProfilePattern(customization);
      case 'dashboard':
        return _generateDashboardPattern(customization);
      case 'list-detail':
        return _generateListDetailPattern(customization);
      case 'settings':
        return _generateSettingsPattern(customization);
      case 'form':
        return _generateFormPattern(customization);
      case 'crud':
        return _generateCrudPattern(customization);
      case 'master-detail':
        return _generateMasterDetailPattern(customization);
      default:
        return _generateDefaultPattern(customization);
    }
  }

  static String _generateLoginPattern(Map<String, dynamic> customization) {
    final title = customization['title'] as String? ?? 'Login';
    final showSocialLogin = customization['social_login'] as bool? ?? false;

    return '''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$title',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Input(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      Input(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: true,
                        required: true,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: LinkButton(
                          onPressed: () {
                            // TODO: Navigate to forgot password
                          },
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        size: ButtonSize.large,
                        onPressed: _handleLogin,
                        child: const Text('Login'),
                      ),${showSocialLogin ? '''
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlineButton(
                        size: ButtonSize.large,
                        onPressed: () {
                          // TODO: Google login
                        },
                        leading: Icon(Icons.g_mobiledata),
                        child: const Text('Continue with Google'),
                      ),''' : ''}
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Don\\'t have an account? '),
                          LinkButton(
                            onPressed: () {
                              // TODO: Navigate to signup
                            },
                            child: const Text('Sign up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement login logic
    }
  }
}
''';
  }

  static String _generateProfilePattern(Map<String, dynamic> customization) {
    final editable = customization['editable'] as bool? ?? true;

    return '''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ${editable ? '''
  final _nameController = TextEditingController(text: 'John Doe');
  final _emailController = TextEditingController(text: 'john@example.com');
  final _bioController = TextEditingController(text: 'Flutter developer');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  ''' : ''}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          ${editable ? '''
          PrimaryButton(
            onPressed: _handleSave,
            child: const Text('Save'),
          ),
          ''' : ''}
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Avatar(
                    size: AvatarSize.xl,
                    initials: 'JD',
                  ),
                  ${editable ? '''
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleButton(
                      size: ButtonSize.sm,
                      onPressed: () {
                        // TODO: Change avatar
                      },
                      child: Icon(Icons.camera_alt, size: 16),
                    ),
                  ),
                  ''' : ''}
                ],
              ),
            ),
            const SizedBox(height: 32),
            ${editable ? '''
            Input(
              label: 'Name',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            Input(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextArea(
              label: 'Bio',
              controller: _bioController,
              maxLines: 3,
            ),
            ''' : '''
            _buildInfoRow('Name', 'John Doe'),
            _buildInfoRow('Email', 'john@example.com'),
            _buildInfoRow('Bio', 'Flutter developer'),
            '''}
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('Notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                    ),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.language),
                    title: Text('Language'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.security),
                    title: Text('Privacy'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ${editable ? '''
  void _handleSave() {
    // TODO: Save profile changes
  }
  ''' : ''}

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
''';
  }

  static String _generateDashboardPattern(Map<String, dynamic> customization) {
    final widgets =
        customization['widgets'] as List? ?? ['stats', 'chart', 'activity'];

    return '''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ${widgets.contains('stats') ? '''
            _buildStatsSection(),
            const SizedBox(height: 16),
            ''' : ''}
            ${widgets.contains('chart') ? '''
            _buildChartSection(),
            const SizedBox(height: 16),
            ''' : ''}
            ${widgets.contains('activity') ? '''
            _buildActivitySection(),
            ''' : ''}
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Users', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('1,234', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Badge(
                    variant: BadgeVariant.success,
                    child: Text('+12%'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('\\\$45,678', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Badge(
                    variant: BadgeVariant.success,
                    child: Text('+8%'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              color: Colors.grey[200],
              child: Center(
                child: Text('Chart Placeholder'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: Avatar(size: AvatarSize.sm, initials: 'U\$index'),
                title: Text('User activity \$index'),
                subtitle: Text('2 hours ago'),
                trailing: Icon(Icons.chevron_right),
              );
            },
          ),
        ],
      ),
    );
  }
}
''';
  }

  static String _generateListDetailPattern(Map<String, dynamic> customization) {
    return r'''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({super.key});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
      ),
      body: Row(
        children: [
          // List view
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return ListTile(
                  selected: isSelected,
                  title: Text('Item $index'),
                  subtitle: Text('Description for item $index'),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          VerticalDivider(width: 1),
          // Detail view
          Expanded(
            flex: 2,
            child: _selectedIndex != null
                ? _buildDetailView(_selectedIndex!)
                : Center(
                    child: Text('Select an item to view details'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item $index',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              PrimaryButton(
                onPressed: () {},
                child: Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Description for item $index'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Additional information about item $index'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
''';
  }

  static String _generateSettingsPattern(Map<String, dynamic> customization) {
    return '''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Preferences',
            children: [
              SwitchListTile(
                title: Text('Notifications'),
                subtitle: Text('Enable push notifications'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Dark Mode'),
                subtitle: Text('Use dark theme'),
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Account',
            children: [
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.security),
                title: Text('Privacy'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.lock),
                title: Text('Change Password'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                leading: Icon(Icons.info),
                title: Text('Version'),
                trailing: Text('1.0.0'),
              ),
              ListTile(
                leading: Icon(Icons.description),
                title: Text('Terms of Service'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Privacy Policy'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DestructiveButton(
              size: ButtonSize.large,
              onPressed: () {},
              child: Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
''';
  }

  static String _generateFormPattern(Map<String, dynamic> customization) {
    // Reserved for future dynamic form field generation
    // ignore: unused_local_variable
    final fields = customization['fields'] as List? ?? [];

    return '''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TODO: Add form fields
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                    },
                    child: Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: Submit form
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
  }

  static String _generateCrudPattern(Map<String, dynamic> customization) {
    final entityName = customization['entity_name'] as String? ?? 'Item';

    return '''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ${entityName}ListScreen extends StatefulWidget {
  const ${entityName}ListScreen({super.key});

  @override
  State<${entityName}ListScreen> createState() => _${entityName}ListScreenState();
}

class _${entityName}ListScreenState extends State<${entityName}ListScreen> {
  // TODO: Add state management

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${entityName}s'),
        actions: [
          PrimaryButton(
            onPressed: () {
              // TODO: Navigate to create screen
            },
            leading: Icon(Icons.add),
            child: Text('Add'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10, // TODO: Use actual data
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('$entityName \$index'),
              subtitle: Text('Description'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Edit'),
                    onTap: () {
                      // TODO: Edit item
                    },
                  ),
                  PopupMenuItem(
                    child: Text('Delete'),
                    onTap: () {
                      // TODO: Delete item
                    },
                  ),
                ],
              ),
              onTap: () {
                // TODO: View details
              },
            ),
          );
        },
      ),
    );
  }
}
''';
  }

  static String _generateMasterDetailPattern(
    Map<String, dynamic> customization,
  ) {
    return _generateListDetailPattern(customization);
  }

  static String _generateDefaultPattern(Map<String, dynamic> customization) {
    return '''
import 'package:flutter/material.dart';
import 'package:coui_flutter/coui_flutter.dart';

class CustomScreen extends StatelessWidget {
  const CustomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen'),
      ),
      body: Center(
        child: Text('Screen content'),
      ),
    );
  }
}
''';
  }

  static String _getPatternDescription(String patternName) {
    switch (patternName.toLowerCase()) {
      case 'login':
        return 'A complete login screen with email/password fields and optional social login';
      case 'profile':
        return 'User profile screen with editable fields and settings';
      case 'dashboard':
        return 'Dashboard with stats, charts, and activity feed';
      case 'list-detail':
        return 'Master-detail layout with list and detail view';
      case 'settings':
        return 'Settings screen with sections and switches';
      case 'form':
        return 'Generic form screen with validation';
      case 'crud':
        return 'Complete CRUD (Create, Read, Update, Delete) interface';
      case 'master-detail':
        return 'Responsive master-detail layout';
      default:
        return 'Custom screen pattern';
    }
  }

  static List<Map<String, dynamic>> _getAllPatterns() {
    return [
      {
        'name': 'login',
        'displayName': 'Login Screen',
        'description': 'Authentication screen with email/password',
        'category': 'auth',
      },
      {
        'name': 'profile',
        'displayName': 'Profile Screen',
        'description': 'User profile with editable fields',
        'category': 'user',
      },
      {
        'name': 'dashboard',
        'displayName': 'Dashboard',
        'description': 'Dashboard with stats and charts',
        'category': 'overview',
      },
      {
        'name': 'list-detail',
        'displayName': 'List-Detail',
        'description': 'Master-detail split view',
        'category': 'layout',
      },
      {
        'name': 'settings',
        'displayName': 'Settings',
        'description': 'Settings screen with sections',
        'category': 'configuration',
      },
      {
        'name': 'form',
        'displayName': 'Form',
        'description': 'Generic form with validation',
        'category': 'input',
      },
      {
        'name': 'crud',
        'displayName': 'CRUD Interface',
        'description': 'Complete create/read/update/delete',
        'category': 'data',
      },
      {
        'name': 'master-detail',
        'displayName': 'Master-Detail',
        'description': 'Responsive master-detail layout',
        'category': 'layout',
      },
    ];
  }
}
