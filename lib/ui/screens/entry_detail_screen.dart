import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/models/vault_entry.dart';
import 'package:secure_vault/repositories/vault_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:secure_vault/ui/widgets/snackbar_message.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/ui/widgets/vault_type_widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_vault/ui/screens/home_screen.dart'
    show vaultListProvider;
import 'package:secure_vault/ui/screens/trash_screen.dart'
    show trashListProvider;

class EntryDetailScreen extends ConsumerStatefulWidget {
  final VaultEntry? entry;
  final VaultType? initialType;

  const EntryDetailScreen({super.key, this.entry, this.initialType});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _notesController;
  late TextEditingController _categoryController;
  bool _isObscured = true;
  QuillController? _quillController;

  bool _isEditing = false;
  late bool _isNewEntry;
  final Set<String> _sessionCategories = {};
  DateTime? _lastAuthTime;
  static const _authTimeout = Duration(seconds: 30);

  late VaultType _type;
  final Map<String, TextEditingController> _dataControllers = {};

  @override
  void initState() {
    super.initState();
    _isNewEntry = widget.entry == null;
    _isEditing = _isNewEntry;
    _type = widget.entry?.type ?? widget.initialType ?? VaultType.login;

    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _usernameController = TextEditingController(
      text: widget.entry?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.entry?.password ?? '',
    );
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
    _categoryController = TextEditingController(
      text: widget.entry?.category ?? (_isNewEntry ? 'General' : ''),
    );

    _initTypeControllers();
    _initQuillController();

    _loadCategories();

    if (_categoryController.text.isNotEmpty) {
      _sessionCategories.add(_categoryController.text);
      _saveCategory(_categoryController.text);
    }
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCats = prefs.getStringList('custom_categories') ?? [];
    if (mounted) {
      setState(() {
        _sessionCategories.addAll(savedCats);
      });
    }
  }

