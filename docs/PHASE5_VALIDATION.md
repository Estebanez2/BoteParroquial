# Phase 5 — Dashboard

2026-10-15. Implementado; validación dirigida. El usuario ha desconectado el móvil,
por lo que no se instala ni se afirma prueba física del Dashboard.

Decisiones explícitas:

- El resumen es el inicio de cada grupo.
- Actividad ordenada por último cambio registrado, con correcciones y anulaciones.
- Reutilizar los datos actuales del MVP; no adelantar agregados ni cambios de Rules.
- Mantener pruebas proporcionadas y explicar qué falta para el MVP.

Implementación:

- Saldo y totales históricos en céntimos. Solo active contribuye; el original
  corregido y los anulados se excluyen, el sustituto activo sí cuenta.
- Conteo de personas activas/inactivas, distinto del de cuentas members.
- Cinco cambios financieros recientes. La corrección se representa una vez y
  lleva al original conservado; una anulación posterior del sustituto es otro cambio.
- Advertencia de saldo negativo, vacío, carga, error y reintento; no mostrar ceros
  ficticios cuando aún se están cargando datos ni mantener cifras tras perder acceso.
- Accesos a personas, miembros y movimientos; registro rápido según permisos.
- DashboardRepository y sus modelos no importan Flutter ni Firebase. Widgets sin
  cálculos financieros, con App*, tema claro/oscuro y movimiento reducido.
- Personas y miembros pasan a /groups/:groupId/persons y /groups/:groupId/members.
  Se extrae GroupAccessBody para compartir el guard visual de estas pantallas.
- Se corrige Ref diferido en los providers de personas y movimientos: seleccionar
  el stream según el estado del grupo dentro de la construcción del provider.

Verificado:

| Comprobación | Resultado |
| --- | --- |
| Formato y flutter analyze --no-pub | Sin incidencias |
| Pruebas dirigidas | 8 superadas: dashboard (2), groups (4), persons (1), movements (1) |
| flutter build apk --debug --no-pub -t lib/main.dart | Correcto; APK listo en build/app/outputs/flutter-apk/app-debug.apk |
| Reglas/datos Firebase | Sin modificaciones; no se repiten pruebas de Rules |
| Móvil / dos administradores | No comprobados en esta fase |

El caso de dominio comprueba cifras esperadas con anulaciones/correcciones,
conteo de personas, deduplicación/orden de actividad, límite, vacío, negativo y
rechazo de datos de otro grupo. El caso de pantalla comprueba actualización por
stream, navegación, error/reintento y revocación, a 360 px, texto al 160 %, oscuro
y movimiento reducido. Los otros seis casos verifican los flujos afectados por
las rutas y suscripciones; no se ejecuta la suite completa ni exportaciones visuales.

No se han creado datos nuevos: siguen disponibles los casos DEMO de Phase 4.
No hay colecciones/campos, índices, reglas, librerías, Functions ni notificaciones nuevos.
El saldo no se almacena. Los flujos actuales cargan todo el historial: esta concesión
del MVP la aprueba el usuario; no da por resuelto el rendimiento con miles de movimientos.
La actividad es una proyección del estado conservado, no un registro exhaustivo de eventos.
La distinción entre caché y conexión y las pruebas de zona horaria siguen en hardening.

Para cerrar el MVP falta Phase 6: revisar robustez/permisos, conexión y concurrencia;
probar el APK/flujo real; configurar y probar otro administrador con sincronización
entre móviles, y completar las comprobaciones de auth pendientes cuando se retomen.
Si se usa iOS, requiere validación en Mac/Xcode. Las ampliaciones Phase 7–12 no son
requisitos para cerrar el MVP Android. Ver docs/ROADMAP.md como registro principal.
