# Guía de pruebas de BoteParroquial con dos o tres móviles

**Actualización del 23/10/2026:** incluye copias diarias locales de consulta,
cifradas y separadas por cuenta. El nuevo recorrido es **COP-01–COP-10**, sección
16. Requiere instalar el APK nuevo en cada móvil; no basta la compilación del día 20.
El usuario sigue ejecutando todas las comprobaciones físicas.

Preparada el **20 de octubre de 2026**. Esta guía no certifica pruebas ejecutadas:
todos los casos empiezan **PENDIENTES**. Leerla no ejecuta operaciones. Tú ejecutas la app.
Incluye cliente y servidor de notificaciones de Phase 9, cuotas, devoluciones e
informes de Phase 10. El usuario ejecuta las comprobaciones físicas.

**Entrega vigente, 20/10/2026:** el reinicio remoto autorizado ya se ha ejecutado.
Los grupos antiguos, incluidos Prueba1 y muestras anteriores, se han sustituido
por los dos grupos de [DEMO_DATOS_2026-10-20.md](DEMO_DATOS_2026-10-20.md).
Las cuentas Google/Firebase se conservan. También se han añadido PDF/Excel,
papelera, baja de cuenta, eliminación de grupo, auditoría de personas/movimientos/
perfil/fotos y agregados de caja. Esta guía incluye ahora sus recorridos.
Solo las pruebas técnicas documentadas están ejecutadas; las casillas móviles
siguen pendientes. Las secciones destructivas sí cambian datos cuando tú las sigues.

Ampliación del 20 de octubre: enlaces HTTPS de invitación publicados y preferencias
económicas/informativas añadidas. Worker desplegado en el segundo Supabase aislado,
cron cada quince minutos y recorrido de bandeja DEMO comprobado. Ningún push o
enlace se ha validado en un móvil en esta entrega. Evidencia exacta:
[informe vigente](PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md).

Ampliación posterior del mismo día: comparaciones en Informes, incluidos periodos
en curso con el mismo tramo transcurrido (D103). Pasos INF-06–08 abajo; sin prueba
física certificada. [Entrega](PHASE10_PERIOD_COMPARISONS_VALIDATION.md).

Continuación Phase 11: historial administrativo paginado y detalle protegido.
Casos AUD-01–05. [Entrega](PHASE11_AUDIT_HISTORY_VALIDATION.md); pendientes físicos.

## 1. Preparación y cuentas

Necesitas Internet, Google Play Services y el mismo APK en todos los Android.
Usa cuentas Google reales diferentes para probar permisos. Los UID ficticios de
las muestras de Firestore no sirven para iniciar sesión.

| Dispositivo | Cuenta | Uso inicial |
| --- | --- | --- |
| M1 | A, tu cuenta habitual | Propietario y operaciones económicas |
| M2 | B, otra cuenta Google | Primero miembro; después administrador |
| M3, opcional | C, tercera cuenta | Miembro mientras B es administrador; después, segundo administrador |

Con dos móviles puedes recorrer toda la matriz por etapas. Si tienes una tercera
cuenta pero no M3, cambia de B a C en M2 cerrando sesión con conexión. No equivale
a tres sesiones simultáneas. Si solo tienes una cuenta, prueba sincronización
entre sus dos móviles; deja **BLOQUEADOS** los casos de separación entre usuarios.

Registra modelo, versión Android, cuenta, rol y versión de APK de cada móvil.
No uses datos personales reales en las notas de prueba ni compartas tokens,
claves, códigos de invitación activos o capturas de credenciales.

### Instalar sin compilar otra vez

APK preparado: `build/app/outputs/flutter-apk/app-debug.apk`.
Su SHA-256 en esta entrega es
Consulta el SHA-256 vigente al final de
[DAILY_OFFLINE_COPIES_VALIDATION.md](DAILY_OFFLINE_COPIES_VALIDATION.md).
El APK anterior del 20/10 tenía hash
`030d8d285e701adc68b77933d22b96ca64ed53d451aa0a0f1e17a6b3c9547a73`
y no incluye las copias diarias.
Si se genera otro APK después, registra su hash y usa ese mismo archivo en todos.
La etiqueta `1.0.0+1` por sí sola no identifica una compilación concreta.

En PowerShell, desde el repositorio:

```powershell
flutter devices
flutter install --debug -d ID_M1 --use-application-binary="build/app/outputs/flutter-apk/app-debug.apk"
flutter install --debug -d ID_M2 --use-application-binary="build/app/outputs/flutter-apk/app-debug.apk"
```

Sustituye `ID_M1` e `ID_M2` por los identificadores reales; repite para M3 si lo
tienes. El A059P se identificaba como `00166155L000316`: confírmalo de nuevo.
También puedes transferir el APK e instalarlo abriéndolo en cada móvil, aceptando
el permiso de instalación de esa aplicación si Android lo pide.

Usa el APK firmado con la clave de desarrollo ya configurada para Google. Si hay
conflicto de firma, registra el error; **no desinstales ni borres datos** para
resolverlo sin revisar antes los envíos pendientes. No hace falta lanzar suites
de pruebas ni recompilar para seguir esta guía.

### Grupos aislados y orden

Primero abre con A = **ale.manu.cristi@gmail.com** los dos grupos DEMO que ya
existen. Comprueba las cifras de la sección 1.1 y su inventario. Para los
recorridos de importes exactos siguientes crea G/H nuevos: sus cálculos parten de
cero y no se pueden ejecutar sobre los DEMO manteniendo los resultados esperados.

Crea grupos nuevos; no sobrescribas las muestras DEMO existentes:

- **G: `[Prueba] QA R1 Finanzas`**. A propietario, EUR, Europe/Madrid. Desmarca
  crear la persona del propietario. Aquí se comprueban importes exactos.
- **H: `[Prueba] QA R1 Accesos`**. A propietario; deja marcada la persona inicial.
  Aquí se prueban miembros, fotos, permisos y cambios delicados.
- Si repites la guía, usa R2, R3… No borres los movimientos anteriores.

Orden recomendado: acceso → grupos/personas → dinero/cuotas/devoluciones/informes
en G → miembros/fotos en H → concurrencia/sin conexión → avisos → transferencia.
La transferencia se hace al final y solo en H.

### 1.1. Comprobación rápida de los datos ya preparados

Con Internet y el APK nuevo en M1, entra con A. Espera la confirmación del servidor
antes de valorar datos que puedan quedar en la caché de instalaciones anteriores.
No reintentes envíos antiguos pendientes contra los grupos eliminados.

| Grupo | Personas visibles / activas | Movimientos | Ingresos activos | Retiradas activas | Saldo |
| --- | --- | --- | --- | --- | --- |
| [DEMO] Comunidad San José | 12 / 11 | 159 | 2.537,50 € | 339,80 € | **2.197,70 €** |
| [DEMO] Jóvenes y proyectos | 8 / 7 | 121 | 1.047,50 € | 339,80 € | **707,70 €** |

- [ ] **DEMO-01**. Abre cada grupo y compara su caja con la tabla. En octubre de
  2026, cuotas del mes: esperado **275,00 € / 105,00 €**, pagado
  **227,50 € / 77,50 €**, pendiente **62,50 € / 37,50 €**, respectivamente.
  La caja del mes es otro concepto: no tiene que coincidir con cuotas pagadas.
