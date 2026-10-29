# Revisión concreta — preferencias económicas e informativas

2026-10-20. El usuario solicita continuar notificaciones y acepta separar estas
dos preferencias push por grupo, manteniendo la bandeja. **Publicado y verificado**:
ruleset `b74cba9c-8221-4c48-9226-5ab95ea716c3`, release
`2026-10-20T09:23:23.193385Z`, SHA remoto/local coincidente
`c9e4cb547e11c5053f8814eea7ca3622a39eef6e45e7af1b02608532516d3c55`.

Único cambio de `firestore.rules`: en
`groups/{groupId}/members/{uid}/notificationPreferences/{preferenceId}` se permite
leer los IDs `reminders`, `economic`, `informative`. Los dos nuevos solo admiten
`pushEnabled: bool` y `updatedAt == request.time`, por su propio UID con membresía
y grupo activos. No se habilitan list/delete, cambios de rol, preferencias de
otras cuentas ni creación de notificaciones desde el cliente.

El contrato anterior de `reminders` permanece intacto. Ninguna regla financiera,
de perfiles, miembros, invitaciones, vínculos o auditoría se modifica. Los registros
privados del worker no tienen acceso cliente: el cierre por defecto los deniega.
El worker usa IAM; estas Rules no limitan una identidad de servidor. El usuario
eligió el segundo Supabase aislado y autorizó identidad/rol y transferencia de
clave por separado. Aplicados y verificados; estado final en
[informe](PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md).

Respaldo remoto y del proyecto previo a esta ampliación:

`C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-20T08-59-14-200Z`

Ruleset activo respaldado: `df77f648-376c-4c4d-a049-91e1db95ad44`.
SHA-256 de Rules: `0348d54d0619a3f73c0f331bd57fa22f39ee2eb60201c1d06911f25f5a9dff4f`.
ZIP de 403 archivos: `f81b564d63f059730b5684a6b3192ee3142e35bd938d8188f523f41de85058be`.
APK anterior: `eb60e8cf867c89c5fe99f4484cb93220f75fa2fb2045b31b8c329bb51fdfbaf3`.
Conserva cambios sin commit y archivos nuevos; excluye cachés. No incluye documentos,
usuarios, fotos o secretos. No sobrescribe copias anteriores ni certifica restauración.

Pruebas de Rules del módulo de notificaciones: tres casos superados en emulador
demo, ampliando el de preferencias con lectura/escritura propia, denegación
cruzada, campos extra y fecha falsa en ambas categorías nuevas. No pruebas sobre
la base real. El informe de entrega registra publicación y hash verificado.
