import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Limit width
          child: const SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Términos y Condiciones de Servicio de Manos del Mar',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Última actualización: 4 de Diciembre de 2025',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 16),
                Text(
                  'Bienvenido a Manos del Mar. Al utilizar nuestra aplicación (la "Plataforma"), aceptas estar sujeto a los siguientes términos y condiciones ("Términos"). Por favor, léelos con atención.',
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: 24),
                _TermSection(
                  title: '1. Aceptación de los Términos',
                  content:
                      'Al crear una cuenta, acceder y/o utilizar la Plataforma, aceptas y te comprometes a cumplir estos Términos de Servicio y nuestra Política de Privacidad. Si no estás de acuerdo con estos términos, no debes registrarte ni utilizar la Plataforma.',
                ),
                _TermSection(
                  title: '2. Descripción del Servicio',
                  content:
                      'Manos del Mar es un mercado en línea que permite a vendedores locales (artesanos y pescadores de Campeche, en adelante "Vendedores") ofrecer y vender sus productos a "Compradores". Manos del Mar actúa como un intermediario tecnológico para facilitar la conexión y la comunicación. El contrato de compraventa es exclusivamente entre el Comprador y el Vendedor. No somos responsables de la calidad, seguridad, legalidad o entrega de los productos.',
                ),
                _TermSection(
                  title: '3. Cuentas de Usuario',
                  content:
                      'Para utilizar la mayoría de las funciones de la Plataforma, debes registrarte y crear una cuenta. Eres el único responsable de mantener la confidencialidad de tu contraseña y de todas las actividades que ocurran en tu cuenta. Te comprometes a proporcionar información precisa, actual y completa durante el proceso de registro.',
                ),
                _TermSection(
                  title: '4. Conducta y Obligaciones del Usuario',
                  content:
                      'Todos los usuarios se comprometen a no utilizar la Plataforma para: (a) realizar actividades fraudulentas o ilegales; (b) publicar contenido falso, engañoso, difamatorio u ofensivo; (c) acosar, abusar o dañar a otro usuario; (d) infringir los derechos de propiedad intelectual de terceros; (e) distribuir spam o publicidad no solicitada.',
                ),
                _TermSection(
                  title: '5. Obligaciones Específicas del Vendedor',
                  content:
                      'Los Vendedores son los únicos responsables de: (a) la veracidad y exactitud de las descripciones, precios y fotos de sus productos; (b) la calidad y seguridad de los productos vendidos; (c) la gestión del inventario; (d) el embalaje y envío de los productos de manera oportuna; y (e) el cumplimiento de todas las leyes y regulaciones aplicables, incluidas las fiscales.',
                ),
                _TermSection(
                  title: '6. Compras y Pagos',
                  content:
                      'Los Compradores se comprometen a completar el pago de los productos que ordenan. Los métodos de pago son acordados directamente con el Vendedor. Manos del Mar no procesa pagos y no se hace responsable de las transacciones financieras entre usuarios. Recomendamos utilizar métodos de pago seguros y verificar la identidad del Vendedor.',
                ),
                _TermSection(
                  title: '7. Envíos y Entregas',
                  content:
                      'El Vendedor es responsable de la logística del envío. Cualquier fecha de entrega estimada es solo una aproximación. Manos del Mar no se hace responsable de retrasos, pérdidas o daños durante el envío.',
                ),
                 _TermSection(
                  title: '8. Disputas, Devoluciones y Cancelaciones',
                  content:
                      'Cualquier disputa, solicitud de devolución o cancelación debe ser resuelta directamente entre el Comprador y el Vendedor. Manos del Mar ofrece un sistema de quejas para mediar en casos donde no se llegue a un acuerdo, pero no garantiza un resultado específico.',
                ),
                _TermSection(
                  title: '9. Propiedad Intelectual',
                  content:
                      'Todo el contenido de la Plataforma, incluyendo logos, textos y software (excluyendo el contenido generado por el usuario), es propiedad de Manos del Mar. El contenido que publicas (como fotos y descripciones de productos) sigue siendo de tu propiedad, pero nos concedes una licencia mundial, no exclusiva y libre de regalías para usarlo en la operación y promoción de la Plataforma.',
                ),
                 _TermSection(
                  title: '10. Limitación de Responsabilidad',
                  content:
                      'La Plataforma se proporciona "tal cual". Manos del Mar no será responsable de ningún daño directo, indirecto, incidental o consecuente que surja del uso o la incapacidad de usar la Plataforma, incluyendo disputas entre usuarios, fallos en los productos o problemas de envío.',
                ),
                _TermSection(
                  title: '11. Modificación de los Términos',
                  content:
                      'Nos reservamos el derecho de modificar estos Términos en cualquier momento. Te notificaremos de los cambios importantes. El uso continuado de la Plataforma después de la notificación constituirá tu aceptación de los nuevos términos.',
                ),
                _TermSection(
                  title: '12. Ley Aplicable y Jurisdicción',
                  content:
                      'Estos Términos se regirán e interpretarán de acuerdo con las leyes del Estado de Campeche y los Estados Unidos Mexicanos. Cualquier disputa será sometida a la jurisdicción de los tribunales competentes de Campeche.',
                ),
                _TermSection(
                  title: '13. Contacto',
                  content:
                      'Si tienes alguna pregunta sobre estos Términos, por favor contáctanos a través de la sección de "Soporte Técnico" en la aplicación o al correo electrónico: legal@manosdelmar.com.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}