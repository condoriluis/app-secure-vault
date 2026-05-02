import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/models/vault_entry.dart';
import 'package:secure_vault/repositories/vault_repository.dart';
import 'package:secure_vault/ui/screens/home_screen.dart'
    show vaultListProvider;
import 'package:secure_vault/ui/widgets/snackbar_message.dart';

final trashListProvider = FutureProvider<List<VaultEntry>>((ref) async {
  final repo = ref.watch(vaultRepositoryProvider);
  return await repo.getDeletedEntries();
});

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Papelera',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () => _showEmptyTrashDialog(context, ref),
            tooltip: 'Vaciar papelera',
          ),
        ],
      ),
      body: trashAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'La papelera está vacía',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildTrashItem(context, ref, entry);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTrashItem(
    BuildContext context,
    WidgetRef ref,
    VaultEntry entry,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final deletedAt = entry.deletedAt ?? DateTime.now();
    final expiresAt = deletedAt.add(const Duration(days: 30));
    final daysRemaining = expiresAt.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getEntryIcon(entry.type),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Se eliminará en $daysRemaining días',
          style: TextStyle(
            fontSize: 12,
            color: daysRemaining < 7
                ? Colors.red.shade400
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: (value) {
            if (value == 'restore') {
              _restoreEntry(context, ref, entry);
            } else if (value == 'delete') {
              _deletePermanently(context, ref, entry);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Restaurar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Eliminar permanentemente',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ],
              ),
            ),
          ],
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
        return Icons.description_rounded;
      case VaultType.identity:
        return Icons.badge_rounded;
      case VaultType.totp:
        return Icons.vpn_key_rounded;
    }
  }

  Future<void> _restoreEntry(
    BuildContext context,
    WidgetRef ref,
    VaultEntry entry,
  ) async {
    await ref.read(vaultRepositoryProvider).restoreEntry(entry.id);
    ref.invalidate(trashListProvider);
    ref.invalidate(vaultListProvider);
    if (context.mounted) {
      showCustomSnackBar(
        context,
        '"${entry.title}" restaurado',
        backgroundColor: Colors.green,
      );
    }
  }

  Future<void> _deletePermanently(
    BuildContext context,
    WidgetRef ref,
    VaultEntry entry,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar permanentemente?'),
        content: Text(
          'Esta acción no se puede deshacer. "${entry.title}" será borrado para siempre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(vaultRepositoryProvider).permanentDeleteEntry(entry.id);
      ref.invalidate(trashListProvider);
      if (context.mounted) {
        showCustomSnackBar(
          context,
          'Eliminado permanentemente',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _showEmptyTrashDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar papelera?'),
        content: const Text(
          'Se eliminarán permanentemente todos los elementos de la papelera.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Vaciar Todo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(vaultRepositoryProvider).emptyTrash();
      ref.invalidate(trashListProvider);
      if (context.mounted) {
        showCustomSnackBar(
          context,
          'Papelera vaciada',
          backgroundColor: Colors.blueGrey,
        );
      }
    }
  }
}
