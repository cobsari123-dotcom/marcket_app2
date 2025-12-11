import 'package:marcket_app/models/faq_item.dart';

class FaqService {
  // Simulated backend data for FAQs
  final List<FaqItem> _allFaqs = [
    FaqItem(
      id: '1',
      question: '¿Cómo hago una compra?',
      answer:
          'Para hacer una compra, navega por los productos, añade los que desees al carrito y procede al pago.',
      roles: ['Buyer'],
    ),
    FaqItem(
      id: '2',
      question: '¿Cómo vendo mis productos?',
      answer:
          'Para vender, debes registrarte como vendedor, crear tu perfil de tienda y subir tus productos para que los compradores los vean.',
      roles: ['Seller'],
    ),
    FaqItem(
      id: '3',
      question: '¿Puedo contactar al vendedor antes de comprar?',
      answer:
          'Sí, puedes usar la función de chat en la página del producto o en el perfil del vendedor para comunicarte directamente.',
      roles: ['Buyer', 'Seller'],
    ),
    FaqItem(
      id: '4',
      question: '¿Cómo gestiono mis pedidos?',
      answer:
          'Accede a tu panel de vendedor para ver y gestionar todos tus pedidos, incluyendo estados y detalles de envío.',
      roles: ['Seller'],
    ),
    FaqItem(
      id: '5',
      question: '¿Qué hago si tengo un problema con mi pedido?',
      answer:
          'Contacta directamente al vendedor a través del chat. Si no se resuelve, puedes escalar el problema a soporte.',
      roles: ['Buyer'],
    ),
    FaqItem(
      id: '6',
      question: '¿Cómo reporto un usuario o producto?',
      answer:
          'En cada perfil de usuario o producto, encontrarás una opción para reportar si consideras que infringe nuestras políticas.',
      roles: ['Buyer', 'Seller'],
    ),
    FaqItem(
      id: '7',
      question: '¿Cómo actualizo la información de mi perfil?',
      answer:
          'Ve a la sección "Mi Perfil" y edita tu información personal, dirección o detalles de negocio.',
      roles: ['Buyer', 'Seller'],
    ),
    FaqItem(
      id: '8',
      question: '¿Cuáles son las tarifas de venta?',
      answer:
          'Nuestras tarifas de venta son un porcentaje del precio final del producto, detallado en la sección de "Tarifas y Comisiones" para vendedores.',
      roles: ['Seller'],
    ),
    FaqItem(
      id: '9',
      question: '¿Cómo apruebo o rechazo publicaciones?',
      answer:
          'Como administrador, puedes acceder al panel de moderación para revisar y tomar acción sobre las publicaciones pendientes.',
      roles: ['Admin'],
    ),
    FaqItem(
      id: '10',
      question: '¿Cómo gestiono los reportes de usuarios?',
      answer:
          'El panel de administración incluye una sección de reportes donde puedes ver las quejas, contactar a los usuarios y aplicar sanciones.',
      roles: ['Admin'],
    ),
    FaqItem(
      id: '11',
      question: '¿Cómo puedo verificar la identidad de un vendedor?',
      answer:
          'Verificamos a nuestros vendedores a través de un proceso de registro. Puedes ver la insignia de verificación en su perfil.',
      roles: ['Buyer'],
    ),
    FaqItem(
      id: '12',
      question: '¿Hay un límite en la cantidad de productos que puedo subir?',
      answer:
          'No hay un límite estricto, pero recomendamos mantener tu catálogo actualizado y gestionar tus existencias eficientemente.',
      roles: ['Seller'],
    ),
    FaqItem(
      id: '13',
      question: '¿Qué medidas de seguridad tienen para los pagos?',
      answer:
          'Utilizamos pasarelas de pago seguras y encriptadas para proteger todas tus transacciones.',
      roles: ['Buyer', 'Seller'],
    ),
    FaqItem(
      id: '14',
      question: '¿Cómo contactar al soporte técnico?',
      answer:
          'Puedes contactar a nuestro equipo de soporte técnico a través de la sección de Ayuda o usando el chat de soporte en la aplicación.',
      roles: ['Buyer', 'Seller', 'Admin'],
    ),
    FaqItem(
      id: '15',
      question: '¿Cómo funciona la política de devoluciones?',
      answer:
          'Nuestra política de devoluciones permite solicitar un reembolso o cambio dentro de los 7 días posteriores a la recepción, bajo ciertas condiciones.',
      roles: ['Buyer', 'Seller'],
    ),
  ];

  Future<List<FaqItem>> getFaqsByRole(String userRole) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _allFaqs
        .where((faq) => faq.roles.contains(userRole))
        .toList();
  }
}
