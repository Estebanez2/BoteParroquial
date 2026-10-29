# Continuación del producto completo — 2026-10-20

Entrega implementada, publicada y sembrada. No equivale a validación física ni
a certificación de producción. Estado final resumido abajo; las fases anteriores
siguen documentadas en sus informes históricos.

## Alcance confirmado por el usuario

- Terminar por bloques los pendientes del producto completo y actualizar la guía
  para dos móviles y un tercero opcional. El usuario ejecuta la app.
- Al final, reiniciar documentos Firestore y fotos Supabase, conservando cuentas
  Firebase Authentication, reglas y configuración de servicios. Esta autorización
  expresa sustituye para ese reinicio la limitación anterior de solo añadir DEMO.
- Antes de borrar, guardar una copia puntual recuperable de documentos y fotos.
  La copia semanal local y su visor quedan aplazados por petición expresa.
- Crear dos grupos DEMO completos cuya propietaria sea ale.manu.cristi@gmail.com
  (`JDQpjp5XtFTDOoVgK5Rbc9EGUHB2`). No crear cuentas Google ficticias.
- Papelera: solo personas sin movimientos, asignaciones, periodos de participación
  ni cuenta vinculada. Restauración durante diez días; quienes tienen historial
  siguen inactivándose.
- Borrar un grupo exige verificar de nuevo la misma cuenta Google y escribir su
  nombre exacto; mostrar antes saldo y cantidades de personas, miembros y movimientos,
  con acceso a exportar.
- Baja de cuenta: transferir/eliminar primero sus grupos propios; retirar acceso,
  dispositivos y fotos propias conservando el historial económico de otros grupos.

## Evidencia disponible

Copia puntual Firestore completada antes de cualquier reinicio:

- Carpeta externa: `C:\Users\aleja\Documents\BoteParroquial-backups\firestore-data\2026-10-20T14-42-28-412Z`.
- Instante coherente: `2026-10-20T14:42:20.788301Z`.
- 63 documentos; SHA-256 de `firestore.json`:
  `48a7b677c86ac36b819e11b872eb8605dd60b663ce916e669f263d586c016197`.
- Tipos REST y rutas conservados, hash releído de disco; dos pruebas locales del
  lector. No incluye fotos ni cuentas Auth. Restauración todavía no ensayada.
- Herramienta: `tools/backup_firestore_data.cjs`; no programa tareas periódicas.

## Resultado de los bloques de esta continuación

1. PDF/Excel y CSV implementados; ficheros y autorización comprobados localmente.
2. Trazabilidad adicional de personas, movimientos, perfil y fotos publicada.
3. Papelera/restauración/purga, eliminación de grupo y baja propia implementadas.
4. D109: caja con agregados nativos exactos y actividad acotada; fuentes de cuotas
   compartidas excluyen retiradas ordinarias. La proyección completa de cuotas y
   los informes explícitos aún crecen con la historia: no afirmar coste constante.
5. Pruebas dirigidas de permisos/integridad, análisis y APK realizados; detalle abajo.
6. Copias finales de documentos/fotos, reinicio y DEMO ejecutados y verificados.
7. Guía de dos/tres móviles actualizada con cifras y recorridos nuevos.

No se han ejecutado las pruebas físicas: las realizará el usuario. La copia
semanal y el visor continúan aplazados por su decisión, no se han programado.

## Implementación entregada

- PDF multipágina con fuente local y Excel XLSX de cuatro hojas (Resumen,
  Personas, Movimientos, Actividad mensual), además de CSV. Comparten permisos,
  selección y cálculo económico; codificación en isolate y revisión de sesión
  antes de compartir. Tres pruebas dirigidas superadas. XLSX no emite fórmulas;
  enteros de más de quince cifras se conservan como texto exacto.
- Altas/ediciones/reactivaciones de personas y movimientos ordinarios generan
  auditoría atómica. Corrección conserva ambos movimientos; devoluciones mantienen
  su contrato anterior. Testigo inmutable `persons.firstMovementId` evita carreras
  con la papelera sin añadir otra lectura al presupuesto de devoluciones.
- Papelera: personas nuevas protegidas, sin historial/vínculo; restauración de
  estado previo durante diez días según servidor. Personas antiguas sin garantía
  de historial no pueden borrarse: se inactivan. Purga explícita tras vencimiento,
  con intención validada en Rules, limpieza de foto y evento inmutable.
- Eliminación de grupo: vista previa online, Google reciente y nombre exacto;
  bloqueo irreversible, tarea privada para reanudar desde Inicio y limpieza por
  lotes de las colecciones del esquema. Tres minutos de margen para envíos ya
  iniciados. El worker incorpora lectura transaccional del grupo antes de escribir
  y no puede recrear descendientes de un grupo bloqueado.
- Baja propia: comprobar grupos propios, retirar membresías conservando vínculo
  e historia, barrera contra nuevos grupos/entradas y segunda consulta, limpiar
  fotos/dispositivos/perfil y borrar la identidad Firebase. Intención mínima se
  conserva si Auth devuelve un resultado incierto, evitando recrear perfil al
  reiniciar. Treinta segundos para terminar subidas previas; reanudable.
- `lifecycle-cleanup` usa JWT del usuario y las Rules para autorizar. Solo la
  limpieza de Storage usa la clave interna ya existente del proyecto de fotos.
  No se crean claves Firebase, no se amplía IAM ni se usa la clave del worker aquí.
- Perfil: renombre auditado y privado. Fotos: intención antes de Storage y
  confirmación posterior; un fallo no inventa éxito. `photo-access` conserva JWT/
  permisos actuales; personas en papelera no admiten edición ordinaria de foto.
