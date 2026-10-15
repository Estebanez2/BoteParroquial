BoteParroquial — MVP

Este documento define únicamente el MVP inicial.

La aplicación completa está definida en:

docs/FULL_PRODUCT_SPEC.md

Objetivo del MVP

Permitir que unos pocos administradores gestionen conjuntamente un bote de dinero desde varios móviles.

Todos los administradores deben consultar los mismos datos mediante Firebase.

Aunque inicialmente exista un único bote utilizado por pocas personas, ninguna parte de la arquitectura debe asumir que solo existirá un grupo.

Login

El usuario inicia sesión mediante Google utilizando Firebase Authentication.

No existen contraseñas propias de BoteParroquial.

Una cuenta autenticada no obtiene automáticamente acceso administrativo.

Los permisos dependen de su membresía en cada grupo.

Grupos

El modelo debe permitir varios grupos.

Durante el MVP puede utilizarse inicialmente un solo grupo.

Cada grupo representa un bote independiente.

Contendrá:

miembros;

personas;

movimientos;

configuración propia.

Personas

Los administradores pueden:

consultar personas;

crear personas;

editar personas;

activar personas;

inactivar personas.

Una persona interna no tiene por qué tener una cuenta de la aplicación.

Las personas con movimientos económicos no se eliminan.

Ingresos

Un administrador puede registrar:

persona;

cantidad;

fecha efectiva;

descripción opcional.

También se almacena automáticamente:

usuario que registra el movimiento;

fecha de creación.

El dinero se almacena en céntimos.

Retiradas

Un administrador puede registrar:

cantidad;

fecha;

motivo;

persona opcional.

Una retirada puede pertenecer a una persona o al grupo en general.

Movimientos

Tipos:

income
withdrawal

Estados preparados:

active
cancelled
corrected

No se eliminan movimientos económicos directamente.

Saldo

Se calcula como:

ingresos activos - retiradas activas

No existe un saldo editable manualmente como fuente de verdad.

Historial

Debe permitir consultar movimientos ordenados cronológicamente.

Cada movimiento mostrará como mínimo:

tipo;

cantidad;

persona;

fecha;

descripción;

creador;

estado.

Roles del modelo

Aunque el MVP inicialmente utilice administradores, el modelo admite:

owner
admin
member

Los permisos completos de la futura versión están definidos en docs/FULL_PRODUCT_SPEC.md.

Fuera del MVP inicial

No implementar todavía salvo fase específica:

cuotas mensuales;

pagos atrasados;

pagos adelantados;

notificaciones;

estadísticas avanzadas;

exportaciones;

invitaciones completas;

auditoría avanzada;

Cloud Functions;

Cloud Storage.