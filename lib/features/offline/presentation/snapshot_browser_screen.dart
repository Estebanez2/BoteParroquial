import '../../../core/routing/app_route.dart';
import '../../../design_system/platform/app_system_back_sound.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/constants/audit_labels.dart';
import '../../../design_system/design_system.dart';
import '../../../models/daily_snapshot.dart';
import '../../../repositories/snapshot_data_repository.dart';
import '../../../services/file_snapshot_storage.dart' show snapshotAccessStamp;
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../groups/presentation/group_members_screen.dart';
import '../../groups/presentation/group_navigation_shell.dart';
import '../../groups/presentation/participants_screen.dart';
import '../../groups/presentation/audit_event_detail.dart'
    show auditDetailsText;
import '../../movements/presentation/movements_screen.dart';
import '../../persons/presentation/persons_screen.dart';
import '../../persons/presentation/person_details_screen.dart';
import '../../quotas/presentation/quota_screen.dart';
import '../../reports/presentation/economic_report_screen.dart';
import '../providers/daily_snapshot_providers.dart';
import '../providers/snapshot_session_providers.dart';

class SnapshotBrowserScreen extends ConsumerStatefulWidget {
  const SnapshotBrowserScreen({super.key, required this.day});
  final String day;
  @override
  ConsumerState<SnapshotBrowserScreen> createState() => _BrowserState();
}

class _BrowserState extends ConsumerState<SnapshotBrowserScreen> {
  late Future<DailySnapshot> _copy;
  @override
  void initState() {
    super.initState();
    _copy = ref.read(dailyCopyControllerProvider.notifier).load(widget.day);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    ref.watch(dailyCopyControllerProvider.select((s) => s.revision));
    return FutureBuilder<DailySnapshot>(
      future: _copy,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const AppScaffold(
            child: LoadingIndicator(label: 'Abriendo copia completa…'),
          );
        }
        if (state.hasError || state.data == null) {
          return AppScaffold(
            child: EmptyState(
              icon: Icons.lock_outline,
              title: 'Copia no disponible',
              description: state.hasError
                  ? failureMessage(state.error!)
                  : 'No hay una copia completa.',
              actionLabel: 'Volver a las copias',
              onAction: () => context.go('/offline'),
            ),
          );
        }
        final copy = state.data!;
        final access = ref
            .read(dailySnapshotRepositoryProvider)
            .lastConfirmedAccess;
        final revoked =
            access != null &&
            copy.groupIds.any((id) {
              final member = copy.documents
                  .where((d) => d.path == 'groups/$id/members/${copy.uid}')
                  .firstOrNull;
              return member == null ||
                  access[id] != snapshotAccessStamp(member);
            });
        if (uid != copy.uid || revoked) {
          return AppScaffold(
            child: EmptyState(
              icon: Icons.lock_outline,
              title: 'Ha cambiado tu acceso',
              description:
                  'No se puede seguir mostrando esta copia. Vuelve al catálogo para abrir su versión autorizada.',
              actionLabel: 'Volver a las copias',
              onAction: () => context.go('/offline'),
            ),
          );
        }
        return SnapshotSessionView(
          key: ValueKey('${copy.uid}/${copy.day}/${copy.groupIds.join(',')}'),
          data: SnapshotDataRepository(copy),
          onExit: () => context.go('/'),
          appearanceTheme: Theme.of(context),
        );
      },
    );
  }
}

class SnapshotSessionView extends StatefulWidget {
  const SnapshotSessionView({
    super.key,
    required this.data,
    required this.onExit,
    this.appearanceTheme,
  });
  final SnapshotDataRepository data;
  final VoidCallback onExit;
  final ThemeData? appearanceTheme;
  @override
  State<SnapshotSessionView> createState() => _SessionState();
}

