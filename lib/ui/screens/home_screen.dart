import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/models/vault_entry.dart';
import 'package:secure_vault/repositories/vault_repository.dart';
import 'package:secure_vault/services/auth_service.dart';
import 'package:secure_vault/ui/screens/auth_check_screen.dart';
import 'package:secure_vault/ui/screens/entry_detail_screen.dart';
import 'package:secure_vault/ui/widgets/app_bar.dart';
import 'package:secure_vault/ui/widgets/snackbar_message.dart';

enum SortOption { titleAsc, titleDesc, dateNewest, dateOldest }

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SortOptionNotifier extends Notifier<SortOption> {
  @override
  SortOption build() => SortOption.dateNewest;

  void set(SortOption value) => state = value;
}

final sortOptionProvider = NotifierProvider<SortOptionNotifier, SortOption>(
  SortOptionNotifier.new,
);

class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, String?>(
      CategoryFilterNotifier.new,
    );

final uniqueCategoriesProvider = Provider<List<String>>((ref) {
  final vaultListAsync = ref.watch(vaultListProvider);
  return vaultListAsync.maybeWhen(
    data: (entries) {
      final categories = entries
          .map((e) => e.category)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      categories.sort();
      return categories;
    },
    orElse: () => [],
  );
});

final vaultListProvider = FutureProvider<List<VaultEntry>>((ref) async {
  final repo = ref.watch(vaultRepositoryProvider);
  return await repo.getAllEntries();
});

