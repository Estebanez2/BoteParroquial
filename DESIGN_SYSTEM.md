# BoteParroquial — Design System v0.1

Implementación y galería preparadas para revisión. **Identidad pendiente de
aprobación del usuario.** Login y home conservan su aspecto anterior. Phase 2 no
ha empezado. Los datos de la galería son ejemplos, no información del backend.

## Identidad visual

Serena, cercana y contemporánea: verde profundo, marfil cálido y acentos arcilla.
Superficies ligeras, contornos suaves y jerarquía fuerte para las cifras. La marca
vectorial representa dos formas que comparten un centro; es una propuesta de
interfaz, no un logotipo definitivo. No incorpora símbolos religiosos explícitos.

Manrope para lectura, acciones y cifras; Newsreader para titulares editoriales.
No usar serif en formularios o tablas. Las fuentes se incluyen localmente en
`assets/fonts/` con sus licencias SIL OFL, sin descargas al abrir la app.
Iconografía Material outlined/rounded coherente, sin otra dependencia de iconos.

## Arquitectura visual

```text
Flutter / Material / eventual librería externa
  → lib/design_system/
    → componentes App* y componentes semánticos como BalanceCard
      → pantallas de features
```

API pública: `package:bote_parroquial/design_system/design_system.dart`.
Los tokens viven en `lib/design_system/theme/`; no crear otra paleta en `core/theme`.
Los componentes no importan Firebase ni modelos/providers de negocio. Reciben
valores y callbacks. PersonListTile, MovementListTile o MonthlyContributionCard
seguirán en su feature y compondrán estas piezas cuando se implementen.

## Tokens

Resolver con `AppColors.of(context)` y `AppTypography.of(context)`. AppColors es
una ThemeExtension con `copyWith`, `lerp` y paletas light/dark. AppTheme configura
la implementación Material de inputs, calendario, diálogos, paneles y tipografía.
Por ahora AppTheme solo se conecta a la galería; la migración requiere aprobación.

### Color

| Token | Claro | Oscuro |
| --- | --- | --- |
| primary | #22594D | #A8D4BD |
| primaryContainer | #E0EEE6 | #234B3D |
| onPrimary | #FFFFFF | #142D24 |
| secondary | #9A503A | #E8AD94 |
| secondaryContainer | #F5E6DE | #50352C |
| background | #F7F6F1 | #121D18 |
| surface | #FFFEFA | #1A2821 |
| surfaceVariant | #EEEFE8 | #23352B |
| textPrimary | #20372F | #EDF0E6 |
| textSecondary | #52645B | #BECABE |
| textMuted | #66736B | #A5B6A7 |
| success | #236749 | #9BD6B4 |
| warning | #88591A | #F0CB88 |
| danger | #B23E3E | #F6AAAA |
| info | #345F87 | #A9CEEE |
| divider | #E2E5DC | #354A3B |
| outline | #818D82 | #829A86 |
| hero | #193F35 | #284E3F |
| onHero | #F5F5E9 | #F5F5E9 |

Primary identifica acciones, secondary aporta acento cálido, hero distingue el
saldo, surface contiene cards/formularios, divider separa y outline delimita
controles. Estados siempre con etiqueta/icono además de color. Los tonos no
conceden permisos ni interpretan estados persistidos.

### Tipografía

| Estilos | Tamaños base |
| --- | --- |
| displayLarge | 48, Newsreader |
| headingLarge / Medium / Small | 30 / 24 / 19, Manrope |
| bodyLarge / Medium / Small | 16 / 14 / 12 |
| labelLarge / Medium / Small | 14 / 12 / 11 |
| moneyHero / Large / Medium | 48 / 30 / 20, cifras tabulares |
| sectionTitle / statisticValue / movementAmount | Alias de headingSmall / moneyLarge / moneyMedium |

Usar estilos semánticos, no TextStyle arbitrarios por pantalla. Las cifras usan
`FontFeature.tabularFigures`. Respetar texto ampliado con layouts flexibles y scroll.

### Espaciado, radios y sombras

- AppSpacing: xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48. Página 24,
  separación de secciones 40, contenido máximo 1080.
- Botón normal: mínimo 52; compacto e icon button: mínimo 48 de alto.
- AppRadius: small 8, medium 12, large 20, extraLarge 28, pill 999.
  Controles 12, cards 20, hero/overlays 28.
- AppShadows.soft: elevación ligera; floating: preparada para superficies
  flotantes. Las cards base usan borde, sin sombra. No inventar sombras por feature.

