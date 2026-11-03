# Ingreso y cuota en el alta, acciones visibles y pruebas push

Actualización posterior: la prueba de las 18:00 no llegó; FCM marcó unregistered
en la cuenta DEMO antigua que se había elegido. El usuario identificó la cuenta
actual por Catequesis, se corrigió el destino y confirmó la recepción a las
19:20. La de 20:00 también apunta ahora a Catequesis. El apartado de programación
inferior conserva el estado inicial, no autoriza reutilizar su UID como actual.
Ver [diagnóstico y evidencia](ACTION_SPACING_AND_PUSH_2026-11-03.md).

03/11/2026. Decisiones D132–D134. El usuario elige un mes con importe editable,
borde marcado/relieve y guardado conjunto con respaldo de reglas.

## Interfaz y dinero

Formulario de ingreso/retirada compacto: sin cabecera repetida ni una tarjeta
completa alrededor de cada campo. Importe compacto, persona, fecha, descripción,
selector de tipo y acción final. La prueba de 412 × 844 con teclado cerrado llega
a «Revisar y guardar» sin desplazamiento. Se conserva scroll de seguridad con
teclado, texto ampliado, errores, correcciones o pantallas menores; no ocultar
campos para afirmar que cabe en cualquier dispositivo.

«Elegir cuota (opcional)» abre mes/año e importe. Selección explícita, sin asumir
que la fecha del ingreso sea el mes pagado. Requiere persona e importe; valida
etapa, límite del ingreso y avisa de sobrepago o cuota desconocida. El remanente
queda recibido sin asignar. Se puede quitar la elección y repartir después como
antes. Una retirada normal no altera cuotas; las devoluciones siguen su flujo
específico por ingreso/meses/crédito. Las correcciones conservan la revisión
posterior del sustituto; no copian automáticamente el reparto del original.

La confirmación muestra ingreso, cuota y remanente. UI → providers → repositorios
puros/capacidad de servicio → transacción Firestore. Ingreso, primer testigo de
historial, auditoría económica, asignación, contador y auditoría del reparto se
guardan juntos. Journal v3 conserva la intención de cuota y lee v1/v2. Resolver
comprueba ingreso y evento inmutable de reparto; el ID del evento deriva del
ingreso y de mes/importe/etapa. Reintentar mantiene ID y plan. No se transforma
un resultado desconocido en otro ingreso. Sin migración de pagos anteriores.

AppButton, AppIconButton y AppCard interactiva comparten borde de acción más
marcado y relieve suave, con tokens centrales; las tarjetas informativas
conservan su borde neutro. Botones secundarios tienen fondo de acción tenue.
Se mantienen paletas, contraste, disabled, foco y efectos B07/B08/B04/B05.

## Qué significa cada opción de avisos

| Opción | Efecto |
| --- | --- |
| Recordatorios → Recibir push | Permite avisos de cuota a las 10:00 del grupo, 7 y 1 días antes de terminar el mes, si corresponde al estado actual y acceso. |
| Recordatorios → Solo bandeja | Conserva esos avisos dentro de la app, sin pedir su entrega push para este grupo. |
| Movimientos y cambios de cuota → Activados/Desactivados | Controla push económico: movimientos asociados a tu persona y cambios de cuota. Normalmente no avisa al autor de su propia operación. La bandeja se conserva. |
| Miembros, accesos e invitaciones → Activados/Desactivados | Controla push informativo según destinatario/rol: solicitudes, entradas, aceptación, vínculo, rol, transferencia o regeneración del código. La bandeja se conserva. |
| Activar avisos en este móvil | Solicita permiso nativo si procede y registra este dispositivo para la cuenta activa. No activa preferencias que hayas apagado por grupo. |
| Comprobar registro | Verifica/actualiza el registro del móvil. No envía una prueba. |
| Retirar avisos de este móvil | Retira aquí el registro para todos los grupos de esta cuenta. No borra la bandeja ni cambia otros dispositivos. |
| Marcar como leído | Cambia el estado del aviso en tu bandeja; no modifica dinero ni permisos. |
| Abrir en el grupo | Abre la sección relacionada con comprobación de acceso. |

La bandeja muestra los últimos 50 avisos de cada grupo. Permiso del sistema,
registro del móvil y preferencias de categorías son controles diferentes.
El texto push es discreto, sin importes. Las explicaciones también se amplían
en la interfaz, no solo en esta documentación.

En este móvil se registra la cuenta activa. Logout retira primero su registro
confirmándolo con conexión; otra cuenta no debería seguir recibiendo nuevos
envíos aquí. Puede recibirlos en otros dispositivos registrados. Un aviso ya
aceptado por FCM antes del logout puede llegar tarde; no prometer retirarlo.

## Dos pruebas pedidas para hoy

Programación remota verificada en **qngrmxfjckrrfiyioyzl**, solo Notificaciones:

- 03/11/2026, **18:00 Europe/Madrid** (17:00 UTC), job 2.
- 03/11/2026, **20:00 Europe/Madrid** (19:00 UTC), job 3.

Destino: cuenta de Alejandro, UID JDQpjp5XtFTDOoVgK5Rbc9EGUHB2, grupo
demo-comunidad-20261020. Usa el registro válido más reciente de esa cuenta en
cada envío. Se encontraron siete registros; no se imprimieron tokens. No se
ha demostrado que todos correspondan a móviles activos.

