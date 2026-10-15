# BoteParroquial — Especificación funcional completa del producto

## 1. Propósito del documento

Este documento define la visión funcional completa de **BoteParroquial**.

Su objetivo es describir con suficiente detalle:

- qué problema resuelve la aplicación;
- qué entidades existen;
- qué puede hacer cada tipo de usuario;
- cómo funcionan los grupos;
- cómo se gestionan las personas;
- cómo funcionan las aportaciones y retiradas;
- cómo se calculan cuotas, pagos pendientes y adelantos;
- cómo deben funcionar las notificaciones;
- qué información debe mostrarse;
- qué reglas no deben romperse;
- qué funcionalidades pertenecen al producto final aunque todavía no estén implementadas.

Este documento describe el producto completo.

No significa que todas las funcionalidades aquí descritas deban implementarse inmediatamente.

El desarrollo debe seguir las fases definidas en:

```text
docs/ROADMAP.md
```

El alcance concreto del MVP actual se encuentra en:

```text
PRODUCT_SPEC.md
```

---

# 2. Visión general del producto

BoteParroquial es una aplicación móvil para gestionar botes de dinero compartidos entre grupos de personas.

Aunque el origen del proyecto sea un bote parroquial, el producto debe diseñarse de forma suficientemente general para poder utilizarse también en:

- parroquias;
- hermandades;
- asociaciones;
- grupos juveniles;
- equipos;
- comunidades;
- viajes;
- peñas;
- grupos de amigos;
- cualquier organización que mantenga un fondo común.

Cada grupo funciona conceptualmente como un bote independiente.

Un grupo dispone de:

- saldo;
- miembros registrados;
- personas internas;
- movimientos económicos;
- cuota mensual;
- historial;
- estadísticas;
- configuración;
- roles;
- invitaciones;
- notificaciones.

La aplicación no mueve dinero real.

No es una entidad bancaria ni procesa pagos.

La aplicación registra información sobre dinero gestionado externamente.

Por ejemplo:

```text
Antonio entrega 20 € en efectivo.
```

Un administrador registra:

```text
Antonio
+20 €
Cuota octubre
```

La aplicación actualiza el saldo y el historial.

---

# 3. Plataformas

La aplicación debe poder utilizarse en:

```text
Android
iOS
```

La implementación principal utilizará Flutter, por lo que la mayor parte del código deberá ser común a ambas plataformas.

Android será inicialmente la plataforma principal de desarrollo y pruebas.

No se deben tomar decisiones arquitectónicas que impidan posteriormente utilizar iOS.

---

# 4. Conceptos principales

La aplicación distingue claramente entre:

```text
Usuario
Grupo
Miembro
Persona interna
Movimiento
Cuota
Periodo de participación
Asignación
Notificación
Evento de auditoría
```

Estos conceptos no deben mezclarse.

---

# 5. Usuario

## 5.1. Definición

Un usuario es una persona que tiene una cuenta en BoteParroquial y puede iniciar sesión.

La cuenta se crea utilizando autenticación mediante Google.

Inicialmente no se utilizarán contraseñas propias de BoteParroquial.

---

## 5.2. Datos del usuario

Cada usuario tendrá como mínimo:

- identificador único;
- correo electrónico;
- nombre visible;
- foto de perfil;
- fecha de creación;
- última actualización;
- último inicio de sesión;
- configuración de notificaciones.

---

## 5.3. Primera entrada

La primera vez que el usuario inicia sesión:

1. Google autentica al usuario.
2. BoteParroquial obtiene su UID.
3. Se comprueba si existe un perfil.
4. Si no existe, se muestra el proceso inicial.
5. Se propone el nombre de Google.
6. Se propone la foto de Google.
7. El usuario puede mantener o cambiar esos datos.
8. Se crea su perfil.

El nombre y la foto utilizados por la aplicación pueden ser distintos de los de Google.

---

## 5.4. Edición del perfil

El usuario podrá cambiar posteriormente:

