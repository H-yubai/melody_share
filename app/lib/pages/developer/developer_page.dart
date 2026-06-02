import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../services/api_service.dart';
import '../../services/developer_settings.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<DeveloperSettings>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('开发者模式')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.developer_mode, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('API 配置', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    controller: TextEditingController(text: settings.baseUrl),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        settings.setBaseUrl(value.trim());
                        ApiService.updateBaseUrl(value.trim());
                        toastification.show(
                          context: context,
                          title: const Text('Base URL 已更新'),
                          type: ToastificationType.success,
                          autoCloseDuration: const Duration(seconds: 2),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            settings.resetBaseUrl();
                            ApiService.updateBaseUrl(settings.baseUrl);
                            toastification.show(
                              context: context,
                              title: const Text('已重置为默认 URL'),
                              type: ToastificationType.success,
                              autoCloseDuration: const Duration(seconds: 2),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('重置为默认'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('调试选项', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('调试模式'),
                    subtitle: const Text('开启后显示详细日志和调试信息'),
                    value: settings.debugMode,
                    onChanged: (_) => settings.toggleDebugMode(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.groups, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('社交网络', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '社交功能开发中...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
