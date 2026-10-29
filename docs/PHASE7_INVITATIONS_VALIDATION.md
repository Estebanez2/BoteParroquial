# Phase 7 — Invitaciones y accesos, 2026-10-17

Continuación autorizada del producto completo. Entrega parcial; no cierra Phase 7
ni las pruebas físicas pendientes del MVP. El usuario ejecutará la aplicación.

La readmisión se incorpora después de este bloque al recibir la respuesta del
usuario: aprobación obligatoria. Estado actual y publicación posterior en
[PHASE7_READMISSION_VALIDATION.md](PHASE7_READMISSION_VALIDATION.md).
Vinculación general y publicación posterior del 2026-10-18:
[PHASE7_LINKS_VALIDATION.md](PHASE7_LINKS_VALIDATION.md).

## Disponible

| Entrada | Comportamiento |
| --- | --- |
| Inicio → Entrar con código | Vista previa mínima del grupo autenticada; después, entrada o solicitud explícita |
| Miembros → Invitaciones y solicitudes | Los miembros activos pueden copiar/compartir el código habilitado mediante el menú nativo |
| Configurar invitación | Owner/admin autorizado activa/desactiva y elige aprobación o entrada automática para cuentas nuevas |
| Regenerar | Confirmación; invalida el código anterior, conserva miembros y solicitudes recibidas |
| Solicitudes | Gestión autorizada acepta/rechaza; aprobación crea member sin persona vinculada, en una transacción |
| Miembros → Retirar acceso | Gestión autorizada inactiva una membresía no owner; conserva persona e historial |
| Miembros → Salir del grupo | Miembro/admin sale con confirmación y vuelve a inicio; no puede hacerlo el owner |
| Historial administrativo | Antes/después de identidad, invitaciones, solicitudes y bajas; últimos 100, sin borrar los anteriores |

No se habilitan invitaciones automáticamente al crear grupos. Al configurar se
elige su estado y aprobación; el formulario inicial permanece desactivado y
propone aprobación. El código tiene formato groupId.secret; secret son 24 bytes
aleatorios seguros codificados como 32 caracteres base64url. No se inventa un
dominio ni se implementan enlaces/deep links en esta entrega.

Las nuevas cuentas nunca reciben admin/owner ni vinculación automática. Las bajas
dejan status=inactive y role=member; antes/después conserva el rol anterior en
auditoría. Personas, movimientos e imágenes no se borran ni se modifican por ello.
Owner protegido; transferencia de propiedad todavía sin implementar.

En la entrega inicial la readmisión permaneció cerrada esperando respuesta, sin
elegir por silencio. Después el usuario elige solicitud con aprobación obligatoria:
Service y Rules se amplían según D069, conservando membresía/vínculo/historial.
El informe de readmisión enlazado arriba registra esa actualización y su evidencia.

## Arquitectura y seguridad

Pantallas → providers de invitaciones → GroupInvitationRepository →
GroupInvitationService / FirestoreGroupInvitationService → Firestore.
Copiar/compartir texto pasa por FileSharingService / NativeFileSharingService.
Modelos de código, ajustes, vista previa y solicitud sin dependencias Flutter/SDK.
Widgets reutilizan App*, tokens, animaciones respetuosas con movimiento reducido
y estados de carga/error. No acceden a Firestore directamente.

Preview con Source.server; escrituras mediante transacciones online. Controles de
versión para configurar/decidir/retirar acceso; doble envío bloqueado en providers.
La consulta de entrada por UID evita duplicar una solicitud pendiente. Las respuestas
de vista previa/envío de otra sesión se descartan. Miembros con timestamps locales
pendientes no se interpretan como documentos confirmados.

Las Rules vuelven a validar código activo, pertenencia/rol, campos exactos,
horas de servidor, transiciones y auditoría atómica. No se confía en ocultar botones.
Get de la membresía y solicitud propias permite que no existan; no abre datos ajenos.
La preview contiene solo nombre, moneda y tipo de aprobación; no lista grupos,
perfiles, miembros, personas, imágenes ni dinero. Requiere autenticación y conocer
el código activo. No es lectura pública ni un secreto que deba publicarse en Git.
Cada código compartido autoriza solicitudes/entradas según el ajuste: tratarlo
como invitación y regenerarlo si se comparte con personas no deseadas.

Solicitudes ya recibidas siguen revisables al regenerar/desactivar. Rechazar no
equivale a banear: una cuenta sin membresía puede solicitar otra vez con código
válido. No hay notificaciones, caducidad automática, rate limiting específico ni
paginación de solicitudes implementados; reevaluar antes de abrir uso público.
Contrato exacto: [FIREBASE_SCHEMA.md](../FIREBASE_SCHEMA.md).

## Publicaciones remotas verificadas

Después de la copia externa, el usuario autoriza expresamente publicar las Rules.
Esto resuelve el rechazo automático registrado en la entrega anterior.

1. Publicación de grupos/perfil anterior a este bloque: ruleset
   22c1005a-6762-4ad2-83c4-5972a69b3c1a, 2026-10-17T10:03:30.662564Z.
   SHA-256 46dcfc359e90e9cc1d5895401d802860c31f8bfd171bf2e186f08128edd191f1.