- nombre;
- foto;
- preferencias de notificaciones.

El usuario podrá consultar:

- correo;
- grupos;
- configuración.

El correo asociado a Authentication no se utilizará como ID interno.

---

# 6. Grupos

## 6.1. Definición

Un grupo representa un bote independiente.

Ejemplos:

```text
Bote Parroquia Amargura
Campamento 2027
Viaje Roma
Grupo Joven
Cofradía
```

Un usuario puede pertenecer a varios grupos.

---

## 6.2. Datos del grupo

Cada grupo tendrá:

- identificador;
- nombre;
- foto;
- descripción opcional;
- moneda;
- zona horaria;
- propietario;
- cuota mensual;
- estado;
- fecha de creación;
- configuración de invitaciones;
- miembros;
- personas internas;
- movimientos;
- estadísticas;
- historial administrativo.

---

# 7. Creación de un grupo

Un usuario autenticado podrá crear un grupo.

Durante la creación se solicitará:

- nombre obligatorio;
- foto opcional;
- descripción opcional;
- moneda;
- zona horaria;
- cuota mensual inicial;
- configuración inicial de invitaciones.

---

## 7.1. Moneda

La moneda se elige al crear el grupo.

Ejemplos:

```text
EUR
USD
GBP
```

Una vez creado el grupo, la moneda no podrá modificarse.

Esto evita inconsistencias con movimientos históricos.

---

## 7.2. Zona horaria

Cada grupo tendrá una zona horaria.

Ejemplo:

```text
Europe/Madrid
```

La zona horaria se utiliza para:

- determinar el mes actual;
- calcular finales de mes;
- enviar notificaciones;
- interpretar fechas;
- generar informes mensuales.

---

## 7.3. Propietario inicial

El usuario que crea el grupo se convierte automáticamente en:

```text
owner
```

Solo puede existir un owner por grupo.

---

## 7.4. Persona interna del propietario

Al crear un grupo, la aplicación deberá poder crear automáticamente una persona interna para el propietario.

Ejemplo:

```text
Usuario:
Alejandro Estebanez

Persona interna:
Alejandro Estebanez
```

Ambos quedan vinculados.

El propietario podrá editar posteriormente el nombre de la persona interna.

---

# 8. Miembros del grupo

## 8.1. Definición

Un miembro es un usuario autenticado que tiene acceso al grupo.

Los miembros tienen un rol.

Roles:

```text
owner
admin
member
```

---

# 9. Owner

## 9.1. Definición

El owner es el propietario del grupo.

Solo existe uno.

---

## 9.2. Permisos

Puede:

- consultar toda la información;
- modificar el grupo;
- gestionar personas;
- registrar ingresos;
- registrar retiradas;
- anular movimientos;
- corregir movimientos;
- gestionar miembros;
- ascender miembros;
- degradar administradores;
- expulsar usuarios;
- gestionar invitaciones;
- cambiar la cuota;
- consultar auditoría;
- generar informes;
- exportar;
- transferir la propiedad;
- eliminar el grupo.

---

## 9.3. Restricciones

El owner no puede:

- ser expulsado por otro usuario;
- ser degradado;
- perder el rol por una acción de un admin.

---

# 10. Admin

## 10.1. Definición

Un administrador puede gestionar el funcionamiento cotidiano del grupo.

---

## 10.2. Permisos

Puede:

- ver toda la información;
- registrar dinero;
- gestionar personas;
- editar personas;
- activar personas;
- inactivar personas;
- vincular usuarios;
- ascender miembros a admin;
- degradar administradores;
- expulsar miembros;
- gestionar invitaciones;
- aprobar entradas;
- cambiar cuota;
- consultar informes;
- exportar;
- consultar auditoría.

---

## 10.3. Restricciones

No puede:

- expulsar al owner;
- degradar al owner;
- transferir propiedad;
- eliminar el grupo;
- autoconvertirse en owner.

---

## 10.4. Requisito para ser administrador

Para ser administrador:

- debe pertenecer al grupo;
- debe tener una persona interna vinculada;
- esa persona debe estar activa.

Si deja de estar vinculada a una persona activa, perderá automáticamente el rol de administrador.

---

# 11. Member

Un miembro normal puede consultar información.

Puede:

- ver saldo;
- ver movimientos;
- ver personas;
- ver aportaciones;
- ver estadísticas;
- ver informes permitidos;
- compartir invitaciones;
- ver su vinculación;
- recibir notificaciones.

No puede:

- crear personas;
- editar personas;
- registrar dinero;
- modificar cuota;
- cambiar roles;
- expulsar miembros;
- cambiar configuración.

---

# 12. Invitaciones

Cada grupo tendrá un sistema de invitación.

Podrá existir:

- código;
- enlace.

Ejemplo conceptual:

```text
ABCD1234
```

o:

```text
https://boteparroquial.app/join/ABCD1234
```

---

## 12.1. Compartir

Cualquier miembro podrá compartir el enlace mediante:

- WhatsApp;
- correo;
- Telegram;
- copiar enlace;
- menú nativo del sistema.

---

## 12.2. Configuración por administradores

Los administradores podrán:

- activar invitaciones;
- desactivar invitaciones;
- regenerar código;
- exigir aprobación;
- permitir acceso automático.

---

## 12.3. Regenerar código

Al regenerar:

- el código anterior deja de funcionar;
- los miembros existentes no se ven afectados;
- se registra la acción en auditoría.

---

# 13. Solicitudes de entrada

Si el grupo requiere aprobación:

1. El usuario abre la invitación.
2. Ve información básica del grupo.
3. Solicita entrada.
4. Los administradores reciben notificación.
5. Un administrador acepta o rechaza.
6. Si acepta, entra como member.

---

# 14. Personas internas

## 14.1. Definición

Una persona interna es alguien sobre quien se registran aportaciones.

Una persona interna puede no tener cuenta en la aplicación.

Ejemplo:

```text
Persona:
Antonio Ruiz

Usuario registrado:
ninguno
```

---

## 14.2. Datos

Cada persona tendrá:

- ID;
- nombre;
- foto opcional;
- notas opcionales;
- estado;
- fecha de creación;
- usuario creador;
- usuario que realizó última modificación;
- periodos de participación;
- usuario vinculado opcional.

---

# 15. Diferencia entre miembro y persona

No deben confundirse.

Ejemplo:

```text
Miembro:
alejandro@gmail.com
```

es una cuenta con acceso.

```text
Persona:
Alejandro Estebanez
```

es una entidad financiera.

Un usuario puede entrar en la aplicación sin estar todavía vinculado a una persona.

---

# 16. Vinculación usuario-persona

Solo un administrador puede realizar vinculaciones.

Reglas:

```text
1 usuario → máximo 1 persona por grupo

1 persona → máximo 1 usuario
```

---

## 16.1. Cambio de vinculación

La vinculación puede cambiarse.

Toda modificación debe quedar registrada.

---

## 16.2. Usuarios pendientes

Cuando entra un nuevo miembro:

- puede quedar sin vinculación;
- los administradores reciben una notificación;
- aparecerá en una lista de pendientes.

---

# 17. Estado de una persona

Estados principales:

```text
active
inactive
```

Una persona activa puede generar obligaciones mensuales.

Una persona inactiva conserva todo su historial.

---

# 18. Periodos de participación

Una persona puede entrar y salir varias veces.

Por eso no debe existir una única fecha de alta y baja.

Debe poder tener varios periodos.

Ejemplo:

```text
01/01/2026 - 31/05/2026

01/09/2026 - actual
```

Las cuotas solo se generan durante periodos computables.

---

# 19. Primer mes computable

Al crear una persona se podrá seleccionar desde qué mes debe empezar a pagar.

Ejemplo:

```text
Persona creada:
octubre 2026

Primer mes computable:
octubre 2026
```

o:

```text
Primer mes computable:
junio 2026
```

