# Phase 8 — Devoluciones y primer mes opcional

2026-10-19. Implementado, Rules publicadas/verificadas y APK compilado. Sin
instalación ni ejecución móvil: el usuario ejecuta la app. No cierra pruebas
físicas aplazadas del MVP, segunda cuenta, dos móviles o iOS.

## Entregado

- Ingreso → Repartir por meses → Devolver parte de esta aportación. Pantalla con
  ingreso/persona, hasta cuatro meses, cantidades parciales, crédito sin asignar,
  fecha y motivo. Combina cuotas y crédito, con revisión y confirmación expresa.
- RefundRepository calcula disponibilidad/reparto; providers coordinan. UI usa
  App* y animación respetando movimiento reducido. Sin reglas económicas en widgets.
- Conserva advertencias de persona inactiva/saldo negativo, ID estable y actor
  antes de confirmar. Impide guardar desde otra sesión tras confirmar.
- Historial distingue Devolución, muestra meses/crédito y enlaza al ingreso.
  Corregir empieza vacío, mantiene origen y limita la unión de meses del original
  y sustituto a cuatro. Para otro origen/más meses, anular y registrar otra.
  Convertir en movimiento normal requiere confirmar que se restauran cuotas.
- Transacción online: movimiento(s), contador por ingreso y evento inmutable
  juntos. Anular restaura pagos/crédito; corregir restaura y aplica el sustituto.
  Conflictos de disponibilidad/versión bloquean el commit entero.
- Asignaciones conservan bruto/historia. La proyección descuenta devoluciones
  active por mes y crédito retornado. Una retirada normal no altera cuotas.
  Ajustes manuales no liberan dinero ya devuelto ni lo reutilizan como crédito.
- Ingreso con devoluciones activas no puede anularse/corregirse, también en Rules.
  Fecha de devolución desde la del ingreso hasta hoy del grupo.
- Journal v2 conserva planes del original/sustituto. Reinicio compara el reparto
  completo y recupera confirmación sin repetir dinero; mantiene lectura de v1.
- Alta de persona con primer mes opcional, desactivado por defecto. Mes confirmado
  antes de crear persona/etapa/auditoría atómicamente, con ID estable y detección
  de reintento confirmado. Omitirlo no genera periodo/deuda. Personas existentes
  y persona inicial de un grupo no reciben meses automáticamente.

D082–D086; contratos en FIREBASE_SCHEMA.md y ARCHITECTURE.md. Sin dependencias
nuevas, backend privilegiado, Cloud Functions, Scheduler o notificaciones.
Firebase mantiene login/datos y Supabase las fotos.

## Validación dirigida

