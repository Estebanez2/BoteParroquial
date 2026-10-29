# Phase 7 — Vínculos usuario/persona, 2026-10-18

Este informe conserva la evidencia de la entrega de vínculos. Posteriormente se
implementan roles generales y transferencia, con una publicación nueva:
[PHASE7_ROLES_TRANSFER_VALIDATION.md](PHASE7_ROLES_TRANSFER_VALIDATION.md).
Esos dos bloques dejan de estar pendientes de implementación, aunque requieren
validación física; el ruleset registrado abajo corresponde a esta entrega histórica.

Continuación parcial de FULL_PRODUCT_SPEC (apartados 16, 16.1, 16.2 y 10.4).
No cierra Phase 7 ni las comprobaciones físicas pendientes del MVP.

## Implementado

| Función | Comportamiento |
| --- | --- |
| Miembros → Vincular persona | Owner/admin autorizado asigna una persona libre del mismo grupo |
| Cambiar vinculación | Cambia a otra persona o elige «Sin persona vinculada», con confirmación |
| Vista «Sin vínculo» | Lista miembros activos pendientes; al vincular desaparecen de la lista |
| Persona inactiva | Permitida con advertencia explícita; no la reactiva ni permite admin |
| Reserva histórica | Salida/expulsión no libera la persona; un gestor debe desvincular expresamente |
| Cuenta inactiva | Se permite quitar el vínculo reservado; asignar otro requiere readmisión previa |
| Propietario | Solo cambia su propio vínculo; otro admin no puede modificarlo |
| Pérdida de administración | Desvincular admin, pasarlo a persona inactiva o inactivar su persona cambia role a member en el mismo commit |
| Reactivación | Reactivar la persona conserva member; no recupera admin automáticamente |
| Auditoría | Antes/después de vínculo y rol; inactivación con rol asociado; eventos inmutables |

El usuario confirma permitir personas inactivas con advertencia y conservar
vínculos hasta desvincular expresamente (D070). Se mantiene D069: readmisión con
aprobación y vínculo conservado. Cambiar no traslada movimientos ni copia fotos,
nombres o notas. La persona sigue siendo una entidad distinta de la cuenta.
No se implementan promociones, transferencia, notificaciones ni cuotas.

## Contrato y arquitectura

members.personId ↔ persons.linkedUid dentro de cada grupo. Una membresía tiene
un solo personId y una persona solo un linkedUid. linkedUid es opcional/null al
leer datos anteriores o personas sin vínculo; nunca es un correo o rol global.
El bootstrap de nuevos grupos crea el vínculo recíproco de persons/owner cuando
se eligió persona inicial. Persona nueva normal nace sin vínculo.

MemberLinkButton/Editor → providers → MemberLinkRepository → MemberLinkService /
FirestoreMemberLinkService → Firebase. Modelos de dominio sin SDK. Providers
resuelven permisos, candidatos y pendientes; widgets componen App* y conservan
solo el borrador visual. Sin colores/tipografías nuevos en features.

Transacción online con versiones de membresía/personas; actualiza cuenta,
persona anterior/nueva y auditoría. Rules valida ambas direcciones, campos,
permisos y evento del mismo commit; no basta con esconder opciones. Una persona
ocupada no puede ser reclamada por otra cuenta aunque se fuerce la escritura.

FirestorePersonService inactiva persona y degrada admin en el mismo commit con
evento person.inactivated. No depende de una Function o de abrir la app más tarde.
Owner queda protegido. Auditoría sigue siendo parcial: no todos los cambios de
nombre/notas u otras entidades están auditados aún.
Contrato exacto: [FIREBASE_SCHEMA.md](../FIREBASE_SCHEMA.md).

## Comprobaciones realizadas

- Formato aplicado a los archivos Dart afectados; flutter analyze --no-pub final
  sin incidencias. Se quitaron imports sobrantes señalados por el análisis.
- Dos casos Flutter dirigidos en test/member_links_test.dart: validación de
  grupo/reserva/owner/cuenta inactiva y degradación; flujo visual de pendientes,
  selector que excluye personas reservadas, advertencia y confirmación de guardado.
- Flujo a 360 px, texto al 160 % y movimiento reducido, sin excepciones. SDK
  simulado; no demuestra operación real de otra cuenta o dispositivo.
- Diez casos distintos de Rules: tres nuevos de vínculos/inactivación y siete
  regresiones afectadas (tres de creación/edición de grupos y cuatro económicas).
  Los nueve iniciales pasan; se corrige el caso de reserva para que fuerce la
  escritura y pruebe el rechazo real de Rules, y se repite solo ese caso: pasa.
- Se verifican transacciones incompletas, ausencia de auditoría, propietario
  protegido, persona inactiva, no autopromoción, reserva de cuenta inactive,
  dos reclamaciones concurrentes con un solo ganador y conservación del dinero.
- Inactivación por el propio admin exige su degradación; reactivar no lo asciende.
  Personas sin campos nuevos siguen admitiendo alta/edición conforme al contrato.
