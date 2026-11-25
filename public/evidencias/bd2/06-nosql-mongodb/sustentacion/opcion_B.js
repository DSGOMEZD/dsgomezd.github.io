// Santiago Gomez, Mariana Duran
// OPCION B - sample_restaurants (MongoDB Atlas)
// restaurants.address.coord = [longitud, latitud]  (un punto)
// neighborhoods.geometry    = poligono GeoJSON del barrio
// Un restaurante pertenece a un barrio si su punto cae DENTRO del poligono.
// Se crea la coleccion nueva restaurantes_por_barrio, restaurants no se modifica.


use('sample_restaurants');



// 1. Restaurantes de Manhattan con calificacion A
//    (grades.0 = la calificacion mas reciente)


db.restaurants.aggregate([
  { $match: { borough: "Manhattan", "grades.0.grade": "A" } },
  { $project: { _id: 0, name: 1, cuisine: 1, calificacion: { $arrayElemAt: ["$grades.grade", 0] } } }
]);



// Paso previo (una sola vez): llenar restaurantes_por_barrio
// Por cada barrio se buscan los restaurantes dentro de su poligono
// y se guardan con el nombre del barrio.


var barrios = db.neighborhoods.find({}, { name: 1, geometry: 1 }).toArray();

for (var i = 0; i < barrios.length; i++) {
  db.restaurants.aggregate([
    { $match: { "address.coord": { $geoWithin: { $geometry: barrios[i].geometry } } } },
    { $project: { name: 1, cuisine: 1, borough: 1, barrio: { $literal: barrios[i].name } } },
    { $merge: { into: "restaurantes_por_barrio" } }
  ]).toArray();
}



// 2. Cantidad de restaurantes por barrio


db.restaurantes_por_barrio.aggregate([
  { $group: { _id: "$barrio", cantidad: { $sum: 1 } } },
  { $sort: { cantidad: -1 } }
]);



// 3. Top 5 barrios con mas restaurantes


db.restaurantes_por_barrio.aggregate([
  { $group: { _id: "$barrio", cantidad: { $sum: 1 } } },
  { $sort: { cantidad: -1 } },
  { $limit: 5 }
]);



// Limpieza: borrar la coleccion nueva cuando termines


db.restaurantes_por_barrio.drop();