final filteredVaultListProvider = Provider<AsyncValue<List<VaultEntry>>>((ref) {
  final vaultListAsync = ref.watch(vaultListProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final sortOption = ref.watch(sortOptionProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);

  return vaultListAsync.whenData((entries) {
    var filtered = entries.where((entry) {
      final matchesSearch =
          entry.title.toLowerCase().contains(searchQuery) ||
          (entry.username?.toLowerCase().contains(searchQuery) ?? false) ||
          (entry.category?.toLowerCase().contains(searchQuery) ?? false);

      final matchesCategory =
          categoryFilter == null || entry.category == categoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();

    switch (sortOption) {
      case SortOption.titleAsc:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SortOption.titleDesc:
        filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SortOption.dateNewest:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortOption.dateOldest:
        filtered.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
    }
    return filtered;
  });
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  final TextEditingController _searchController = TextEditingController();

  void _appLock() {
    ref.read(authServiceProvider).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthCheckScreen()),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAll(List<VaultEntry> entries) {
    setState(() {
      if (_selectedIds.length == entries.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(entries.map((e) => e.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? theme.colorScheme.surface.withOpacity(0.95)
            : theme.dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark
              ? BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5)
              : BorderSide.none,
        ),
        title: Text(
          '¿Eliminar $count elemento${count > 1 ? 's' : ''}?',
          style: theme.dialogTheme.titleTextStyle,
        ),
        content: Container(
          decoration: isDark
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                )
              : null,
          padding: isDark ? const EdgeInsets.all(12) : null,
          child: Text(
            'Esta acción no se puede deshacer. Los elementos seleccionados serán eliminados permanentemente.',
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
                      elevation: 0,
                    ),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
        final idsToDelete = _selectedIds.toList();
        await ref.read(vaultRepositoryProvider).deleteEntries(idsToDelete);

        // ignore: unused_result
        ref.refresh(vaultListProvider);

        _exitSelectionMode();

        if (mounted) {
          showCustomSnackBar(
            context,
            '$count elemento${count > 1 ? 's' : ''} eliminado${count > 1 ? 's' : ''}',
            durationSeconds: 3,
            backgroundColor: Colors.orange,
          );
        }
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(
            context,
            'Error al eliminar: $e',
            durationSeconds: 2,
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}m';
      return 'Ahora';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(filteredVaultListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final filteredEntries = entriesAsync.value ?? [];

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
        appBar: _isSelectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                ),
                title: Text('${_selectedIds.length} selec.'),
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                elevation: 4,
                shadowColor: Colors.black12,
                actions: [
                  IconButton(
                    icon: Icon(
                      _selectedIds.length == filteredEntries.length &&
                              filteredEntries.isNotEmpty
                          ? Icons.deselect_outlined
                          : Icons.select_all,
                    ),
                    tooltip: 'Seleccionar todo',
                    onPressed: () => _selectAll(filteredEntries),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Eliminar seleccionados',
                    onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : MyAppBar(
                isAuthenticated: ref.watch(authServiceProvider).isAuthenticated,
                appLockCallback: () => _appLock(),
              ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  left: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 0,
                            ),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: false,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar en tu bóveda...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: isDark
                                    ? primaryColor.withOpacity(0.8)
                                    : primaryColor,
                              ),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(searchQueryProvider.notifier)
                                            .set('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            onChanged: (value) {
                              ref.read(searchQueryProvider.notifier).set(value);
                            },
                            onTapOutside: (event) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 0),
                      _buildSortPopupMenu(),
                    ],
                  ),
                  const SizedBox(height: 1),
                  _buildCategoryBar(),
                  if (!_isSelectionMode &&
                      (entriesAsync.value?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              filteredEntries.length == entriesAsync.value!.length
                                  ? '${filteredEntries.length} registros'
                                  : '${filteredEntries.length} de ${entriesAsync.value!.length} filtrados',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20), // Espacio mínimo entre textos
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(
                                    0.4,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Selección múltiple con toque largo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(vaultListProvider);
                  await ref.read(vaultListProvider.future);
                },
                color: primaryColor,
                backgroundColor: theme.colorScheme.surface,
                displacement: 20,
                strokeWidth: 2.5,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    entriesAsync.when(
                      data: (entries) {
                        if (entries.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    searchQuery.isEmpty
                                        ? Icons.lock_outline
                                        : Icons.search_off,
                                    size: 64,
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'Tu bóveda está vacía'
                                        : 'No se encontraron resultados',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: theme.colorScheme.onBackground
                                          .withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (searchQuery.isEmpty &&
                                      ref.watch(categoryFilterProvider) == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Añade tu primera entrada',
                                        style: TextStyle(
                                          color: theme.colorScheme.onBackground
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final entry = entries[index];
                              final isSelected = _selectedIds.contains(
                                entry.id,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: _isSelectionMode
                                      ? () => _toggleSelection(entry.id)
                                      : () {
                                          Navigator.of(context)
                                              .push(
                                                PageRouteBuilder(
                                                  pageBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                      ) => EntryDetailScreen(
                                                        entry: entry,
                                                      ),
                                                  transitionDuration:
                                                      Duration.zero,
                                                  reverseTransitionDuration:
                                                      Duration.zero,
                                                ),
                                              )
                                              .then(
                                                (_) => ref.refresh(
                                                  vaultListProvider,
                                                ),
                                              );
                                        },
                                  onLongPress: () =>
                                      _enterSelectionMode(entry.id),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isDark
                                            ? [
                                                Colors.white.withOpacity(0.15),
                                                Colors.white.withOpacity(0.05),
                                              ]
                                            : [
                                                Colors.white,
                                                Colors.grey.shade50,
                                              ],
                                      ),
                                      color: isSelected
                                          ? primaryColor.withOpacity(
                                              isDark ? 0.25 : 0.15,
                                            )
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        isDark
                                            ? BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              )
                                            : BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isSelected
                                                    ? [
                                                        primaryColor,
                                                        primaryColor
                                                            .withOpacity(0.8),
                                                      ]
                                                    : [
                                                        primaryColor
                                                            .withOpacity(
                                                              isDark
                                                                  ? 0.3
                                                                  : 0.1,
                                                            ),
                                                        primaryColor
                                                            .withOpacity(
                                                              isDark
                                                                  ? 0.2
                                                                  : 0.05,
                                                            ),
                                                      ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _getEntryIcon(entry.type),
                                              size: 24,
                                              color: isSelected
                                                  ? Colors.white
                                                  : primaryColor,
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  size: 16,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (entry.category != null &&
                                              entry.category!.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: primaryColor
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              child: Text(
                                                entry.category!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _getEntrySubtitleInfo(
                                            entry,
                                            theme,
                                            primaryColor,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              'Actualizado: ${_formatDate(entry.updatedAt)}',
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.5),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: _isSelectionMode
                                          ? Checkbox(
                                              value: isSelected,
                                              onChanged: (v) =>
                                                  _toggleSelection(entry.id),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              fillColor:
                                                  MaterialStateProperty.resolveWith(
                                                    (states) =>
                                                        states.contains(
                                                          MaterialState
                                                              .selected,
                                                        )
                                                        ? primaryColor
                                                        : (isDark
                                                              ? Colors.white
                                                                    .withOpacity(
                                                                      0.3,
                                                                    )
                                                              : Colors
                                                                    .grey
                                                                    .shade300),
                                                  ),
                                              checkColor: Colors.white,
                                            )
                                          : Icon(
                                              Icons.chevron_right_rounded,
                                              color: isDark
                                                  ? Colors.white.withOpacity(
                                                      0.5,
                                                    )
                                                  : Colors.grey.shade400,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }, childCount: entries.length),
                          ),
                        );
                      },
                      loading: () => const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => SliverFillRemaining(
                        child: Center(child: Text('Error: $err')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showTypeSelector(context),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
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

  Widget _getEntrySubtitleInfo(
    VaultEntry entry,
    ThemeData theme,
    Color primaryColor,
  ) {
    String info = '';
    IconData icon = Icons.person_outline;

    switch (entry.type) {
      case VaultType.login:
        info = entry.username ?? '';
        icon = Icons.person_outline;
        break;
      case VaultType.creditCard:
        final number = entry.data['number'] ?? '';
        if (number.length >= 4) {
          info = '**** **** **** ${number.substring(number.length - 4)}';
        } else {
          info = 'Tarjeta de Crédito';
        }
        icon = Icons.credit_card_outlined;
        break;
      case VaultType.identity:
        final idType = entry.data['id_type'] ?? 'ID';
        final number = entry.data['number'] ?? '';
        if (number.length >= 4) {
          info = '$idType: ****${number.substring(number.length - 4)}';
        } else {
          info = idType;
        }
        icon = Icons.badge_outlined;
        break;
      case VaultType.secureNote:
        info = 'Nota Protegida';
        icon = Icons.lock_outline_rounded;
        break;
      case VaultType.totp:
        info = entry.username?.isNotEmpty == true
            ? entry.username!
            : 'Generador de códigos';
        icon = Icons.timer_outlined;
        break;
    }

    if (info.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              info,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'JetBrainsMono',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Añadir a la Bóveda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Selecciona el tipo de registro que deseas crear',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 24,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _TypeItem(
                  icon: Icons.login_rounded,
                  label: 'Login',
                  color: Colors.blue.shade400,
                  onTap: () => _navigateToDetail(VaultType.login),
                ),
                _TypeItem(
                  icon: Icons.credit_card_rounded,
                  label: 'Tarjeta',
                  color: Colors.orange.shade400,
                  onTap: () => _navigateToDetail(VaultType.creditCard),
                ),
                _TypeItem(
                  icon: Icons.note_alt_rounded,
                  label: 'Nota',
                  color: Colors.green.shade400,
                  onTap: () => _navigateToDetail(VaultType.secureNote),
                ),
                _TypeItem(
                  icon: Icons.badge_rounded,
                  label: 'ID',
                  color: Colors.purple.shade400,
                  onTap: () => _navigateToDetail(VaultType.identity),
                ),
                _TypeItem(
                  icon: Icons.vpn_key_rounded,
                  label: '2FA',
                  color: Colors.red.shade400,
                  onTap: () => _navigateToDetail(VaultType.totp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(VaultType type) {
    Navigator.pop(context);
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EntryDetailScreen(initialType: type),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        )
        .then((_) => ref.refresh(vaultListProvider));
  }

  Widget _buildCategoryBar() {
    final categories = ref.watch(uniqueCategoriesProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _CategoryChip(
            label: 'Todos',
            isSelected: selectedCategory == null,
            onSelected: (selected) {
              if (selected) {
                ref.read(categoryFilterProvider.notifier).set(null);
              }
            },
          ),
          const SizedBox(width: 6),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _CategoryChip(
                label: category,
                isSelected: selectedCategory == category,
                onSelected: (selected) {
                  ref
                      .read(categoryFilterProvider.notifier)
                      .set(selected ? category : null);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortPopupMenu() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return PopupMenuButton<SortOption>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor, width: 0),
          boxShadow: [
            if (theme.brightness != Brightness.dark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(
          Icons.sort_rounded,
          color: theme.brightness == Brightness.dark
              ? primaryColor.withOpacity(0.8)
              : primaryColor,
          size: 24,
        ),
      ),
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (option) {
        ref.read(sortOptionProvider.notifier).set(option);
      },
      itemBuilder: (context) => [
        _buildSortMenuItem(
          SortOption.dateNewest,
          'Más recientes',
          Icons.history_rounded,
        ),
        _buildSortMenuItem(
          SortOption.dateOldest,
          'Más antiguos',
          Icons.calendar_today_rounded,
        ),
        _buildSortMenuItem(
          SortOption.titleAsc,
          'Título (A-Z)',
          Icons.sort_by_alpha_rounded,
        ),
        _buildSortMenuItem(
          SortOption.titleDesc,
          'Título (Z-A)',
          Icons.sort_by_alpha_rounded,
        ),
      ],
    );
  }

  PopupMenuItem<SortOption> _buildSortMenuItem(
    SortOption option,
    String label,
    IconData icon,
  ) {
    final isSelected = ref.watch(sortOptionProvider) == option;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? primaryColor
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 16, color: primaryColor),
          ],
        ],
      ),
    );
  }
}

class _TypeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TypeItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 90,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: primaryColor.withOpacity(isDark ? 0.3 : 0.2),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? primaryColor
            : (isDark ? Colors.white.withOpacity(0.6) : Colors.black54),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