### Movimiento

AppMotion: fast 140 ms, normal 220 ms, slow 320 ms; easeOutCubic/easeInOutCubic.
AppReveal combina fade y desplazamiento de 8 puntos; MoneyText ofrece
AnimatedSwitcher opcional. Evitar rebotes y animar cada cambio. AppMotion,
AppReveal y LoadingIndicator respetan movimiento reducido; el loader usa un
icono estático accesible cuando ese ajuste está activo.

## Componentes implementados

| Componente | Variantes y capacidad |
| --- | --- |
| AppButton | primary, secondary, outline, ghost, destructive; normal/compact; loading; disabled con onPressed null; iconos inicial/final; fullWidth |
| AppIconButton | standard (por defecto), ghost, danger; tooltip obligatorio |
| AppTextField | label, hint, icon, error, helper, password, enabled, readOnly, controller, validator y formateadores |
| AppMoneyField | currency explícita; callback int? de céntimos; dos decimales sin miles ni negativos |
| AppDropdown<T> | Opciones tipadas, valor controlado, error y deshabilitado |
| AppDateField | Fecha controlada, límites opcionales y calendario localizado |
| AppCard | standard (por defecto), elevated, outlined, interactive |
| BalanceCard | Saldo/moneda proporcionados; ingresos/retiradas opcionales; pie y motivo decorativo |
| StatisticCard | Etiqueta, valor ya preparado, icono y pie opcional |
| AppAvatar | ImageProvider con fallback a iniciales; small/medium/large; indicador con etiqueta |
| AppBadge | neutral, primary, success, warning, danger, info; icono opcional |
| StatusChip | Pagado, Pendiente, Parcial, Adelantado, Admin, Owner, Member, Activo, Inactivo |
| MoneyText | balance, income, withdrawal; hero/large/medium; moneda y animación opcionales |
| AppDialog | information, confirmation, warning, danger; cancelación/descartar devuelve false |
| AppSnackbar | success, error, warning, info; un mensaje visible a la vez |
| LoadingIndicator | Tamaño/color, etiqueta accesible y alternativa sin movimiento |
| EmptyState | Icono, título, explicación y acción opcional |
| AppTopBar | Título, leading, acciones; sin elevación ni tintes automáticos |
| AppBottomNavigation | Destinos tipados, índice y callback, sin lógica de rutas |
| AppScaffold | SafeArea, margen, fondo, ancho máximo, scroll, app bar y navegación inferior |
| AppSection | Título, introducción opcional y separación común |
| AppBottomSheet | Título, builder, scroll y ajuste al teclado |
| AppBrand | Marca vectorial con nombre o compacta |

Cada archivo tiene implementación real. Los enums usan `standard` para la
variante por defecto porque `default` es palabra reservada de Dart.

### Dinero y fechas

`parseMoneyCents('20,50')` devuelve 2050, también acepta punto decimal. No usa
double. El input bloquea caracteres inválidos y más de dos decimales; vacío
devuelve null. Admite hasta 12 cifras de unidades y dos decimales. Cero se puede
escribir: su validez en una operación pertenece al validador/repository de negocio.

`formatMoneyCents` usa punto de miles y coma decimal. MoneyText añade signo y
semántica; saldo admite negativos. Withdrawal recibe importe positivo. EUR, USD
y GBP tienen símbolo; otros códigos se muestran como texto conservando **dos
decimales**. No convierte divisas ni soporta todavía otras unidades mínimas.
BalanceCard no calcula el saldo. StatisticCard no calcula métricas. StatusChip no
implementa cuotas o permisos. Ninguno de estos componentes persiste datos.

AppDateField devuelve una fecha de calendario local. Conversión a zona de grupo,
UTC y persistencia corresponde a la feature/service. Controllers externos son
propiedad del llamador y deben liberarse en su ciclo de vida.

## Uso

```dart
import 'package:bote_parroquial/design_system/design_system.dart';

AppButton(
  label: 'Guardar',
  leadingIcon: Icons.check_rounded,
  loading: state.isLoading,
  fullWidth: true,
  onPressed: save,
)
```

En features, las acciones de negocio deben venir de providers. Buscar el componente
existente antes de crear otro. No instanciar componentes complejos externos
directamente en pantallas si hay o debe haber un equivalente App*.

## Galería de desarrollo

```sh
flutter run --debug -t lib/main_showcase.dart
```

