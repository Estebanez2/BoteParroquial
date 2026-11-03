# Laboratorio temporal de animaciones — 03/11/2026

Continuación D130: el usuario ya elige efectos y confirma CONSERVAR el laboratorio
por ahora. La integración en el producto se registra en
[SELECTED_MOTION_2026-11-03.md](SELECTED_MOTION_2026-11-03.md). Esta página conserva
el catálogo y su entrega original; la retirada requiere una indicación posterior.

## Alcance y entrada (D129)

El usuario no está convencido con las animaciones actuales y solicita un apartado
temporal para comparar alternativas antes de elegir las definitivas. Decide un
acceso visible **Laboratorio de animaciones** en Inicio, en debug/profile y oculto
en release. No es la galería general ni se añade esa galería a producción.

Ruta autenticada: `/testing/motion`. Biblioteca temporal:
`lib/design_system/lab/`. No usa Firebase, providers de negocio ni repositorios;
el catálogo solo administra estado visual efímero. El contenido de destino es
ficticio. Ninguna elección modifica las animaciones globales, paleta, datos o
permisos. No se persiste una selección: el usuario indicará los códigos y destinos.
La implementación D128 queda provisional, no aprobada por abrir este laboratorio.

El menú Añadir conserva el signo + para crear y muestra **llave** en Entrar con
código. AppFloatingActions admite iconos por opción, sin decidir acciones ni roles.
Este ajuste es independiente y debe conservarse al retirar el laboratorio.

## Qué permite comparar

Catálogo representativo de 40 opciones, con etiquetas estables dentro de esta
entrega; no supone enumerar todas las combinaciones matemáticas de animaciones.

| Pantallas | Variantes |
| --- | --- |
| P01–P07 | Sin efecto, fundido, cuatro direcciones y avance corto |
| P08–P09 | Eje compartido horizontal/vertical, incluida la salida del origen |
| P10–P13 | Zoom normal/profundo/desde grande y fundido secuencial |
| P14–P16 | Giro plano y giros 3D sobre ambos ejes |
| P17–P21 | Círculo, revelados lateral/vertical, diagonal y entrada elástica |
| P22–P24 | Estilo Cupertino y transiciones Zoom/FadeForwards del SDK |
| Botones | Variantes |
| B01–B06 | Presión, crecimiento, salto, sacudida, balanceo y giro del icono |
| B07–B12 | Brillo, onda, barrido, elasticidad, elevación y cambio de icono |
| Barra | Variantes |
| N01–N04 | Indicador suave, elástico, fundido y línea viajera |

Slider común de 150–1.000 ms, con valor inicial de 400 ms. P01 es instantánea.
Cada pantalla abre el mismo contenido para facilitar la comparación; Atrás invierte
la transición. El origen escucha el efecto elegido para demostrar también las
salidas compartidas y nativas. Un Navigator local con NavigatorPopHandler conserva
Atrás dentro del laboratorio antes de salir a Inicio.

Tres categorías siempre accesibles en la barra inferior: Pantallas, Botones y
Barra. El contenido y los controles superiores se desplazan para admitir texto
ampliado. Los botones experimentales no añaden encima el pulso global de AppButton;
ejecutan su propio efecto, finito y sin repetición continua. Se cancelan al
desmontar y evitan dobles activaciones durante el ciclo. El contador de pruebas
es local a la pantalla; las barras solo cambian su muestra.

Se respetan tema, fuente y movimiento reducido. No se desactiva silenciosamente
la accesibilidad del móvil: si está activa, se informa y los efectos son estáticos.
No hay blur, fotos descargadas ni nuevas dependencias. No se atribuye fluidez a
un efecto sin comprobarlo en dispositivo; el catálogo incluye opciones expresivas
para comparar, no recomendaciones de rendimiento.

## Referencias consultadas

- [PageRouteBuilder y animaciones de rutas de Flutter](https://docs.flutter.dev/cookbook/animation/page-route-animation).
- [Curvas de animación del SDK](https://api.flutter.dev/flutter/animation/Curves-class.html).
- [Hero y límites de transiciones compartidas](https://api.flutter.dev/flutter/widgets/Hero-class.html).

Se usan primitivas del SDK y renderizadores de prueba propios; no se instala una
librería ni se adopta automáticamente su estilo para la app.

## Validación

Cuatro casos dirigidos distintos comprobados:

1. Menú Añadir: llave y selección de la opción de código.
2. Todas las variantes de ruta: abrir y volver, también con el origen compartido.
3. Los doce botones: efecto finito, doble toque y reducción de movimiento.
4. Laboratorio: cambio de duración/categoría, entrada y Atrás local, barra y
   contador; texto ampliado al 160 % en 360×800.

Se corrigieron la firma del callback void de NavigatorPopHandler y la renovación
del estado visual dentro del Navigator local. Los fallos de observación del test
se resolvieron desplazando a la vista los controles virtualizados y esperando al
frame de layout antes de tocar. Se repitieron solo los casos afectados. El log
inicial `.dart_tool/motion-lab-tests.log` conserva la primera ejecución con el
fallo de integración; `.dart_tool/motion-lab-integration.log` registra su cierre.
No se ejecutó la suite completa ni se conectó un móvil.

`flutter analyze --no-pub`: sin incidencias. Compilaciones debug y profile
correctas. APK finales de esta entrega:

- `build/app/outputs/flutter-apk/app-debug.apk`, SHA-256:
  `8ee30911b01aa9ab07fc22661bda994ab52b3723a1b9c6b8566c6cd9fc0d01e4`.
- `build/app/outputs/flutter-apk/app-profile.apk`, SHA-256:
  `72a14ac8c66b5651b7cb1441f696b9301f91414c0588a67ea8f775c129200e8b`.

Usar profile para comparar en móvil sin la sobrecarga de debug. No se han
instalado ni arrancado estos APK en dispositivos. Logs finales de compilación:
`.dart_tool/motion-lab-analyze.log`, `motion-lab-debug.log`, `motion-lab-profile.log`.
La ausencia en release se establece por guardas constantes en acceso, ruta y
pantalla; no se ha compilado ni instalado una versión release en esta entrega.

## Retirada aplazada por el usuario

No retirarlo todavía: el usuario pide conservarlo incluso después de la elección
D130. Cuando solicite retirarlo, conservar las implementaciones elegidas en App*
y retirar:

- El bloque/import del laboratorio en HomeScreen.
- Su ruta/import condicional en app/router.dart.
- `lib/design_system/lab/` y `test/motion_lab_test.dart`, conservando o trasladando
  la comprobación de la llave si sigue siendo útil.

Actualizar este informe, AGENTS, README, DESIGN_SYSTEM, DECISIONS, ROADMAP y la guía.
Conservar el mapa de iconos y la llave, las restricciones de acceso, el visor de
copias y el resto del producto. No hay datos remotos que limpiar por esta tarea.

Prueba física pendiente: **LAB-01–LAB-05**, sección 21 de GUIA_PRUEBAS_MOVILES.md.
El usuario instala/ejecuta. No hay aprobación visual ni medición física de FPS,
ni comprobación iOS acreditadas.