- [ ] **DEMO-02**. Busca a Marta (atrasos), Luis (pago parcial), Carmen
  (sobrepagos y devolución), Pablo (pendientes), Lucía (crédito libre) y Javier
  (inactivo con historia hasta junio). Los dos grupos tienen importes distintos.
  La ficha del propietario incluye adelantos de noviembre/diciembre.
- [ ] **DEMO-03**. En Movimientos, busca «DEMO» y filtra estados. Hay ingresos
  anulados, retirada corregida con sustituto y devoluciones activas/anuladas/
  corregidas. Abre los detalles y compara origen, reparto e historial.
- [ ] **DEMO-04**. Auditoría tiene más de cincuenta eventos en cada grupo:
  «Cargar más cambios» debe servir sin fabricar datos adicionales.
- [ ] **DEMO-05**. M1 comparte una invitación desde la app: Comunidad requiere
  aprobación y Jóvenes admite directamente a nuevos usuarios. Con B en M2
  comprueba ambas rutas. El código no está en este documento: cópialo desde la app.
- [ ] **DEMO-06**. En Miembros solo aparece A al principio. Vincula B a una
  persona libre antes de ascenderla a admin; no hay cuentas Google ficticias.
  Para probar todo sin alterar los ejemplos de caja usa después G/H.

Estas cifras son la referencia inicial del **20/10/2026**. Si registras cambios,
devolverás/anularás importes o cambia el mes, anota la nueva referencia; no lo
consideres fallo por diferir de esta tabla. Para informes selecciona 2026 y octubre
o año completo según el dato; la previsión futura queda separada de deuda vencida.

## 2. Acceso, perfil y restauración

- [ ] **AUTH-01**. M1/A: abre la app y entra con Google. Comprueba nombre, perfil
  y grupos propios; cancela una selección de cuenta y confirma que puedes volver
  a intentarlo sin quedar bloqueado.
- [ ] **AUTH-02**. Cierra de verdad el proceso desde Ajustes de Android →
  Aplicaciones → BoteParroquial → Forzar detención. Ábrelo: conserva la sesión
  sin pedir otra vez Google. Repite tras reiniciar el móvil. Quitar de recientes
  no siempre termina el proceso.
- [ ] **AUTH-03**. M2/B: inicia sesión. No debe ver G ni H antes de entrar en
  ellos. Tampoco la foto de cuenta, bandeja o datos privados de A.
- [ ] **AUTH-04**. Cierra sesión y entra con otra cuenta en el mismo móvil.
  No quedan datos o fotos privados de la anterior en pantalla. Si has activado
  avisos, usa el cierre con conexión descrito en el apartado 12.
- [ ] **AUTH-05**. Abre Tu perfil y vuelve varias veces al inicio. La foto
  conservada en caché no se sustituye fugazmente por iniciales al navegar.
  No des por hecho que editar un perfil cambia nombres de personas internas.

## 3. Crear grupos, separación y persona inicial

- [ ] **GRP-01**. Crea G con las opciones indicadas arriba. No aparece una
  persona automática del propietario. Saldo inicial cero e historial vacío.
- [ ] **GRP-02**. Crea H con persona inicial activada. Aparece la persona de A
  vinculada a su membresía. Es distinta del perfil global de la cuenta.
- [ ] **GRP-03**. Edita nombre y descripción de H. Un segundo miembro ve el
  cambio al sincronizar. No se cambia moneda mediante la edición del grupo.
- [ ] **GRP-04**. Deja B en H y fuera de G. Cambiar de grupo nunca mezcla
  personas, movimientos, cuotas, imágenes o saldo. B no puede abrir G por haber
  pertenecido a H. No introduzcas enlaces de navegación artificiales como si
  la app tuviera enlaces públicos de grupos ya implementados.
- [ ] **GRP-05**. Prueba nombre vacío y cancelación del formulario. No crea
  grupos incompletos ni duplicados por pulsaciones rápidas.

## 4. Personas

Para las cifras de los apartados 5–8, crea en G **solo `Ana QA`**, con primer mes
explícito **M−1**. M significa el mes actual de Europe/Madrid; si pruebas en
octubre de 2026, M−1 es septiembre, M octubre y M+1 noviembre. Usa el mes real
cuando ejecutes la guía, sin cambiar el reloj para forzar resultados.

- [ ] **PER-01**. Crear Ana, editar nombre/notas y cancelar otra edición.
  Nombre vacío no se guarda. Los límites mostrados por los campos se respetan.
- [ ] **PER-02**. En H, crea otra persona sin primer mes. No inventa una etapa
  ni deuda cero. Configura después expresamente su primer mes desde su ficha.
- [ ] **PER-03**. En H, registra un ingreso pequeño para una persona de prueba
  y después inactívala. Su historial se conserva y puede encontrarse con el
  filtro correspondiente. No hay borrado financiero de su historia.
- [ ] **PER-04**. Registra un movimiento para esa persona inactiva: debe
  advertirlo y permitir continuar; no la reactiva automáticamente.
- [ ] **PER-05**. Reactívala. No se duplican persona ni movimientos y no
  recupera un rol admin perdido por haber quedado inactiva.

## 5. Movimientos y saldo: recorrido con resultados exactos

En G, configura la primera cuota en **20,00 € desde M−1** en «Cuotas y etapas».
Usa fecha efectiva de hoy para todos los movimientos de esta tabla. Añade en la
descripción `[Prueba]` y el identificador I1, I2… para encontrarlos.

| Caso | Operación, en este orden | Saldo esperado |
| --- | --- | ---: |
| MOV-01 | I1: ingreso 50,00 € asociado a Ana | 50,00 € |
| MOV-02 | I2: ingreso general 10,00 €, sin persona | 60,00 € |
| MOV-03 | W1: retirada general 5,00 € | 55,00 € |
| MOV-04 | Corrige I2 a ingreso 12,00 € | 57,00 € |
| MOV-05 | Anula W1 | 62,00 € |
| MOV-06 | Corrige el sustituto de I2: cambia ingreso 12 a retirada 2,00 € | 48,00 € |
| MOV-07 | Anula esa retirada de 2,00 € | **50,00 €** |

- [ ] Revisa cada fila, en historial y dashboard. Los originales quedan con
  estado corregido/anulado y relación con el sustituto; no se borran ni suman
  dos veces. Al final solo I1 aporta al saldo.
- [ ] **MOV-08**. Prueba cero, signo negativo, cantidad vacía y tres decimales:
  no se confirma dinero inválido. `20,50` se conserva como 2050 céntimos, sin
  errores de redondeo visibles.
- [ ] **MOV-09**. Fecha de mañana no permitida; hoy y una anterior sí. Cancela
  la comprobación de fecha anterior para no alterar la tabla.
- [ ] **MOV-10**. Abre detalles, vuelve, busca y usa los filtros disponibles.
  Distingue fecha efectiva del orden de últimos cambios del dashboard.
  Cancelar una revisión no registra otro movimiento.

## 6. Repartir un ingreso por meses

Continúa con I1 activo de 50 €. Hasta repartirlo, sus 50 € están en el bote,
pero **no pagan cuotas**. Con Ana desde M−1 y cuota 20 €, el pendiente hasta M
es 40 €. No añadas más personas a G hasta terminar el apartado 8.

