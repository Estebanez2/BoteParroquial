# Edición, personas, paletas y avisos — 02/11/2026

## Entrega y acuerdos

D116–D119 recogen la petición y las dos elecciones del usuario. Esta entrega
amplía v0.4, conserva la navegación, las cinco identidades y el guardado local de
apariencia. No se cambian Rules, índices, backend de fotos, worker ni cron. No se
siembran ni borran datos remotos y no se instala la app en ningún dispositivo.

### Recorte acorde con el destino

Portadas de grupo: marco horizontal 16:9 al elegir de galería, hacer una foto y
editar la actual. Vista previa panorámica, igual que el resumen. Avatares de
cuenta/miembro/persona: recorte cuadrado, mostrado circularmente. El formato lo
propaga PhotoController → PhotoRepository → PhotoPickerService → AppImageCropper;
no se deduce de la orientación del archivo original. Las imágenes existentes no
se recortan ni suben automáticamente. Se mantienen zoom/rotación, JPEG sin EXIF,
límite de 512 KiB, permisos y guardado explícito. En iOS el marco no intercambia
ancho y alto al rotar. Referencia de la API:
[image_cropper](https://pub.dev/packages/image_cropper).

### Salir sin guardar

`AppFormGuard` centraliza aviso, bloqueo durante envío y vuelta tras confirmar.
Aplicado a los editores de personas, perfil, grupo, movimientos, fotos y selección
de primeros meses. La flecha, Cancelar donde existe y Atrás del sistema quedan
protegidos. «Seguir editando» conserva el borrador; «Descartar cambios» sale.
Volver a los valores originales no pregunta. Un guardado confirmado permite
salir; un fallo conserva la protección. No es un guardado automático ni un
respaldo de borradores ante cierre forzado del proceso. Cambiar una foto que ya
se guardó es una operación independiente: descartar el texto de una persona no
revierte esa foto guardada. Otros formularios antiguos no se declaran cubiertos
por esta entrega.

### Completar primeros meses en conjunto

En **Personas**, bloque destacado «PRIMER MES DE CUOTA» con cantidad pendiente y
«Completar primer mes». Se abre una selección con casillas, «Seleccionar todas»,
«Quitar selección» y un primer mes común. Nadie se selecciona automáticamente.
El mes actual es una propuesta editable, nunca un periodo persistido por defecto.

Solo se incluyen personas activas sin `lastParticipationPeriodId` y sin ninguna
etapa en los datos consultados del grupo. No se reactivan inactivas ni sustituyen
periodos existentes. El repositorio prepara los candidatos; el provider coordina
sesión/permisos y llama al repositorio de participación existente. Reutiliza una
lectura compartida de periodos por grupo, sin abrir una consulta por ficha.

Antes de guardar se confirma cantidad, mes y consecuencias. Cada persona se
guarda en su transacción existente, con auditoría y validación de concurrencia
en servidor. **El conjunto no es una transacción global**: se detiene ante el
primer fallo, informa las confirmadas y conserva el resto seleccionado. Un
resultado incierto requiere revisar/actualizar; no se sobrescribe una etapa
creada por otro gestor. Cambiar sesión/permisos impide continuar. No se crean
pagos, asignaciones, movimientos ni reglas de cuota. En el visor de copias no
aparece la gestión.

### Paletas con más colores

Se mantienen los identificadores guardados y Sistema/Claro/Oscuro:

| Paleta | Principal | Complementario | Tercer acento |
| --- | --- | --- | --- |
| Atlántico | Azul | Ámbar | Lavanda |
| Iris | Violeta | Lima | Rosa |
| Coral | Coral | Turquesa | Violeta |
| Bosque | Verde | Frambuesa | Ocre |
| Grafito | Tinta neutra | Cobre | Petróleo |

Grafito combina dos acentos cromáticos sobre el neutro. Cada modo tiene sus
propios colores y superficies. Tokens secundarios/terciarios, ThemeExtension,
ColorScheme y transiciones se mantienen centralizados. Botones secundarios,
paneles degradados suaves, Participantes, estadísticas y vista previa de Ajustes
muestran los acentos en una misma pantalla. Éxito, advertencia y error conservan
su semántica; no se recolorean importes para simular cambios financieros.

### Solicitud inicial de notificaciones

D119 sustituye la elección histórica D093 de pedirlas solo mediante botón. En la
primera entrada con cuenta autenticada en este móvil se solicita permiso al SO
y, si se concede, se registra el dispositivo. No hace falta entrar en cada grupo.
Android/iOS controlan si muestran el diálogo: si el permiso ya estaba concedido,
puede no aparecer. No se intenta un registro asociado a otra identidad sin login.
Las instalaciones anteriores sin registro ni elección local pasan por esta
solicitud una vez al actualizar; no es posible reconstruir una elección local
que la versión anterior no conservaba después de retirar su registro.

La elección se guarda localmente por UID, con hash en el nombre y solo un booleano
versionado, sin tokens. Se registra antes del diálogo para no repetirlo si se
rechaza o interrumpe; una aceptación permite reintentar un registro fallido.
Un rechazo o retirada expresa no se reactiva automáticamente al volver a abrir.
Perfil conserva activar/comprobar/retirar y cada grupo conserva sus preferencias.
Recordatorios, económico e informativo **ya tenían valor predeterminado activo**
cuando no hay preferencia; no se escribe masivamente ni se sobreescribe un false.

El journal de registro/retirada y la retirada confirmada antes de logout siguen
vigentes. Logout conserva la retirada como elección desactivada en este móvil;
al volver se puede activar desde Perfil. El permiso no acredita entrega FCM.
APNs/iOS y validación física continúan pendientes.

## Comprobaciones

Pruebas dirigidas: guardia de formulario, flujo de personas, fotos, selección
múltiple/resultado parcial/permisos, apariencia/contraste de diez variantes y
cliente de notificaciones/elección persistida. Los fixtures de pantallas aíslan
el ciclo de copias y no usan Firebase real. No se ejecuta la suite completa.

23 pruebas dirigidas distintas superadas. Los dos fallos iniciales de fixtures
se corrigieron manteniendo la sesión observada en la nueva pantalla y aislando
el ciclo de copias en el test antiguo de bandeja. Solo esos dos archivos se
repitieron después; no se repitieron las comprobaciones ya superadas sin motivo.
`flutter analyze --no-pub`: sin incidencias.
`flutter build apk --debug --no-pub`: compilación correcta.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
SHA-256: `1fd589427afd0da427761bc8041cbeea870fe60b160b0a2f710e5c274a738809`.

Registros locales de esta ejecución en `.dart_tool/nov02-tests.log` y
`.dart_tool/nov02-recheck.log`; análisis final `.dart_tool/nov02-analyze-final.log`
y compilación `.dart_tool/nov02-apk.log`. Estos logs no se incorporan a Git.
Rules locales mantienen SHA-256
`35bf3eec1b7b4ff1a23d297e51368bc7a4ac0b4f58be332b9e9845d8cb7e85f1`;
no se ha publicado ni consultado una versión remota en esta tarea.

La guía de móviles incorpora **sección 17, UX-01–UX-06**, y actualiza AVI-01/02.
Todos los casos nuevos en dispositivos siguen pendientes: no se ejecutó la app,
ni una subida real de foto, ni guardados remotos de primeros meses, ni una entrega
push en este trabajo.
