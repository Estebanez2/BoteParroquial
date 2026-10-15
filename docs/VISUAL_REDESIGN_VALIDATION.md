# Rediseño visual por referencias — v0.2

2026-10-15. El usuario aporta ocho imágenes como referencia visual. Después elige:

- Rediseñar ahora con iniciales y aplazar las subidas de fotos/Storage.
- Foto futura de cuenta propia y fotos independientes por grupo con permisos D053.
- Aplicar la estética solo a funciones existentes; no adelantar funcionalidades
  futuras dibujadas, como invitaciones, notificaciones y estadísticas avanzadas.

## Implementación

Verde casi negro, menta y coral; fondos/superficies con degradados, contornos,
paneles con anillos, títulos Newsreader y texto Manrope local. Oscuro predeterminado;
la variante clara sigue disponible en el tema y en vistas de comprobación.
Se adapta la composición al contenido real, ancho y texto ampliado: las capturas
son referencia estética, no fotografías ni cifras que se deban inventar en la app.

Los cambios viven en tokens y componentes App*. Se añaden AppGradients, AppHeroPanel,
AppCover, AppAdaptiveRow, AppNavigationTile, AppChoiceBar, AppExpandableRow,
AppAvatarMenu y AppActionMenu. AppAvatar obtiene iniciales de nombre/apellidos;
sin nombre muestra un icono. AppCover reserva el espacio visual para una imagen
de grupo, con iniciales mientras no exista una imagen proporcionada por el llamador.
No hay selector de fotos ni botones de cámara aparentando una subida funcional.

Pantallas adaptadas:

- Inicio: marca serif, menú de cuenta, panel de bienvenida y tarjetas de grupos
  con cubierta, rol, moneda y saldo real del provider. No hay botón ficticio de crear.
- Resumen: cabecera compartida, saldo, acciones, accesos, cifras agrupadas y actividad.
- Historial: grupos por fecha efectiva y filas desplegables. Sus detalles conservan
  autores, fechas, motivos, enlaces entre correcciones y acciones según permisos.
- Personas: cabecera, lista con iniciales, estado, edición y menú de activación.
  Alta/edición pasa a pantalla completa por la nueva referencia; notas siguen con
  el límite existente, alta sigue activa y la inactivación conserva confirmación.
- Movimiento: selector segmentado ingreso/retirada, campos en tarjetas y cantidad
  destacada. Ingreso sigue exigiendo persona, aunque la imagen la describa opcional;
  motivo obligatorio en retirada y demás validaciones económicas se conservan.
- Miembros: resumen/lista con datos reales. No se inventan correos, última conexión
  ni invitaciones; se muestra joinedAt, no una fecha de actividad inexistente.
- Login: migra a App*; estados, errores y acción Google permanecen en providers.

UI → Provider → Repository → Service se mantiene. MovementHistoryRepository
agrupa por fecha sin SDK ni Flutter, conservando estados y aislamiento por groupId.
Home reutiliza dashboardProvider para saldos: mantiene la concesión del MVP de leer
flujos completos por grupo; no se han implementado agregados ni otra fuente de saldo.
El menú de cuenta se cierra al cambiar identidad para no retener datos anteriores.

## Comprobado

- flutter analyze --no-pub: sin incidencias.
- Ocho comprobaciones dirigidas de los flujos de Dashboard, Groups, Persons y
  Movements superadas. Incluyen navegación, permisos simulados, texto al 160 %,
  movimiento reducido, creación/edición/estado, corrección/anulación y recuperación.
- Cuatro comprobaciones simuladas de auth superadas tras mover cuenta/logout al
  menú y adaptar login. No son las pruebas manuales aplazadas de segunda cuenta.
- Cuatro comprobaciones de componentes: iniciales con acentos, contraste de tokens
  claro/oscuro, botón deshabilitado/cargando y entrada exacta de céntimos.
- Una exportación visual dirigida genera ocho vistas, con fuentes locales reales:
  home-dark, group-dark, persons-dark, members-dark, history-dark, movement-dark,
  person-editor-dark y group-light. Exportación con datos simulados, sin Firebase.
  Se inspeccionan composiciones y se corrigen cortes de palabras/controles.
- APK normal debug compilado. La instalación se intentó en A059P, pero ADB no lo
  detectaba en ese momento; no se afirma validación nativa de esta versión.
- Sin cambios de Firebase, Rules, índices, dependencias ni datos de la base en
  este rediseño. Las reglas y datos previos de Phase 6 permanecen.

Vistas fuera de Git: `.dart_tool/groups_preview/`.
APK: `build/app/outputs/flutter-apk/app-debug.apk`.

```powershell
flutter test --no-pub --dart-define=EXPORT_GROUP_PREVIEWS=true test/groups_preview_test.dart
```

## Pendiente

- Instalar/comprobar esta versión en A059P y recibir aprobación visual del usuario.
  No dar por conseguida una coincidencia exacta con las imágenes sin esa revisión.
- Fotos reales, almacenamiento y permisos D053: expresamente aplazados. Antes de
  implementarlos, cerrar la relación entre foto de persona interna y de membresía.
- Funciones futuras de las referencias continúan en sus fases; ningún control
  decorativo concede acceso o simula una función inexistente.
- Recuperación/offline físicos, segunda cuenta, sincronización en dos móviles e
  iOS mantienen su estado previo. Ver ROADMAP y PHASE6_VALIDATION.

Referencias originales: archivos aportados con nombres `Imagen de ChatGPT 15 oct
2026, 17_41_41-1.png` hasta `17_41_46-8.png` en Downloads. No se incorporan las
capturas completas como fondos de pantalla ni se reutilizan sus fotografías para
atribuir imágenes ficticias a personas/grupos reales.