En I1 abre «Repartir por meses», también accesible desde la ficha de Ana.

| Caso | Asignación de I1 | Pendiente hasta M | Crédito sin asignar |
| --- | --- | ---: | ---: |
| ALO-01 | Sin reparto | 40,00 € | 50,00 € |
| ALO-02 | M−1: 20,00 € | 20,00 € | 30,00 € |
| ALO-03 | M: 10,00 € | 10,00 € | 20,00 € |
| ALO-04 | M+1: 10,00 € | 10,00 € | **10,00 €** |

- [ ] El saldo sigue en 50 €. M figura parcial, M+1 como adelanto, nunca como
  atraso. Comprueba propuesta por antigüedad y horizonte de doce meses futuros;
  revisa la propuesta y confirma cada mes, sin reparto automático de historia.
- [ ] **ALO-05**. Cambia el total de I1 para M−1 de 20 a **25 €**, aceptando la
  advertencia de sobrepago. Pendiente de M sigue en 10 €, no en 5 €. Crédito 5 €.
  Después vuelve a fijar el total de M−1 en **20 €**: recuperas la base de la tabla.
  El editor fija el total de ese ingreso/mes; no añadas 20 otra vez por error.
- [ ] **ALO-06**. Intenta superar el dinero disponible de I1. No se permite
  repartir dinero inexistente, ni un ingreso de otra persona/grupo.

## 7. Devoluciones, restauración y límites

Base de partida: caja 50 €, reparto M−1=20, M=10, M+1=10, crédito libre 10 €.
Abre la devolución desde el ingreso I1. Una retirada ordinaria asociada a una
persona **no** es una devolución de cuotas.

| Caso | Operación | Resultado esperado |
| --- | --- | --- |
| DEV-01 | R1: devuelve 5 € de M−1 y 3 € de crédito libre | Retirada 8 €, caja **42 €**; pagado M−1=15, M=10, M+1=10; crédito=7; pendiente hasta M=15 |
| DEV-02 | Intenta devolver otros 16 € de M−1 o 8 € de crédito | Bloqueado: solo quedan 15 y 7 respectivamente; no cambia la caja |
| DEV-03 | Intenta bajar el reparto bruto de M−1 a 4 € | Bloqueado: ya hay 5 € devueltos de ese reparto |
| DEV-04 | Intenta anular/corregir I1 mientras R1 está activa | Bloqueado; no rompe el origen de la devolución |
| DEV-05 | Retirada ordinaria 2 € para Ana, sin plan de devolución | Caja 40 €; cuotas y crédito no cambian. Anúlala para volver a 42 € |
| DEV-06 | Anula R1 | Caja **50 €** y base de reparto restaurada; R1 conservada |
| DEV-07 | Registra otra devolución igual a R1 | Caja 42 € |
| DEV-08 | Corrige esta última: revisa el reparto nuevo y elige 4 € de M y 1 € de crédito | Caja **45 €**; pagado M−1=20, M=6, M+1=10; crédito=9; pendiente=14 |
| DEV-09 | Anula el sustituto de DEV-08 | Caja **50 €**, base de reparto restaurada |
| DEV-10 | Devuelve solo 2 € de crédito libre | Caja 48 €, cuotas iguales, crédito 8 €. Anula para volver a la base |

- [ ] Comprueba parciales y combinaciones sin sobrepasar el origen. Al corregir,
  el nuevo reparto requiere revisión expresa; no se copia sin confirmación.
- [ ] **DEV-11**, ampliación: registra otro ingreso de 5 € de Ana. Reparte 1 €
  en cada uno de M−1, M, M+1, M+2 y M+3, aceptando sobrepago si corresponde.
  De ese ingreso permite devolver cuatro meses distintos; el quinto no cabe en
  la misma devolución. No permite mezclar otro ingreso de origen. Si confirmas
  4 €, caja 51 €; anula esa devolución (55 €) y luego el ingreso (50 €).
- [ ] **DEV-12**, en H o en un ingreso adicional: tras anular todas sus
  devoluciones, corrige un ingreso repartido. El original y sus asignaciones
  se conservan, dejan de pagar y el sustituto empieza sin reparto. No lo hagas
  sobre I1 hasta terminar las comprobaciones numéricas siguientes.

La corrección de una devolución conserva su ingreso de origen y admite hasta
cuatro meses en la unión del plan anterior y el nuevo. Para otro origen o más
meses, anula y crea otra operación; no se reutiliza dinero ya devuelto.

## 8. Dashboard, informes y exportaciones

Vuelve a la base: I1 activo, caja 50 €, M−1=20 pagados, M=10, M+1=10, crédito=10.

- [ ] **INF-01**. Dashboard: acumulado pendiente de cuotas 10 €, caja 50 €.
  Cuotas de M: esperado 20 €, pagado 10 €, pendiente 10 €. Caja de M: ingresos
  activos 50 €, retiradas activas 0 €. No suma corregidos ni anulados.
- [ ] **INF-02**. Informe de M−1: cuota pagada 20 € aunque I1 se recibió hoy.
  Caja de M−1 sin movimientos efectivos de ese mes: 0 €. Se muestra el estado
  actualizado hasta hoy, no una reconstrucción del cierre pasado.
- [ ] **INF-03**. Trimestre/año que incluya M: el pendiente solo llega a M.
  Meses posteriores dentro del periodo aparecen aparte como previsión. El
  adelanto no convierte una obligación futura en atraso ni paga otro mes.
- [ ] **INF-04**. Exporta movimientos a CSV como A o admin autorizado. Abre
  el selector de compartir y cancélalo una vez; no envía nada automáticamente.
  Después guarda una copia y ábrela: tildes correctas, estados, referencias de
  corrección e importes en céntimos. La suma de efectos activos es **5000**, no
  la suma bruta de todas las filas históricas. CSV no es un informe de cuotas.
- [ ] **INF-05**. B como miembro no tiene exportación administrativa habilitada.
  No hay exportaciones PDF/Excel listas todavía. Puede consultar los informes
  y sus comparaciones mientras su membresía esté activa.
- [ ] **INF-06**. Elige M y abre «Comparar con el periodo anterior». Comprueba las
  fechas: desde el primer día hasta hoy, frente al mismo tramo de M−1. Si ese mes
  tiene menos días, acaba en su último día. Con la base de esta sección, ingresos
  actuales **50 €**, anteriores **0 €** si no hay más movimientos; diferencia
  **+50 €**, sin inventar un porcentaje sobre cero. Las cuotas de M−1 siguen
  pagadas **20 €**, las de M **10 €**: el cobro de I1 no se cuenta dos veces en caja.
- [ ] **INF-07**. Cambia al trimestre y al año en curso: el anterior termina en
  el mismo mes relativo y día, sin comparar tres/doce meses completos contra un
  avance parcial. Selecciona después un periodo terminado: ambos completos.
  Cumplimiento cambia en **puntos porcentuales**; neto del tramo no es saldo del bote.
- [ ] **INF-08**. Mes futuro o sin periodo anterior dentro de 2000–2100: explicación
  sin comparación de hechos inventada. Una persona sin periodos configurados
  mantiene esperado/pendiente/cumplimiento desconocidos en el tramo afectado.
  Una devolución o anulación actualiza las cifras históricas: no reconstruye un
  cierre. No confundas la comparación con el CSV, que sigue exportando movimientos.