La primera representación excedía el presupuesto de evaluación con cuatro meses.
Se usaron mapas de mes a céntimos y se repartieron comprobaciones entre tres
testigos obligatorios: contador meses 0/1, evento mes 2, movimiento destino/anulado
mes 3. Se mantienen identidad, actor, capacidad y deltas. Todos se exigen en el
mismo commit; no hay un testigo opcional. Referencia:
[límites de Security Rules](https://firebase.google.com/docs/firestore/security/rules-structure).

La revisión automática rechazó sustituir reglas/tests por alcance de seguridad
insuficientemente autorizado. La propuesta quedó aislada; después el usuario
autorizó expresamente otra copia del estado actual, incorporación, publicación y
validación. Rechazo resuelto; sin aprobación pendiente. Registro inicial en
PHASE8_REFUNDS_RULES_REVIEW.md.

- 14 Dart/widget aprobados: refunds_test (4), person_initial_month_test (2),
  quota_allocations_test (4), movement_recovery_test (3), refund_flow_test (1).
  Incluyen proyección de pagos/deuda/adelantos/crédito, restauración/sustituto,
  límites, fecha anterior, suelo de reparto ya devuelto, journal en disco/reinicio
  y mismo importe con otro reparto. Alta con/sin mes y confirmación.
- Flujo de interfaz confirma crear/corregir/anular y conserva navegación durante
  la actualización de fuente, a 360 px, texto 140 % y movimiento reducido.
  Alta comprobada a 360 px y texto 160 %. Son dobles locales, no red real.
- 18 casos distintos de Rules aprobados: refunds_rules (4), allocations_rules (4),
  movements_rules (4), quotas_rules (6). Regresiones contra candidato aislado;
  mantienen controles al incorporarlo. La ejecución final de refunds_rules usa
  directamente firestore.rules, sin sustituir predicados.
- Refunds prueba cuatro meses por admin al crear/corregir/anular; parciales y
  crédito; ingreso sin allocations/contador; permisos y auditoría inmutable;
  testigos omitidos; importes/persona/mes/fecha falsos y mapas manipulados;
  reparto manual posterior; bloqueo del ingreso y dos devoluciones concurrentes
  sobre el mismo dinero: solo un ganador.
- Iteraciones iniciales fallidas por presupuesto/expectativa se corrigieron;
  no son evidencia aprobada. Solo se repitieron casos afectados, sin suite completa.
- dart format de archivos afectados; flutter analyze --no-pub sin incidencias.
- flutter build apk --debug --no-pub aprobado; aviso previo del toolchain sobre
  migración Kotlin, sin fallo. APK: build/app/outputs/flutter-apk/app-debug.apk.
- Sin instalación/arranque; no se reanudan pruebas manuales aplazadas.

Logs ignorados en .dart_tool: refunds-tests.log, refund-flow.log,
refunds-rules-final.log, refunds-regression-{allocations,movements,quotas}.log,
refunds-analyze-final.log, refunds-build.log, refunds-backup.log,
refunds-rules-deploy.log y refunds-rules-verified.log.

## Respaldo anterior a publicar

No sustituye ni sobrescribe copias anteriores, incluida la del MVP:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T17-27-58-065Z
```

- Reglas descargadas de la publicación remota activa, no del archivo local.
  Ruleset anterior 19c7a8f8-7ff2-4b94-b7dc-4264df8cc585, 54209 bytes, SHA-256
  b98fa4c4356da632aab553ab33d3ef92a5c69dbf70c9d647eb136a11a16886c8.
  Fuente, manifest.json, firebase.rollback.json y RESTORE.md propios.
- workspace-before-refunds-rules.zip: 362 archivos incluidos cambios sin commit y
  nuevos; comprobado número de entradas. SHA-256
  2a11ed2566b928b6c76a5096fa05cf7d5a7d17d51df8b85cf08aa6a46cfce455.
  workspace-manifest.json, workspace-git-status.txt y WORKSPACE_RESTORE.md.
  HEAD de referencia e00938c2bf0b1abaa70733973aa0605aebecfd9b: no equivale al ZIP
  por los cambios sin commit. Sin crear commit, preparar ni descartar cambios.
- app-debug-before-refunds.apk: APK anterior, compilado a las 09:55:41 UTC,
  242765750 bytes. Hash original/copia coincidente:
  ef25983bac161a120ce38fd1b4bb622f51091ba9a6f38654a0a32db0c5a95926.

El ZIP es instantánea del trabajo local anterior a incorporar el candidato;
incluye devoluciones en curso y reglas locales distintas de las remotas. No es
código idéntico al APK anterior. Excluye Git, cachés, compilados y dependencias
instaladas; conserva manifests/configuración. Recuperar extrayendo en carpeta
nueva y revisando antes de superponer versiones. APK previo y reglas remotas
anteriores se conservan por separado.

Es copia de código/permisos/APK, no exportación de documentos Firestore, usuarios
Auth ni fotos Supabase. Publicar reglas no borra/restaura esos datos. No se ha
ejecutado restauración ni ensayado recuperación completa.

## Publicación verificada

Solo firestore:rules, proyecto boteparroquial, base (default).

- Ruleset projects/boteparroquial/rulesets/38c2c77a-c18c-4c51-a8a9-f43e9dfa5702.
- Release actualizado 2026-10-19T17:33:36.670521Z.
- SHA-256 remoto/local 5c776e8d4b9b965ca4fe19a9e14f3564378e5461767a69c59d628098e20c3520.
- Compilación/publicación correctas; verify_firestore_rules.cjs: matchesLocal=true.

Cero documentos remotos creados, modificados o borrados. Sin nuevas DEMO,
migraciones, índices o cambios en Auth Console/Supabase. Los datos ficticios son
del emulador. Verificación remota acredita publicación/coincidencia de fuente,
no una devolución desde un móvil real.

## Pendientes

Los pendientes siguientes corresponden al cierre de esta entrega. El bloque de
cumplimiento/dashboard se incorpora después en PHASE10_QUOTA_REPORTS_VALIDATION.md;
consultar ROADMAP para el estado vigente.

El usuario puede ejecutar la app: crear persona con/sin mes; abrir ingreso y
devolver una parte de un mes junto con crédito; revisar ficha, historial,
corrección/anulación y devolución solo de crédito. Es guía pendiente, no evidencia
obtenida en dispositivo.

Phase 8 tiene su núcleo dentro de los límites acordados. Queda validación física;
si se solicita, confirmar una propuesta entera o ampliar devoluciones a varios
ingresos/más meses mediante backend. Sin altas futuras programadas ni edición
retroactiva de etapas cerradas.

Del producto completo: enlaces de invitación con dominio real; notificaciones y
programación; informes de cumplimiento/comparaciones y agregados; auditoría
general, papelera y eliminación segura; PDF/Excel/exportaciones grandes.
Las pruebas físicas previas del MVP siguen según ROADMAP, sin darlas por completas.
