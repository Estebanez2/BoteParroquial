# Copia de las reglas publicadas — 2026-10-17

Descargadas de la publicación activa de Firebase, no del firestore.rules local
que entonces contenía cambios pendientes. Proyecto boteparroquial, base (default).
Es la instantánea anterior al despliegue autorizado del mismo día; la publicación
actual está registrada en [PHASE8_REFUNDS_VALIDATION.md](PHASE8_REFUNDS_VALIDATION.md).

## Nuevo respaldo antes de devoluciones — 2026-10-19

Por petición explícita, copia del estado de permisos actual y archivos locales:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T17-27-58-065Z
```

Reglas activas anteriores de asignaciones, ruleset
19c7a8f8-7ff2-4b94-b7dc-4264df8cc585, SHA-256
b98fa4c4356da632aab553ab33d3ef92a5c69dbf70c9d647eb136a11a16886c8.
También ZIP de 362 archivos locales incluidos cambios sin commit y APK anterior.
La copia del MVP y las intermedias se conservan. No es exportación de documentos,
Auth ni fotos. El ZIP conserva trabajo en curso y no equivale al APK previo ni
a la fuente remota; cada artefacto está identificado. Hashes, exclusiones y
restauración en PHASE8_REFUNDS_VALIDATION.md y en los manifests de la carpeta.
Reglas nuevas publicadas después con autorización expresa y hash verificado.

## Copia guardada fuera de Git

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-17T09-55-17-280Z
```

Contiene firestore.rules (fuente exacta), manifest.json (identidad y hash),
firebase.rollback.json (configuración de restauración) y RESTORE.md (instrucciones).
Descartar los cambios de este repositorio no elimina esa carpeta externa.
No contiene credenciales ni tokens. Es una copia de permisos, no de documentos,
cuentas o fotos; restaurarla no revierte los datos creados después.

## Evidencia

- Descarga: 17/10/2026, 11:55 en Europe/Madrid (09:55 UTC).
- Release: projects/boteparroquial/releases/cloud.firestore.
- Ruleset activo al hacer la copia: projects/boteparroquial/rulesets/3a47ea62-c02e-47d8-ab82-deb95b2313ad.
- Publicado el 2026-10-15; coincide con el registro de Phase 6.
- SHA-256: 757811e1be9ff9c994939df550b09a70e82a42968b1b8dfc11cb92914ff13d10.
- 9596 bytes. Archivo guardado vuelto a leer y hash comparado con la fuente remota.
- Release consultado antes/después de descargar, sin cambios entre ambas lecturas.
- Sintaxis del script comprobada con node --check. Sin pruebas Flutter ni despliegues.

## Restaurar cuando el usuario lo autorice

El comando también está en RESTORE.md fuera del repositorio, por si se descartan
estos archivos locales. Requiere Firebase CLI y sesión con permisos de publicación:

```powershell
firebase.cmd deploy --only firestore:rules --project boteparroquial --config "C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-17T09-55-17-280Z\firebase.rollback.json" --non-interactive
```

Solo publica las reglas de esta copia. No sobrescribe el firestore.rules de trabajo
ni restaura documentos/índices/fotos. Revisar la compatibilidad de la versión de la
app que se use entonces: funciones nuevas pueden perder permisos al volver atrás.
No se ha ejecutado ninguna restauración. Después se publicaron reglas nuevas
con autorización expresa; la copia anterior permanece intacta.

## Crear otra copia

Antes de asignaciones se guarda otra copia verificada el 2026-10-19:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T09-49-21-773Z
```

Ruleset b7d039b7-06c4-4e20-a947-557342332195, 48673 bytes, SHA-256
e268187755291c0c5fa8bb4d78325f36b02459e0e1fd6ae8b7d1989bfbf48f4a.
Fuente, manifest y RESTORE.md propios; ninguna copia anterior se sobrescribe.
Después se publican y verifican Rules de asignaciones; estado actual en
PHASE8_ALLOCATIONS_VALIDATION.md. Sin restaurar ni respaldar documentos.

Antes de cuotas/periodos se guarda otra copia verificada el 2026-10-19:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T09-03-57-855Z
```

Ruleset b71e918a-cec6-4593-9560-2e88387e755d, SHA-256
cf818683961a26ef5416d257e7b1e620ad03d0aac6e72a3d1faf876b5b647019, 36776 bytes.
Manifest, fuente y restauración propios; conserva las copias anteriores.

Se ha creado otra copia verificada antes de roles/transferencia (18/10/2026):

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-18T10-19-06-127Z
```

Contiene la versión de vínculos b3d98bda-b2d0-4070-83f2-3765cf28cf69, SHA-256
305fe15bf4e83cf66fe205ff006a8cb105ef5948c7c6d1a52171f1b6b0279e31, 32396 bytes.
Manifest y RESTORE.md propios; conserva intacta la copia original de Phase 6.
No se ha ejecutado ninguna restauración ni se han respaldado documentos.

```powershell
node tools/backup_firestore_rules.cjs
```

Usa la sesión Firebase CLI existente y solo lecturas remotas. Crea una carpeta
nueva fuera de Git y nunca sobrescribe una copia anterior. Puede especificarse
un destino absoluto nuevo con --output. La implementación usa los módulos de
Firebase CLI instalado; si cambia su API interna, revisarlos antes de actualizarla.

Antes de publicar dispositivos/bandeja, el usuario solicita otra copia completa
del estado disponible (2026-10-19). Carpeta nueva, sin sobrescribir las anteriores:

```text
C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-19T18-49-13-767Z
```

Reglas activas de devoluciones: ruleset 38c2c77a-c18c-4c51-a8a9-f43e9dfa5702,
SHA-256 5c776e8d4b9b965ca4fe19a9e14f3564378e5461767a69c59d628098e20c3520.
Añade ZIP de 395 archivos del proyecto actual con cambios sin commit/nuevos,
APK recién compilado, manifiestos/hashes, estado Git e instrucciones propias.
El ZIP/APK contienen ya el cliente de avisos preparado, antes de publicar sus
permisos; no son una reconstrucción del código anterior a programarlo. Fuente
remota y candidato local se conservan diferenciados. No incluye documentos,
usuarios Auth, índices u objetos de fotos; no se ha probado restaurar.
Publicación posterior, hashes y límites:
[PHASE9_NOTIFICATION_CLIENT_VALIDATION.md](PHASE9_NOTIFICATION_CLIENT_VALIDATION.md).
La copia inicial de solo reglas de las 18:33 UTC permanece también intacta.
