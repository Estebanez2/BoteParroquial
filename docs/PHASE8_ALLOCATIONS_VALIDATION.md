# Phase 8 — Asignaciones y pagos de cuotas

Entrega del 2026-10-19. Implementada y con Rules publicadas; validación física
pendiente. El usuario ejecuta la app. No cierra Phase 8 ni los pendientes del MVP.

## Qué se ha hecho

- Pantalla de reparto por ingreso, accesible desde el historial y la ficha de persona.
  Permite asignar a varios meses, ajustar un total mensual y liberar con 0,
  conservando registros e historia. No modifica el importe ni el saldo del bote.
- Propuesta por antigüedad: meses anteriores pendientes, actual y hasta doce meses
  futuros. Usa solo dinero libre del ingreso y no sobrepasa la cuota pendiente
  consultada. Se revisa y confirma cada mes por separado; recalcula al guardar.
  El sobrante queda sin asignar y el reparto manual no está limitado a doce meses.
- Ficha con esperado acumulado, asignado hasta el actual, diferencia, pendientes
  por mes, parciales, pagados, sobrepagos, adelantos, crédito futuro y sin asignar.
  Un sobrepago no compensa otros meses automáticamente; una diferencia global 0
  puede coexistir con meses pendientes. Ingresos históricos no se asignan solos.
- Al anular/corregir un ingreso, su reparto permanece consultable pero deja de
  pagar cuotas. El sustituto comienza sin reparto y la corrección lo advierte.
- Ajustes y contador del ingreso con auditoría inmutable en una transacción online.
  Identidad del actor y versión comprobadas. La suma asignada nunca supera el ingreso,
  incluso entre administradores que asignan a meses distintos simultáneamente.
- La confirmación de actualización también observa cuotas, periodos y asignaciones.
  Conserva el aviso diferido para evitar flashes iniciales; no habilita escrituras
  offline. La transacción falla sin conexión y exige comprobar/reintentar.

Decisiones expresas del usuario D079–D081: revisar el reparto del sustituto, doce
meses futuros de propuesta y permitir exceso manual advertido. D077/D078 conservan
las reglas de cuotas y participación. D064 sigue pendiente en devoluciones.

## Cálculo y límites

UI → providers → AllocationRepository / QuotaSettlementRepository → AllocationService
→ FirestoreAllocationService. Modelos puros, sin SDK; widgets solo presentan y
confirman. El resumen se basa en asignaciones expresas e ingresos active. Falta de
periodos o de precio mantiene deuda/diferencia desconocidas; no se publica cero.
Un precio futuro puede cambiar según D077: el pago se conserva y se recalcula su
cumplimiento con la regla vigente. Un mes fuera de participación puede conservar
dinero asignado tras una baja; se muestra no computable y puede liberarse.

Cada operación cambia un solo ingreso/mes. El total introducido sustituye el de
ese ingreso para ese mes. Antes de enviar se revisa el exceso respecto de la cuota
conocida; el límite duro de servidor es el importe del ingreso, no la cuota mensual.
La propuesta es una fotografía revisable, no una reserva de cuotas frente a otros
gestores. Las Rules no fijan un precio dentro del registro de pago.

Ante respuesta incierta, la pantalla conserva la intención y el ID para comprobar
o reintentar el mismo envío. El Service reconoce el evento ya guardado. Reabrir
consulta el estado y la asignación es absoluta/versionada: no suma otra vez ni crea
un ingreso nuevo. No se añade una cola de envíos automáticos. Esto es independiente
del diario persistente que ya protege la creación/corrección de movimientos.

Persistencia en FIREBASE_SCHEMA.md: allocations/{movementId}_{monthOrdinal},
allocationBalances/{movementId} y auditEvents. El contador solo protege capacidad
del ingreso; nunca es fuente del saldo del grupo. No se borra historia.

Se mantiene la estrategia existente de leer los datos completos del grupo/persona;
no se han implementado agregados para gran volumen. No hay índices compuestos nuevos,
Cloud Functions ni cambios de Firebase Auth o Supabase.

## Comprobaciones realizadas

