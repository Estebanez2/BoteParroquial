import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

class BoteParroquialApp extends ConsumerWidget {
  const BoteParroquialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'BoteParroquial',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245C47)),
      useMaterial3: true,
    ),
    routerConfig: ref.watch(routerProvider),
  );
}
