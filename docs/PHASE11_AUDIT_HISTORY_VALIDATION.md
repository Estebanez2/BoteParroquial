# Consulta de auditoría administrativa — 2026-10-20

Corrección D160 (04/11/2026): el decoder antiguo rechazaba Timestamp dentro de
before/after de movimientos e invalidaba páginas enteras. Corregido sin alterar
eventos; cursor conserva nanosegundos, y la cabecera distingue fallo/carga de cero
confirmado. Evidencia en MENUS_ACTIONS_AUDIT_2026-11-04.md. La validación de esta
entrega histórica no cubría esa combinación real de eventos.

Continuación acotada de Phase 11 y apartados 57–58 de la especificación completa.
Implementación de consulta terminada; no acredita ejecución física ni auditoría
de todas las operaciones. El usuario ejecuta la app.

## Entregado

Grupo → Historial administrativo ya no se limita a los últimos cien cambios.
Consulta cincuenta por página y usa el botón **«Cargar más cambios»**, elegido
por el usuario en D104. Un documento adicional sirve para detectar otra página.

- Búsqueda que ignora mayúsculas, tildes y espacios repetidos; por acción, autor,
  entidad y valores anteriores/nuevos. Filtros por autor y tipo de entidad.
- Coincidencias explícitas **entre los cambios cargados**. No hace búsquedas de
  texto completo en Firestore ni carga todo el histórico al escribir. Se puede
  seguir consultando páginas aunque la primera no tenga coincidencias.
- Fichas de registro con operación, autor y fecha. Detalle con antes/después,
  importes y meses legibles, y desplegable con identificadores para revisar una
  incidencia. Los nombres se resuelven con las membresías actuales; no se
  inventa una instantánea histórica del nombre. Hora identificada como del móvil.
- La primera página escucha cambios. Al empezar a paginar se congela su límite;
  las novedades muestran «Mostrar cambios nuevos» para reiniciar la consulta,
  sin insertar filas que desplacen los límites y dejen huecos entre páginas.
- Caché inicial señalizada con el retraso visual existente, sin afirmar ausencia
  de Internet durante una confirmación breve. Páginas antiguas exigen respuesta
  del servidor; no se anuncia final completo a partir de una caché sin confirmar.
- Bloqueo de doble carga y validación de cada página. Error conserva las filas
  consultadas cuando es recuperable; datos inválidos o pérdida de permisos retiran
  el contenido. Respuestas tardías se descartan al cambiar cuenta, acceso o consulta.
- Detalle abierto también reevalúa permisos y la cuenta que lo abrió. No conserva
  valores privados visibles al perder acceso, aunque la hoja siga abierta.

No hay edición/borrado de auditoría, cambios económicos ni restauraciones.

## Contrato y arquitectura

Pantalla/controles/detalle → audit_history_providers → AuditHistoryRepository →
AuditHistoryService / FirestoreAuditHistoryService → Firestore. Modelo puro en
audit_history.dart; lectura separada del contrato de crear/editar grupos. Se
retira el lector antiguo limitado a cien y su provider, sin alterar sus escrituras.

Ruta existente `groups/{groupId}/auditEvents`. Orden descendente por createdAt e
ID de documento. Cursor ligado al grupo con segundos y nanosegundos originales,
sin convertir primero a DateTime y perder precisión. El desempate compara bytes
UTF-8 como los IDs de Firestore. Cada página comprueba grupo, orden, duplicados,
cursor y campos antes de incorporarse. No se cambia la forma persistida.

El decodificador conserva eventos antiguos sin entityType (group por defecto),
lee el entityId real y mantiene los mapas planos antes/después. Rechaza formatos
inválidos en lugar de omitir silenciosamente parte de una página. Los campos
técnicos de devoluciones no se confunden con esos mapas administrativos.

Providers limitados por UID/grupo y gestión autorizada; el backend conserva los
permisos existentes de owner/admin. No se añaden índices, dependencias, permisos,
colecciones o campos. No se publican Rules/Firebase/Supabase ni se crean datos DEMO
remotos. Cero documentos creados, modificados o borrados en esta entrega.
La fuente local de Rules sigue con SHA-256:
`c9e4cb547e11c5053f8814eea7ca3622a39eef6e45e7af1b02608532516d3c55`.
Su publicación previa está en el informe de notificaciones; no se afirma una
nueva comprobación remota. La copia externa anterior permanece intacta.

## Comprobaciones realizadas

Cuatro casos distintos dirigidos, sin suite general:

- Cursor y dominio: dos páginas sin repetición; eventos de otro grupo; orden con
  nanosegundos dentro de la misma microfecha y desempate UTF-8; búsqueda española;
  contrato antiguo sin tipo, precisión del Timestamp y rechazo de mapa corrupto.
- Estado: caché sin confirmar no carga otra página, doble pulsación solo consulta
  una vez; novedades conservan la frontera; actualizar reinicia con la nueva
  cabecera; una respuesta pendiente tras revocar acceso no repone datos privados.
- UI: búsqueda sin coincidencias iniciales, cargar hasta un evento antiguo y
  abrir su detalle; claro/oscuro, ancho 360, texto 160 % y movimiento reducido.
  Revocar acceso con detalle abierto retira valores. Servicios simulados.
- Regresión existente «Grupos, informes, ficha, auditoría y nombre de perfil
  integrados»: navegación de grupo a la nueva consulta vacía, sin romper el resto.

Los casos afectados se repiten tras ampliar caché/actualización y endurecer los
controles de respuestas tardías. Un análisis inicial detectó estilo y dobles de
interfaces selladas del SDK en la prueba: corregidos usando el decodificador de
datos, sin desactivar avisos del analizador. Análisis final limpio (5,1 s).
Formato de archivos afectados aplicado. Logs ignorados `.dart_tool/audit-history-*`.
APK debug compilado (13,6 s), sin instalación ni arranque. Se mantienen avisos
de migración Kotlin del plugin, sin error de compilación. El APK se actualizó
tras ajustar la presentación de una caché vacía aún sin confirmar.

Archivo: `build/app/outputs/flutter-apk/app-debug.apk`, 242.983.175 bytes.
SHA-256: `30c215e4e043ab6c43533b0e58f2d8e534499332086f40dba06e03143d92a439`.

No se ejecutan suites de Rules porque no cambian permisos. Las pruebas de
adaptadores y cursores no certifican una consulta del SDK contra la red real;
la primera ejecución física y otros roles/cuentas siguen pendientes.

## Revisión pendiente y siguiente alcance

Seguir AUD-01–05 en [la guía móvil](GUIA_PRUEBAS_MOVILES.md). Con más de cincuenta
eventos, cargar dos páginas y comprobar un detalle antiguo. Si no hay suficientes
registros, dejar la paginación física pendiente; no fabricar cien cambios reales
solo para marcar el caso como superado.

Esta entrega mejora la consulta de **eventos que ya se guardan**. No reconstruye
el pasado ni introduce auditoría nueva en altas de personas sin primer periodo,
ediciones ordinarias de personas o cambios de foto. Los movimientos conservan
su propio historial. Completar cobertura de escrituras requiere su contrato
atómico y revisión de Rules correspondientes; no darlo por hecho por esta UI.

Papelera de diez días, restauración/eliminación segura de elementos admisibles,
eliminación de grupos y baja de cuenta permanecen pendientes. Tampoco cierra
agregados/volumen, PDF/Excel o pruebas físicas anteriores. Las páginas cargadas
se acumulan en memoria durante la consulta: virtualización y búsqueda remota para
volumen extremo son ampliaciones, sin afirmar escalabilidad ilimitada.