En el segundo caso aparecerán cuotas atrasadas.

---

# 20. Inactivar una persona

Al inactivar una persona:

- mantiene historial;
- mantiene estadísticas;
- no genera nuevas cuotas;
- deja de recibir recordatorios;
- puede reactivarse.

---

# 21. Reactivación

Al reactivar se crea un nuevo periodo.

El administrador elige desde qué mes vuelve a computar.

---

# 22. Eliminación de personas

Personas con movimientos:

```text
NO se eliminan
```

Se inactivan.

Personas sin historial podrían enviarse a papelera.

---

# 23. Cuota mensual

Cada grupo tendrá una cuota mensual general.

Ejemplo:

```text
20 € al mes
```

La cuota es igual para todas las personas activas.

---

# 24. Cambio de cuota

Los administradores pueden cambiarla.

Nunca debe sobrescribirse simplemente el valor histórico.

Debe guardarse una regla temporal.

Ejemplo:

```text
enero - junio:
20 €

desde julio:
25 €
```

---

# 25. Estado mensual

Por cada persona y mes se podrá calcular un estado.

Ejemplos:

```text
paid
partial
pending
overpaid
futurePaid
notApplicable
```

---

# 26. Aportaciones

Una persona puede:

- pagar una sola vez;
- pagar varias veces;
- pagar exactamente la cuota;
- pagar menos;
- pagar más;
- pagar meses atrasados;
- pagar meses futuros.

---

# 27. Movimiento económico

Cada operación de dinero se representa como un movimiento.

Tipos:

```text
income
withdrawal
```

Estados:

```text
active
cancelled
corrected
```

---

# 28. Ingreso

Solo owner/admin.

Campos:

- persona;
- cantidad;
- fecha efectiva;
- descripción opcional;
- creador;
- fecha de creación.

---

## 28.1. Ejemplo

```text
Persona:
Antonio

Cantidad:
20 €

Fecha:
15/10/2026

Descripción:
Cuota octubre

Registrado por:
María
```

---

# 29. Retirada

Solo owner/admin.

Campos:

- cantidad;
- fecha;
- motivo;
- persona opcional;
- usuario que registra.

---

## 29.1. Retirada general

Ejemplo:

```text
50 €
Compra de material
```

sin persona.

---

## 29.2. Retirada asociada

Ejemplo:

```text
Pablo
30 €
Devolución
```

---

# 30. Saldo

Fuente de verdad:

```text
total ingresos activos
-
total retiradas activas
```

No se debe permitir editar manualmente el saldo como si fuera un número aislado.

---

# 31. Saldo negativo

Permitido.

Debe mostrarse advertencia.

Ejemplo:

```text
Saldo actual:
50 €

Retirada:
80 €

Resultado:
-30 €
```

Debe existir confirmación adicional.

---

# 32. Correcciones de movimientos

Los movimientos económicos históricos no se editan libremente.

No se debe hacer:

```text
50 € → cambiar directamente a 20 €
```

---

# 33. Anulación

Un movimiento puede cambiar:

```text
active → cancelled
```

Debe guardarse:

- motivo;
- usuario;
- fecha.

---

# 34. Corrección

Un movimiento puede cambiar:

```text
active → corrected
```

Se crea un nuevo movimiento sustituto.

Ejemplo:

```text
Original:
50 €

Corrección:
20 €
```

El original queda conservado.

---

# 35. Asignaciones mensuales

Para saber a qué meses corresponde un ingreso existirán `allocations`.

Ejemplo:

```text
Ingreso:
50 €

Asignaciones:

20 € → mayo
20 € → junio
10 € → julio
```

---

# 36. Asignación automática

La aplicación podrá proponer:

1. deuda más antigua;
2. siguientes meses pendientes;
3. mes actual;
4. meses futuros;
5. crédito sin asignar.

---

# 37. Asignación manual

El administrador también puede indicar explícitamente:

```text
20 € → noviembre

20 € → diciembre
```

---