- Siete casos Flutter dirigidos, todos superados: cuatro de dominio financiero,
  un flujo nuevo de reparto y dos regresiones afectadas de cuotas/ficha/grupos.
  Cubren propuesta y horizonte, pagos parciales, exceso, crédito, anulación/corrección,
  datos incompletos, cuota 0, límites y ámbito; el flujo verifica que no se escribe
  antes de confirmar y que se advierte el exceso. Pantalla de 360 px, texto 160 %,
  movimiento reducido y comprobación efectiva de ambos temas.
- Ocho casos de Rules, todos superados: cuatro nuevos de asignaciones y cuatro
  existentes de movimientos. Permisos owner/admin/member/ajeno, enteros/no negativos,
  límite por ingreso, contador falseado, omitir auditoría/contador, etapa/persona/tipo
  incorrectos, concurrencia, dos asignaciones compartiendo contador, prohibición de
  borrado y edición de auditoría, anulación terminal y liberación tras cierre de etapa.
  Solo emulador con proyectos demo; no usan cuentas Google reales ni base remota.
- flutter analyze --no-pub: sin incidencias.
- flutter build apk --debug --no-pub: APK generado en
  build/app/outputs/flutter-apk/app-debug.apk. Aviso existente de plugins pendientes
  de migración a Kotlin integrado; no impide compilar.
- Emulador de esta tarea cerrado; no se ejecutó la suite completa.

Logs ignorados: .dart_tool/allocations-final-tests.log, allocations-rules.log,
allocations-analyze-final.log, allocations-build.log y allocations-final-checks.log.
No se instala ni arranca la app. No se reanudan segunda cuenta, dos móviles,
Google físico o iOS aplazados. Compilar no demuestra conexión real ni flujo móvil.

## Publicación y copia anterior

Rules publicadas con la autorización vigente, solo firestore:rules. Verificación
remota/local mediante tools/verify_firestore_rules.cjs:

- Proyecto boteparroquial, base (default).
- Ruleset projects/boteparroquial/rulesets/19c7a8f8-7ff2-4b94-b7dc-4264df8cc585.
- Actualización 2026-10-19T09:50:45.107352Z.
- SHA-256 b98fa4c4356da632aab553ab33d3ef92a5c69dbf70c9d647eb136a11a16886c8.
- matchesLocal=true. Compilación y publicación completadas.

Copia previa descargada y verificada fuera de Git, sin sobrescribir las anteriores:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T09-49-21-773Z
```

Ruleset anterior b7d039b7-06c4-4e20-a947-557342332195, 48673 bytes, SHA-256
e268187755291c0c5fa8bb4d78325f36b02459e0e1fd6ae8b7d1989bfbf48f4a.
Contiene fuente, manifest y RESTORE.md propios. Una copia de Rules no respalda
documentos; descartar cambios en Git no revierte el despliegue.
Logs: allocations-rules-backup.log, allocations-rules-deploy.log y
allocations-rules-verified.log en .dart_tool. No se ha restaurado ninguna copia.

Cero documentos remotos creados, modificados o borrados. No hay nuevos datos DEMO,
migraciones ni reparto de ingresos de Prueba1. Solo despliegue de permisos.

## Qué falta y cómo revisarlo

Estado histórico de esta entrega, sustituido posteriormente por
PHASE8_REFUNDS_VALIDATION.md: se implementan devoluciones y primer mes opcional.
Al cerrar el bloque de asignaciones quedaban pendientes los siguientes puntos.

Siguiente bloque de Phase 8: devolución asociada a una retirada con selección de
asignaciones revertidas, y sus efectos al anular/corregir esa devolución (D064).
Registrar una retirada ordinaria ahora no modifica las cuotas. También falta el
primer mes opcional durante el alta: hoy se elige después desde la ficha.
No se han implementado aplicación de toda la propuesta en un solo envío, cambios
retroactivos de etapas ni altas futuras programadas.

El usuario puede ejecutar la app y revisar: configurar cuota del grupo, elegir
primer mes de persona si falta, abrir un ingreso → Repartir por meses, escoger
propuesta o mes/cantidad manual, confirmar y consultar ficha. Revisar también
anulación/corrección y conservación del reparto original. Son comprobaciones
pendientes, no evidencias ya obtenidas en dispositivo.

Otras fases siguen según ROADMAP: dominio de invitaciones, notificaciones,
estadísticas/agregados, auditoría general/recuperación, eliminación segura y
exportaciones ampliadas. No se declaran terminadas por esta entrega.