Después de estas cifras puedes ampliar casos:

- [ ] **CUO-01**. Intenta cambiar cuota actual/pasada: bloqueado. Programa 30 €
  desde M+1. Sustituye la futura por 25 € con confirmación y comprueba historial.
  Si necesitas repetir las cifras anteriores, vuelve a programar 20 € desde M+1.
- [ ] **CUO-02**. En otro grupo de prueba, cuota 0: sin deuda mensual nueva;
  esperado cero no se presenta como cobertura del 100 %.
- [ ] **CUO-03**. Al final en G, crea una persona sin primer mes: configuración
  incompleta, nunca pendiente global conocido de cero. Configúrala desde M:
  aparece su obligación de 20 €, sin modificar caja ni movimientos de Ana.
- [ ] **CUO-04**. En H, persona de prueba desde M−1: inactiva eligiendo último
  mes M, reactiva desde M. M cuenta una sola vez. No admite fin anterior al
  comienzo ni futuro; no permite reescribir libremente etapas cerradas.
  Inactivar no elimina obligaciones históricas según las etapas conservadas.

## 9. Invitaciones, vínculos y permisos con dos cuentas

Todo en H. No incorpores B a G hasta terminar la separación de grupos.

- [ ] **INV-01**. A abre invitaciones. B introduce el código y ve la vista
  previa mínima. Código inexistente o desactivado no deja entrar ni consultar
  personas/movimientos. Regenerar invalida el código anterior.
- [ ] **INV-02**. Con aprobación requerida, B solicita entrar. Antes de aprobar
  no tiene acceso. A rechaza una solicitud y verifica ausencia de membresía
  activa; B vuelve a solicitar y A aprueba. Entra como **member**, sin persona
  vinculada automáticamente.
- [ ] **INV-03**. En otra entrada de prueba usa modo automático. Un usuario
  nuevo entra como miembro, nunca administrador.
- [ ] **INV-ENLACE**. A copia o comparte el enlace HTTPS desde Invitaciones.
  En M2, con el APK actualizado instalado, ábrelo desde una conversación o correo.
  Debe abrir la vista previa en la app, sin entrar automáticamente. Si B no tiene
  sesión, inicia Google y comprueba que conserva esa misma invitación. Si no tiene
  la app, abre la página de ayuda y copia el código; no presupone una ficha de tienda.
  El enlace regenerado anterior debe ser rechazado por la vista previa del servidor.
  Si Android muestra la web pese a tener la app, revisa Ajustes → Aplicaciones →
  BoteParroquial → Abrir de forma predeterminada → enlaces compatibles. Anota el
  resultado; la comprobación HTTP del dominio no demuestra apertura física.
- [ ] **VIN-01**. A vincula B a una persona libre de H. Se refleja en ambos
  móviles. Otra persona no puede quedar vinculada al mismo usuario, ni otra
  cuenta a la misma persona. Cambiar el vínculo no traslada dinero/fotos/nombres.
- [ ] **VIN-02**. Vincula B a una persona inactiva aceptando advertencia. Puede
  seguir como miembro; no puede ascender a admin con esa persona inactiva.
- [ ] **ROL-01**. Reactiva su persona y asciende B a admin. El cambio aparece
  en M2. Inactiva su persona o desvincúlala: vuelve a member, atómicamente.
  Reactivar/revincular no devuelve admin por sí solo; hay que promover expresamente.
- [ ] **ROL-02**. A y admin autorizado pueden gestionar las operaciones que les
  corresponden; B como member consulta y cambia su foto/preferencias, pero no
  crea personas/movimientos, reparte cuotas ni administra otros miembros.
- [ ] **ROL-03**. El propietario no puede salir, ser expulsado o perder su
  vínculo/persona activa mediante operaciones que eludan la transferencia.
- [ ] **INV-04**. B sale o A lo expulsa. Ya no accede a datos/bandeja de H.
  Su persona, historial y vínculo reservado se conservan. Aunque la entrada
  nueva sea automática, su readmisión requiere aprobación.
- [ ] **INV-05**. A aprueba la readmisión. B vuelve como member, sin recuperar
  admin ni reactivar su persona. Conserva su vínculo y antigüedad anteriores.
- [ ] **VIN-03**. Con B fuera, A solo puede quitar su vínculo, no asignarle
  otro mientras está inactivo. Antes de reasignar esa persona a otra cuenta debe
  desvincular expresamente. Nunca reasigna historia por el mero abandono.
- [ ] **AUD-01**. Como gestor, abre la auditoría disponible. Verifica actor,
  operación y cambios de las acciones auditadas de miembros, roles, cuotas y
  repartos. Abre «Ver detalle»: antes/después, importes/meses legibles y fecha
  identificada como hora del móvil. «Identificadores del registro» permite anotar
  evento, entidad y actor de una incidencia. No permite editar eventos.
- [ ] **AUD-02**. Si hay más de cincuenta registros, pulsa «Cargar más cambios».
  Los anteriores permanecen y aparecen más antiguos sin duplicarse. Pulsar rápido
  dos veces no duplica páginas. Si no hay suficientes registros, deja PENDIENTE
  la paginación física; no fabriques cien cambios solo para aprobar el caso.
- [ ] **AUD-03**. Busca un valor/autor y filtra por tipo. El contador dice cuántos
  coinciden **entre los cargados**: cero no significa que no existan más antiguos.
  Cargar otra página amplía esa búsqueda. Limpiar filtros conserva páginas.
- [ ] **AUD-04**. Con páginas antiguas cargadas en M1, un gestor en M2 hace un
  cambio auditado válido. M1 anuncia «Mostrar cambios nuevos» sin desplazar la
  consulta que estabas revisando. Pulsarlo reinicia con la cabecera reciente.
  Sin paginar, la primera página sigue actualizando en directo.
- [ ] **AUD-05**. B admin abre detalle y A le retira ese permiso: datos privados
  desaparecen aunque la hoja siga abierta. Cambiar cuenta/grupo tampoco conserva
  resultados del anterior. Sin conexión, la caché aún sin confirmar se señala
  tras el margen visual y no permite consultar páginas antiguas como si fueran
  completas. Reconecta y actualiza. Movimientos conservan su historial separado;
  el historial administrativo y la papelera son pantallas diferentes.

### Si hay M3/C

- [ ] **TRES-01**. A owner, B admin, C member: los tres ven el mismo H; C no
  obtiene acciones de gestión al ver cambios hechos por B.
- [ ] **TRES-02**. Vincula C a persona activa y promuévelo a admin. Comprueba
  permisos entre dos admins, especialmente fotos. Después degrádalo a member.
- [ ] **TRES-03**. B y C solicitan cambios mientras A mantiene abierta la vista:
  no se mezclan destinatarios ni se aplica a C una acción elegida para B.

Con solo dos móviles, deja TRES pendientes o prueba B y C sucesivamente anotando
que no fue una validación simultánea.

## 10. Fotos de cuenta, grupo, miembros y personas

Prueba en H; usa fotos ficticias. Verifica el resultado desde el otro móvil.