# 38. Crédito futuro

Dinero asignado a meses futuros.

Debe poder distinguirse del pago del mes actual.

---

# 39. Crédito sin asignar

Dinero recibido que todavía no está asociado a ningún mes.

Cuenta en el bote.

No marca cuotas como pagadas hasta ser asignado.

---

# 40. Resumen individual

Cada persona tendrá una ficha.

Mostrará:

- total aportado;
- total retirado;
- neto;
- cuota acumulada esperada;
- cantidad asignada;
- diferencia;
- crédito futuro;
- crédito sin asignar;
- meses pagados;
- meses pendientes;
- historial.

---

# 41. Diferencia de cuota

Conceptualmente:

```text
aportaciones asignadas hasta hoy
-
cuotas esperadas hasta hoy
```

Resultado:

```text
positivo
al día
negativo
```

---

# 42. Salida de un usuario del grupo

Si un miembro abandona:

- pierde acceso;
- la persona interna permanece;
- el historial permanece;
- la vinculación se conserva como histórico;
- el administrador puede decidir si la persona sigue activa.

---

# 43. Expulsión

Admin/owner puede expulsar miembros.

El owner no puede ser expulsado.

Al expulsar:

- usuario pierde acceso;
- la persona no desaparece;
- movimientos no cambian;
- se registra auditoría.

---

# 44. Transferencia de propiedad

El owner puede transferir propiedad.

El receptor debe:

- ser miembro;
- estar vinculado a una persona activa.

Debe requerir confirmación fuerte.

---

# 45. Owner que quiere salir

No puede salir directamente.

Debe:

```text
transferir propiedad
```

o:

```text
eliminar grupo
```

---

# 46. Eliminación del grupo

Solo owner.

Debe ser irreversible.

Antes de confirmar mostrar:

- nombre;
- saldo;
- miembros;
- personas;
- número de movimientos;
- advertencia.

Debe recomendar exportar los datos.

---

# 47. Confirmación fuerte

Puede utilizarse:

- reautenticación Google;
- confirmación escrita;
- correo;
- combinación de varias.

---

# 48. Eliminación final

Al confirmar:

- bloquear operaciones;
- invalidar invitaciones;
- eliminar accesos;
- eliminar grupo;
- redirigir miembros a inicio.

---

# 49. Notificaciones

Existirán notificaciones:

```text
push
in-app
```

---

# 50. Recordatorio mensual

Si una persona no alcanza la cuota:

```text
7 días antes de final de mes
```

y:

```text
1 día antes
```

---

# 51. Ejemplo de recordatorio

```text
Tu aportación de octubre está pendiente.

Cuota:
20 €

Aportado:
10 €

Pendiente:
10 €
```

---

# 52. Personas sin usuario

Si una persona no tiene usuario vinculado:

- no puede recibir push;
- los administradores reciben aviso.

---

# 53. Otras notificaciones

- solicitud de acceso;
- miembro aceptado;
- miembro nuevo;
- usuario sin vincular;
- vinculación realizada;
- nombramiento admin;
- pérdida de rol;
- ingreso asociado;
- retirada asociada;
- cambio de cuota;
- transferencia de propiedad;
- movimiento anulado;
- invitación regenerada.

---

# 54. Preferencias de notificación

El usuario podrá desactivar determinadas notificaciones informativas.

Las notificaciones económicas importantes pueden estar activadas por defecto.

---

# 55. Dashboard del grupo

Pantalla principal del grupo.

Debe mostrar:

- saldo actual;
- ingresos del mes;
- retiradas del mes;
- cantidad esperada;
- cantidad aportada;
- cantidad pendiente;
- personas al día;
- personas pendientes;
- actividad reciente.

---

# 56. Historial económico

Pantalla separada.

Incluye:

- ingresos;
- retiradas;
- anulaciones;
- correcciones.

Filtros:

- fecha;
- persona;
- tipo;
- estado;
- creador.

---

# 57. Historial administrativo

Separado del económico.

