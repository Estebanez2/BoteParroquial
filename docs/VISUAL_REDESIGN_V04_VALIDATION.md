# Rediseño v0.4 — apariencia y navegación a medida

2026-10-30. Implementado, APK compilado e instalado en A059P; aprobación física pendiente.
Sustituye la apariencia v0.3 rechazada expresamente por el usuario.

## Acuerdos y alcance

- Nueva estética global con varias paletas, todas con claro y oscuro.
- El usuario elige guardar la apariencia **en este móvil** (D114).
- El usuario elige Atrás de sección → resumen del grupo → lista de grupos (D115).
- Retirar por completo el recuadro promocional de Inicio.
- Portada horizontal grande del grupo, de ancho completo, seguida del nombre y
  descripción. Participantes como página de entrada a Personas y Miembros.
- Mismas acciones de ingreso/retirada en resumen y Actividad; retirar del resumen
  los accesos generales duplicados que ya tiene la barra inferior.

## Entregado

### Apariencia

Cinco paletas: **Atlántico** (azul profesional), **Iris** (violeta expresivo),
**Coral** (terracota cálido), **Bosque** (salvia) y **Grafito** (grises profundos).
Cada una define acento, contenedor, fondo y superficie en claro/oscuro; los demás
tokens se resuelven centralmente, incluidos contornos, variantes y paneles.
Fondos planos, campos rellenos, tarjetas de radio 24 y paneles de radio 32;
controles de radio 16, distintivos tipo píldora, sin órbitas en los paneles.
La barra inferior es de ancho completo y admite etiquetas en varias líneas.

«Ajustes de apariencia» está en el icono de paleta de Inicio y en Tu perfil.
Modo Sistema/Claro/Oscuro y selección de paleta con muestras de ambos modos.
Base inicial: Atlántico/Sistema. Cambiar se aplica inmediatamente a la app, sin
reiniciar rutas, y conserva la elección de modo al cambiar paleta.

Persistencia por instalación en `appearance.json`, en application support:
UI → AppearanceController → AppearanceRepository → AppearanceService /
FileAppearanceService. Modelos sin Flutter/Firebase. Escrituras serializadas,
temporal/rename, fallback ante archivo ausente/corrupto y protección contra carga
tardía. Fallo al guardar conserva la selección visible y permite reintentar.
No se sincroniza con la cuenta ni se añade configuración remota.

### Estructura de pantallas

- Inicio: Tus grupos directamente, tarjetas con imagen panorámica y saldo,
  creación con +, invitación, copias y selector de apariencia. Se elimina todo
  el panel «CADA APORTE CUENTA».
- Resumen: foto 16:9 sin margen horizontal (a 360 px se comprueba ancho 360),
  nombre y descripción debajo, rol/moneda y contenido económico. Otras secciones
  muestran identidad compacta para dejar espacio al contenido.
- `PhotoCover` reutiliza caché/bytes/permisos existentes. `BoxFit.cover` adapta la
  vista; no modifica el fichero guardado ni el contrato del editor cuadrado.
  Sin foto conserva iniciales; las capturas usan ese fallback y datos simulados.
- Barra Inicio/Actividad/Participantes/Informes. Participantes ofrece «Ver personas»
  y «Ver miembros». Personas/Miembros mantienen también la barra seleccionada.
- `MovementActions` es el mismo componente en resumen y Actividad, con las mismas
  etiquetas, iconos, tonos, tamaños y rutas; permisos mediante el provider existente.
- Del resumen se retiran las tarjetas generales «Ver movimientos», «Ver personas»,
  «Ver miembros», «Informes del grupo», el enlace «Ver informe de cuotas» y el acceso
  general del título de actividad. Se mantienen cifras, cuotas y enlaces de detalle.
- Campos, formularios, cuotas, informes, avisos, perfiles, auditoría y pantallas
  secundarias reciben el nuevo sistema visual centralizado.

### Navegación y visor

