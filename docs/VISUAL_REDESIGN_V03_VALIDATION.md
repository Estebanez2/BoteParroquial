# Rediseño v0.3 — carbón y menta

**Histórico:** el usuario rechaza esta apariencia después de instalarla y solicita
la nueva entrega [v0.4](VISUAL_REDESIGN_V04_VALIDATION.md). No considerar aprobada v0.3.

Entrega: 2026-10-30. Implementación terminada; aprobación visual en móvil pendiente.

## Petición y dirección elegida

El usuario aporta dos referencias de Inicio y resumen del grupo. Solicita renovar
el aspecto de toda la app, extender el diseño a los componentes que no aparecen
en las imágenes y consultar recursos externos, especialmente de animación.
Ante la elección entre reproducción muy fiel e interpretación con más personalidad,
elige **«Más expresivo»** (D113).

## Implementación

- Paleta compartida carbón/menta, textos blancos fríos, secundario coral y peligro
  rosa. Tema claro coordinado con superficies blancas/verdosas.
- Manrope también en títulos y cifras destacadas, con cifras tabulares y los
  formateadores exactos existentes. Sustituye los titulares serif de v0.2.
- Tarjetas, paneles, campos, botones, icon buttons, distintivos, selectores de
  opciones y estadísticas actualizados en `lib/design_system/`. Controles con
  radio 12, tarjetas 20 y paneles 28; áreas táctiles mínimas conservadas.
- Inicio: marca bicolor, cabecera de comunidad, grupos compactos con rol/saldo,
  creación desde el botón + con tooltip y acceso a invitación/copias.
- Resumen: identidad en tarjeta, saldo, acciones de ingreso/retirada, cifras
  históricas y actividad reciente antes del bloque de cuotas. Etiquetas de caja
  histórica y fecha de confirmación conservadas.
- Barra inferior flotante: Inicio, Actividad, Personas e Informes. Usa rutas de
  consulta existentes y se retira si no hay membresía. Miembros y Cuotas siguen
  accesibles desde el resumen. La gestión autorizada se agrupa en el desplegable
  «Gestionar este espacio».
- El estilo compartido alcanza Personas, Miembros, historial, formularios, cuotas,
  informes, perfil, invitaciones, avisos, auditoría, bajas y copias. La estructura
  de cada pantalla secundaria sigue componiendo los componentes App* existentes.
- El visor de copias conserva su contenedor aislado, fecha fija y aviso persistente;
  la barra inferior resuelve sus rutas dentro de ese visor.

### Movimiento

- `AppReveal`: entrada de 540 ms, fade/desplazamiento/escala, con orden opcional
  de 65 ms por elemento, acotado a cinco escalones. Lista de grupos escalonada.
- `AppPressFeedback`: respuesta .975 al pulsar; las acciones, foco y semántica
  pertenecen al control Material. Soltar/cancelar restablece la escala.
- `AppAtmosphere`: órbitas decorativas que se dibujan una vez en 900 ms dentro
  de los paneles. No son un gráfico de tendencia ni un porcentaje de cumplimiento.
- Desplegables y navegación inferior usan las duraciones comunes.
- Movimiento reducido: entradas inmediatas, sin escala al pulsar y ornamentación
  ya dibujada. No se añade animación continua al fondo.

### Recursos consultados y adaptación

| Fuente | Uso en esta entrega |
| --- | --- |
| [Forui](https://forui.dev) | Referencia de controles móviles mínimos, superficies y jerarquía consistente |
| [Flutter Animate, gskinner](https://github.com/gskinner/flutter_animate) | Referencia de fade/scale, secuencias, entradas de listas y reacciones al estado |
| [Flutter: Introduction to animations](https://docs.flutter.dev/ui/animations) | Implementación con animaciones implícitas, Tween y curvas del SDK |

Se adaptan las ideas al sistema propio App*. No se incorpora código, assets ni
una nueva dependencia de esos repositorios. Los recursos consultados no descargan
contenido al ejecutar la app.

## Comprobaciones realizadas

1. `dart format lib test`: aplicado; las modificaciones de formato pertenecen a
   archivos de esta entrega.
2. `flutter analyze`: **sin incidencias** tras los últimos cambios Dart.
3. Comando dirigido:

   ```text
   flutter test --no-pub test/design_system_test.dart test/dashboard_test.dart test/groups_test.dart test/quota_report_flow_test.dart test/full_product_progress_test.dart test/daily_snapshots_test.dart
   ```

   **33 pruebas superadas**: controles/contraste/galería en claro y oscuro a 360 px
   con texto 160 %, pulsación cancelada y movimiento reducido, entrada finita,
   navegación del resumen, cambios de cuenta y revocación, grupos/informes/ficha/
   auditoría/perfil y copias. La prueba del visor recorre Actividad → Inicio y
   comprueba que siguen el aviso fijo y las acciones de escritura ausentes.
4. Exportación visual optativa:

   ```text
   flutter test --no-pub --dart-define=EXPORT_GROUP_PREVIEWS=true test/groups_preview_test.dart
   ```

   **Una prueba superada**, ocho PNG con fuentes reales en
   `.dart_tool/groups_preview/`: Inicio, resumen, Personas, Miembros, historial,
   nuevo movimiento y alta de persona en oscuro; resumen en claro. Todos se han
   abierto y revisado. Se corrigió la disposición de tarjetas estrechas detectada
   en la primera captura. Son fixtures locales, no capturas de datos del servidor.
5. `flutter build apk --debug`: **compilado** en
   `build/app/outputs/flutter-apk/app-debug.apk`.
   Instalado posteriormente por petición del usuario en **A059P**, Android 16
   (API 36), mediante `flutter install --debug -d 00166155L000316`.
   Instalación completada; apertura y aprobación visual pendientes del usuario.
6. `git diff --check`: sin errores de whitespace en la revisión de código.

### Ajustes de fixtures durante la comprobación

Los flujos antiguos de UI iniciaban el controlador de copias contra `FakeApp`,
sin un Firebase válido. Se añade `test/support/idle_daily_copies.dart` para aislar
ese ciclo de vida en las pruebas visuales; las pruebas específicas de copias
siguen usando su implementación real. Los fixtures de informes/creación y la
exportación se completan con fuentes de caja/personas/cuotas en memoria. Los
recorridos de creación y edición se adaptan al botón + y al nuevo desplegable.

## Pendientes

- El usuario ejecuta el APK instalado y confirma la estética, comodidad y animación
  en su móvil, con sus fotos/datos reales.
- La revisión PNG y las pruebas de widgets no acreditan fluidez en hardware,
  funcionamiento de canales nativos ni aprobación visual física.
- Compilación/ejecución iOS requiere Mac/Xcode y sigue pendiente.
- Los pendientes funcionales y físicos de las entregas anteriores conservan su
  estado en `ROADMAP.md` y sus documentos de validación.

Esta entrega modifica presentación y pruebas locales. No se han publicado reglas,
índices o servicios, ni cambiado datos remotos. La lógica financiera y los
permisos siguen en sus capas existentes.