Ejemplos:

```text
María creó a Antonio.

Alejandro ascendió a Pablo a admin.

Pablo cambió la cuota de 20 € a 25 €.

María vinculó a Lucía con lucia@gmail.com.
```

---

# 58. Evento de auditoría

Cada evento deberá poder registrar:

- acción;
- usuario;
- fecha;
- entidad afectada;
- valor anterior;
- valor nuevo;
- motivo opcional.

---

# 59. Estadísticas mensuales

Mostrar:

- saldo inicial;
- ingresos;
- retiradas;
- saldo final;
- cuotas esperadas;
- aportado;
- pendiente;
- porcentaje de cumplimiento;
- personas pagadas;
- personas parciales;
- personas pendientes.

---

# 60. Estadísticas trimestrales

Mostrar:

- tres meses;
- evolución;
- total ingresado;
- total retirado;
- saldo;
- cumplimiento medio;
- comparación con trimestre anterior.

---

# 61. Estadísticas anuales

Mostrar:

- evolución mensual;
- total anual;
- gastos;
- saldo inicial/final;
- aportaciones por persona;
- cuotas esperadas;
- diferencias;
- meses pendientes.

---

# 62. Informe individual

Debe permitir consultar:

- total histórico;
- total retirado;
- neto;
- esperado;
- aportado;
- diferencia;
- meses;
- evolución;
- periodos.

---

# 63. Gráficos

Ejemplos futuros:

- evolución del saldo;
- aportaciones por mes;
- ingresos vs retiradas;
- porcentaje de cumplimiento;
- evolución individual.

---

# 64. Exportación

Owner/admin podrá exportar.

Formatos:

```text
PDF
CSV
Excel
```

---

# 65. PDF

Puede incluir:

- grupo;
- periodo;
- saldo;
- resumen;
- tabla;
- movimientos;
- estadísticas.

---

# 66. Excel

Posibles hojas:

```text
Resumen
Personas
Movimientos
Cuotas
Asignaciones
Miembros
Auditoría
```

---

# 67. CSV

Adecuado para exportaciones simples.

---

# 68. Papelera

Determinados elementos pueden mantenerse temporalmente.

Periodo:

```text
10 días
```

---

# 69. Elementos compatibles

Ejemplos:

- persona sin historial;
- configuraciones eliminables;
- ciertos elementos no financieros.

---

# 70. Elementos no compatibles

No usar papelera para:

- movimientos;
- grupos eliminados definitivamente;
- personas con historial.

---

# 71. Seguridad funcional

La aplicación no debe basar permisos únicamente en UI.

Ejemplo incorrecto:

```text
ocultar botón "Añadir dinero"
```

no es seguridad.

---

# 72. Seguridad real

Debe existir validación en backend/reglas para:

- autenticación;
- membresía;
- rol;
- grupo;
- campos;
- transiciones;
- relaciones.

---

# 73. Protección contra escalada

Un cliente no debe poder modificar:

```text
role = member
```

a:

```text
role = owner
```

directamente.

---

# 74. Protección económica

La aplicación debe impedir:

- cantidades negativas inválidas;
- movimientos sin tipo;
- estados imposibles;
- edición histórica no autorizada;
- movimientos entre grupos;
- referencias a personas de otro grupo.

---

# 75. Dinero

Todos los importes se almacenan como enteros.

Ejemplo:

```text
20,50 € = 2050
```

No usar `double` como fuente financiera.

---

# 76. Moneda

Cada grupo utiliza una única moneda.

No se suman importes de monedas distintas.

---

# 77. Fechas

Distinguir:

```text
createdAt
```

momento de registro,

de:

```text
occurredAt
```

fecha económica del movimiento.

---

# 78. Tiempo de servidor

Metadatos críticos deben usar hora confiable del servidor siempre que sea posible.

---

# 79. Funcionamiento offline

La aplicación podrá consultar información cacheada.

Sin embargo, las operaciones económicas sensibles pueden requerir conexión.

