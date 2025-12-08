import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Preguntas Frecuentes'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Compradores'),
              Tab(text: 'Vendedores'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: 800), // Limit width for FAQ content
            child: const TabBarView(
              children: [
                _FaqList(faqItems: _buyerFaqs),
                _FaqList(faqItems: _sellerFaqs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  final List<_FaqItem> faqItems;

  const _FaqList({required this.faqItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: faqItems.length,
      itemBuilder: (context, index) {
        final faq = faqItems[index];
        return ExpansionTile(
          title: Text(faq.question,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(faq.answer, textAlign: TextAlign.justify),
            ),
          ],
        );
      },
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

const List<_FaqItem> _buyerFaqs = [
  _FaqItem(
    question: '1. ¿Qué es Manos del Mar?',
    answer:
        'Manos del Mar es una plataforma digital que conecta a artesanos y pescadores locales del estado de Campeche directamente con compradores, promoviendo el comercio justo y la economía regional.',
  ),
  _FaqItem(
    question: '2. ¿Cómo puedo registrarme?',
    answer:
        'Puedes registrarte como Comprador desde la pantalla de "Registrarse". Simplemente selecciona tu tipo de perfil, llena tus datos y ¡listo!',
  ),
  _FaqItem(
    question: '3. ¿Cómo puedo comprar un producto?',
    answer:
        'Navega por las publicaciones y productos, agrégalos a tu carrito de compras y procede al pago. Recibirás notificaciones sobre el estado de tu pedido.',
  ),
  _FaqItem(
    question: '4. ¿Qué métodos de pago se aceptan?',
    answer:
        'Actualmente, aceptamos pagos a través de transferencias bancarias y depósitos. Estamos trabajando para integrar pagos con tarjeta de crédito/débito y otras pasarelas de pago próximamente.',
  ),
  _FaqItem(
    question: '5. ¿Cómo se realizan los envíos?',
    answer:
        'Cada vendedor es responsable de la logística de envío. La plataforma facilita la comunicación para que puedas coordinar la entrega directamente con el vendedor.',
  ),
  _FaqItem(
    question: '6. ¿Puedo devolver un producto?',
    answer:
        'Las políticas de devolución dependen de cada vendedor. Te recomendamos revisar sus políticas en su perfil o contactarlos directamente a través del chat antes de realizar tu compra.',
  ),
  _FaqItem(
    question: '7. ¿Cómo puedo contactar a un vendedor?',
    answer:
        'Puedes contactar a un vendedor a través del chat en línea disponible en su perfil público o en los detalles de una de sus publicaciones.',
  ),
  _FaqItem(
    question: '8. ¿Qué hago si tengo un problema con mi pedido?',
    answer:
        'El primer paso es contactar al vendedor. Si no obtienes una respuesta satisfactoria, puedes levantar una queja en nuestra sección de "Soporte Técnico".',
  ),
  _FaqItem(
    question: '9. ¿Es seguro comprar en la plataforma?',
    answer:
        'Sí, la plataforma utiliza los servicios de Firebase para garantizar la seguridad de los datos. Sin embargo, las transacciones finales se coordinan entre comprador y vendedor.',
  ),
  _FaqItem(
    question: '10. ¿Cómo se calculan las calificaciones de los productos?',
    answer:
        'La calificación de un producto es el promedio de todas las valoraciones que los compradores le han dado después de una compra confirmada.',
  ),
  _FaqItem(
    question: '11. Olvidé mi contraseña, ¿cómo la recupero?',
    answer:
        'En la pantalla de inicio de sesión, haz clic en "¿Olvidaste tu contraseña?". Recibirás un correo electrónico con las instrucciones para restablecerla.',
  ),
  _FaqItem(
    question: '12. ¿Cómo edito la información de mi perfil?',
    answer:
        'Dirígete a la sección "Mi Perfil" en tu panel de usuario. Ahí podrás actualizar tu nombre, foto de perfil y otros datos personales.',
  ),
  _FaqItem(
    question: '13. ¿Qué pasa si un vendedor no envía mi producto?',
    answer:
        'Si un vendedor no cumple con el envío después de que el pago ha sido confirmado, por favor, repórtalo inmediatamente en el buzón de quejas para que podamos intervenir.',
  ),
  _FaqItem(
    question: '14. ¿Cómo se protegen mis datos personales?',
    answer:
        'Nos tomamos muy en serio tu privacidad. Tus datos se manejan de acuerdo a nuestra Política de Privacidad y solo se comparten cuando es estrictamente necesario para una transacción.',
  ),
  _FaqItem(
    question: '15. ¿Puedo chatear con otros compradores?',
    answer:
        'No, la función de chat está diseñada exclusivamente para la comunicación entre compradores y vendedores, y para el contacto con el soporte técnico.',
  ),
  _FaqItem(
      question: '16. ¿Cómo puedo ver el historial de mis compras?',
      answer:
          'En tu panel de comprador, encontrarás una sección de "Mis Compras" donde podrás ver todos los pedidos que has realizado.'),
  _FaqItem(
    question: '17. ¿Puedo guardar productos para comprarlos después?',
    answer:
        '¡Sí! Utiliza el ícono de corazón en los productos o publicaciones para agregarlos a tu lista de "Favoritos".',
  ),
  _FaqItem(
      question: '18. ¿Qué significa que un producto sea "destacado"?',
      answer:
          'Un producto destacado es aquel que el vendedor ha marcado para promocionar. ¡Suelen ser productos populares o novedades que no te puedes perder!'),
  _FaqItem(
      question: '19. ¿Cómo sé si un vendedor es confiable?',
      answer:
          'Puedes revisar las calificaciones y comentarios que otros compradores han dejado en el perfil del vendedor y en sus productos.'),
  _FaqItem(
    question: '20. ¿La aplicación tiene notificaciones?',
    answer:
        'Sí, recibirás notificaciones sobre el estado de tus pedidos, nuevos mensajes en el chat y respuestas a tus quejas o sugerencias.',
  ),
  _FaqItem(
    question: '21. ¿Cómo sé si mi pedido ha sido enviado?',
    answer:
        'El estado de tu pedido cambiará a "Enviado" en tu sección de "Mis Pedidos". Además, el vendedor puede contactarte por chat para darte los detalles del envío.',
  ),
  _FaqItem(
    question:
        '22. ¿Puedo cambiar la dirección de envío después de hacer un pedido?',
    answer:
        'Debes contactar al vendedor inmediatamente a través del chat. Si el producto aún no ha sido enviado, es posible que el vendedor pueda ajustar la dirección.',
  ),
  _FaqItem(
    question: '23. ¿Qué hago si recibo un producto dañado?',
    answer:
        'Contacta al vendedor tan pronto como recibas el producto. Aporta fotos y detalles del daño. Si no llegan a un acuerdo, puedes levantar una queja en Soporte Técnico.',
  ),
  _FaqItem(
    question: '24. ¿Hay un costo de envío fijo?',
    answer:
        'No, los costos y métodos de envío son gestionados por cada vendedor. Debes acordar estos detalles directamente con ellos antes o después de tu compra.',
  ),
  _FaqItem(
    question: '25. ¿Cómo puedo dejar una reseña a un vendedor?',
    answer:
        'Una vez que tu pedido se marca como "Completado", tendrás la opción de dejar una reseña y calificación tanto para el producto como para el vendedor desde tu historial de pedidos.',
  ),
  _FaqItem(
    question: '26. ¿Mis datos de pago están seguros?',
    answer:
        'La plataforma no almacena directamente tus datos de pago. Las transacciones se coordinan entre tú y el vendedor. Te recomendamos usar métodos de pago seguros.',
  ),
  _FaqItem(
    question: '27. ¿Puedo comprar desde fuera de Campeche?',
    answer:
        'Esto depende de cada vendedor. Consulta directamente con ellos para saber si realizan envíos fuera del estado de Campeche.',
  ),
  _FaqItem(
    question: '28. ¿Hay alguna app móvil para Manos del Mar?',
    answer:
        '¡Sí! Estás usando nuestra aplicación móvil, disponible para Android. También puedes acceder a la plataforma a través de nuestro sitio web.',
  ),
  _FaqItem(
    question: '29. ¿Cómo puedo buscar un producto o vendedor específico?',
    answer:
        'En la pantalla de "Inicio", utiliza la barra de búsqueda en la parte superior para encontrar vendedores por su nombre. Próximamente añadiremos búsqueda de productos.',
  ),
  _FaqItem(
    question: '30. ¿Qué son las "publicaciones" y cómo me benefician?',
    answer:
        'Las publicaciones son como una red social dentro de la app. Los vendedores comparten historias, ofertas y novedades. ¡Es una gran forma de descubrir productos y conectar con su origen!',
  ),
];

const List<_FaqItem> _sellerFaqs = [
  _FaqItem(
    question: '1. ¿Tiene algún costo registrarse o vender en la plataforma?',
    answer:
        'El registro es completamente gratuito. Se aplica una pequeña comisión a las ventas realizadas a través de la plataforma para cubrir los costos de operación y mantenimiento.',
  ),
  _FaqItem(
    question: '2. ¿Cómo puedo vender mis productos en Manos del Mar?',
    answer:
        'Regístrate como "Vendedor", completa tu perfil con la información de tu negocio y comienza a subir tus productos y publicaciones. ¡Es muy fácil!',
  ),
  _FaqItem(
    question: '3. ¿Qué tipo de productos puedo vender?',
    answer:
        'Puedes vender productos artesanales y productos del mar procesados que sean originarios del estado de Campeche.',
  ),
  _FaqItem(
    question: '4. ¿Cómo subo un producto?',
    answer:
        'En tu panel de vendedor, ve a la sección "Mis Productos" y pulsa el botón para añadir uno nuevo. Podrás agregar fotos, descripción, precio y stock.',
  ),
  _FaqItem(
    question: '5. ¿Qué son las publicaciones?',
    answer:
        'Las publicaciones son una forma de compartir historias sobre tus productos, tu proceso de creación o cualquier noticia relevante. ¡Ayudan a conectar con tus clientes!',
  ),
  _FaqItem(
    question: '6. ¿Puedo cambiar mi tipo de perfil de Comprador a Vendedor?',
    answer:
        'Actualmente, no es posible cambiar el tipo de perfil una vez creado. Si deseas ser vendedor, deberás crear una nueva cuenta con un correo electrónico diferente.',
  ),
  _FaqItem(
    question: '7. ¿Cómo edito la información de mi perfil?',
    answer:
        'Dirígete a la sección "Mi Perfil" en tu panel de usuario. Ahí podrás actualizar tu nombre, foto de perfil y otros datos personales o de negocio.',
  ),
  _FaqItem(
    question: '8. ¿Cómo se verifica el pago de un pedido?',
    answer:
        'El comprador debe subir un comprobante de pago. Como vendedor, debes revisar este comprobante para confirmar el pago y proceder con el envío.',
  ),
  _FaqItem(
    question: '9. ¿Puedo cancelar un pedido?',
    answer:
        'Como vendedor, puedes cancelar un pedido si no tienes stock o por alguna otra razón justificada. Revisa nuestras políticas para más detalles.',
  ),
  _FaqItem(
    question:
        '10. ¿Qué información es visible en mi perfil público de vendedor?',
    answer:
        'Tu nombre, foto de perfil, nombre del negocio, y tus publicaciones y productos activos son visibles para todos los usuarios.',
  ),
  _FaqItem(
      question: '11. ¿Cómo se gestionan los envíos?',
      answer:
          'Cada vendedor es responsable de gestionar sus propios envíos. Te recomendamos acordar los detalles y costos del envío con el comprador a través del chat.'),
  _FaqItem(
      question: '12. ¿Cómo recibo el pago de mis ventas?',
      answer:
          'En tu perfil de vendedor, puedes especificar tus instrucciones de pago. El comprador te pagará directamente siguiendo esas instrucciones.'),
  _FaqItem(
      question: '13. ¿Qué hago si un comprador no paga un pedido?',
      answer:
          'Si un comprador no realiza el pago en un tiempo razonable, puedes cancelar el pedido y reportar al usuario en la sección de "Soporte Técnico".'),
  _FaqItem(
      question: '14. ¿Cómo puedo mejorar la visibilidad de mis productos?',
      answer:
          'Toma fotos de alta calidad, escribe descripciones detalladas, mantén tu stock actualizado y crea publicaciones interesantes para atraer a más clientes.'),
  _FaqItem(
      question: '15. ¿Puedo ofrecer descuentos o promociones?',
      answer:
          'Actualmente no hay una función específica para promociones, pero puedes ajustar los precios de tus productos o mencionarlo en la descripción o en una publicación.'),
  _FaqItem(
      question: '16. ¿Cómo puedo ver el historial de mis ventas?',
      answer:
          'En tu panel de vendedor, encontrarás una sección de "Mis Ventas" donde podrás ver todos los pedidos que has recibido y su estado.'),
  _FaqItem(
      question: '17. ¿Qué pasa si recibo una mala calificación?',
      answer:
          'Una mala calificación puede afectar tu reputación. Te recomendamos siempre ofrecer un buen servicio al cliente y resolver cualquier problema de manera proactiva.'),
  _FaqItem(
      question: '18. ¿Cómo se manejan los impuestos?',
      answer:
          'Cada vendedor es responsable de declarar sus propios impuestos de acuerdo a la legislación vigente en México.'),
  _FaqItem(
      question: '19. ¿Puedo tener varias fotos por producto?',
      answer:
          '¡Sí! Al agregar o editar un producto, puedes subir varias imágenes para mostrarlo desde diferentes ángulos.'),
  _FaqItem(
    question: '20. ¿Cómo contacto a soporte si tengo un problema?',
    answer:
        'Puedes usar el "Buzón de Quejas y Sugerencias" o el "Chat en Línea con Administrador" disponibles en la sección de "Soporte Técnico".',
  ),
  _FaqItem(
    question: '21. ¿Cómo marco un pedido como "enviado" o "entregado"?',
    answer:
        'En los detalles de cada pedido dentro de tu sección de "Mis Ventas", encontrarás opciones para actualizar el estado del pedido a "Enviado" o "Completado".',
  ),
  _FaqItem(
    question: '22. ¿Qué debo hacer si un comprador me deja una mala reseña?',
    answer:
        'Te recomendamos contactar al comprador de manera profesional para entender el problema. Si crees que la reseña es injusta o falsa, puedes reportarla a Soporte Técnico.',
  ),
  _FaqItem(
    question: '23. ¿Puedo ver estadísticas de mis ventas?',
    answer:
        'Actualmente, el historial de ventas es la principal herramienta para llevar un registro. Estamos trabajando en un panel de estadísticas más avanzado para futuras versiones.',
  ),
  _FaqItem(
    question: '24. ¿Cómo se maneja el stock de mis productos?',
    answer:
        'El stock se descuenta automáticamente con cada venta confirmada. Es tu responsabilidad mantener los números de stock correctos en la plataforma.',
  ),
  _FaqItem(
    question: '25. ¿Puedo poner mi tienda en "modo vacaciones"?',
    answer:
        'No existe un "modo vacaciones" oficial, pero puedes desactivar temporalmente tus productos para que no aparezcan en la búsqueda y así evitar recibir pedidos mientras no estás disponible.',
  ),
  _FaqItem(
    question:
        '26. ¿Hay algún límite en la cantidad de productos que puedo publicar?',
    answer:
        'No, no hay límite. Puedes publicar tantos productos como desees, siempre que cumplan con nuestras políticas y sean de la región de Campeche.',
  ),
  _FaqItem(
    question: '27. ¿Qué tipo de fotos de producto son más efectivas?',
    answer:
        'Fotos claras, bien iluminadas, sobre un fondo neutro, y que muestren el producto desde varios ángulos suelen ser las más efectivas para atraer compradores.',
  ),
  _FaqItem(
    question: '28. ¿Cómo respondo a las preguntas de los compradores?',
    answer:
        'Recibirás notificaciones de nuevos mensajes. Puedes acceder a todos tus chats desde la sección "Mensajes" en tu panel de vendedor.',
  ),
  _FaqItem(
    question: '29. ¿Qué pasa si no puedo cumplir con un pedido?',
    answer:
        'Debes comunicarte con el comprador lo antes posible para explicarle la situación. Si es necesario, cancela el pedido desde tu panel, explicando la razón.',
  ),
  _FaqItem(
    question: '30. ¿Cómo puedo destacar entre otros vendedores?',
    answer:
        'Además de tener buenos productos, ofrece un excelente servicio al cliente, responde rápidamente a los mensajes, envía los pedidos a tiempo y mantén tu perfil y publicaciones actualizadas.',
  ),
];