- [ ] **FOT-01**. Sin imagen: iniciales del nombre y apellidos. Desde Tu perfil,
  elige galería; prueba recorte, zoom y rotación, guarda. Repite con cámara.
  Deniega permiso una vez y cancela el selector: la foto anterior permanece.
- [ ] **FOT-02**. «Editar foto actual»: abre la imagen existente, cambia el
  encuadre y guarda sin volver a buscarla. Cancelar conserva la anterior.
- [ ] **FOT-03**. En Miembros, sin excepción propia del grupo, se ve la foto de
  cuenta. Pon una excepción de H: cambia solo H. Cambiar luego la foto de cuenta
  no elimina esa excepción. «Usar foto de cuenta» retira la excepción.
- [ ] **FOT-04**. Cada usuario cambia su foto global; nadie cambia la global de
  otro. Admin cambia la foto de grupo de miembros normales, **no** la de otro
  admin ni la del owner. Owner puede cambiar también la de admins. Cada miembro
  puede cambiar su propia excepción.
- [ ] **FOT-05**. Solo owner cambia la imagen del grupo. Las personas internas
  tienen foto independiente gestionada por gestores autorizados: vincular una
  cuenta no copia ni sincroniza sus fotos.
- [ ] **FOT-06**. Navega varias veces entre inicio, dashboard, personas y miembros:
  imágenes ya cargadas no parpadean mostrando iniciales. En otro móvil permite
  revalidación de caché (aproximadamente un minuto; vuelve a abrir/actualizar).
  La primera descarga de una foto nueva puede tardar: no es el mismo caso.
- [ ] **FOT-07**. Quita una imagen y comprueba el fallback correcto, incluidas
  iniciales o foto de cuenta según destino. Cierra sesión y cambia de usuario:
  las fotos privadas de la cuenta anterior no se muestran.
- [ ] **FOT-08**. Abre editor, cancela, cambia de persona y abre otra foto.
  Nunca guarda el archivo en el destino anterior por una respuesta tardía.

## 11. Concurrencia, conexión y recuperación

Usa H y cantidades pequeñas para no romper las tablas de G. Anota el saldo previo.

- [ ] **RED-01**. Con Internet, abre varias veces pantallas: no aparece durante
  un instante el texto de «sin conexión». El estado de caché es conservador;
  no es una medición instantánea de Internet.
- [ ] **RED-02**. Carga H, personas e historial. Desactiva **Wi-Fi y datos**.
  Puedes consultar lo ya guardado; tras el margen de aproximadamente dos segundos
  aparece el aviso de datos posiblemente desactualizados. Una vista nunca cargada
  puede no estar disponible. No exige que el primer acceso sin caché funcione.
- [ ] **RED-03**. Intenta registrar/anular/corregir o repartir dinero sin red.
  No confirma una operación económica inexistente ni altera definitivamente el
  saldo. Recupera Internet, revisa el estado y confirma una sola vez si procede.
- [ ] **RED-04**. Con A y B autorizados, registra 1 € desde cada móvil. Resultado
  conjunto: +2 €, con dos movimientos distintos. Pulsar rápido no duplica un envío.
- [ ] **RED-05**. Ambos abren el mismo movimiento; uno corrige y el otro intenta
  anular la versión antigua. Debe detectar conflicto, conservar historia y no
  aplicar una segunda transición incompatible. Revisa desde ambos móviles.
- [ ] **RED-06**. Abre una edición como B admin. A lo degrada antes de guardar:
  el servidor debe rechazar el cambio ya no autorizado, aunque el formulario
  siga abierto. Repite con un reparto si quieres ampliar el caso sensible.
- [ ] **RED-07**. Abre la misma persona en ambos móviles y guarda sucesivamente;
  una edición obsoleta no sobrescribe silenciosamente una modificación protegida.
- [ ] **RED-08**, si logras reproducirlo: corta la red mientras envías dinero y
  fuerza la detención del proceso. Al volver, recupera el intento y consulta su
  resultado; no reenvía automáticamente ni duplica. Si el envío ya terminó antes
  del corte, anota «no reproducido», no lo marques superado.
- [ ] **RED-09**. Si aparece un conflicto de un intento pendiente, revisa primero
  el historial y confirma descartar **solo el intento local**. Los movimientos
  guardados siguen existiendo. No borres datos de la app para eliminar el aviso.
- [ ] **RED-10**. Con fecha automática, cambia solo la zona horaria del móvil a
  una que tenga otro día civil que Madrid si puedes. «Hoy» usa la zona del grupo.
  Restaura la zona del móvil. No adelantes el reloj para simular recordatorios.

## 12. Notificaciones: lo que ya se puede comprobar

Cliente y worker están desplegados, con reglas, índice y cron activos. La
actividad nueva se revisa cada quince minutos; no notifica el historial anterior
a la activación. Una bandeja vacía no demuestra un fallo. Registrar un dispositivo
no genera por sí mismo un aviso. El móvil debe tener permiso, registro y conexión.

- [ ] **AVI-01**. Instalación/cuenta sin consentimiento previo: iniciar sesión
  no muestra el permiso de notificaciones automáticamente. Tu perfil y la
  campana del dashboard permiten abrir el panel de avisos.
- [ ] **AVI-02**. Pulsa «Activar avisos en este móvil». Android solicita permiso
  cuando corresponda. Denegarlo no activa el registro; puedes intentarlo de nuevo
  o concederlo en Ajustes de Android si el sistema ya no muestra la pregunta.
- [ ] **AVI-03**. Con permiso y conexión, queda activado este móvil. Forzar
  detención y abrir conserva la intención; no pide permiso otra vez. Usa la
  opción de comprobar estado si necesitas confirmar registro.
- [ ] **AVI-04**. En H alterna «Recibir push»/«Solo bandeja». La preferencia es
  de esa cuenta en ese grupo, no de todas sus cuentas/grupos ni del permiso del
  móvil. Si usas la misma cuenta en otro teléfono, ve la misma preferencia.
  Desactivar push no vacía la bandeja.
- [ ] **AVI-CATEGORIAS**. En la misma pantalla, cambia por separado «Movimientos
  y cambios de cuota» y «Miembros, accesos e invitaciones». Solo modifica esa
  categoría para tu cuenta dentro del grupo. No cambia la preferencia mensual ni
  las de otra cuenta. Comprueba la entrega con AVI-10–14, sin darla por superada.
- [ ] **AVI-05**. Con avisos registrados, corta Internet e intenta salir de la
  cuenta: debe exigir confirmar la retirada remota y mantener la sesión mientras
  no pueda. Reinicia el proceso: no reactiva una retirada que quedó pendiente.
  Reconecta y termina la retirada/salida. Entrar otra vez no equivale a volver
  a activar voluntariamente avisos.
- [ ] **AVI-06**, dos móviles con **la misma cuenta**: actívalos en ambos. Retira
  los avisos/cierra sesión en uno. El otro conserva su registro. Para esta prueba
  puedes salir temporalmente de B con conexión y entrar como A en M2; después
  vuelve a B. No uses esta configuración para certificar permisos entre usuarios.
- [ ] **AVI-07**, inspección opcional de Firebase Console: bajo
  `users/{uid}/pushDevices` comprueba que hay un documento por registro de móvil
  y que retirar uno no borra los demás. No copies ni pegues los tokens en informes.