Debe priorizarse consistencia frente a permitir cualquier operación offline.

---

# 80. Concurrencia

Dos administradores pueden utilizar el grupo simultáneamente.

Las operaciones deben evitar:

- saldo incorrecto;
- dobles escrituras;
- doble contabilización;
- estados inconsistentes.

Cuando sea necesario se utilizarán:

- transacciones;
- batches;
- backend seguro.

---

# 81. Sincronización

Los cambios deben propagarse entre dispositivos.

Ejemplo:

```text
Admin A registra +20 €.
```

Admin B debe ver el nuevo movimiento sin reiniciar la aplicación.

---

# 82. Escalabilidad

La arquitectura debe permitir pasar de:

```text
2 administradores
1 grupo
20 personas
```

a:

```text
muchos grupos
muchos miembros
miles de movimientos
```

sin rehacer todo el modelo.

---

# 83. Rendimiento

Cuando los datos crezcan se utilizarán:

- paginación;
- índices;
- resúmenes;
- agregados;
- consultas acotadas.

No leer todo el historial para mostrar siempre el dashboard.

---

# 84. Resúmenes precalculados

En el futuro se podrán almacenar agregados como:

```text
monthlySummaries
```

pero serán derivados.

La fuente de verdad sigue siendo el historial.

---

# 85. Búsquedas

Será útil buscar:

- persona;
- movimiento;
- descripción;
- fecha.

---

# 86. Filtros

Historial:

- mes;
- año;
- persona;
- tipo;
- estado;
- autor.

---

# 87. Ordenación

Personas:

- nombre;
- total;
- deuda;
- estado.

Movimientos:

- fecha;
- cantidad.

---

# 88. Experiencia del usuario

La aplicación debe ser simple.

Las operaciones principales no deberían requerir navegar por muchas pantallas.

Ejemplo:

```text
Grupo
→ Añadir ingreso
→ Persona
→ Cantidad
→ Confirmar
```

---

# 89. Confirmaciones

Acciones normales:

confirmación ligera.

Acciones peligrosas:

confirmación fuerte.

---

# 90. Acciones peligrosas

Ejemplos:

- saldo negativo;
- expulsar miembro;
- degradar admin;
- transferir owner;
- eliminar grupo;
- anular movimiento.

---

# 91. Accesibilidad

Debe utilizar:

- textos legibles;
- contraste adecuado;
- botones claros;
- soporte de escalado de fuente;
- labels adecuados.

---

# 92. Diseño

Material moderno, limpio y sencillo.

El diseño no debe impedir uso rápido.

Información económica relevante debe ser visible de forma clara.

---

# 93. Estados vacíos

Ejemplos:

```text
Todavía no hay personas.

No hay movimientos este mes.

No tienes grupos.
```

Mostrar acciones relevantes.

---

# 94. Errores

Los errores deben ser comprensibles.

No mostrar al usuario:

```text
FirebaseException: permission-denied
```

Mostrar:

```text
No tienes permisos para realizar esta acción.
```

---

# 95. Historial y trazabilidad

Una prioridad del producto es poder saber:

```text
qué pasó
quién lo hizo
cuándo
a quién afectó
```

---

# 96. Datos que nunca deben perderse silenciosamente

- movimientos;
- correcciones;
- anulaciones;
- cambios de rol;
- cambios de cuota;
- transferencias;
- historial de personas.

---

# 97. Configuración del grupo

Owner/admin podrán modificar:

- nombre;
- foto;
- descripción;
- cuota;
- invitaciones.

No modificar:

```text
currency
```

una vez creado.

---

# 98. Cierre de sesión

El usuario puede cerrar sesión.

No elimina:

- perfil;
- grupos;
- membresías;
- datos.

---

# 99. Eliminación de cuenta

Debe diseñarse cuidadosamente.

Antes de eliminar una cuenta:

- resolver grupos de los que sea owner;
- conservar trazabilidad;
- anonimizar o mantener referencias históricas según política futura.