  Future<void> _saveCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCats = prefs.getStringList('custom_categories') ?? [];
    if (!savedCats.contains(category)) {
      savedCats.add(category);
      await prefs.setStringList('custom_categories', savedCats);
    }
  }

  void _initQuillController() {
    if (_type != VaultType.secureNote) return;

    final content = widget.entry?.notes ?? '';
    final isReadOnly = !_isEditing;

    if (content.isEmpty) {
      _quillController = QuillController.basic()..readOnly = isReadOnly;
      return;
    }

    try {
      final doc = Document.fromJson(jsonDecode(content));
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: isReadOnly,
      );
    } catch (e) {
      final doc = Document()..insert(0, content);
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: isReadOnly,
      );
    }
  }

  void _initTypeControllers() {
    final data = widget.entry?.data ?? {};
    if (_type == VaultType.creditCard) {
      _dataControllers['number'] = TextEditingController(
        text: data['number'] ?? '',
      );
      _dataControllers['holder'] = TextEditingController(
        text: data['holder'] ?? '',
      );
      _dataControllers['expiry'] = TextEditingController(
        text: data['expiry'] ?? '',
      );
      _dataControllers['cvv'] = TextEditingController(text: data['cvv'] ?? '');
      _dataControllers['brand'] = TextEditingController(
        text: data['brand'] ?? 'Visa',
      );
    } else if (_type == VaultType.totp) {
      _dataControllers['secret'] = TextEditingController(
        text: data['secret'] ?? '',
      );
    } else if (_type == VaultType.identity) {
      _dataControllers['number'] = TextEditingController(
        text: data['number'] ?? '',
      );
      _dataControllers['full_name'] = TextEditingController(
        text: data['full_name'] ?? '',
      );
      _dataControllers['id_type'] = TextEditingController(
        text: data['id_type'] ?? '',
      );
      _dataControllers['country'] = TextEditingController(
        text: data['country'] ?? '',
      );
      _dataControllers['expiry'] = TextEditingController(
        text: data['expiry'] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _quillController?.dispose();
    for (var controller in _dataControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{};
    _dataControllers.forEach((key, controller) {
      data[key] = controller.text;
    });

    final entry = VaultEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      title: _titleController.text,
      type: _type,
      username: _usernameController.text,
      password: _passwordController.text,
      notes: _type == VaultType.secureNote && _quillController != null
          ? jsonEncode(_quillController!.document.toDelta().toJson())
          : _notesController.text,
      category: _categoryController.text,
      data: data,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (_isNewEntry) {
        await ref.read(vaultRepositoryProvider).addEntry(entry);
      } else {
        await ref.read(vaultRepositoryProvider).updateEntry(entry);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          'Error al guardar: $e',
          durationSeconds: 2,
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _openQRScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _dataControllers['secret']!.text = result;
      });
    }
  }

  Future<void> _delete() async {
    if (_isNewEntry) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? theme.colorScheme.surface.withOpacity(0.95)
            : theme.dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark
              ? BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                )
              : BorderSide.none,
        ),
        title: Text(
          '¿Eliminar entrada?',
          style: theme.dialogTheme.titleTextStyle,
        ),
        content: Container(
          decoration: isDark
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                )
              : null,
          padding: isDark ? const EdgeInsets.all(12) : null,
          child: Text(
            'Esta acción no se puede deshacer.',
            style: theme.dialogTheme.contentTextStyle,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: isDark
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        )
                      : null,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: isDark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey.shade700,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade700],
                    ),
                  ),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(vaultRepositoryProvider).deleteEntry(widget.entry!.id);
        ref.invalidate(vaultListProvider);
        ref.invalidate(trashListProvider);
        if (mounted) {
          showCustomSnackBar(
            context,
            'Movido a la papelera',
            backgroundColor: Colors.blueGrey,
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(
            context,
            'Error al mover a papelera: $e',
            durationSeconds: 2,
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    showCustomSnackBar(
      context,
      '$label copiado',
      durationSeconds: 3,
      backgroundColor: Colors.green.shade600,
    );
  }

  void _showPasswordGenerator() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _PasswordGeneratorDialog(),
    );

    if (password != null && password.isNotEmpty) {
      setState(() {
        _passwordController.text = password;
        _isObscured = false;
      });
    }
  }

  Future<bool> _requestAuth() async {
    if (_lastAuthTime != null &&
        DateTime.now().difference(_lastAuthTime!) < _authTimeout) {
      return true;
    }

    final authService = ref.read(authServiceProvider);

    // 1. Try Biometrics
    if (await authService.hasBiometrics()) {
      final success = await authService.loginWithBiometrics();
      if (success) {
        _lastAuthTime = DateTime.now();
        return true;
      }
    }

    // 2. Try PIN
    if (await authService.hasPin() && mounted) {
      final pin = await showDialog<String>(
        context: context,
        builder: (context) => _PinVerifyDialog(),
      );

      if (pin != null) {
        final success = await authService.loginWithPin(pin);
        if (success) {
          _lastAuthTime = DateTime.now();
          return true;
        } else if (mounted) {
          showCustomSnackBar(
            context,
            'PIN Incorrecto',
            backgroundColor: Colors.red,
          );
        }
      } else {
        return false;
      }
    }

    if (mounted) {
      final password = await showDialog<String>(
        context: context,
        builder: (context) => _PasswordVerifyDialog(),
      );

      if (password != null) {
        final success = await authService.login(password);
        if (success) {
          _lastAuthTime = DateTime.now();
          return true;
        } else if (mounted) {
          showCustomSnackBar(
            context,
            'Contraseña Incorrecta',
            backgroundColor: Colors.red,
          );
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isViewMode = !_isEditing;

    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onBackground;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.08),
                  primaryColor.withOpacity(0.15),
                  primaryColor.withOpacity(0.35),
                  theme.colorScheme.secondary.withOpacity(0.25),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              )
            : null,
        color: isDark ? null : theme.colorScheme.background,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: isDark
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(0.08),
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.35),
                        theme.colorScheme.secondary.withOpacity(0.25),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  )
                : null,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        )
                      : null,
                  color: isDark ? null : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : theme.dividerColor,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : textColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              title: Text(
                _isNewEntry
                    ? 'Nueva Entrada'
                    : (isViewMode ? 'Detalles' : 'Editar Entrada'),
                style: TextStyle(
                  color: isDark ? Colors.white : textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                if (!_isNewEntry && isViewMode)
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            )
                          : null,
                      color: isDark ? null : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.2)
                            : theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: isDark ? Colors.white : primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                          if (_quillController != null) {
                            _quillController!.readOnly = false;
                          }
                        });
                      },
                      tooltip: 'Editar',
                    ),
                  ),
                if (_isEditing && !_isNewEntry) ...[
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.2),
                          primaryColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white : primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _isObscured = true;
                          _titleController.text = widget.entry?.title ?? '';
                          _usernameController.text =
                              widget.entry?.username ?? '';
                          _passwordController.text =
                              widget.entry?.password ?? '';
                          _notesController.text = widget.entry?.notes ?? '';
                          _categoryController.text =
                              widget.entry?.category ?? 'General';
                          _initTypeControllers();
                          _initQuillController();
                        });
                      },
                      tooltip: 'Cancelar',
                    ),
                  ),
                ],
                if (_isEditing && !_isNewEntry)
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.3),
                          Colors.red.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: Colors.red.shade300,
                        size: 20,
                      ),
                      onPressed: _delete,
                      tooltip: 'Eliminar',
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isViewMode) _buildEntryHeader(),
                const SizedBox(height: 14),
                _buildCategoryBar(),
                const SizedBox(height: 2),
                _buildTypeSpecificSection(
                  isViewMode,
                  isDark,
                  primaryColor,
                  theme,
                ),
                const SizedBox(height: 12),
                _buildSectionTitle(
                  _type == VaultType.secureNote
                      ? 'Contenido de la Nota'
                      : 'Notas Adicionales',
                ),
                const SizedBox(height: 12),
                if (isViewMode && _type == VaultType.secureNote)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2C3E50), const Color(0xFF000000)]
                            : [Colors.white, const Color(0xFFF1F4F8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'CONFIDENCIAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _isObscured
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black45,
                                          ),
                                          onPressed: () async {
                                            if (_isObscured) {
                                              if (await _requestAuth()) {
                                                setState(
                                                  () => _isObscured = false,
                                                );
                                              }
                                            } else {
                                              setState(
                                                () => _isObscured = true,
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.copy_rounded,
                                            size: 20,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black45,
                                          ),
                                          onPressed: () async {
                                            if (await _requestAuth()) {
                                              _copyToClipboard(
                                                _type == VaultType.secureNote &&
                                                        _quillController != null
                                                    ? _quillController!.document
                                                          .toPlainText()
                                                    : _notesController.text,
                                                'Nota',
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _isObscured
                                    ? Text(
                                        'Nota protegida. Desbloquea para leer.',
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          fontStyle: FontStyle.italic,
                                          fontFamily: 'JetBrainsMono',
                                        ),
                                      )
                                    : AbsorbPointer(
                                        child: DefaultTextStyle.merge(
                                          style: const TextStyle(
                                            fontFamily: 'JetBrainsMono',
                                          ),
                                          child: QuillEditor.basic(
                                            controller: _quillController!,
                                            config: const QuillEditorConfig(
                                              scrollable: false,
                                              autoFocus: false,
                                              expands: false,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ]
                            : [Colors.white, Colors.grey.shade50],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        isDark
                            ? BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            : BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                      ],
                    ),
                    child:
                        _type == VaultType.secureNote &&
                            _quillController != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Notas Seguras',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isObscured
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        if (_isObscured) {
                                          if (_isNewEntry ||
                                              await _requestAuth()) {
                                            setState(() => _isObscured = false);
                                          }
                                        } else {
                                          setState(() => _isObscured = true);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isObscured) ...[
                                const Divider(height: 0.5),
                                QuillSimpleToolbar(
                                  controller: _quillController!,
                                  config: const QuillSimpleToolbarConfig(
                                    showFontFamily: false,
                                    showFontSize: false,
                                    showStrikeThrough: false,
                                    showInlineCode: false,
                                    showColorButton: true,
                                    showBackgroundColorButton: true,
                                    showAlignmentButtons: true,
                                    showListCheck: false,
                                    showCodeBlock: false,
                                    showQuote: true,
                                    showIndent: false,
                                    showLink: false,
                                    showDirection: false,
                                    showSearchButton: false,
                                    showSubscript: false,
                                    showSuperscript: false,
                                    multiRowsDisplay: true,
                                  ),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: QuillEditor.basic(
                                    controller: _quillController!,
                                    config: const QuillEditorConfig(
                                      scrollable: false,
                                      autoFocus: false,
                                      expands: false,
                                      padding: EdgeInsets.zero,
                                      placeholder:
                                          'Escribe tu nota segura aquí...',
                                    ),
                                  ),
                                ),
                              ] else
                                Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Center(
                                    child: Text(
                                      'Nota protegida. Desbloquea para editar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'JetBrainsMono',
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : _buildModernTextField(
                            controller: _notesController,
                            label: 'Notas privadas',
                            icon: Icons.notes_rounded,
                            readOnly: isViewMode,
                            maxLines: 3,
                            isFirst: true,
                            isLast: true,
                            alignLabelWithHint: true,
                          ),
                  ),
                const SizedBox(height: 20),
                if (_isEditing)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'GUARDAR DATOS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSpecificSection(
    bool isViewMode,
    bool isDark,
    Color primaryColor,
    ThemeData theme,
  ) {
    if (isViewMode) {
      if (_type == VaultType.secureNote) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Datos Sensibles'),
              if (_type != VaultType.login)
                IconButton(
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: primaryColor,
                  ),
                  onPressed: () async {
                    if (_isObscured) {
                      if (await _requestAuth()) {
                        setState(() => _isObscured = false);
                      }
                    } else {
                      setState(() => _isObscured = true);
                    }
                  },
                  tooltip: 'Mostrar datos',
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (_type == VaultType.login)
            _buildLoginFields(isViewMode, isDark, theme),
          if (_type == VaultType.creditCard)
            CreditCardWidget(
              data: widget.entry?.data ?? {},
              isVisible: !_isObscured,
            ),
          if (_type == VaultType.totp)
            TOTPWidget(
              secret: widget.entry?.data['secret'] ?? '',
              isVisible: !_isObscured,
            ),
          if (_type == VaultType.identity)
            IdentityWidget(
              data: widget.entry?.data ?? {},
              isVisible: !_isObscured,
            ),
          if (_type == VaultType.secureNote) const SizedBox.shrink(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Información Principal'),
        const SizedBox(height: 12),
        Container(
          decoration: _buildContainerDecoration(isDark),
          child: Column(
            children: [
              _buildModernTextField(
                controller: _titleController,
                label: 'Título',
                icon: Icons.title_rounded,
                isFirst: true,
                isLast: _type == VaultType.secureNote,
                validator: (v) => v!.isEmpty ? 'El título es requerido' : null,
              ),
              if (_type == VaultType.login) ...[
                _buildDivider(theme),
                _buildLoginFields(isViewMode, isDark, theme),
              ],
              if (_type == VaultType.creditCard) ...[
                _buildDivider(theme),
                _buildCreditCardFields(theme),
              ],
              if (_type == VaultType.totp) ...[
                _buildDivider(theme),
                _buildTOTPFields(theme),
              ],
              if (_type == VaultType.identity) ...[
                _buildDivider(theme),
                _buildIdentityFields(theme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildContainerDecoration(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]
            : [Colors.white, Colors.grey.shade50],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        width: 1.5,
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 20,
      color: theme.dividerColor,
    );
  }

  Widget _buildLoginFields(bool isViewMode, bool isDark, ThemeData theme) {
    if (!isViewMode) {
      return Column(
        children: [
          _buildModernTextField(
            controller: _usernameController,
            label: 'Usuario / Email',
            icon: Icons.person_outline_rounded,
            isFirst: true,
          ),
          _buildDivider(theme),
          _buildModernTextField(
            controller: _passwordController,
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            obscureText: _isObscured,
            fontFamily: 'JetBrainsMono',
            isLast: true,
            suffixAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.auto_fix_high_rounded,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                  ),
                  onPressed: _showPasswordGenerator,
                  tooltip: 'Generar Contraseña',
                ),
                IconButton(
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() => _isObscured = !_isObscured);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF000000)]
              : [Colors.white, const Color(0xFFF1F4F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAccountDetailItem(
              isDark: isDark,
              primaryColor: primaryColor,
              label: 'USUARIO / EMAIL',
              value: _usernameController.text,
              icon: Icons.person_rounded,
              onCopy: () =>
                  _copyToClipboard(_usernameController.text, 'Usuario'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                height: 1,
              ),
            ),
            _buildAccountDetailItem(
              isDark: isDark,
              primaryColor: primaryColor,
              label: 'CONTRASEÑA',
              value: _passwordController.text,
              icon: Icons.lock_rounded,
              isPassword: true,
              isObscured: _isObscured,
              onCopy: () async {
                if (await _requestAuth()) {
                  _copyToClipboard(_passwordController.text, 'Contraseña');
                }
              },
              onToggle: () async {
                if (_isObscured) {
                  if (await _requestAuth()) {
                    setState(() => _isObscured = false);
                  }
                } else {
                  setState(() => _isObscured = true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetailItem({
    required bool isDark,
    required Color primaryColor,
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onCopy,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggle,
  }) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: (isDark ? Colors.white70 : Colors.black54),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isObscured ? '••••••••••••' : value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: isPassword ? 'JetBrainsMono' : null,
                ),
              ),
            ],
          ),
        ),
        if (isPassword)
          IconButton(
            icon: Icon(
              isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
            onPressed: onToggle,
          ),
        IconButton(
          icon: Icon(
            Icons.copy_rounded,
            size: 20,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
          onPressed: onCopy,
        ),
      ],
    );
  }

  Widget _buildCreditCardFields(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        _buildModernTextField(
          controller: _dataControllers['number']!,
          label: 'Número de Tarjeta',
          icon: Icons.credit_card,
          isFirst: true,
          obscureText: _isObscured,
          fontFamily: 'JetBrainsMono',
          suffixAction: IconButton(
            icon: Icon(
              _isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey.shade600,
            ),
            onPressed: () async {
              if (_isObscured) {
                if (_isNewEntry || await _requestAuth()) {
                  setState(() => _isObscured = false);
                }
              } else {
                setState(() => _isObscured = true);
              }
            },
          ),
        ),
        _buildDivider(theme),
        _buildModernTextField(
          controller: _dataControllers['holder']!,
          label: 'Nombre en la Tarjeta',
          icon: Icons.person,
        ),
        _buildDivider(theme),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _dataControllers['expiry']!,
                label: 'Vencimiento',
                icon: Icons.calendar_today,
              ),
            ),
            Expanded(
              child: _buildModernTextField(
                controller: _dataControllers['cvv']!,
                label: 'CVV',
                icon: Icons.security,
                isLast: true,
                obscureText: _isObscured,
                fontFamily: 'JetBrainsMono',
                suffixAction: IconButton(
                  icon: Icon(
                    _isObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                  ),
                  onPressed: () async {
                    if (_isObscured) {
                      if (_isNewEntry || await _requestAuth()) {
                        setState(() => _isObscured = false);
                      }
                    } else {
                      setState(() => _isObscured = true);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTOTPFields(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return _buildModernTextField(
      controller: _dataControllers['secret']!,
      label: 'Clave Secreta (Base32)',
      icon: Icons.vpn_key,
      isLast: true,
      obscureText: _isObscured,
      fontFamily: 'JetBrainsMono',
      suffixAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey.shade600,
            ),
            onPressed: _openQRScanner,
            tooltip: 'Escanear QR',
          ),
          IconButton(
            icon: Icon(
              _isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey.shade600,
            ),
            onPressed: () async {
              if (_isObscured) {
                if (_isNewEntry || await _requestAuth()) {
                  setState(() => _isObscured = false);
                }
              } else {
                setState(() => _isObscured = true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityFields(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        _buildModernTextField(
          controller: _dataControllers['full_name']!,
          label: 'Nombre Completo',
          icon: Icons.person,
          isFirst: true,
        ),
        _buildDivider(theme),
        _buildModernTextField(
          controller: _dataControllers['number']!,
          label: 'Número de Documento',
          icon: Icons.badge,
          obscureText: _isObscured,
          fontFamily: 'JetBrainsMono',
          suffixAction: IconButton(
            icon: Icon(
              _isObscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey.shade600,
            ),
            onPressed: () async {
              if (_isObscured) {
                if (_isNewEntry || await _requestAuth()) {
                  setState(() => _isObscured = false);
                }
              } else {
                setState(() => _isObscured = true);
              }
            },
          ),
        ),
        _buildDivider(theme),
        _buildModernTextField(
          controller: _dataControllers['id_type']!,
          label: 'Tipo de Documento',
          icon: Icons.info_outline,
        ),
        _buildDivider(theme),
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _dataControllers['expiry']!,
                label: 'Vencimiento',
                icon: Icons.calendar_today,
              ),
            ),
            Expanded(
              child: _buildModernTextField(
                controller: _dataControllers['country']!,
                label: 'País',
                icon: Icons.public,
                isLast: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntryHeader() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onBackground;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getEntryIcon(_type), size: 48, color: primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            _titleController.text.isEmpty
                ? 'Nueva Entrada'
                : _titleController.text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.entry != null) ...[
            const SizedBox(height: 8),
            Text(
              'Creado: ${_formatDate(widget.entry!.createdAt)}',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getEntryIcon(VaultType type) {
    switch (type) {
      case VaultType.login:
        return Icons.login_rounded;
      case VaultType.creditCard:
        return Icons.credit_card_rounded;
      case VaultType.secureNote:
        return Icons.note_alt_outlined;
      case VaultType.identity:
        return Icons.badge_outlined;
      case VaultType.totp:
        return Icons.vpn_key_outlined;
    }
  }

  Widget _buildCategoryBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final isViewMode = !_isEditing;

    final categories = ['General', 'Redes', 'Trabajo'];
    final currentCategory = _categoryController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categoría'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              if (!isViewMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () async {
                      final customCat = await showDialog<String>(
                        context: context,
                        builder: (context) => _CustomCategoryDialog(),
                      );
                      if (customCat != null && customCat.isNotEmpty) {
                        setState(() {
                          _categoryController.text = customCat;
                          _sessionCategories.add(customCat);
                        });
                        _saveCategory(customCat);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add, size: 20, color: primaryColor),
                    ),
                  ),
                ),
              ..._sessionCategories
                  .where((cat) => !categories.contains(cat))
                  .map((cat) {
                    final isSelected = currentCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: isViewMode
                            ? null
                            : (selected) {
                                setState(() {
                                  _categoryController.text = selected
                                      ? cat
                                      : '';
                                });
                              },
                        selectedColor: primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor.withOpacity(0.5)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  }),
              ...categories.map((cat) {
                final isSelected = currentCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: isViewMode
                        ? null
                        : (selected) {
                            setState(() {
                              _categoryController.text = selected ? cat : '';
                            });
                          },
                    selectedColor: primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onBackground.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    bool obscureText = false,
    bool isFirst = false,
    bool isLast = false,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    Widget? suffixAction,
    bool showCopy = false,
    bool requiresAuth = false,
    String? fontFamily,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    // Determinar el borderRadius según la posición
    BorderRadius? borderRadius;
    if (isFirst && isLast) {
      borderRadius = BorderRadius.circular(20);
    } else if (isFirst) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      );
    } else if (isLast) {
      borderRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      );
    }

    return Container(
      decoration: borderRadius != null
          ? BoxDecoration(borderRadius: borderRadius)
          : null,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscureText,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 16,
          fontFamily: fontFamily,
          color: textColor,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hintColor,
            fontWeight: FontWeight.normal,
          ),
          alignLabelWithHint: alignLabelWithHint,
          prefixIcon: icon != null ? Icon(icon, color: hintColor) : null,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (suffixAction != null) suffixAction,
              if (showCopy && controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: hintColor),
                  onPressed: () async {
                    if (requiresAuth) {
                      if (!await _requestAuth()) return;
                    }
                    _copyToClipboard(controller.text, label);
                  },
                  tooltip: 'Copiar',
                ),
            ],
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _PinVerifyDialog extends StatefulWidget {
  @override
  State<_PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends State<_PinVerifyDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: isDark
          ? theme.colorScheme.surface.withOpacity(0.95)
          : theme.dialogTheme.backgroundColor,
      title: Text(
        'Ingresa PIN',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark
              ? primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Container(
        padding: isDark ? const EdgeInsets.all(12) : null,
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'JetBrainsMono',
            letterSpacing: 16,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: '••••',
            counterText: '',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              letterSpacing: 16,
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: isDark
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      )
                    : null,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey.shade700,
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                ),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verificar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordVerifyDialog extends StatefulWidget {
  @override
  State<_PasswordVerifyDialog> createState() => _PasswordVerifyDialogState();
}

class _PasswordVerifyDialogState extends State<_PasswordVerifyDialog> {
  final _controller = TextEditingController();
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark
        ? primaryColor.withOpacity(0.3)
        : Colors.grey.withOpacity(0.2);

    return AlertDialog(
      backgroundColor: isDark
          ? theme.colorScheme.surface.withOpacity(0.95)
          : theme.dialogTheme.backgroundColor,
      title: Text(
        'Verificar Identidad',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      content: TextField(
        controller: _controller,
        obscureText: _isObscured,
        style: TextStyle(color: textColor, fontFamily: 'JetBrainsMono'),
        decoration: InputDecoration(
          labelText: 'Contraseña maestra',
          labelStyle: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onBackground.withOpacity(0.7),
            fontFamily: 'JetBrainsMono',
          ),
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.4)
                : Colors.grey.withOpacity(0.4),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: primaryColor.withOpacity(0.6),
              width: 2,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isObscured ? Icons.visibility : Icons.visibility_off,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _isObscured = !_isObscured),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: isDark
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey.shade700,
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                ),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Verificar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomCategoryDialog extends StatefulWidget {
  @override
  State<_CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<_CustomCategoryDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return AlertDialog(
      backgroundColor: isDark
          ? theme.colorScheme.surface.withOpacity(0.95)
          : theme.dialogTheme.backgroundColor,
      title: const Text(
        'Nueva Categoría',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5)
            : BorderSide.none,
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Ej: Redes Sociales...',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text(
            'AÑADIR',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _PasswordGeneratorDialog extends StatefulWidget {
  const _PasswordGeneratorDialog();

  @override
  State<_PasswordGeneratorDialog> createState() =>
      _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<_PasswordGeneratorDialog> {
  double _length = 12;
  bool _useUppercase = true;
  bool _boolLowercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _generatedPassword = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    const String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lower = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%&*-_=+';

    String charset = '';
    if (_useUppercase) charset += upper;
    if (_boolLowercase) charset += lower;
    if (_useNumbers) charset += numbers;
    if (_useSymbols) charset += symbols;

    if (charset.isEmpty) {
      setState(() => _generatedPassword = '');
      return;
    }

    final random = Random.secure();
    final password = List.generate(
      _length.toInt(),
      (index) => charset[random.nextInt(charset.length)],
    ).join();

    setState(() => _generatedPassword = password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isDark
            ? BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5)
            : BorderSide.none,
      ),
      title: Row(
        children: [
          Icon(Icons.auto_fix_high_rounded, color: primaryColor),
          const SizedBox(width: 12),
          const Text(
            'Generador Seguro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Text(
              _generatedPassword.isEmpty
                  ? 'Selecciona opciones'
                  : _generatedPassword,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Longitud:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_length.toInt()}',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Slider(
            value: _length,
            min: 8,
            max: 64,
            divisions: 56,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() => _length = val);
              _generate();
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildOption(
                'A-Z',
                _useUppercase,
                (v) => setState(() => _useUppercase = v!),
              ),
              _buildOption(
                'a-z',
                _boolLowercase,
                (v) => setState(() => _boolLowercase = v!),
              ),
              _buildOption(
                '0-9',
                _useNumbers,
                (v) => setState(() => _useNumbers = v!),
              ),
              _buildOption(
                '!@#',
                _useSymbols,
                (v) => setState(() => _useSymbols = v!),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _generatedPassword.isEmpty
              ? null
              : () => Navigator.pop(context, _generatedPassword),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Usar Contraseña'),
        ),
      ],
    );
  }

  Widget _buildOption(String label, bool value, Function(bool?) onChanged) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        onChanged(!value);
        _generate();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? primaryColor
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: (v) {
                  onChanged(v);
                  _generate();
                },
                activeColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
