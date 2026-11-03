/// Temporary comparison catalogue. No persisted choice or application defaults.
enum LabPageEffect {
  none('P01', 'Sin transición', 'Referencia instantánea para comparar.'),
  fade('P02', 'Fundido', 'La nueva pantalla aparece gradualmente.'),
  right('P03', 'Desde la derecha', 'Deslizamiento horizontal completo.'),
  left('P04', 'Desde la izquierda', 'Deslizamiento en el sentido contrario.'),
  up('P05', 'Desde abajo', 'La pantalla sube hasta ocupar su lugar.'),
  down('P06', 'Desde arriba', 'La pantalla baja hasta ocupar su lugar.'),
  shortSlide(
    'P07',
    'Avance corto y fundido',
    'Desplazamiento corto, sin recorrer todo el ancho.',
  ),
  sharedX(
    'P08',
    'Eje compartido horizontal',
    'La pantalla anterior acompaña el desplazamiento.',
  ),
  sharedY(
    'P09',
    'Eje compartido vertical',
    'Las dos pantallas se desplazan verticalmente.',
  ),
  zoom('P10', 'Zoom de acercamiento', 'Crece desde el 80 % con fundido.'),
  deepZoom('P11', 'Zoom profundo', 'Crece desde el 50 % con fundido.'),
  zoomOut(
    'P12',
    'Zoom desde grande',
    'Se reduce hasta encajar en la pantalla.',
  ),
  fadeThrough(
    'P13',
    'Fundido secuencial',
    'Sale el contenido y entra el siguiente con escala.',
  ),
  turn('P14', 'Giro y zoom', 'Un giro plano acompaña el crecimiento.'),
  flipX(
    'P15',
    'Giro 3D horizontal',
    'La pantalla se abre sobre su eje vertical.',
  ),
  flipY(
    'P16',
    'Giro 3D vertical',
    'La pantalla se abre sobre su eje horizontal.',
  ),
  circle('P17', 'Revelado circular', 'Un círculo se expande desde el centro.'),
  wipeX(
    'P18',
    'Revelado lateral',
    'El contenido se descubre de izquierda a derecha.',
  ),
  wipeY(
    'P19',
    'Revelado vertical',
    'El contenido se descubre de abajo hacia arriba.',
  ),
  diagonal('P20', 'Entrada diagonal', 'Deslizamiento diagonal con fundido.'),
  spring('P21', 'Entrada elástica', 'Una entrada lateral con rebote.'),
  ios('P22', 'Estilo iOS', 'Transición Cupertino del SDK.'),
  androidZoom(
    'P23',
    'Zoom Android',
    'Transición ZoomPageTransitionsBuilder del SDK.',
  ),
  androidForward('P24', 'Avance Android', 'Transición FadeForwards del SDK.');

  const LabPageEffect(this.id, this.title, this.description);
  final String id, title, description;
}

enum LabButtonEffect {
  press('B01', 'Presión', 'Se hunde y vuelve a su tamaño.'),
  pop('B02', 'Salto de escala', 'Crece con un pequeño rebote.'),
  bounce('B03', 'Salto vertical', 'Salta y vuelve al punto de partida.'),
  shake('B04', 'Sacudida', 'Vibra hacia los lados.'),
  tilt('B05', 'Balanceo', 'Oscila sobre su centro.'),
  spin('B06', 'Vuelta del icono', 'El icono da una vuelta completa.'),
  shine('B07', 'Banda de brillo', 'Un destello recorre el botón.'),
  ring('B08', 'Onda exterior', 'Se expande una onda alrededor del botón.'),
  fill('B09', 'Barrido de color', 'Un segundo acento cruza la superficie.'),
  squish('B10', 'Elástico', 'Se estira y recupera su forma.'),
  lift('B11', 'Elevación', 'Sube suavemente y vuelve.'),
  iconSwap(
    'B12',
    'Icono de confirmación',
    'El icono cambia y recupera el original.',
  );

  const LabButtonEffect(this.id, this.title, this.description);
  final String id, title, description;
}

enum LabBarEffect {
  glide('N01', 'Deslizamiento suave'),
  spring('N02', 'Indicador elástico'),
  fade('N03', 'Cambio por fundido'),
  underline('N04', 'Línea viajera');

  const LabBarEffect(this.id, this.title);
  final String id, title;
}
