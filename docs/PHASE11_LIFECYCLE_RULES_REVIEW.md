# Revisión de permisos candidatos — 2026-10-20

Publicadas y verificadas. Revisión previa conservada como contrato del cambio;
hash final y evidencia en [entrega](FULL_PRODUCT_COMPLETION_2026-10-20.md).
Autorización funcional: D106–D108 y petición expresa de terminar el producto.

## Cambios concretos

- Papelera y purga de personas sin historial/vínculo. Garantía solo para altas
  nuevas protegidas; primer movimiento deja un testigo permanente en la persona.
  Restaurar antes de diez días; purgar después, con hora de servidor, intención
  confirmada, limpieza de foto y auditoría. Las personas antiguas se inactivan.
- Eliminación irreversible de grupo completo: solo owner con Google de los últimos
  cinco minutos y nombre exacto. Bloquear primero; después de tres minutos permitir
  al mismo actor leer/borrar descendientes, incluidos metadatos privados del worker.
  La raíz se elimina conjuntamente con finalizar la tarea privada de esa cuenta.
  Esta es una excepción expresa al borrado financiero: no habilita borrar un
  movimiento individual de un grupo activo. Un cliente malicioso propietario ya
  autorizado para destruir el grupo podría dejar residuos; la herramienta oficial
  drena el registro de colecciones del esquema antes de borrar la raíz.
- Baja propia: el flujo exige transferir/borrar grupos propios, retira membresías,
  congela nuevas entradas y consulta de nuevo antes de sellar. Limpia fotos,
  dispositivos y perfil antes de Firebase Auth. La identidad se borra con el SDK
  de la propia cuenta; no se incorpora administración Auth de otras personas.
  El marcador privado evita recrear perfil/dispositivos si Auth queda incierto.
- Auditoría obligatoria de personas, movimientos ordinarios y renombre propio.
  Fotos tienen intención y confirmación separadas; no hay transacción distribuida
  entre Storage y Firestore. Un gestor autorizado puede emitir eventos de fotos de
  su ámbito; esos eventos no acreditan movimientos, roles ni integridad económica.
  Los eventos de cuenta son privados; miembros pueden consultar su evento propio
  de foto de grupo, pero no listar el historial administrativo.

## Aislamiento

`lifecycle-cleanup` se despliega solo al proyecto de fotos. Autoriza con JWT del
usuario y Rules actuales; su clave interna Supabase se usa solo para Storage.
No recibe rutas, buckets, roles, UID de actor o credenciales de servidor desde
Flutter. No se crea/traslada ninguna clave Firebase ni se amplía IAM.

Worker de avisos: cada escritura lee el grupo dentro de una transacción. Un
borrado que bloquea la raíz invalida escrituras de un cron con listado antiguo.
Se mantienen cuotas, devoluciones y permisos de movimientos; no borrar historia
por operaciones ordinarias. Las nuevas consultas de caja son exclusivamente de lectura.

## Compatibilidad y respaldo

El APK anterior carece de los nuevos eventos obligatorios: para volver a esa
versión hay que restaurar sus Rules junto con el APK. Un cambio de Git no revierte
configuración remota. Copia de las Rules activas verificada en:

`C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-10-20T15-50-33-427Z`

SHA anterior: `c9e4cb547e11c5053f8814eea7ca3622a39eef6e45e7af1b02608532516d3c55`.
ZIP de trabajo candidato y APK anterior se guardarán allí antes de publicar.
La copia puntual de documentos y fotos se registra por separado; no es semanal.