### Bandeja y marcado leído sin enviar push: muestra manual opcional

La muestra antigua `[Prueba] Pipeline de avisos` se eliminó en el reinicio autorizado.
Los nuevos DEMO comienzan con bandeja vacía, sin enviar el historial de prueba.
Para comprobar aislamiento entre dos cuentas en H, puedes crear **tú** documentos
ficticios desde Firebase Console → Firestore → datos. La consola usa privilegios
de operador, no los permisos del usuario de la app. Esta guía no crea documentos.

1. Consulta los UID reales de A y B en Firebase Authentication, por correo.
2. Con ambos miembros activos de H, crea en
   `groups/{id real de H}/notifications/manual-qa-r1-a` estos campos:

   | Campo | Tipo / valor |
   | --- | --- |
   | recipientUid | string: UID real de A |
   | kind | string: `quotaReminder` |
   | title | string: `[Prueba] Aviso manual A` |
   | body | string: `Prueba de bandeja; no representa una deuda real.` |
   | createdAt | timestamp: fecha y hora actuales |
   | readAt | null |

3. Crea otro con ID nuevo `manual-qa-r1-b`, destinatario B y título terminado en B.
   Si esos IDs existen, usa R2; no sobrescribas ni edites avisos reales.
4. **AVI-08**: A solo ve el suyo; B solo el suyo. Marca leído: cambia ese estado,
   no el texto ni el aviso de la otra cuenta. La misma cuenta en otro móvil ve
   el leído sincronizado. La bandeja muestra como máximo los últimos 50 avisos.
5. **AVI-09**: cambia a «Solo bandeja»: sigue viéndolo. Al perder la membresía
   activa ya no debe consultar la bandeja de H.

Esta muestra manual no dispara FCM: el worker consume sucesos válidos, no envía
automáticamente cualquier documento añadido a notifications. No certifica envío
con el móvil bloqueado ni recordatorios reales.

### Entrega real con dos móviles: pendiente de ejecutar

No hacen falta cambios de servidor para empezar. Usa el APK indicado arriba,
cuentas distintas A/B y grupo de pruebas H. No uses el grupo DEMO sembrado para
estas operaciones. Elige sucesos nuevos; el autor normalmente no recibe su propio
aviso. Anota la hora y espera hasta la siguiente comprobación de quince minutos
(más el tiempo de ejecución/red). No repitas la operación para forzar un aviso.

- [ ] **AVI-10**. A owner activa avisos en M1 y categoría informativa de H.
  B, todavía fuera de H, solicita entrar con código y aprobación obligatoria.
  Deja la solicitud pendiente hasta la siguiente comprobación: A recibe un único
  aviso discreto y entrada en bandeja. Pulsa el aviso y revisa H. Si apruebas antes
  del sondeo, la solicitud ya resuelta puede no generar su aviso de pendiente.
- [ ] **AVI-11**. B activa avisos en M2 antes de que A apruebe. Tras aprobación
  y siguiente sondeo, B recibe aceptación y puede abrir H. Después vincula B a
  una persona activa siguiendo la sección de vínculos. No confundas varios kinds
  distintos (aceptación/entrada/vínculo) con duplicar el mismo aviso.
- [ ] **AVI-12**. Con económico activado en B, A registra un ingreso DEMO asociado
  a esa persona (anota su ID/importe y el efecto en caja). B recibe el aviso sin
  importes. Repite con un nuevo movimiento en segundo plano y otro con proceso
  cerrado normalmente, sin «Forzar detención» de Android: el sistema puede
  bloquear entregas tras forzar detención hasta abrir la app. En primer plano
  comprueba bandeja/recepción; no exijas el mismo banner que con pantalla bloqueada.
- [ ] **AVI-13**. B desactiva económico, mantiene informativo. Un nuevo ingreso
  de A conserva bandeja en B sin push económico. Un cambio de cuota futuro válido
  también es económico. Un cambio informativo válido, por ejemplo rol de B según
  los requisitos de la guía, conserva su preferencia independiente. No ocultes
  cantidades en la app: solo los push son discretos.
- [ ] **AVI-14**. Tras marcar leído, esperar otro sondeo no vuelve a dejarlo sin
  leer ni repite su push. Revisa retirada/logout AVI-05/06 y que una cuenta fuera
  de H no reciba actividad posterior. Un push aceptado previamente por FCM podría
  llegar después; distingue su hora del nuevo suceso. Con M3, misma cuenta B en
  otro móvil: retirar M2 conserva M3, sin confundir registro con preferencia de grupo.
- [ ] **AVI-15**, calendario real. Cuota pendiente y persona activa: recordatorio
  a partir de las 10:00 del grupo, siete y un días **antes del último día** del mes
  (mes de 31 días: días 24 y 30). Comprueba cuota pagada/inactiva sin recordatorio,
  resumen de gestores para personas sin cuenta activa disponible, sin importes,
  y ausencia de duplicados en posteriores sondeos del día. No adelantes relojes
  ni cambies la fecha del servidor de producción para simularlo. Si no coincide
  el día, deja PENDIENTE; horario de verano y recuperación requieren observación
  controlada, no se dan por probados por haber recibido otro aviso de actividad.

No repitas manualmente un envío de resultado incierto: la reserva evita reintento
de ese push y la bandeja permite consultar el aviso. Cuarentena de tokens inválidos
y caídas se han probado localmente; su comprobación física no requiere manipular
tokens o credenciales en Console. iOS/APNs sigue bloqueado por su configuración.
No actives Blaze ni otro plan de pago para esta guía.

## 13. Transferencia de propiedad, al final y solo en H

Deja a B activo y vinculado a una persona activa; A mantiene también su vínculo.

- [ ] **TRA-01**. Solo A owner puede transferir. Nombre incorrecto o cancelación
  de la nueva verificación Google no cambia propiedad. Seleccionar otra cuenta
  Google no transfiere ni sustituye la sesión del usuario existente.
- [ ] **TRA-02**. Nombre exacto de H + reverificación de la misma cuenta A:
  B pasa a owner y **A a member**. No se mueven fotos, personas ni dinero.
  Ambos móviles actualizan permisos. La creación histórica sigue atribuida a A.
- [ ] **TRA-03**. Antiguo owner A ya no administra. B no puede salir/ser expulsado
  como owner. Si quieres volver al estado inicial, B transfiere expresamente a A
  con los mismos requisitos; no edites los roles a mano en Firestore.

### 13.1. PDF, Excel y CSV

- [ ] **EXP-01**. A abre Informes de Comunidad, selecciona **Año / 2026** y
  «PDF». Pulsa «Exportar y compartir», guarda el archivo con una aplicación del
  móvil y ábrelo. Debe incluir grupo, periodo, resumen y tablas legibles en varias
  páginas, acentos y céntimos correctos. Caja anual inicial: **2.197,70 €**.
- [ ] **EXP-02**. Repite con «Excel». Abre el `.xlsx` en Excel, Google Sheets o
  LibreOffice. Comprueba las cuatro hojas: Resumen, Personas, Movimientos y
  Actividad mensual. Las cantidades están identificadas en céntimos; no hay
  fórmulas ejecutables procedentes de nombres/descripciones. Son datos económicos;
  no se exporta la base privada de cuentas/dispositivos ni toda la auditoría.
