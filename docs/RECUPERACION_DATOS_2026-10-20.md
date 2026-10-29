# Copia puntual anterior al reinicio

**No hay copia semanal ni visor programados:** el usuario los ha aplazado
expresamente (D105). Estas son copias puntuales recuperables, fuera de Git.

## Copias finales de datos y fotos

Firestore:

`C:\Users\aleja\Documents\BoteParroquial-backups\firestore-data\2026-10-20T16-10-28-462Z`

- 63 documentos, instantánea `2026-10-20T16:10:25.293483Z`.
- `firestore.json` conserva rutas, tipos REST, enteros int64 y timestamps originales.
- SHA-256 `2f1a42898ffc6734cfd53e789c29ed1818f5258afa3d8b770c3d2dd16c59e077`.
- Puede contener datos privados y registros de dispositivos: no subirla al repo,
  compartirla por chat ni asumir que sus tokens siguen siendo válidos al restaurar.

Fotos:

`C:\Users\aleja\Documents\BoteParroquial-backups\photos\2026-10-20T16-10-35-860Z`

- 3 archivos, 339.398 bytes; binarios con hash individual y catálogo de ruta/MIME.
- SHA-256 de `photos.json`:
  `fd96f05bbd5a27426cbf3a0e298447c75a8ee4da5fe0572ca958a3f4faa7fff3`.
- No incluye claves, cuentas Auth ni configuración de Supabase.

Se hicieron con cron pausado y reglas temporales de mantenimiento; antes de borrar
se compararon otra vez documentos/updateTime y catálogo/id/updated_at de fotos.
Se rechazaba el reinicio si había cambios o lease de worker activo. No se tocó Auth.
Las copias anteriores de las 14:42/15:50 UTC también se conservan sin sobrescribir.

## Validar y restaurar

Las herramientas siguientes **validan sin modificar la nube por defecto**:

```powershell
node tools/restore_firestore_data.cjs "C:\Users\aleja\Documents\BoteParroquial-backups\firestore-data\2026-10-20T16-10-28-462Z"
node tools/restore_supabase_photos.cjs "C:\Users\aleja\Documents\BoteParroquial-backups\photos\2026-10-20T16-10-35-860Z"
```

La validación offline de rutas, manifiestos, cantidades y hashes está comprobada.
**No se ha ensayado una restauración remota**: no se han vuelto a borrar los DEMO
para simularla. No confundir validación de copia con restauración verificada.

Para restaurar de verdad, solicitarlo expresamente y revisar primero los datos
nuevos que se conservarán. El procedimiento es: pausar cron, cerrar escrituras,
respaldar el estado actual, vaciar únicamente los datos autorizados, ejecutar
restauración y verificar, restaurar Rules compatibles y reactivar cron. Los scripts
exigen base/bucket vacíos, confirmación de proyecto y no sobrescriben documentos.
Firestore requiere sesión Firebase CLI; fotos, ruta absoluta de Supabase CLI:

```text
node tools/restore_firestore_data.cjs CARPETA --apply --confirm boteparroquial
node tools/restore_supabase_photos.cjs CARPETA RUTA_SUPABASE_EXE --apply --confirm ietnizafvtovelyuxbvk
```

No ejecutar esos ejemplos sobre la base actual. No restaurar registros push de
modo que reactiven avisos de una cuenta/dispositivo retirado; revisar y solicitar
consentimiento de nuevo cuando corresponda. La herramienta restaura exactamente
los documentos, no decide por el usuario esa política de recuperación.

## Copia de permisos, APK y fuentes

Versión remota anterior a esta continuación:

`C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-20T15-50-33-427Z`

- Rules anteriores: SHA-256
  `c9e4cb547e11c5053f8814eea7ca3622a39eef6e45e7af1b02608532516d3c55`.
- APK anterior copiado: SHA-256
  `60d9eed49159df735461b74c69f5b5af67224bda88bf03fae8a7105266c13251`.
- `working-tree-candidate.zip`, 487 archivos: SHA-256
  `a01b0b7d8fa966cb962a62b21ada179bdc9178a30f788bd2d28f78ecd82107cd`.
  Este ZIP contiene el código candidato de esta continuación y el APK es anterior:
  no representan el mismo build ni una instantánea exacta de fuentes anterior al turno.

Versión final activa verificada:

`C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-20T16-14-28-634Z`

SHA-256 `35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`.
Las reglas de mantenimiento ya se retiraron. Volver a un APK anterior que no genera
la nueva auditoría exige restaurar también sus Rules compatibles. Descartar archivos
en Git no cambia reglas, funciones, fotos ni documentos publicados.

La restauración de Rules tiene instrucciones en su manifiesto/carpeta y en
[FIRESTORE_RULES_BACKUP.md](FIRESTORE_RULES_BACKUP.md). Volver al comportamiento
anterior de fotos también requiere publicar el código anterior de `photo-access`:
son servicios remotos distintos, no se revierten instalando solo un APK.
