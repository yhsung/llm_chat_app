import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServiceType = ref.watch(selectedServiceTypeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'LLM Service',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<LlmServiceType>(
            title: const Text('OpenAI'),
            value: LlmServiceType.openAi,
            groupValue: selectedServiceType,
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedServiceTypeProvider.notifier).state = value;
              }
            },
          ),
          RadioListTile<LlmServiceType>(
            title: const Text('Azure OpenAI'),
            value: LlmServiceType.azureOpenAi,
            groupValue: selectedServiceType,
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedServiceTypeProvider.notifier).state = value;
              }
            },
          ),
          RadioListTile<LlmServiceType>(
            title: const Text('Ollama'),
            value: LlmServiceType.ollama,
            groupValue: selectedServiceType,
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedServiceTypeProvider.notifier).state = value;
              }
            },
          ),
          const Divider(),

          // Service-specific settings
          Builder(
            builder: (context) {
              switch (selectedServiceType) {
                case LlmServiceType.openAi:
                  return const OpenAiSettings();
                case LlmServiceType.azureOpenAi:
                  return const AzureOpenAiSettings();
                case LlmServiceType.ollama:
                  return const OllamaSettings();
              }
            },
          ),
        ],
      ),
    );
  }
}

class OpenAiSettings extends ConsumerStatefulWidget {
  const OpenAiSettings({super.key});

  @override
  ConsumerState<OpenAiSettings> createState() => _OpenAiSettingsState();
}

class _OpenAiSettingsState extends ConsumerState<OpenAiSettings> {
  final TextEditingController _apiKeyController = TextEditingController();
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final openAiService = ref.read(llmServiceFactoryProvider).openAiService;

      // Load API key
      final apiKey = await openAiService.getApiKey();
      _apiKeyController.text = apiKey ?? '';

      // Load current model
      final currentModel = await openAiService.getCurrentModel();

      // Load available models
      final models = await openAiService.getAvailableModels();

      setState(() {
        _selectedModel = currentModel;
        _availableModels = models;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final openAiService = ref.read(llmServiceFactoryProvider).openAiService;
      await openAiService.setApiKey(apiKey);
      await _loadSettings();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving API key: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveModel() async {
    if (_selectedModel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final openAiService = ref.read(llmServiceFactoryProvider).openAiService;
      await openAiService.setModel(_selectedModel!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Model saved')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving model: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OpenAI Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'Enter your OpenAI API key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveApiKey,
            child: const Text('Save API Key'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
            value: _selectedModel,
            items: _availableModels.map((model) {
              return DropdownMenuItem<String>(value: model, child: Text(model));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedModel = value;
              });
              _saveModel();
            },
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class AzureOpenAiSettings extends ConsumerStatefulWidget {
  const AzureOpenAiSettings({super.key});

  @override
  ConsumerState<AzureOpenAiSettings> createState() =>
      _AzureOpenAiSettingsState();
}

class _AzureOpenAiSettingsState extends ConsumerState<AzureOpenAiSettings> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _apiVersionController = TextEditingController();
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _apiVersionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final azureService = ref
          .read(llmServiceFactoryProvider)
          .azureOpenAiService;

      // Load API key
      final apiKey = await azureService.getApiKey();
      _apiKeyController.text = apiKey ?? '';

      // Load endpoint
      final endpoint = await azureService.getEndpoint();
      _endpointController.text = endpoint ?? '';

      // Load API version
      final apiVersion = await azureService.getApiVersion();
      _apiVersionController.text = apiVersion;

      // Load current model
      final currentModel = await azureService.getCurrentModel();

      // Load available models
      final models = await azureService.getAvailableModels();

      setState(() {
        _selectedModel = currentModel;
        _availableModels = models;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final apiKey = _apiKeyController.text.trim();
    final endpoint = _endpointController.text.trim();
    final apiVersion = _apiVersionController.text.trim();

    if (apiKey.isEmpty || endpoint.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final azureService = ref
          .read(llmServiceFactoryProvider)
          .azureOpenAiService;
      await azureService.setApiKey(apiKey);
      await azureService.setEndpoint(endpoint);

      if (apiVersion.isNotEmpty) {
        await azureService.setApiVersion(apiVersion);
      }

      if (_selectedModel != null) {
        await azureService.setModel(_selectedModel!);
      }

      await _loadSettings();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Azure OpenAI Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'Enter your Azure OpenAI API key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(
              labelText: 'Endpoint',
              hintText: 'Enter your Azure OpenAI endpoint',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiVersionController,
            decoration: const InputDecoration(
              labelText: 'API Version',
              hintText: 'Enter API version (e.g., 2023-05-15)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Deployment',
              border: OutlineInputBorder(),
            ),
            value: _selectedModel,
            items: _availableModels.map((model) {
              return DropdownMenuItem<String>(value: model, child: Text(model));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedModel = value;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: const Text('Save Settings'),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class OllamaSettings extends ConsumerStatefulWidget {
  const OllamaSettings({super.key});

  @override
  ConsumerState<OllamaSettings> createState() => _OllamaSettingsState();
}

class _OllamaSettingsState extends ConsumerState<OllamaSettings> {
  final TextEditingController _endpointController = TextEditingController();
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ollamaService = ref.read(llmServiceFactoryProvider).ollamaService;

      // Load endpoint
      final endpoint = await ollamaService.getEndpoint();
      _endpointController.text = endpoint;

      // Load current model
      final currentModel = await ollamaService.getCurrentModel();

      // Load available models
      final models = await ollamaService.getAvailableModels();

      setState(() {
        _availableModels = models;
        if (models.contains(currentModel)) {
          _selectedModel = currentModel;
        } else {
          _selectedModel = null;
        }
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final endpoint = _endpointController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final ollamaService = ref.read(llmServiceFactoryProvider).ollamaService;
      await ollamaService.setEndpoint(endpoint);

      if (_selectedModel != null) {
        await ollamaService.setModel(_selectedModel!);
      }

      await _loadSettings();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ollama Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(
              labelText: 'Endpoint',
              hintText: 'Enter Ollama endpoint (e.g., http://localhost:11434)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
            value: _selectedModel,
            items: _availableModels.map((model) {
              return DropdownMenuItem<String>(value: model, child: Text(model));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedModel = value;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: const Text('Save Settings'),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