«BoteParroquial · Prueba 1 de 2» / «Prueba 2 de 2», texto explícito sin importes.
Pruebas push puntuales solicitadas por el usuario, independientes de categorías:
ambos grupos tenían recordatorios apagados, y **no se han cambiado esas
preferencias**. No crean un falso recordatorio mensual ni un aviso en bandeja;
solo un registro técnico de entrega marcado test. No cambian personas ni dinero.

Función nueva notification-probe, autenticada con el secreto existente del worker;
solo POST y cuerpo {}. Destinatario, grupo y dos fechas fijados en servidor, sin
parámetros para enviar a terceros. Caduca cada ventana a los diez minutos. Relee
grupo/membresía y registro antes del envío; no entrega a un registro retirado.
Reserva duradera una vez por prueba incluso con concurrencia/rotación de token;
no reintenta un resultado FCM incierto. El SQL elimina cada job tras solicitar el
envío. El cron habitual job 1 cada quince minutos no se ha alterado. No IAM,
claves, secretos nuevos ni cambio del proyecto de fotos. Función expirada queda
inerte; su retirada se puede hacer después de revisar la entrega.

Autenticación remota: 401 sin secreto; 200 autorizado y cero intentos antes de
la hora. Cron consultado: GMT, jobs 2/3 activos y horarios UTC correctos.
Fuente SQL reproducible: supabase/notification_probe_20261103.sql. Referencia:
[programación oficial de Supabase](https://supabase.com/docs/guides/functions/schedule-functions).
**Programados no significa entregados**: recepción en móvil pendiente. Mantener
sesión de esa cuenta, Internet y permiso nativo; poner app en segundo plano o
bloquear móvil para ver el aviso del sistema. No hace falta instalar el nuevo APK
para recibir estas pruebas si el registro previo ya es válido.

## Evidencia y estado de publicación

- Flutter: dos casos nuevos (reparto/límites/etapa y journal tras respuesta
  perdida; flujo UI compacto con importe parcial) y un flujo financiero existente
  (ingreso, retirada, corrección y anulación), superados. Un caso adicional de
  recuperación previa confirma compatibilidad. Cuatro casos Flutter distintos,
  con fixtures y almacenamiento temporal aislado; no pruebas físicas.
- Reglas: cuatro casos dirigidos en emulador, superados, incluida atomicidad y
  denegaciones. Sin operaciones económicas de prueba en la base real.
- Deno: un caso de fechas, último registro, concurrencia, resultado incierto,
  registro retirado y acceso revocado, superado; check de la función limpio.
- flutter analyze: sin incidencias. No suite completa.

Logs locales: .dart_tool/entry-quota-flow.log, entry-compact-test.log,
entry-quota-rules-test.log, entry-quota-legacy-recovery.log y
entry-initial-quota-analyze-final.log. Nueve casos dirigidos distintos en total.

Respaldo de reglas **remotas activas**, verificado y sin credenciales:
`C:\Users\aleja\Documents\BoteParroquial-backups\firestore-rules\2026-11-03T16-19-30-199Z`.
Hash anterior: `35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`.
Incluye manifest, firebase.rollback.json y RESTORE.md. No es copia de documentos.
Revisión concreta: [INITIAL_QUOTA_RULES_REVIEW.md](INITIAL_QUOTA_RULES_REVIEW.md).

Reglas publicadas y verificadas contra la fuente local:
`projects/boteparroquial/rulesets/44a20498-b7bb-4efd-bb96-ab1236d2c5e8`,
release `2026-11-03T16:21:22.909804Z`, SHA-256
`fee05c4c229be0c907840b47c6c5269213c2f419955620c6d7d8f81f75556055`.
Solo se publicaron firestore:rules; sin índices, Hosting o cambios financieros.
El compilador de Rules emite advertencias de tipos/variables, sin errores; no
se amplió este cambio a una reescritura general de reglas. Logs de publicación
y comparación: entry-quota-rules-deploy.log y entry-quota-rules-verify.log.

APK profile compilado: `build/app/outputs/flutter-apk/app-profile.apk`, SHA-256
`44f29008efe890947b4cf133563f352eb3b455b95fa70a570569d92188129715`.
APK debug: `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256
`c36f37ec5814fdc6ccf2d277dd28f2fe533e7e545631c0665c39ed345ae616db`.
Logs entry-quota-profile.log / entry-quota-debug.log. Se conserva la corrección
D131 y las animaciones elegidas; este profile no activa las métricas optativas.
No se han instalado ni ejecutado estos nuevos APK; lo hace el usuario.

Comando directo, desde la raíz en PowerShell, conservando datos:

```powershell
& "C:\Users\aleja\AppData\Local\Android\Sdk\platform-tools\adb.exe" -s 00166155L000316 install -r "build\app\outputs\flutter-apk\app-profile.apk"
```

Comprobaciones nuevas en la sección 24 de GUIA_PRUEBAS_MOVILES.md.
No acreditar prueba física del formulario ni recepción push.

La corrección previa D131 sí recibe confirmación del usuario: «ahora sí va
fluido», tras corregir la instalación. Es aprobación de su recorrido en A059P,
no una medición universal de FPS ni de otros dispositivos.
