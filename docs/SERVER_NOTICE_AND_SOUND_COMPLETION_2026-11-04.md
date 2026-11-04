# Aviso del servidor y conexiones de sonido — D149–D150

## Mensaje solicitado

El error de cuota conserva FailureCode.resourceExhausted y usa el texto común:

> El servidor está temporalmente fuera de servicio. Inténtalo más tarde o mañana.
> Puedes consultar una copia guardada.

Se reutiliza en REST de caja, descarga de copias y mapeos SDK de perfil/grupos,
movimientos, personas, cuotas, asignaciones, invitaciones, gestión, vínculos,
roles e historial. La sincronización de grupo muestra Servidor no disponible
con este mensaje y conserva el botón de copias. No se cambia su retraso para
evitar un aviso fugaz durante una conexión correcta.

Es el texto de producto elegido por el usuario; técnicamente el diagnóstico previo
era HTTP 429 por cuota, no evidencia de caída completa. Se conserva esa distinción
en el código y la documentación. «Mañana» invita a reintentar, no promete una hora
de recuperación. No se han consultado métricas ni cambiado facturación o servidor.
No se modifica el aislamiento del visor ni se salta automáticamente a otra fuente.

## Resultado de la auditoría de audio

Los cinco efectos existían, pero faltaban conexiones. En particular, guardar un
movimiento no mostraba AppSnackbar de éxito y por tanto no emitía confirmación.
Se añade success solo después del resultado guardado, corregido o anulado verdadero,
antes de abandonar el editor; AsyncError del controller emite warning. Una validación
incompleta o un envío fallido no confirma éxito. No se usa AppFormGuard.saved como
disparador global, porque algunos selectores solo confirman borradores locales.

| Acción | Conexión actual |
| --- | --- |
| Botón, icono, tarjeta, menú y pestaña | AppControlFeedback y componentes compartidos ya conectados |
| Escritura | AppTextField → typing por ráfagas; sin contraseña ni restauraciones |
| Abrir un selector de fecha/campo con acción | AppTextField.onTap explícito → tap |
| Casilla o interruptor | AppToggleTile nuevo; sustituye los controles directos de apariencia y primer mes en lote |
| Elegir color o tocar gráfica | AppColorField/Plane y AppLineChart; sin sonido continuo al arrastrar |
| Abrir foto | Foto de cuenta/persona/miembro y portada interactiva → tap |
| Foto preparada | Listener del borrador del editor → photo, ya existente |
| Foto guardada | Confirmación de éxito ya existente en AppSnackbar |
| Movimiento guardado/corregido/anulado | Resultado confirmado del controller → success, añadido |
| Validación, acción no disponible o error | Feedback común; errores de foto existentes y movimiento completado |

Se mantienen efectos locales, volumen suave, modo silencio, preferencia del móvil,
cancelación al desactivar/suspender y reproducción sin esperar desde las acciones.
No se añaden activos de audio, SDKs, permisos ni dependencias. Sonidos de teclado,
cámara y controles nativos del sistema no se sustituyen por los de Flutter. No se
consideran comprobados auditivamente hasta probar un dispositivo.

## Verificación realizada

Solo tres casos dirigidos distintos, sin suite general:

1. ui_sounds_test.dart, Componentes emiten: escritura/contraseña/restauración,
   campo con acción, casilla, interruptor, botón y resultado de éxito.
   Log .dart_tool/sounds-completion-controls.log.
2. movements_test.dart, Flujo financiero: céntimos, advertencias, corrección y
   anulación sin doble saldo; ningún success con datos incompletos y cuatro
   confirmaciones para los cuatro guardados. Reproductor simulado, sin SDK de audio.
   Log .dart_tool/server-sounds-movement-test.log.
3. firestore_quota_recovery_test.dart: clasificación de cuota del SDK y texto
   «Inténtalo más tarde o mañana» conservados.
   Log .dart_tool/server-message-test.log.

Los tres casos pasan. Análisis limpio: .dart_tool/server-sounds-analyze.log.
Compilación profile correcta: .dart_tool/server-sounds-profile.log.
APK: build/app/outputs/flutter-apk/app-profile.apk (128,3 MB según Flutter).
SHA256: 8019c583e2865de0fc6e07ea0fafc2c35ffb494b4049c442ca285f527c238922.
El usuario instala y ejecuta, sin instalación automática. diff --check limpio.
No hay lecturas/escrituras de prueba remotas ni cambios de Rules, índices o datos.

## Pendiente en móvil

Probar el aviso cuando ocurra el error y abrir una copia; no provocar tráfico para
agotar cuota. Comprobar escritura por ráfagas, foto preparada frente a guardada,
guardado de movimiento confirmado, silencio y preferencia apagada. Con servidor
limitado, no debe oírse éxito por un intento económico no confirmado.
La guía está ampliada en la sección 28 de GUIA_PRUEBAS_MOVILES.md.