class _SessionState extends State<SnapshotSessionView> {
  final _backSound = AppSystemBackSound();
  late final ProviderContainer _container;
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    _container = createSnapshotContainer(widget.data);
    String id(GoRouterState s) => s.pathParameters['groupId']!;
    _router = GoRouter(
      observers: [_backSound.observer()],
      initialLocation: '/',
      routes: [
        appRoute(
          path: '/',
          builder: (c, s) =>
              _SnapshotHome(data: widget.data, onExit: widget.onExit),
          routes: [
            ShellRoute(
              observers: [_backSound.observer()],
              pageBuilder: (context, state, child) => AppMotionPage<void>(
                key: state.pageKey,
                motion: AppPageMotion.group,
                origin: state.extra is AppGroupOrigin
                    ? (state.extra as AppGroupOrigin).rect
                    : null,
                child: GroupNavigationShell(state: state, child: child),
              ),
              routes: [
                appRoute(
                  path: 'groups/:groupId',
                  motion: AppPageMotion.section,
                  sectionIndex: 0,
                  builder: (c, s) => DashboardScreen(groupId: id(s)),
                  routes: [
                    appRoute(
                      path: 'participants',
                      motion: AppPageMotion.section,
                      sectionIndex: 2,
                      builder: (c, s) => ParticipantsScreen(groupId: id(s)),
                    ),
                    appRoute(
                      path: 'persons',
                      motion: AppPageMotion.section,
                      sectionIndex: 2,
                      builder: (c, s) => PersonsScreen(groupId: id(s)),
                    ),
                    appRoute(
                      path: 'members',
                      motion: AppPageMotion.section,
                      sectionIndex: 2,
                      builder: (c, s) => GroupMembersScreen(groupId: id(s)),
                    ),
                    appRoute(
                      path: 'reports',
                      motion: AppPageMotion.section,
                      sectionIndex: 3,
                      builder: (c, s) => EconomicReportScreen(groupId: id(s)),
                    ),
                    appRoute(
                      path: 'movements',
                      motion: AppPageMotion.section,
                      sectionIndex: 1,
                      builder: (c, s) => MovementsScreen(
                        groupId: id(s),
                        focusId: s.uri.queryParameters['focus'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        appRoute(
          path: '/groups/:groupId/persons/:personId',
          builder: (c, s) => PersonDetailsScreen(
            groupId: id(s),
            personId: s.pathParameters['personId']!,
          ),
        ),
        appRoute(
          path: '/groups/:groupId/quotas',
          builder: (c, s) => QuotaScreen(groupId: id(s)),
        ),
        for (final collection in [
          'auditEvents',
          'notifications',
          'joinRequests',
          'persons',
        ])
          appRoute(
            path: '/records/:groupId/$collection',
            builder: (c, s) => _SnapshotRecords(
              data: widget.data,
              groupId: id(s),
              collection: collection,
            ),
          ),
        appRoute(
          path: '/groups/:groupId/notifications',
          builder: (c, s) => _SnapshotRecords(
            data: widget.data,
            groupId: id(s),
            collection: 'notifications',
          ),
        ),
      ],
      redirect: (context, state) {
        final group = state.pathParameters['groupId'];
        if (group != null && !widget.data.snapshot.groupIds.contains(group)) {
          return '/';
        }
        return null;
      },
      errorBuilder: (c, s) => AppScaffold(
        child: EmptyState(
          icon: Icons.lock_outline,
          title: 'La copia es de solo lectura',
          description:
              'Para editar, enviar invitaciones o cambiar datos vuelve al modo actual.',
          actionLabel: 'Ver grupos de la copia',
          onAction: () => c.go('/'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: _container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BoteParroquial · Copia',
      theme: widget.appearanceTheme ?? AppTheme.light,
      themeMode: ThemeMode.light,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      backButtonDispatcher: _backSound.dispatcher,
      builder: (context, child) => Column(
        children: [
          Material(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AppReadOnlyBanner(
                  dateLabel:
                      '${MaterialLocalizations.of(context).formatShortDate(widget.data.snapshot.asOf.toLocal())} · ${TimeOfDay.fromDateTime(widget.data.snapshot.asOf.toLocal()).format(context)}',
                  onExit: widget.onExit,
                ),
              ),
            ),
          ),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    ),
  );
}

class _SnapshotHome extends StatelessWidget {
  const _SnapshotHome({required this.data, required this.onExit});
  final SnapshotDataRepository data;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppTopBar(
      title: 'Tus espacios guardados',
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a datos actuales',
        onPressed: onExit,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.groups.isEmpty)
          const EmptyState(
            icon: Icons.folder_outlined,
            title: 'Sin grupos en esta copia',
            description:
                'No había grupos autorizados o se retiró su acceso al recuperar conexión.',
          ),
        for (final group in data.groups) ...[
          AppReveal(
            child: AppGroupEntry(
              onOpen: (origin) =>
                  context.go('/groups/${group.id}', extra: origin),
              builder: (context, activate) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      group.name,
                      style: AppTypography.of(context).editorialTitle,
                    ),
                    if (group.description != null)
                      Text(
                        group.description!,
                        style: AppTypography.of(context).bodyMedium,
                      ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Entrar en el grupo guardado',
                      tapEffect: AppTapEffect.none,
                      trailingIcon: Icons.chevron_right_rounded,
                      onPressed: activate,
                    ),
                    for (final item in [
                      ('auditEvents', 'Historial administrativo guardado'),
                      ('notifications', 'Mis avisos guardados'),
                      ('joinRequests', 'Solicitudes guardadas'),
                      ('persons', 'Papelera guardada'),
                    ])
                      if ((item.$1 == 'notifications' ||
                              data.canReadManagement(group.id)) &&
                          data
                              .rows('groups/${group.id}', item.$1)
                              .any(
                                (r) =>
                                    item.$1 != 'persons' ||
                                    r.data['trashedAt'] != null,
                              ))
                        AppButton(
                          label: item.$2,
                          variant: AppButtonVariant.ghost,
                          onPressed: () =>
                              context.push('/records/${group.id}/${item.$1}'),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    ),
  );
}

class _SnapshotRecords extends StatefulWidget {
  const _SnapshotRecords({
    required this.data,
    required this.groupId,
    required this.collection,
  });
  final SnapshotDataRepository data;
  final String groupId, collection;
  @override
  State<_SnapshotRecords> createState() => _RecordsState();
}

class _RecordsState extends State<_SnapshotRecords> {
  int _limit = 50;
  @override
  Widget build(BuildContext context) {
    if (widget.collection != 'notifications' &&
        !widget.data.canReadManagement(widget.groupId)) {
      return const AppScaffold(
        child: EmptyState(
          icon: Icons.lock_outline,
          title: 'Consulta no autorizada',
          description:
              'Ese apartado no estaba disponible para tu cuenta al guardar la copia.',
        ),
      );
    }
    final rows =
        widget.data
            .rows('groups/${widget.groupId}', widget.collection)
            .where(
              (r) =>
                  widget.collection != 'persons' || r.data['trashedAt'] != null,
            )
            .toList()
          ..sort(
            (a, b) => (b.data['createdAt'] ?? b.data['updatedAt'] ?? '')
                .toString()
                .compareTo(
                  (a.data['createdAt'] ?? a.data['updatedAt'] ?? '').toString(),
                ),
          );
    const labels = {
      'action': 'Operación',
      'actorUid': 'Autor',
      'createdAt': 'Fecha',
      'before': 'Antes',
      'after': 'Después',
      'displayName': 'Nombre',
      'notes': 'Notas',
      'status': 'Estado',
      'title': 'Título',
      'body': 'Mensaje',
      'trashedAt': 'En papelera desde',
    };
    String format(Object? value) {
      if (value is Map) {
        final currency = widget.data.groups
            .firstWhere((g) => g.id == widget.groupId)
            .currency;
        return auditDetailsText(Map<String, Object?>.from(value), currency);
      }
      return value?.toString() ?? '—';
    }

    return AppScaffold(
      appBar: AppTopBar(
        title: 'Registros guardados',
        leading: AppIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Volver a grupos guardados',
          onPressed: () => context.go('/'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No había registros',
              description: 'Esta copia no contiene datos de esta consulta.',
            ),
          for (final row in rows.take(_limit)) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final key in labels.keys)
                    if (row.data.containsKey(key))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SelectableText(
                          '${labels[key]}: ${key == 'action'
                              ? (auditActionLabels[row.data[key]] ?? 'Cambio registrado')
                              : key == 'actorUid'
                              ? (widget.data.members(widget.groupId).where((m) => m.uid == row.data[key]).firstOrNull?.displayName ?? 'Usuario histórico')
                              : format(row.data[key])}',
                          style: AppTypography.of(context).bodyMedium,
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (rows.length > _limit)
            AppButton(
              label: 'Cargar más de la copia',
              variant: AppButtonVariant.outline,
              onPressed: () => setState(() => _limit += 50),
            ),
        ],
      ),
    );
  }
}
