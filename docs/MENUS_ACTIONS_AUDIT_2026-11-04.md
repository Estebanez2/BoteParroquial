# Sonidos de menú, acciones y lectura del historial — D159–D160

## Entrega

- Desplegables conservan la familia anterior tap_1–4.wav. Nuevo evento semántico
  UiSound.menu para AppDropdown, AppExpandableRow, AppActionMenu, AppAvatarMenu,
  AppFloatingActions y AppMenuSurface. AppButton/AppIconButton admiten override
  semántico al abrir un menú, sin duplicar emisiones.
- Clics normales usan click_1–4.wav: sonidos propios más cálidos de 105 ms,
  variaciones aleatorias sin repetición inmediata, generados localmente. Cada
  familia mantiene su selector independiente. Back, nivel 75 % predeterminado,
  volumen elegido, silencio, apagado y zonas no interactivas quedan como D157.
- Retirado Gestionar este espacio. Debajo de Cuotas y etapas aparecen Editar grupo
  e Historial administrativo como AppNavigationTile, mismo componente/espaciado.
  Conservan el mismo permiso de gestión, rutas y controles de destino.

## Causa comprobada del historial vacío

Consulta remota de solo lectura, limitada a diez grupos y una página de 51 eventos
por grupo. Había tres grupos: Catequesis devolvió 21 eventos; los dos DEMO devolvieron
51 cada uno (no son sus totales). En Catequesis cinco eventos contenían
`after.occurredAt` de tipo Firestore Timestamp; en DEMO aparecía también en `before`.
El decoder admitía solo string/bool/int/null en esos mapas, por lo que un evento
válido de movimiento invalidaba toda la página y el contador seguía mostrando cero.
No es evidencia de ausencia de cambios, pérdida de datos ni caída del servidor.

Corrección:

- Admitir Timestamp en valores antes/después y convertirlo a DateTime UTC en el
  service; no introducir tipos Firebase en los modelos. Los detalles muestran
  Fecha efectiva y zona UTC explícita, además del importe entero/tipo legible.
- Mantener rechazo de mapas anidados/tipos no previstos y validación de rutas,
  grupo, orden, IDs y cursores. createdAt conserva segundos/nanosegundos para
  paginación; la conversión de valores de detalle no modifica el registro remoto.
- Lectura de escucha con await-for para traducir errores Firebase asíncronos.
- Cabecera sin eventos confirmados muestra Consultando cambios o Historial no
  disponible si hay fallo; cero solo se presenta como resultado confirmado.

No se han reconstruido eventos ni escrito datos. Sin cambios Rules, índices,
despliegues, permisos o secretos.

## Validación

Ocho casos dirigidos superados entre audit_history_test.dart y
sound_surface_and_preferences_test.dart. Incluyen la regresión Timestamp/importe,
rechazo de estructuras inválidas, páginas y revocación, búsqueda/detalle en UI,
sonido por acción y variantes por familia. flutter analyze: sin incidencias.

APK release 1.0.2+3 compilado (136,4 s), firma existente D156 comprobada con
apksigner y versión confirmada con aapt. 75.742.297 bytes, SHA-256 del APK:
`100f52c6b2314407c3eeec908bf809310be189e506e968951ffe3c16a7532b65`.
Ruta: `build/app/outputs/flutter-apk/app-release.apk`.
Usuario instala y
ejecuta; la consulta de operador no prueba permisos en móvil ni audibilidad física.

## Comprobar en móvil

1. Actualizar la release oficial con app-release.apk, sin desinstalarla.
2. Comparar clic de botón con abrir menú de cuenta, desplegable de mes y selección:
   normal cálido nuevo, menú con sonido anterior. Probar Volver, silencio y apagado.
3. Inicio → debajo de Cuotas y etapas, ver Editar grupo e Historial administrativo;
   no debe quedar Gestionar este espacio.
4. Catequesis → Historial administrativo → Actualizar historial. Deben mostrarse
   los registros disponibles según la cuenta actual; la consulta de operador vio
   21 en esta revisión. Abrir un Movimiento registrado y comprobar Fecha efectiva.
5. En DEMO comprobar Cargar más cambios y filtrado sobre los cargados. Si falla
   red/cuota/permisos, mostrar error/reintento, no afirmar cero registros.