- Caja: cuatro sumas REST con entero int64 estricto bajo el mismo `readTime`,
  disparadas por escucha de un movimiento reciente. Sin convertir dinero a double.
  Última confirmación privada por UID/grupo/mes en almacenamiento temporal local,
  purgada al salir; no es respaldo y Android puede desalojarla. Fecha visible.
- Cuotas de dashboard: streams compartidos de ingresos y devoluciones, sincronizados
  mediante SDK; periodos y asignaciones siguen compartidos por grupo. Informes y
  búsquedas sobre todo el histórico se abren explícitamente, no para caja inicial.
- El lector de recordatorios excluye papelera; conserva personas inactivas con
  periodos históricos. El worker comprueba transaccionalmente la raíz antes de escribir.

## Publicación y estado remoto final

- Rules activas: `projects/boteparroquial/rulesets/bdfcf7c5-7f67-4fba-b3f9-5b3e26cf6757`.
  Hash remoto/local coincidente:
  `35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`.
  Publicadas y verificadas tras el mantenimiento. No quedan Rules de bloqueo temporal.
- Dos índices nuevos de movimientos para sumas por estado/tipo/importe y fecha.
  Ocho agregados reales de los DEMO coinciden con el historial en la misma instantánea.
- Supabase fotos `ietnizafvtovelyuxbvk`: `photo-access` v4 y `lifecycle-cleanup` v1 ACTIVE.
- Supabase avisos `qngrmxfjckrrfiyioyzl`: `notification-worker` v5 ACTIVE;
  cron `*/15 * * * *` activo de nuevo. Sin claves nuevas ni ampliación IAM.
- Los tres endpoints rechazan solicitudes sin credenciales con HTTP 401.
- Worker autenticado: HTTP 200, dos grupos procesados, cero fallos. Bandejas DEMO
  vacías; no se envían sucesos históricos ni se han registrado dispositivos.
- Reinicio verificado: 63 documentos y 3 fotos anteriores eliminados; 1.254
  documentos DEMO creados y releídos. Dos estados del worker se añadieron después.
  Cuentas Auth y configuración intactas. Fotos actuales: cero, iniciales por defecto.
- [Inventario y cifras DEMO](DEMO_DATOS_2026-10-20.md).
- [Copias y recuperación](RECUPERACION_DATOS_2026-10-20.md).

## Comprobaciones realizadas

- Siete pruebas Dart dirigidas: PDF/XLSX/CSV y permisos (3), coordinación de baja
  y reanudación (2), precisión int64 y dashboard sin lectura completa (2).
- Reglas en emulador: papelera/traza (3), devoluciones con cuatro meses y rechazo
  de cambios parciales (4), bloqueo/borrado/baja (3), fotos (1), perfil (5), vínculo
  recíproco/regresión (1) y agregados con aislamiento/revocación (1).
  Se corrigió el caso antiguo de lectura de membresía propia, que ya era permitida;
  la comprobación privada se hace con una membresía ajena. No se abrió ese permiso.
- Quince casos Deno afectados: fotos (6), auditoría de foto (2), limpieza (3),
  transacción del worker (2), lector de recordatorios/papelera (2).
- Dos pruebas del lector de respaldo y validación offline de ambas copias.
  No se ejecutó restauración destructiva sobre la nube.
- Validador DEMO usa `QuotaReportRepository`/`RefundPlan` reales; no una fórmula
  de prueba que sustituya sus reglas. Relectura remota completa del plan sembrado.
- `flutter analyze`: sin incidencias; `flutter build apk --debug`: compilación correcta.
  APK: `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256
  `030d8d285e701adc68b77933d22b96ca64ed53d451aa0a0f1e17a6b3c9547a73`.
- No se ejecutó una suite completa ni se instaló/arrancó la app en móviles.

## Límites y pendientes reales

- El usuario ejecutará la [guía](GUIA_PRUEBAS_MOVILES.md) en dos/tres Android:
  sesiones reales, varios roles, concurrencia, fotos, archivos, operaciones
  destructivas y push recibido. Las pruebas antiguas en A059P no validan estos cambios.
- iOS: Mac/Xcode, firma, APNs/capabilities y asociación de dominio con Team ID real.
  No se inventa configuración Apple ni se acredita compatibilidad física con un APK.
- Publicación de tienda y firma release no forman una prueba debug. No se han hecho.
- Volumen extremo: cuotas siguen leyendo ingresos/devoluciones/asignaciones/periodos;
  los informes/exportaciones explícitos consultan historial. Agregados derivados,
  paginación económica de servidor, generación masiva de ficheros y ampliar devoluciones
  más allá de un origen/cuatro meses requieren un bloque posterior acordado.
- Los gráficos adicionales de la especificación son ejemplos futuros; no se ha
  introducido una nueva pantalla analítica por cada ejemplo. App Check/Crashlytics
  figuran como servicios futuros, no como configuración ya aplicada.
- Purga de personas vencidas explícita, no cron nuevo. El borrado de grupo recorre
  las colecciones del esquema: si se añaden otras, ampliar su registro de limpieza.
- La baja conserva un marcador mínimo si Auth resulta incierto; no borrar ese
  testigo ni equipararlo a historial económico borrado. El flujo oficial retira
  membresías antes de sellar; Firebase SDK siempre permite al propio usuario
  solicitar la eliminación de su identidad con autenticación reciente.
- Respaldo semanal/visor aplazados expresamente. No activar facturación ni servicios
  nuevos para cerrar estos pendientes sin consultarlo.
