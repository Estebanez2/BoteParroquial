# Cuotas temporales y periodos — 2026-10-19

Informe de la entrega anterior a asignaciones. El estado actual añade reparto de
ingresos y resumen de pagos en [PHASE8_ALLOCATIONS_VALIDATION.md](PHASE8_ALLOCATIONS_VALIDATION.md).
Los pendientes y el ruleset citados aquí describen aquel bloque, no la publicación
más reciente. Se conserva su evidencia sin declarar pruebas físicas completadas.

Integración terminada de este bloque de Phase 8, con Rules publicadas/verificadas,
análisis limpio y APK debug compilado. Sin ejecución en móvil. No significa cuotas
pagadas/deuda: allocations, pagos parciales y crédito siguen pendientes.

## Decisiones resueltas

D077: cambios desde el mes siguiente, primera cuota con inicio explícito, primer
mes de cada persona elegido expresamente y último mes inclusivo al inactivar.
También permite cuota 0 y sustituir cuotas futuras conservando sus versiones.
D078: baja y vuelta pueden compartir mes; se computa una sola vez. Permite
reactivar inmediatamente sin duplicar la obligación. No quedan esas preguntas pendientes.

## Implementado

- Dashboard → «Cuotas y etapas»: cuota vigente, configuración inicial, cambios
  futuros e historial de versiones. Confirmación expresa de importe y mes; los
  meses actuales/pasados quedan protegidos también en servidor.
- Regla vigente por mes más versiones inmutables. Primera configuración, regla,
  versión y auditoría atómicas. UI muestra últimas 20 versiones por mes; todas
  permanecen guardadas. Cero suspende la cuota hasta la siguiente regla.
- Ficha de persona: elegir primer mes, ver etapas, cerrar con último mes inclusivo
  e inactivar, o reactivar con etapa nueva. Sin inferir periodos de createdAt/isActive
  ni crear historia al leer personas anteriores.
- Cierre de periodo/persona/degradación de admin/auditoría atómicos. Reactivar no
  devuelve admin. El cambio antiguo de estado no puede saltarse un periodo configurado.
- Mes compartido entre dos etapas cuenta una vez, incluso si sus datos llegan
  desordenados. Etapa cerrada precede a abierta con mismo inicio; se rechazan
  solapamientos interiores. No se borran ni reabren periodos cerrados.
- Resumen anual hasta el mes actual de importes esperados y configuración incompleta.
  No marca deuda ni pagos. Mantiene saldo e ingresos/retiradas existentes.
- Auditoría presenta meses/importes legibles y admite ints en mapas planos.
- AppMonthField reutiliza AppDropdown/AppAdaptiveRow; UI compone App* y AppReveal,
  con temas y movimiento reducido. intl 0.20.2 pasa de transitiva a directa sin
  actualizar su versión. No hay otro SDK o servicio externo nuevo.

Arquitectura: UI → providers → QuotaRepository/ParticipationRepository → servicios
Firestore. Cálculo esperado por QuotaExpectationRepository puro desde providers;
ninguna consulta Firebase o lógica de obligaciones en widgets. Todas las rutas y
operaciones reciben groupId. Contrato exacto en FIREBASE_SCHEMA.md.

## Límites de esta entrega

Inicio/cierre de participación eligen meses hasta el actual; sin altas programadas.
Personas nuevas y owner inicial configuran su primer mes después desde la ficha;
integrarlo opcionalmente en el formulario de alta sigue pendiente. No hay prorrateo,
cuotas individuales, edición libre de periodos cerrados, allocations, deuda/crédito,
notificaciones o asignación automática de ingresos antiguos.

Transacciones online, sin reenvíos automáticos; ante resultado incierto se consulta
la historia antes de repetir. No se amplía el diario económico persistente.
Los usuarios de APK anteriores deben actualizarlo para gestionar personas con periodo.

Rules usa request.time y las seis zonas admitidas para determinar exclusivamente
el mes civil. Los offsets sirven para fronteras de mes/DST, no para convertir horas
generales. Zonas desconocidas fallan cerradas; revisar ante cambios de leyes horarias.
UI mantiene timezone/IANA. No se modifica la validación anterior de occurredAt.

## Comprobado