Identidad, Controles, Feedback y Tokens permiten revisar claro/oscuro, inputs,
fechas/opciones, cards, badges, diálogos, snackbars y paneles. El estado es local.
No inicializa Firebase ni se añade a rutas de producción. El entrypoint rechaza
ejecución fuera de debug. No se añadió soporte web/escritorio al proyecto; los
layouts anchos también se revisan en el entorno de pruebas.

Para volver a la app: `flutter run --debug -t lib/main.dart`. Ambos entrypoints
usan el mismo identificador Android: ejecutar uno sustituye temporalmente el
binario instalado. No hace falta desinstalar para alternarlos.

Login y home no se han rediseñado ni conectado al tema nuevo. Su apariencia
provisional es una excepción documentada, no un patrón para nuevas pantallas.
Después de aprobar el estilo se migrarán en una tarea explícita.

## Librerías evaluadas

Consulta del 2026-10-15 para Flutter 3.44.8 / Dart 3.12.2. Son requisitos declarados,
no prueba de integración de paquetes no instalados. Los candidatos publican
soporte Android/iOS. Las fechas permiten evaluar actividad sin instalar paquetes.

| Candidato | Versión / publicación | Requisitos declarados | Decisión |
| --- | --- | --- | --- |
| [Forui](https://pub.dev/packages/forui) | 0.27.6 / 2026-10-14 | Flutter ≥3.47.0-0; Dart ≥3.13.0-0 | Incompatible con el SDK instalado; referencia visual |
| [shadcn_flutter](https://pub.dev/packages/shadcn_flutter) | 0.0.55 / 2026-10-01 | Flutter ≥3.47.0; Dart ≥3.13.0 | Incompatible con el SDK instalado |
| [shad](https://pub.dev/packages/shad) | 0.99.4 / 2026-08-18 | Flutter ≥3.41.0; Dart ≥3.11.0 | Requisitos compatibles; no hace falta otra capa completa de UI |
| [flutter_animate](https://pub.dev/packages/flutter_animate) | 4.5.2 / 2024-11-25 | Flutter ≥2.0.0; Dart ≥2.17.0 | Compatible por requisitos; el SDK cubre la animación actual. Reevaluar si crecen los efectos |
| [Widgetbook](https://pub.dev/packages/widgetbook) | 3.25.0 / 2026-06-25 | Flutter ≥3.44.0; Dart ≥3.10.0 | Compatible por requisitos; la galería equivalente basta ahora. Candidato de desarrollo cuando crezca el catálogo |

Elección actual: App* propios sobre Flutter/Material y `flutter_localizations` del
SDK para calendario en español. No se añadió una biblioteca visual externa.
Envolver una futura biblioteca detrás de App*. No actualizar Flutter ni fijar
paquetes antiguos solo por esta propuesta.

Referencias: [tokens shadcn/ui](https://ui.shadcn.com/docs/theming),
[Forui](https://forui.dev/docs),
[Manrope](https://github.com/google/fonts/tree/main/ofl/manrope) y
[Newsreader](https://github.com/google/fonts/tree/main/ofl/newsreader).

## Validación y revisión

- Suite completa: 22 pruebas superadas; exportación visual optativa omitida por
  defecto. Las ocho pruebas de auth/base siguen pasando.
- Design System: 14 pruebas, incluyendo dinero, contraste, estados, diálogo,
  calendario y ocho combinaciones claro/oscuro a 360 px con texto al 160 %.
- Contraste ≥4.5:1 comprobado para los tres textos sobre fondo y para los pares
  primary/onPrimary y hero/onHero. No equivale a una auditoría completa de accesibilidad.
- Se exportaron seis vistas de galería; se inspeccionaron identidad clara/oscura,
  controles, feedback y paleta. No son capturas de datos reales ni pruebas nativas iOS.
- `flutter analyze`: sin incidencias. Los APK debug de la galería y de la app normal
  compilan. La galería se conserva en `build/app/outputs/flutter-apk/design-system-debug.apk`
  y la app normal en `build/app/outputs/flutter-apk/app-debug.apk`.

```sh
flutter test --dart-define=EXPORT_DESIGN_PREVIEWS=true test/design_system_preview_test.dart
```

Las vistas se escriben en `.dart_tool/design_system_preview/`, fuera de Git. La
exportación carga las fuentes reales y MaterialIcons. Las pruebas ordinarias no
escriben artefactos ni dependen de un golden de plataforma.

Revisar identidad, densidad, tipografía, modos y controles con el usuario antes
de migrar. Las pruebas manuales de autenticación aplazadas siguen pendientes y
no se reanudan aquí. iOS requiere Mac/Xcode para validación nativa.
