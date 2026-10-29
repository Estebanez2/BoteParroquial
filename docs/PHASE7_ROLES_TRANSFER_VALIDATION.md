# Roles y transferencia de propiedad — 2026-10-18

Continuación de FULL_PRODUCT_SPEC (9, 10 y 44). No declara terminado el producto
completo ni supera las comprobaciones físicas del MVP que siguen aplazadas.

## Implementado

- Miembros permite hacer administrador a un miembro activo con persona activa
  vinculada recíprocamente, y pasar un admin a miembro con confirmación.
  Owner y admin autorizado pueden hacerlo; nunca degradar al propietario.
- Solo owner ve «Transferir la propiedad». Pantalla propia con candidatos válidos,
  nombre exacto del grupo y nueva verificación de la misma cuenta Google.
- El usuario elige que el propietario anterior pase a member. Ambas cuentas
  conservan sus personas, antigüedad, fotos e historial financiero.
- Transacción de ambas membresías, metadatos del grupo y evento administrativo;
  cambios de rol tienen su propio evento atómico. Control de versiones y permisos
  actuales, incluyendo comprobación después de volver de Google.
- Firebase reautentica al usuario existente; elegir otra cuenta, cancelar o cambiar
  sesión interrumpe el envío. Rules exige proveedor google.com y auth_time de hasta
  cinco minutos, no futuro. La confirmación escrita se exige en UI; Rules compara
  el nombre vigente en auditoría, sin poder acreditar escritura humana del texto.
- Auditoría presenta «Rol cambiado» y «Propiedad transferida» con antes/después.
  createdBy sigue siendo el creador histórico; owner actual procede de members.

UI → providers → MemberRoleRepository → MemberRoleService /
FirestoreMemberRoleService → Firebase. Reautenticación por AuthRepository/Service;
ningún acceso Firebase desde pantallas ni reglas financieras en componentes.
Sin dependencias nuevas, Functions, notificaciones o cambios en Supabase.

## Comprobaciones realizadas

- dart format de los archivos Dart afectados. flutter analyze: sin incidencias.
- flutter test test/member_roles_test.dart: dos casos dirigidos superados.
  Dominio comprueba grupo/vínculo/actividad/confirmación antes de escribir; flujo
  simulado a 360 px, texto 160 % y movimiento reducido comprueba formulario,
  cancelación Google, cambio de sesión durante espera y transferencia correcta.
  SDK Google real sustituido por fake: esto no valida su diálogo nativo.
- Emulador Firestore: catorce casos distintos comprobados satisfactoriamente,
  tres nuevos de roles/transferencia y once de regresión relacionada (tres de
  creación/identidad de grupos, tres de vínculos y cinco de invitaciones/accesos).
  Rechaza autopromoción, cambios al owner, inactivos/sin vínculo, auditoría falsa,
  transferencia incompleta, cuenta sin permisos, Google caducado/futuro u otro
  proveedor, alteración de campos históricos y segundo owner añadido al commit.
  Dos transferencias simultáneas dejan un único propietario.
- Una primera ejecución detectó que ampliar las ramas superaba el límite de
  evaluación al inactivar un admin. Se corrigió seleccionando la rama por acción
  de auditoría y se repitieron los flujos afectados; once casos pasaron. Después
  de exigir proveedor Google se repitieron solo los tres casos nuevos: superados.
  Los intentos maliciosos rechazados pueden agotar la evaluación; no se confunde
  ese rechazo con demostrar que una escritura válida sea aceptada.
- Primer intento de prueba visual necesitó desplazarse hasta el selector en el
  dispositivo simulado; corregido el test y dos casos superados. Sin suite completa.
- flutter build apk --debug: compilado (assembleDebug 22,2 s). Artefacto:
  build/app/outputs/flutter-apk/app-debug.apk. Sin instalación ni arranque.

Logs locales ignorados por Git: .dart_tool/roles-flutter-tests.log,
roles-rules.log, roles-rules-final.log, roles-google-rules.log,
roles-analyze-final.log y roles-build.log.

## Publicación y respaldo

Publicación expresamente autorizada en la continuación del producto. Antes se
guardó la fuente remota activa de vínculos, verificada, en carpeta externa nueva:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-18T10-19-06-127Z
```

No sobrescribe la copia de Phase 6. Ambas contienen fuente, manifest y restauración.
Ver FIRESTORE_RULES_BACKUP.md. Restaurar Git no revierte Rules; restaurar Rules no
revierte documentos ni fotos. Revisar compatibilidad antes de volver atrás.

firebase.cmd deploy --only firestore:rules --project boteparroquial --non-interactive
completado, con compilación correcta. Conserva avisos de tipos de ternarios
opcionales del contrato anterior; no son errores de compilación.
tools/verify_firestore_rules.cjs compara release/fuente remota con archivo local:

- Proyecto boteparroquial, base (default).
- Ruleset: projects/boteparroquial/rulesets/b71e918a-cec6-4593-9560-2e88387e755d.
- Publicación: 2026-10-18T10:19:39.169901Z.
- SHA-256: cf818683961a26ef5416d257e7b1e620ad03d0aac6e72a3d1faf876b5b647019.
- matchesLocal=true. Logs roles-rules-backup.log, roles-rules-deploy.log y
  roles-rules-verified.log en .dart_tool/.

No se han creado, editado ni borrado documentos remotos. No se han transferido
grupos a UID ficticios ni cambiado roles de cuentas reales. Las escrituras de
estas pruebas se limitan al emulador; respaldo/publicación no tocan los datos.

## Pendientes y siguiente bloque

El usuario ejecutará la app. Reautenticación nativa y cambios de roles/propiedad
con otras cuentas reales siguen sin validar. Segunda cuenta/dos móviles/iOS siguen
aplazados: no se han reanudado pruebas manuales ni se afirman superadas.

Phase 7 aún requiere enlaces con dominio real y revisión física. La especificación
completa mantiene cuotas e historial de reglas, periodos de participación,
allocations, deuda/crédito, devoluciones con asignaciones elegidas, notificaciones,
comparativas/agregados escalables, auditoría general/papelera/eliminación segura
y PDF/Excel/exportaciones grandes. Siguiente bloque funcional principal: Phase 8,
concretando las decisiones de cuotas que aún no estén acordadas antes de implementarlas.

Referencias técnicas consultadas: [reautenticación Flutter de Firebase](https://firebase.google.com/docs/auth/flutter/manage-users#re-authenticate_a_user)
y [Timestamp de Security Rules](https://firebase.google.com/docs/reference/rules/rules.Timestamp#tomillis).
