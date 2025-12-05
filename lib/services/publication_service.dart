import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/publication.dart';

class PublicationService {
  final DatabaseReference _publicationsRef = FirebaseDatabase.instance.ref('publications');

  // Obtener un stream de publicaciones con paginación, filtro y ordenamiento
  Stream<List<Publication>> getPublicationsStream({
    int pageSize = 10,
    String? startAfterKey, // La última clave de la publicación para la paginación
    String? startAfterValue, // El valor de ordenamiento de la última publicación
    String? category,
    String sortBy = 'timestamp', // Campo por el que ordenar
    bool descending = true, // true para más nuevas primero
  }) {
    Query query = _publicationsRef;

    // Ordenamiento
    query = query.orderByChild(sortBy);

    // Paginación
    if (startAfterKey != null && startAfterValue != null) {
      query = query.startAfter([startAfterValue, startAfterKey]);
    }

    // Limitar el número de resultados
    query = query.limitToFirst(pageSize);

    return query.onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value == null) {
        return [];
      }
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      List<Publication> publications = [];
      data.forEach((key, value) {
        publications.add(Publication.fromMap(Map<String, dynamic>.from(value), key));
      });

      // Ordenar si es necesario
      publications.sort((a, b) {
        final aValue = _getPublicationSortValue(a, sortBy);
        final bValue = _getPublicationSortValue(b, sortBy);
        return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
      });

      return publications;
    });
  }

  // Helper para obtener el valor de ordenamiento
  Comparable _getPublicationSortValue(Publication p, String sortBy) {
    switch (sortBy) {
      case 'timestamp':
        return p.timestamp;
      case 'title':
        return p.title;
      // Añadir otros campos de ordenamiento aquí si es necesario
      default:
        return p.timestamp;
    }
  }

  // Otros métodos como addPublication, updatePublication, deletePublication se añadirán aquí más tarde
  // O se crearán servicios específicos para las publicaciones de un vendedor.
}