- flutter build apk --debug --no-pub -t lib/main.dart correcto. APK actualizado
  en build/app/outputs/flutter-apk/app-debug.apk. No hay nuevas dependencias nativas.
- Sin suite Flutter completa, instalación, arranque, segundo Google real ni iOS.
  No se reanudan pruebas manuales aplazadas. El usuario ejecutará la app.

Logs locales: member-links-analyze.log, member-links-rules-validation.log,
member-links-concurrency-validation.log y member-links-android-build.log en
.dart_tool/. Emulador usado en la tarea cerrado tras las comprobaciones.

## Preparación de los datos existentes

tools/backfill_person_links.cjs es de solo lectura por defecto. Consulta las
membresías incluyendo inactive, detecta personas ausentes, duplicados o referencias
contradictorias y se detiene si hay conflictos. No decide vínculos por nombres.
--apply usa precondiciones updateTime y un commit atómico; --verify solo lee.
Cada petición usa opciones propias del cliente CLI para no compartir cuerpos
mutables entre consultas paralelas.

Plan confirmado: cuatro grupos, sin conflictos; faltaban únicamente dos
referencias inversas en demo7-invitations-20261017:

- persons/owner → UID del propietario actual del DEMO.
- persons/demo7-person-lucia → demo7-member-lucia, cuenta ficticia.

Aplicadas y verificadas. Se añaden linkedUid/lastAuditEventId a esas dos personas
y dos eventos person.linkBackfilled con actor system:backfill-person-links.
Las membresías repiten su personId existente como comprobación del snapshot;
no se altera su valor ni sus timestamps de negocio. Se conservan metadatos
históricos de personas, nombres, actividad, roles, movimientos y fotos. No se
escriben datos de Prueba1 ni de los otros grupos. No es seeding que sustituya
datos existentes ni una prueba bajo permisos cliente: usa CLI privilegiada.

Verificación posterior: pendingLinks=0, conflicts=0. Los logs de plan/aplicación/
verificación están en .dart_tool/person-links-*.log. La copia externa de Rules
de Phase 6 sigue intacta; restaurar Rules o descartar Git no deshace esta adición
de campos. Las Rules antiguas pueden rechazar escrituras con los campos nuevos:
revisar compatibilidad de app/esquema al volver atrás, sin borrar historia.

## Nuevos ejemplos DEMO

tools/seed_phase7_links.cjs --apply --verify crea cinco documentos nuevos con
precondición exists=false, solo en demo7-invitations-20261017:

- persons/demo7-link-active: «[Prueba] Persona libre activa».
- persons/demo7-link-inactive: «[Prueba] Persona libre inactiva».
- persons/demo7-link-admin-person: persona activa del admin ficticio.
- members/demo7-link-admin: admin ficticio, vinculado recíprocamente a esa persona.
- auditEvents/demo-links-provisioned: preparación técnica del ejemplo.

Lectura posterior confirma los cinco documentos; cero sobrescrituras y cero
cuentas Auth creadas. No se añaden movimientos. La inactiva se aprovisiona por CLI;
no implica alta inicial inactiva desde la app. El admin ficticio permite observar
su degradación desde la cuenta owner; no acredita login de un admin real.
Verificación global final: cuatro grupos, seis membresías, diez personas, tres
vínculos recíprocos y cero pendientes/conflictos. Log member-links-demo-seed.log.

## Rules publicadas y verificadas

Proyecto boteparroquial, base (default). Publicación autorizada en la continuación
del producto; compilada y completada. Lectura de release/fuente con
tools/verify_firestore_rules.cjs: matchesLocal=true.

- Ruleset: projects/boteparroquial/rulesets/b3d98bda-b2d0-4070-83f2-3765cf28cf69.
- Actualización: 2026-10-18T09:46:37.411830Z.
- SHA-256 remoto/local: 305fe15bf4e83cf66fe205ff006a8cb105ef5948c7c6d1a52171f1b6b0279e31.
- Logs: .dart_tool/member-links-rules-deploy.log y member-links-rules-verified.log.

No cambia Supabase, Authentication, índices ni configuración de Console. Los
clientes anteriores deben actualizarse para crear grupos con persona vinculada
o inactivar personas: las nuevas Rules exigen reciprocidad/auditoría. No se
interpreta un APK compilado como una prueba física ni se borra la copia anterior.

## Pendientes

Gestión general de roles y promociones, transferencia de propiedad, enlaces con
dominio real y notificaciones de usuarios pendientes. Cuotas/periodos/allocations
siguen sin implementar. Concurrencia/permisos locales no sustituyen las pruebas
aplazadas con dos cuentas/móviles. Phase 6 conserva sus pendientes físicos.

Para revisión manual futura: abrir Miembros, «Sin vínculo», asignar la persona
libre activa/inactiva a una cuenta DEMO y confirmar; comprobar historial administrativo.
Inactivar «[Prueba] Persona de admin ficticio» desde Personas y comprobar que el
admin ficticio queda como miembro. Son pasos propuestos, no ejecutados en móvil.