2. Publicación del bloque inicial con invitaciones/bajas: ruleset
   c4d4cdd5-23d6-4a9e-8cc3-30cbf1370d3b, 2026-10-17T10:22:46.741797Z.
   SHA-256 24427857da7be5acc28e60811953ab3248c063058683c10aa92c76eee6aaa6f9.

Proyecto boteparroquial, base (default). Comando firebase.cmd deploy --only
firestore:rules --project boteparroquial --non-interactive, compilación y release
correctos. tools/verify_firestore_rules.cjs lee la release y su fuente: hash remoto
igual al local, matchesLocal=true. No cambia índices, configuración Google ni
Supabase. Logs en .dart_tool/phase7-rules-deploy.log y phase7-rules-verified.log.

La copia externa de Phase 6 permanece intacta:
[FIRESTORE_RULES_BACKUP.md](FIRESTORE_RULES_BACKUP.md). No se ha restaurado nada.
Descartar Git no revierte Rules ni documentos remotos. Restaurar esas Rules deja
de permitir funciones nuevas y no borra los datos creados después.

## Comprobaciones necesarias realizadas

- flutter analyze --no-pub: sin incidencias; formato Dart aplicado.
- Tres casos Flutter dirigidos en test/group_invitations_test.dart: contrato de
  códigos/aislamiento/owner/compartición; bloqueo de doble envío y respuesta de
  otra sesión; flujo visual configurar/copiar/aprobar/retirar acceso/solicitar.
- Flujo a 360 px, texto al 160 % y movimiento reducido, sin excepciones. Se
  corrige la selección de un control tapado por el snackbar en el test y se
  repite solo ese caso. SDK/servicios simulados; no acredita compartir nativo real.
- Once casos distintos de Rules en emulador: cuatro nuevos de invitaciones y
  siete regresiones afectadas (tres de grupos/auditoría y cuatro de dinero).
  Incluyen código anterior/desactivado, privacidad, aprobación, atomicidad,
  autopromoción, owner protegido, integridad económica y concurrencia.
- Tras cerrar readmisiones se repiten solo los cuatro casos nuevos. Al añadir
  una aserción de renombrado con preview existente se repite solo ese caso; pasa.
  El primer filtro con comillas de Windows no seleccionó casos y no se cuenta.
- flutter build apk --debug --no-pub -t lib/main.dart: correcto; APK actualizado
  en build/app/outputs/flutter-apk/app-debug.apk. Advertencia ya conocida sobre
  compatibilidad futura KGP en plugins Firebase; no impide esta compilación.
- Sin suite Flutter completa, instalación ni ejecución en dispositivo. No se
  reanudan segunda cuenta real, dos móviles, pruebas offline o iOS aplazadas.

## Datos DEMO creados y verificados

tools/seed_phase7_invitations.cjs --apply --verify crea únicamente documentos
nuevos en un commit con precondición exists=false. Repetir --apply falla si ya
existen; --verify permite comprobarlos sin escribir.

| Elemento | Identificador / cantidad |
| --- | --- |
| Grupo | demo7-invitations-20261017; nombre «[Prueba] Invitaciones DEMO» |
| Propietario | La misma cuenta owner actual de Prueba1; no se modifica aquel grupo |
| Miembros | 2: owner y demo7-member-lucia, ficticio |
| Personas | 2: owner y demo7-person-lucia |
| Movimiento | demo7-income: ingreso activo DEMO de 2050 céntimos para Lucía |
| Solicitudes | demo7-pending-ana y demo7-pending-luis, ambas pending y ficticias |
| Ajustes/invitación | 1 configuración activa con aprobación y 1 preview |
| Eventos | 4: creación, configuración y dos solicitudes |
| Total | 14 documentos creados; 0 sobrescritos; lectura posterior confirma cantidades |

Los UID ficticios no son usuarios de Firebase Auth. Su aprobación permite
inspeccionar la UI de miembros, pero no demuestra login ni permisos de otra
cuenta real. Los datos se crean con CLI privilegiada, que omite Rules; los
permisos cliente se comprueban por separado en emulador. No se inventa esa
evidencia física. No se borra ni reinicia la base. Log: .dart_tool/phase7-demo-seed.log.

## Pendientes siguientes

Gestión general
de roles y transferencia segura; después cuotas/periodos/allocations según
roadmap. Enlaces requieren acordar un dominio real. Auditoría completa,
notificaciones, informes de cuotas/comparaciones y PDF/Excel no implementados.
La consulta completa del historial del MVP sigue pendiente de sustituirse por
consultas/agregados para volumen grande. Phase 6 mantiene su validación física.
La vinculación única ya se añade en la entrega posterior del 2026-10-18.

Cuando el usuario ejecute la app puede abrir el grupo DEMO, aceptar/rechazar una
solicitud, retirar el acceso ficticio y comprobar que Lucía y sus 20,50 € siguen
en Personas/Movimientos. Estos pasos están propuestos, aún no realizados en móvil.
