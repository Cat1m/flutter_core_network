// example/lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_core_network/flutter_core_network.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentEnvironment = 'JSONPlaceholder';
  bool _loggingEnabled = true;

  final Map<String, String> _environments = {
    'JSONPlaceholder': 'https://jsonplaceholder.typicode.com',
    'Development': 'https://dev-api.example.com',
    'Staging': 'https://staging-api.example.com',
    'Production': 'https://api.example.com',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Network Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Environment'),
                  subtitle: Text(_currentEnvironment),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  onTap: _showEnvironmentSelector,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Enable Logging'),
                  subtitle: const Text('Log network requests and responses'),
                  value: _loggingEnabled,
                  onChanged: _toggleLogging,
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Test Connection'),
                  subtitle: const Text('Test network connectivity'),
                  trailing: const Icon(Icons.network_check),
                  onTap: _testConnection,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Clear all cached data'),
                  trailing: const Icon(Icons.clear_all),
                  onTap: _clearCache,
                ),
              ],
            ),
          ),
          const ListTile(
            title: Text(
              'Package Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: const [
                ListTile(
                  title: Text('Package'),
                  subtitle: Text('flutter_core_network'),
                ),
                Divider(height: 1),
                ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
                Divider(height: 1),
                ListTile(title: Text('Author'), subtitle: Text('Your Name')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEnvironmentSelector() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Environment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _environments.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.key),
                      subtitle: Text(entry.value),
                      value: entry.key,
                      groupValue: _currentEnvironment,
                      onChanged: (value) {
                        Navigator.pop(context);
                        _changeEnvironment(value!);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _changeEnvironment(String environment) {
    setState(() {
      _currentEnvironment = environment;
    });

    // Reinitialize network service with new environment
    NetworkService.initialize(
      NetworkConfig(
        baseUrl: _environments[environment]!,
        enableLogging: _loggingEnabled,
        maxRetries: 3,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Environment changed to $environment'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleLogging(bool value) {
    setState(() {
      _loggingEnabled = value;
    });

    // Reinitialize with updated logging setting
    NetworkService.initialize(
      NetworkConfig(
        baseUrl: _environments[_currentEnvironment]!,
        enableLogging: value,
        maxRetries: 3,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logging ${value ? 'enabled' : 'disabled'}')),
    );
  }

  void _testConnection() async {
    try {
      final networkService = NetworkService.instance;
      await networkService.get('/users/1');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearCache() {
    // Implement cache clearing logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
