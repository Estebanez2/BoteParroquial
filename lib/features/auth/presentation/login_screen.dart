import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(firebaseStartupProvider);
    final action = ref.watch(authControllerProvider);
    final session = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('BoteParroquial')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_outlined, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenido a BoteParroquial',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Accede con tu cuenta de Google.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!startup.isReady)
                    Text(
                      startup.error == null
                          ? 'Configuración de Firebase pendiente.'
                          : 'Firebase no disponible. Completa la configuración o revisa la conexión.',
                      textAlign: TextAlign.center,
                    ),
                  if (action.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        failureMessage(action.error!),
                        textAlign: TextAlign.center,
                        semanticsLabel:
                            'Error de acceso: ${failureMessage(action.error!)}',
                      ),
                    ),
                  if (session.hasError) ...[
                    Text(
                      failureMessage(session.error!),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(authControllerProvider.notifier)
                          .retrySession(),
                      child: const Text('Reintentar sesión'),
                    ),
                  ],
                  FilledButton.icon(
                    onPressed: !startup.isReady || action.isLoading
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signIn(),
                    icon: action.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      action.isLoading ? 'Conectando…' : 'Continuar con Google',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