- [ ] **EXP-03**. Exporta CSV y comprueba separador `;`, acentos y columna de
  céntimos. Selecciona otro mes y verifica que cambian las filas. Anulados y
  corregidos conservan su estado; no vuelven a sumarse por aparecer en el archivo.
- [ ] **EXP-04**. B como member puede consultar informes autorizados pero no
  exportar. Como admin, puede hacerlo. Si A retira su rol antes de compartir, la
  app vuelve a comprobarlo y no debe entregar un archivo de una sesión ajena.
  Cancelar el menú de compartir no envía nada automáticamente.

### 13.2. Papelera de personas

- [ ] **PAP-01**. Como gestor abre Personas → Papelera en un DEMO. Deben aparecer
  «Restaurable diez días» y «Papelera vencida». No figuran en Personas ni cuentan
  en sus cuotas. La restaurable vence el **29/10/2026 a las 09:00 UTC**; si pruebas
  después, crea una nueva persona sin primer mes y usa su papelera reciente.
- [ ] **PAP-02**. Restaura la primera: vuelve activa al listado y genera evento.
  Como no tenía participación configurada, su cuota será **desconocida**, no cero.
  El inventario económico inicial deja de servir para totales de personas/cuotas
  hasta volver a enviarla a la papelera o configurar expresamente su periodo.
- [ ] **PAP-03**. Crea otra persona sin primer mes, cuenta ni movimientos,
  envíala a papelera y recupérala. Su nombre/notas y estado previo se conservan.
  Una persona con cuota/periodo, vínculo o movimientos debe inactivarse: no se
  admite su eliminación por este mecanismo, aunque un ingreso esté anulado.
- [ ] **PAP-04**. Elimina definitivamente la vencida. Desaparece la ficha y su
  foto independiente si existía; queda auditoría. No se puede restaurar después.
  No cambies la fecha del móvil para simular diez días: el servidor valida el plazo.
  B como member no puede restaurar ni purgar. Sin Internet no se confirma borrado.

No hay purga automática programada: los registros vencidos siguen en la papelera
hasta que un gestor confirma «Eliminar definitivamente».

### 13.3. Eliminación irreversible de un grupo

**Hazlo en un tercer grupo desechable `[Prueba] Borrar`, al final.** Mantén los dos
DEMO y G/H si quieres conservar sus recorridos. Añade una persona, un ingreso,
una foto y B como miembro para ver el efecto completo.

- [ ] **DEL-01**. En configuración, solo A como owner ve «Eliminar grupo».
  Abre la vista previa: saldo, personas, membresías y movimientos coinciden con
  lo que has creado. Ofrece exportar antes. Las personas de papelera también
  cuentan en esa vista previa de borrado, porque se eliminarán con el grupo.
- [ ] **DEL-02**. Escribe un nombre incorrecto: no comienza. Cancela Google:
  tampoco. Con nombre exacto, confirma y verifica la **misma cuenta A**; una cuenta
  distinta no debe reemplazar la sesión ni autorizar la operación.
- [ ] **DEL-03**. El grupo queda bloqueado inmediatamente y deja de estar
  disponible para B. Antes de tres minutos, no se completa el borrado. Cierra y
  vuelve a abrir la app: Inicio ofrece «Reanudar eliminación». Después de tres
  minutos, verifica Google otra vez, escribe el nombre exacto y reanuda.
- [ ] **DEL-04**. Se eliminan documentos/subcolecciones y fotos del grupo,
  manteniendo las cuentas y otros grupos. Una interrupción de conexión deja tarea
  para continuar; no vuelve a habilitar el grupo. No hay restauración desde la app.

### 13.4. Baja propia de cuenta Firebase

**Usa B o C de prueba, no A propietaria de los ejemplos.** No se elimina la cuenta
Google del teléfono. Sí se elimina su identidad en esta aplicación; iniciar sesión
de nuevo no recupera sus accesos ni sus vínculos automáticamente.

- [ ] **CTA-01**. Con una cuenta que sea propietaria de un grupo, abre Perfil →
  Baja de cuenta. Debe exigir transferir o eliminar primero ese grupo. Cancelar
  Google no retira accesos ni borra fotos.
- [ ] **CTA-02**. Con B sin grupos propios y miembro de H, comprueba antes su
  persona vinculada, movimientos y fotos. Confirma su misma cuenta Google. Se
  retira la membresía; H y el historial siguen existiendo para A.
- [ ] **CTA-03**. La baja queda pendiente durante al menos treinta segundos para
  cerrar subidas previas. Reinicia la app y usa «Reanudar la baja de mi cuenta»;
  vuelve a verificar B. Sin conexión se muestra error y se conserva la intención.
- [ ] **CTA-04**. Al terminar, sale del acceso de B. Se retiran dispositivos,
  perfil y fotos de cuenta/miembro de B; se conserva la persona interna, su foto
  independiente, vínculo histórico y movimientos de H. A comprueba esa conservación.
  La entrega de push a dispositivos ya retirados no debe seguir activada.
- [ ] **CTA-05**. Si vuelves a entrar con Google B, se crea un acceso nuevo;
  solicita invitación y vinculación expresas. No reutilices el UID antiguo como
  si fuera la nueva identidad. No borrar marcadores de recuperación manualmente.

### 13.5. Caja agregada y trazabilidad ampliada

- [ ] **CAJ-01**. En M1 abre el dashboard; en M2 como admin registra 1,23 € en un
  grupo de prueba. El saldo total y la caja del mes se actualizan. Anula: regresan
  a su valor anterior. No esperan a los quince minutos del worker de avisos.
- [ ] **CAJ-02**. Con caja ya confirmada, desconecta Internet y vuelve al grupo:
  si la caché sigue disponible se muestra la última confirmación y su fecha. No se
  presenta como saldo actualizado. La caché puede ser eliminada por Android;
  sin dato previo no se inventa un cero. Reconecta y comprueba nueva confirmación.
- [ ] **CAJ-03**. Cambia cuenta/grupo y comprueba que no aparecen importes de
  otra cuenta. Si B pierde su membresía, no puede seguir consultando agregados.
- [ ] **TRA-01**. Crea/edita/reactiva una persona y crea/anula/corrige un movimiento;
  comprueba sus eventos antes/después. Renombra tu perfil y verifica que el nombre
  persiste al volver a entrar. Cambiar nombres no renombra personas/membresías.
- [ ] **TRA-02**. Cambia o retira una foto: auditoría de grupo registra intención y
  confirmación separadas. Un envío fallido puede dejar solo intención; no significa
  que la foto se guardara. La auditoría del perfil/foto de cuenta es privada, no se
  publica como historial administrativo del grupo.

## 14. Presentación, accesibilidad e iOS

- [ ] **UI-01**. Pantallas principales, formularios largos, teclado y botón atrás
  no cortan botones ni pierden cambios sin la confirmación prevista.
- [ ] **UI-02**. Aumenta tamaño de letra de Android; prueba pantalla pequeña y
  lector de pantalla. Textos, controles, importes y acciones siguen utilizables.
- [ ] **UI-03**. Activa quitar/reducir animaciones en Android: transiciones
  respetan esa preferencia; no son imprescindibles para entender la operación.
