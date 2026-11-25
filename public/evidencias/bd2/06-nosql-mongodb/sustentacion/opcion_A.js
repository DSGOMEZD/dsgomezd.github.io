// Santiago Gomez, Mariana Duran
// OPCION A - sample_restaurants (MongoDB Atlas)
// restaurants.address.coord = [longitud, latitud]  (un punto)
// neighborhoods.geometry    = poligono GeoJSON del barrio
// Un restaurante pertenece a un barrio si su punto cae DENTRO del poligono.


use('sample_restaurants');



// 1. Restaurantes de Manhattan con calificacion A
//    (grades.0 = la calificacion mas reciente)


db.restaurants.aggregate([
  { $match: { borough: "Manhattan", "grades.0.grade": "A" } },
  { $project: { _id: 0, name: 1, cuisine: 1, calificacion: { $arrayElemAt: ["$grades.grade", 0] } } }
]);



// 2. Cantidad de restaurantes por barrio
//    Se recorre cada barrio y se cuentan los restaurantes
//    cuyo punto cae dentro de su poligono.


var barrios = db.neighborhoods.find({}, { name: 1, geometry: 1 }).toArray();
var resultado = [];

for (var i = 0; i < barrios.length; i++) {
  var total = db.restaurants.countDocuments({
    "address.coord": { $geoWithin: { $geometry: barrios[i].geometry } }
  });
  resultado.push({ barrio: barrios[i].name, cantidad: total });
}

resultado.sort(function (a, b) { return b.cantidad - a.cantidad; });
resultado;


// 3. Top 5 barrios con mas restaurantes
//    Igual que el punto 2, pero al final solo se toman 5.


var barrios = db.neighborhoods.find({}, { name: 1, geometry: 1 }).toArray();
var resultado = [];

for (var i = 0; i < barrios.length; i++) {
  var total = db.restaurants.countDocuments({
    "address.coord": { $geoWithin: { $geometry: barrios[i].geometry } }
  });
  resultado.push({ barrio: barrios[i].name, cantidad: total });
}

resultado.sort(function (a, b) { return b.cantidad - a.cantidad; });
resultado.slice(0, 5);