Las rutas principales están anidadas bajo `/` → `/groups/:groupId` → sección.
La navegación inferior usa `go`, pero los padres siguen siendo páginas reales.
Atrás desde Actividad/Informes/Participantes vuelve al resumen y desde este a
Tus grupos. Desde Participantes se hace `push` a Personas/Miembros; Atrás recupera
esa página de elección. Las URL existentes siguen siendo válidas.

El router de la copia aplica el mismo anidamiento y permite Participantes. El
ThemeData elegido se pasa desde fuera; no se conecta su ProviderContainer al vivo
ni se introduce el servicio de preferencias dentro del visor. Aviso fijo, fecha
y bloqueos de SDK/escritura conservados.

## Verificación realizada

**37 pruebas dirigidas distintas superadas**, en ejecuciones acotadas, repitiendo
solo los flujos afectados por correcciones posteriores:

| Archivo | Casos | Evidencia |
| --- | ---: | --- |
| `design_system_test.dart` | 17 | Contraste base, controles, cancelación de pulsación, movimiento reducido, galería claro/oscuro a 360 px y texto 160 % |
| `appearance_test.dart` | 4 | Contraste en diez combinaciones; archivo y restauración; última escritura; carga tardía; error/reintento; selector con texto 160 % |
| `dashboard_test.dart` | 2 | Datos/permisos, portada de ancho completo, ausencia de accesos duplicados, selección Participantes y botón Atrás real del binding para las tres secciones y el resumen |
| `groups_test.dart` | 4 | Aislamiento de grupos/cuentas, revocación y reintento |
| `quota_report_flow_test.dart` | 1 | Dashboard/informes en ambos modos y acceso desde la barra tras retirar el enlace duplicado |
| `full_product_progress_test.dart` | 4 | Flujos de grupos, informes, ficha, auditoría y perfil, además de casos de dominio existentes |
| `daily_snapshots_test.dart` | 5 | Aislamiento/cifrado/lectura coherente, tema Coral oscuro recibido sin SDKs, Atrás desde Actividad y Participantes con aviso fijo |

En el fixture de dashboard se corrigen razones de anulación/corrección presentes
en registros activos sin sus timestamps: no son estados válidos. Las pruebas
usan servicios en memoria y no escriben datos remotos.

Comprobaciones adicionales:

- `dart format lib test`: aplicado.
- `flutter analyze`: sin incidencias tras corregir dos avisos de estilo.
- `flutter test --no-pub --dart-define=EXPORT_GROUP_PREVIEWS=true test/groups_preview_test.dart`:
  una prueba de exportación superada; **19 PNG** en `.dart_tool/visual_v04/`.
  Ocho vistas de Inicio/personas/miembros/historial/formulario/Participantes/
  informes/ajustes, alta de persona y diez vistas del grupo (cinco paletas × dos
  modos). Se han abierto y revisado; tras detectar etiquetas estrechas en Informes,
  se ajustó StatisticCard y se exportó de nuevo.
- `flutter build apk --debug`: compilado en
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Instalación solicitada después por el usuario: A059P, Android 16, dispositivo
  `00166155L000316`. `adb -s 00166155L000316 install -r build/app/outputs/flutter-apk/app-debug.apk`
  devuelve **Success**. Actualización sin desinstalar; apertura a cargo del usuario.
- `git diff --check`: sin errores en la revisión de código.

## Pendiente de comprobar en móvil

- Abrir el APK v0.4 ya instalado y revisar el resultado.
- Confirmar estética y comodidad con fotos reales, tanto en claro como en oscuro.
- Cambiar paleta/modo, cerrar y volver a abrir; comprobar persistencia en Android.
- Botón Atrás físico/predictivo y recorridos del grupo. El binding de widgets
  verifica el flujo de pop, pero no acredita el gesto/actividad nativa en hardware.
- iOS/Mac, permisos reales y pruebas funcionales previas mantienen sus pendientes.

No se han cambiado Rules, índices, SDKs, servicios remotos, datos financieros ni
permisos. Esta entrega no acredita aprobación estética ni validación física.