- [ ] **UI-04**. Estética oscura de referencia coherente en login, grupos,
  personas, movimientos e informes. El tema claro del sistema no implica que
  exista un selector de tema en producción; su revisión requiere la galería o
  una compilación adecuada, no marcarla aprobada por probar solo el oscuro.

**iOS sigue pendiente**: estos APK son Android. Compilar/probar iPhone requiere
Mac, Xcode, firma y configuración iOS; los push necesitan además APNs/capabilities.
Dos o tres Android no validan iOS.

## 15. Registrar resultados y terminar

Estados: **PENDIENTE**, **SUPERADO**, **FALLO**, **BLOQUEADO**, **NO REPRODUCIDO**.
No marques superado algo que solo has leído o cuyo botón estaba oculto: ocultar
UI no prueba por sí mismo que el servidor rechace una operación maliciosa. Las
pruebas de Rules en emulador tienen evidencia separada en los informes de fase.

Copia esta tabla a un archivo `docs/RESULTADOS_MOVILES_YYYY-MM-DD.md` cuando
empieces y añade una fila por caso o incidencia. No incluyas secretos.

| Caso | Estado | Móvil/cuenta/rol | Resultado real / evidencia | Fecha y APK |
| --- | --- | --- | --- | --- |
| AUTH-01 | PENDIENTE | M1 / A / owner | Sin ejecutar | — |
| MOV-01 | PENDIENTE | M1 / A / owner | Sin ejecutar | — |
| AVI-envío-real | PENDIENTE | M1/M2 | Worker activo; falta entrega física | — |

Ante un fallo: anota pantalla, acción, importe, grupo/ID del movimiento, conexión,
hora, estado esperado y observado. Una captura o vídeo corto ayuda; oculta correo
si vas a compartirlo fuera del proyecto. No repitas un envío de resultado incierto
antes de revisar historial/recuperación.

Al terminar, registra grupos y cuentas empleados y si dejaste roles, invitaciones
o preferencias cambiados. Puedes desactivar códigos y retirar avisos en móviles
de prueba. No limpies la base ni elimines movimientos como parte de estas pruebas.
Las copias de Rules/proyecto/APK **no son copias de documentos ni fotos**.

Referencias de estado: [roadmap](ROADMAP.md),
[servidor y enlaces](PHASE9_NOTIFICATIONS_AND_LINKS_VALIDATION.md),
[cliente de notificaciones](PHASE9_NOTIFICATION_CLIENT_VALIDATION.md),
[devoluciones](PHASE8_REFUNDS_VALIDATION.md),
[informes](PHASE10_QUOTA_REPORTS_VALIDATION.md) y
[fotos](SUPABASE_SETUP.md). Las pruebas físicas históricas no sustituyen los casos
multiusuario de esta guía, y esta guía no sustituye sus informes de validación.

## 16. Copias diarias locales para consultar sin conexión

Instala el APK del **23/10/2026** o posterior en cada móvil. No borres datos de la
app para instalarlo: eliminarías sus archivos locales. Cada teléfono debe hacer
su propia primera descarga. Este recorrido sigue **PENDIENTE** en móviles.

- [ ] **COP-01 — Primera copia en M1**. Con Internet, abre la cuenta A que ya
  pertenece a los grupos DEMO. En Inicio pulsa «Copias para consultar sin conexión»
  o «Ver copias guardadas en este móvil». Espera a que aparezca una entrada con
  fecha/hora real, grupos y documentos. No tienes que abrir antes Personas,
  Movimientos ni Informes para que se incluyan. Ver la caché no acredita una copia.
- [ ] **COP-02 — Comparar el contenido**. Pulsa «Ver copia guardada», entra en un
  grupo y compara saldo, personas, movimientos, cuotas e informes con el estado
  confirmado de ese instante. Anota la hora. Los cambios posteriores no aparecen
  en ella. Copiar datos no registra otro movimiento ni cambia sus importes.
- [ ] **COP-03 — Ninguna red**. Vuelve a datos actuales, activa modo avión y apaga
  también Wi-Fi. Cierra y vuelve a abrir el proceso conservando la sesión. Desde
  Inicio abre las copias: puedes navegar por la información descargada, incluso
  movimientos que no habías abierto online. La caché normal sigue siendo otra fuente.
- [ ] **COP-04 — Solo lectura**. Debe permanecer el aviso «COPIA GUARDADA · SOLO
  LECTURA» y su fecha. No hay registrar/anular/corregir, modificar personas/cuotas/
  roles, enviar invitaciones, cambiar fotos ni activar avisos. Consultar un aviso
  no lo marca leído. No resuelve ni reenvía operaciones económicas pendientes.
- [ ] **COP-05 — M2 y M3**. Repite con B y C. En una cuenta nueva sin grupos no se
  consume la copia diaria con un archivo vacío: entra por invitación y espera su
  copia. Un member no recibe auditoría/solicitudes generales de administración.
  Compartir el APK no transfiere archivos ni claves de M1 a M2.
- [ ] **COP-06 — Reconectar**. Recupera Internet con una copia abierta: no mezcla
  cambios nuevos. Pulsa «Volver a los datos actuales» y comprueba lo registrado
  desde otro móvil. La caché puede ser más reciente que la copia; esta no es una
  vista en vivo ni se impone automáticamente como la fuente más actual.
- [ ] **COP-07 — Días y retención**. Abre con conexión otro día real: nueva entrada,
  anterior conservada. Al reunir ocho días de capturas completas, quedan siete.
  Si no abriste ayer, se ofrece la última fecha real. No adelantes el reloj: el día
  procede del servidor y del calendario de Madrid. Días sin abrir con conexión
  no generan archivos. La primera captura diaria no se sobrescribe al reabrir.
- [ ] **COP-08 — Interrumpir descarga**. Preparando la copia de un día nuevo, corta
  la red. La anterior sigue abriéndose y no aparece otra parcial. Reconecta y usa
  «Comprobar copia de hoy». No se inventan ceros ni se sustituye una copia válida
  por una descarga fallida. Los permisos confirmados sí pueden retirar datos.
- [ ] **COP-09 — Acceso y cuentas**. Con B y copia guardada, A retira su acceso o
  lo degrada. En B, con conexión, comprueba la copia: se retira el grupo afectado
  del archivo anterior y los otros se conservan. El visor abierto debe bloquearse
  al confirmarse el cambio. Offline no se descubre una revocación nueva. Cierra
  sesión con conexión si lo exigen los avisos: sus copias se retiran y no aparecen
  al entrar con otra cuenta. Sin sesión restaurada no se inicia Google offline.
- [ ] **COP-10 — Fotos y limpieza**. Solo aparecen fotos disponibles en la caché;
  pueden faltar o ser posteriores. No se descargan todas. En el catálogo confirma
  «Eliminar las copias de esta cuenta en este móvil»: no cambia Firestore ni los
  archivos de M2/M3. Después necesita conexión para una copia nueva. Un archivo
  que no se abre se señala como error, sin presentar importes inventados.

No desinstales ni borres datos para simular desconexión: puedes perder copias y
claves. Son archivos privados cifrados de consulta, no el respaldo externo de
recuperación. La copia semanal del portátil sigue aplazada.
Evidencia y APK: [DAILY_OFFLINE_COPIES_VALIDATION.md](DAILY_OFFLINE_COPIES_VALIDATION.md).
