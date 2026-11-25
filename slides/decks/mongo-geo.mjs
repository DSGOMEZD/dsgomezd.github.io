export default {
  file: "consultas-geoespaciales-mongodb",
  out: "evidencias/bd2/06-nosql-mongodb/investigacion",
  byline: "Santiago Gómez · Bases de Datos II · Universidad El Bosque",
  seed: 41,
  slides: [
    { type: "cover", title: "CONSULTAS GEOESPACIALES EN MONGODB", subtitle: "GeoJSON, índices 2dsphere y operadores de ubicación" },
    {
      type: "text",
      title: "¿PARA QUÉ SIRVEN?",
      text: "Permiten guardar **ubicaciones** y responder preguntas como: ¿qué restaurantes quedan dentro de este barrio?, ¿cuál es el repartidor más cercano?, ¿qué rutas cruzan esta zona?",
      icon: "pin",
    },
    {
      type: "bullets",
      title: "GEOJSON",
      cols: 1,
      items: [
        "Formato estándar (RFC 7946) para describir geometrías.",
        "**Point**: un punto. **LineString**: una línea. **Polygon**: un área cerrada. También MultiPolygon.",
        "Las coordenadas van en orden **[longitud, latitud]**, al revés de como las muestra Google Maps.",
        "Longitud entre −180 y 180; latitud entre −90 y 90.",
        "Un polígono debe cerrarse: el primer y el último punto son el mismo.",
      ],
      note: "Invertir latitud y longitud es el error más común: el punto termina en otro continente.",
    },
    {
      type: "compare",
      title: "ÍNDICES GEOESPACIALES",
      cols: [
        { title: "2dsphere", items: ["Calcula sobre la **esfera** terrestre.", "Trabaja con objetos GeoJSON.", "Es el recomendado para datos reales de mapas.", "`createIndex({ ubicacion: \"2dsphere\" })`"] },
        { title: "2d", items: ["Calcula sobre un **plano**.", "Usa pares de coordenadas simples (legacy).", "Útil para mapas de juegos o planos internos.", "No sirve bien para distancias grandes."] },
      ],
    },
    {
      type: "table",
      title: "OPERADORES PRINCIPALES",
      head: ["Operador", "Qué responde", "¿Requiere índice?"],
      rows: [
        ["$geoWithin", "Documentos totalmente dentro de una figura", "No, pero lo usa si existe"],
        ["$geoIntersects", "Documentos que tocan o cruzan una figura", "No, pero lo usa si existe"],
        ["$near / $nearSphere", "Documentos ordenados del más cercano al más lejano", "Sí"],
        ["$geoNear (etapa)", "Lo mismo en un pipeline y agrega la distancia", "Sí, y va de primera"],
      ],
    },
    {
      type: "text",
      title: "EL CASO DE LA SUSTENTACIÓN",
      text: "En **sample_restaurants** cada restaurante tiene un punto (`address.coord`) y cada barrio un polígono (`neighborhoods.geometry`). Un restaurante pertenece a un barrio si su punto cae **dentro** del polígono: eso es exactamente `$geoWithin`.",
      icon: "pin",
    },
    {
      type: "compare",
      title: "OPCIÓN A VS OPCIÓN B",
      cols: [
        { title: "A · Contar en el cliente", items: ["Por cada barrio, `countDocuments` con `$geoWithin`.", "Ordena y recorta en JavaScript.", "No crea colecciones nuevas.", "Repite todas las consultas para el punto 2 y el 3."] },
        { title: "B · Materializar con $merge", items: ["Recorre los barrios una sola vez y guarda cada restaurante con su barrio.", "Los puntos 2 y 3 son un `$group` normal.", "Ocupa espacio y hay que borrarla o actualizarla.", "Mejor si la misma pregunta se repite."] },
      ],
      note: "Es la misma decisión que una vista vs una vista materializada en SQL.",
    },
    {
      type: "code",
      title: "LA PREGUNTA AL REVÉS",
      code: `// ¿En qué barrio está este punto?
db.neighborhoods.findOne(
  { geometry: { $geoIntersects: { $geometry: {
      type: "Point",
      coordinates: [ -73.93414657, 40.82302903 ]
  } } } },
  { name: 1 }
);

// Restaurantes a menos de 1 km, del más cercano al más lejano
db.restaurants.createIndex({ "address.coord": "2dsphere" });
db.restaurants.aggregate([
  { $geoNear: {
      near: { type: "Point", coordinates: [ -73.9341, 40.8230 ] },
      key: "address.coord",
      distanceField: "metros",
      maxDistance: 1000
  } },
  { $project: { _id: 0, name: 1, metros: { $round: ["$metros", 0] } } }
]);`,
      side: [
        "`$geoIntersects` busca el polígono que contiene al punto.",
        "`$geoNear` devuelve la distancia en metros en el campo indicado.",
        "En sample_restaurants `address.coord` es un par legacy: 2dsphere lo acepta.",
      ],
    },
    {
      type: "bullets",
      title: "BUENAS PRÁCTICAS",
      cols: 1,
      items: [
        "Crear el índice **2dsphere** antes de consultas frecuentes por ubicación.",
        "Validar que los polígonos estén cerrados y no se crucen a sí mismos.",
        "Revisar siempre el orden **[longitud, latitud]** al importar datos.",
        "Para radios con `$centerSphere` la distancia va en radianes: km ÷ 6378,1.",
        "Si la misma consulta pesada se repite, guardar el resultado (como en la opción B).",
      ],
    },
    {
      type: "refs",
      items: [
        "MongoDB. *Geospatial Queries*. Documentación oficial.",
        "MongoDB. *Find Restaurants with Geospatial Queries* (tutorial con sample_restaurants).",
        "MongoDB. *2dsphere Indexes* y *$geoNear (aggregation)*. Documentación oficial.",
        "Butler, H. et al. (2016). *RFC 7946: The GeoJSON Format*. IETF.",
      ],
    },
    { type: "thanks" },
  ],
};