---

# 100. Servicios técnicos futuros

La aplicación completa podrá utilizar:

```text
Firebase Authentication
Cloud Firestore
Cloud Storage
Cloud Functions
Cloud Scheduler
Firebase Cloud Messaging
App Check
Crashlytics
```

No todos son necesarios desde el MVP.

---

# 101. Cloud Storage

Se utilizará cuando se permita guardar imágenes personalizadas.

Ejemplos:

- perfil;
- grupo;
- persona.

---

# 102. Cloud Functions

Se introducirá cuando existan operaciones que deban ejecutarse de forma segura en servidor.

Ejemplos:

- operaciones económicas complejas;
- transferencia de propiedad;
- eliminación segura;
- procesamiento de resúmenes;
- notificaciones.

---

# 103. Cloud Scheduler

Para tareas programadas.

Ejemplo:

```text
revisar diariamente cuotas pendientes
```

---

# 104. Firebase Cloud Messaging

Para notificaciones push.

---

# 105. App Check

Para reducir tráfico ilegítimo contra el backend.

---

# 106. Crashlytics

Para detectar fallos en producción.

---

# 107. Fases conceptuales

La aplicación completa puede evolucionar aproximadamente así:

```text
Foundation
Authentication
Groups
Persons
Movements
Dashboard
Security
Invitations
Quotas
Notifications
Reports
Audit
Exports
Polish
```

---

# 108. Principios de producto

## 108.1. Transparencia

Todos deben poder entender dónde está el dinero.

---

## 108.2. Trazabilidad

Nunca ocultar cambios históricos importantes.

---

## 108.3. Simplicidad

Registrar una aportación debe ser rápido.

---

## 108.4. Seguridad

Un usuario no debe modificar datos para los que no tiene permisos.

---

## 108.5. Escalabilidad

El MVP no debe impedir el producto completo.

---

## 108.6. Integridad financiera

Nunca sacrificar consistencia de los datos por comodidad.

---

# 109. Reglas invariantes

Estas reglas deben considerarse fundamentales.

1. Cada movimiento pertenece a un grupo.
2. Cada persona pertenece a un grupo.
3. Los roles pertenecen a una membresía.
4. Solo existe un owner por grupo.
5. Owner no puede ser expulsado.
6. Admin no puede modificar al owner.
7. El dinero se guarda en enteros.
8. Los movimientos no se eliminan.
9. Las correcciones conservan el original.
10. Las personas con historial se inactivan.
11. La moneda no cambia después de crear el grupo.
12. Las cuotas históricas no se sobrescriben.
13. Un usuario solo puede estar vinculado a una persona por grupo.
14. Una persona solo puede estar vinculada a un usuario.
15. Solo owner/admin registran movimientos.
16. Todos los miembros pueden consultar los datos económicos del grupo.
17. El saldo se deriva de movimientos válidos.
18. Las operaciones sensibles deben validarse fuera de la UI.
19. El historial económico y administrativo son diferentes.
20. El propietario debe transferir su rol antes de abandonar.

---

# 110. Estado final esperado del producto

Cuando el producto completo esté implementado, un usuario podrá:

1. instalar la aplicación;
2. iniciar sesión con Google;
3. crear su perfil;
4. crear o unirse a un grupo;
5. consultar el saldo;
6. ver personas;
7. consultar aportaciones;
8. revisar estadísticas;
9. recibir notificaciones;
10. compartir invitaciones.

Un administrador podrá:

1. gestionar personas;
2. registrar ingresos;
3. registrar retiradas;
4. corregir errores;
5. cambiar cuotas;
6. administrar miembros;
7. revisar pendientes;
8. generar informes;
9. exportar datos;
10. consultar auditoría.

El owner podrá además:

1. transferir propiedad;
2. realizar acciones administrativas definitivas;
3. eliminar el grupo.

La aplicación deberá permitir que todas estas acciones sean coherentes entre varios móviles y que el historial económico permanezca fiable a lo largo del tiempo.