- dart format de los archivos afectados. flutter analyze --no-pub: sin incidencias.
- Seis casos Flutter distintos dirigidos superados: dos de cálculo base, uno de
  escritura/participación, uno visual de cuotas y primer mes a 360 px/texto 160 %/
  movimiento reducido, y dos regresiones afectadas: Personas y grupo/informes/ficha/
  auditoría. Tras D078 se repiten solo los cuatro casos de cuotas afectados.
- Diez casos distintos de Rules superados: cuatro nuevos de cuotas, periodos,
  degradación de admin y calendario; seis regresiones de vínculos e identidad/grupos.
  Rechazan cambios por member/ajenos, meses protegidos, float/negativos, omitir
  versión/auditoría/persona/periodo, solapamientos interiores, borrar/reabrir historia
  y conservar admin al inactivar. Comprueban concurrencia de reglas/periodos.
- Doce puntos de frontera de mes/año/DST en las seis zonas forman un caso de calendario,
  contrastado con Intl/IANA. Tras D078 se repiten solo los cuatro casos nuevos de Rules:
  superados, incluida reactivación en el mismo mes de la baja.
- flutter build apk --debug --no-pub final: compilado, assembleDebug 22,3 s.
  build/app/outputs/flutter-apk/app-debug.apk. Sin instalación ni arranque. Se conserva
  el aviso existente de plugins pendientes de migración a Kotlin integrado.

Logs ignorados: .dart_tool/phase8-final-tests.log, phase8-regression-tests.log,
phase8-rules.log, phase8-final-rules.log, phase8-analyze-final.log y phase8-build-final.log.
No se ejecuta la suite completa. Estas pruebas no sustituyen Google, otras cuentas,
dos móviles o iOS; sus comprobaciones físicas aplazadas permanecen pendientes.

## Publicación y respaldo

Publicación de Rules autorizada en la continuación del producto. Antes se descarga
la versión activa de roles a otra carpeta externa, sin sobrescribir copias previas:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T09-03-57-855Z
```

Fuente, manifest y restauración; 36776 bytes, hash
cf818683961a26ef5416d257e7b1e620ad03d0aac6e72a3d1faf876b5b647019.
Es copia de permisos, no de datos. Descartar Git no revierte Rules; restaurar Rules
no revierte documentos/fotos. Revisar compatibilidad de la app antes de volver atrás.

firebase.cmd deploy --only firestore:rules --project boteparroquial --non-interactive:
compilación/publicación completadas. El compilador conserva avisos de inferencia
de tipos en ternarios/null de helpers; no son errores y las rutas válidas tienen
pruebas explícitas de aceptación. tools/verify_firestore_rules.cjs confirma:

- Proyecto boteparroquial, base (default).
- Ruleset: projects/boteparroquial/rulesets/b7d039b7-06c4-4e20-a947-557342332195.
- Publicación: 2026-10-19T09:15:51.925178Z.
- SHA-256 local/remoto: e268187755291c0c5fa8bb4d78325f36b02459e0e1fd6ae8b7d1989bfbf48f4a.
- matchesLocal=true. Logs phase8-rules-backup/deploy/verified.log en .dart_tool/.

Cero documentos remotos creados, modificados o borrados. Sin migración, nuevos
DEMO, cambios en Auth Console, índices o Supabase. Cada grupo/persona conserva
sus datos hasta que un gestor configure expresamente las cuotas/periodos.

## Revisión y continuación

El usuario ejecutará la app. Entrar al grupo → Cuotas y etapas, revisar importe/
inicio antes de confirmar; en la ficha elegir primer mes y revisar importes esperados.
Comprobar cierre/reactivación y que el mes compartido no duplique. Son pasos futuros,
no pruebas físicas ya realizadas. No reanudar segunda cuenta aplazada sin petición.

Próximo bloque: allocations, pagos parciales/atrasados/adelantados, crédito y selección
de asignaciones revertidas en devoluciones (D064). Phase 8 sigue parcial; Phase 6
mantiene validación física y Phase 9 notificaciones permanece pendiente.

Referencias: [IANA Europa](https://data.iana.org/time-zones/tzdb/europe),
[IANA Norteamérica](https://data.iana.org/time-zones/tzdb/northamerica),
[IANA Sudamérica](https://data.iana.org/time-zones/tzdb/southamerica),
[Security Rules](https://firebase.google.com/docs/reference/rules/rules).
