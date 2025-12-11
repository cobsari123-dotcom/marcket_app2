# Marcket App: Manos del Mar 🛍️

¡Bienvenido a Marcket App, también conocida como "Manos del Mar"! Una aplicación móvil de comercio electrónico desarrollada con Flutter que conecta a artesanos y pescadores locales de Campeche, México, con consumidores interesados en productos auténticos y sostenibles.

## 📝 Tabla de Contenidos

*   [🌟 La Misión de Manos del Mar](#-la-misión-de-manos-del-mar)
*   [✨ Características Principales](#-características-principales)
    *   [Para Compradores 🛒](#para-compradores-)
    *   [Para Vendedores 🧑‍💼](#para-vendedores-)
    *   [Para Administradores 👮](#para-administradores-)
*   [🚀 Mejoras Recientes](#-mejoras-recientes)
    *   [Sistema Integral de Pedidos y Pagos](#sistema-integral-de-pedidos-y-pagos)
    *   [Mejoras en Perfiles y Administración](#mejoras-en-perfiles-y-administración)
    *   [UI/UX y Rendimiento](#uiux-y-rendimiento)
*   [🛠️ Arquitectura y Tecnologías](#️-arquitectura-y-tecnologías)
    *   [Stack Tecnológico](#stack-tecnológico)
    *   [Arquitectura de Software](#arquitectura-de-software)
    *   [Estructura del Proyecto](#estructura-del-proyecto)
*   [🏁 Empezando](#-empezando)
*   [🤝 Cómo Contribuir](#-cómo-contribuir)
*   [© Licencia](#-licencia)

---

## 🌟 La Misión de Manos del Mar

Nuestra misión es empoderar a los productores locales, aumentar sus ingresos y promover el rico patrimonio cultural de Campeche, ofreciendo una plataforma digital que supera las barreras de los intermediarios y la falta de visibilidad en línea.

## ✨ Características Principales

### Para Compradores 🛒
- **Feed de Productos y Publicaciones:** Explora un flujo constante de productos auténticos y publicaciones de diferentes vendedores, con paginación para un rendimiento óptimo.
- **Filtros y Ordenamiento:** Filtra las publicaciones por categoría y ordénalas por fecha o título para encontrar exactamente lo que buscas.
- **Lista de Deseos (Favoritos):** Guarda tus productos preferidos en una lista de favoritos para acceder a ellos fácilmente.
- **Gestión de Carrito y Compras Avanzada:** Añade productos al carrito, selecciona métodos de pago (transferencia bancaria o pago contra entrega), proporciona dirección de envío detallada y sube comprobantes de pago.
- **Seguimiento de Pedidos Detallado:** Rastrea el estado de tus pedidos, visualiza códigos de entrega, tiempos estimados y números de seguimiento.
- **Chat Directo con Vendedores y Soporte:** Comunícate directamente con artesanos, pescadores locales y con el equipo de soporte para cualquier incidencia.
- **Reseñas y Calificaciones:** Valora los productos y vendedores después de una compra.
- **Inicio Dinámico:** La pantalla de inicio ahora muestra una variedad de productos de diferentes vendedores, con la opción de filtrar por categoría y una presentación aleatoria para una experiencia de compra más dinámica.

### Para Vendedores 🧑‍💼
- **Dashboard de Vendedor:** Un panel de control intuitivo para gestionar tu tienda.
- **Gestión de Productos y Publicaciones:** Añade, edita y elimina productos y publicaciones promocionales de forma sencilla.
- **Gestión de Pedidos Avanzada:** Revisa y gestiona los pedidos, verifica comprobantes de pago, actualiza estados (preparación, enviado, entregado), genera códigos de entrega seguros y proporciona información de seguimiento.
- **Perfil de Vendedor Personalizado:** Personaliza tu perfil público con tu historia, información de tu negocio y enlaces a redes sociales.
- **Chat Directo con Compradores y Soporte:** Comunícate directamente con tus clientes y con el equipo de soporte para cualquier incidencia.
- **Información de Usuario en el Menú:** El menú del dashboard ahora muestra el nombre, correo electrónico, rol y foto de perfil del vendedor.

### Para Administradores 👮
- **Dashboard de Administrador:** Un panel central para supervisar y gestionar la plataforma.
- **Gestión de Usuarios Detallada:** Busca usuarios por ID público, nombre o correo electrónico. Visualiza perfiles completos de compradores y vendedores, incluyendo productos y publicaciones de estos últimos.
- **Soporte Centralizado:** Atiende consultas y gestiona quejas de los usuarios a través de un chat y un sistema de tickets.
- **Notificaciones a Usuarios:** Envía avisos y notificaciones directamente a los usuarios.
- **Control Total de Cuentas:** Supervisa y gestiona la actividad de vendedores, incluyendo la verificación de comprobantes de pago y la resolución de disputas.
- **Información de Usuario en el Menú:** El menú del dashboard ahora muestra el nombre, correo electrónico y rol del administrador.

---

## 🚀 Mejoras Recientes

Hemos realizado una serie de mejoras significativas en la aplicación para ofrecer una experiencia más completa, segura y eficiente:

### **Sistema Integral de Pedidos y Pagos**
*   **Modelo de Orden Expandido:** El modelo de orden (`Order`) ha sido completamente reestructurado para incluir detalles de dirección de entrega (calle, colonia, código postal, ciudad, estado), número de teléfono, correo electrónico del comprador, método de pago, fecha y ventana de tiempo de entrega estimada, y un **código de seguridad para la entrega (`deliveryCode`)**.
*   **Checkout Avanzado para Compradores:**
    *   **Selección de Método de Pago:** El comprador puede elegir entre "Transferencia Bancaria" y "Pago contra Entrega".
    *   **Formulario de Dirección de Envío:** Se recopila información detallada de la dirección de entrega durante el proceso de compra.
    *   **Carga de Comprobante de Pago:** Para transferencias bancarias, el comprador puede subir una imagen de su comprobante, que se almacena en Firebase Storage.
*   **Gestión Detallada de Órdenes para Vendedores:**
    *   **Verificación de Pagos:** El vendedor puede visualizar el comprobante de pago subido por el comprador y tiene opciones para "Confirmar Pago" (cambiando el estado a "En Preparación") o "Rechazar Pago" (revirtiendo el estado a "Pendiente de Pago" y solicitando un motivo de rechazo).
    *   **Generación de Códigos de Entrega Seguros:** Al confirmar un pago, se genera automáticamente un `deliveryCode` único para el pedido, que se utiliza para verificar la entrega al cliente.
    *   **Actualizaciones de Estado y Logística:** El vendedor puede actualizar el estado del pedido a "Enviado" (ingresando un número de seguimiento y estableciendo una fecha y ventana de tiempo de entrega estimada) y "Entregado" (confirmando la entrega con el `deliveryCode`).
*   **Notificaciones de Entrega en Tiempo Real:**
    *   Se ha implementado una **Función de Nube de Firebase (`sendDeliveryNotification`)** que envía notificaciones push al comprador cada vez que el estado de su pedido cambia (enviado, entregado, cancelado o pago rechazado).

### **Gestión Avanzada de Cuentas y Contenido (Admin y Comprador)**
*   **Funcionalidades de Administración de Cuentas:** Los administradores ahora pueden enviar advertencias o sanciones a usuarios, suspender cuentas por periodos definidos (una semana, un mes, permanente o personalizado) y eliminar cuentas de forma permanente, todo con notificaciones automáticas al usuario afectado.
*   **Feed de Productos para Compradores:** La pantalla de inicio del comprador ha sido refactorizada para mostrar un listado de productos directo de la base de datos, facilitando la exploración y compra.
*   **Publicaciones Estilo Reels:** Nueva sección para compradores que permite visualizar publicaciones de vendedores en un formato vertical de "reels", con interacción de "Me Gusta", "Comentar" y "Compartir".
*   **Mejoras en Soporte Técnico (Admin):** La lista de chats de soporte ahora muestra la foto de perfil y el nombre del usuario (comprador o vendedor) que envió el mensaje, mejorando la identificación visual.

### **Mejoras en Perfiles y Administración**
*   **ID Público para Usuarios:** Todos los usuarios (compradores y vendedores) ahora tienen un `publicId` único generado automáticamente al completar su perfil, facilitando su identificación.
*   **Pantalla de Detalle de Usuario para Administradores:** Nueva interfaz que permite a los administradores buscar usuarios por `publicId`, nombre o correo electrónico y visualizar un perfil completo. Para vendedores, esto incluye acceso directo a sus productos y publicaciones.
*   **Resolución de Disputas y Contacto con Soporte:**
    *   Se ha añadido un botón "Contactar a Soporte" en la pantalla de detalles de cada pedido (visible para compradores y vendedores).
    *   Al activarlo, inicia un chat directo con el equipo de soporte, pre-llenando automáticamente los detalles del `orderId` para una asistencia rápida y contextualizada.
*   **Pantalla "Sobre Nosotros":** Nueva sección informativa accesible desde el menú lateral de todos los roles, explicando la génesis de la app por estudiantes de la UTC y facilitando diversos canales de contacto.

### **UI/UX y Rendimiento**
*   **Feed de Publicaciones Estilo TikTok Unificado:** La pantalla principal de "Inicio" para todos los roles (Comprador, Vendedor, Administrador) ahora presenta un feed de publicaciones a pantalla completa con desplazamiento vertical, incluyendo funciones de "Me Gusta", "Comentarios" (con carga de imágenes) y "Compartir".
*   **Pulido Visual y Animaciones:**
    *   **Iconografía Mejorada:** Utilización de `FontAwesomeIcons` para un aspecto más moderno y profesional en el feed de publicaciones.
    *   **Animaciones Sutiles:** Incorporación de animaciones `fade` y `slideY` en los elementos del menú lateral de los dashboards para una experiencia de navegación más fluida y atractiva.
    *   **Diseño Profesional:** Mejoras en el layout del perfil de edición de vendedor y en la `FullScreenPublicationView` para una apariencia más cuidada y consistente.

### **Mejoras en UI y Navegación**
*   **Manejo de AppBar y Cajón de Navegación Unificado:** Se ha centralizado la gestión del `AppBar` y el botón de menú de hamburguesa en el `ResponsiveScaffold` para pantallas móviles, eliminando `AppBars` duplicados y asegurando que el cajón de navegación (`Drawer`) se abra correctamente al hacer clic en el icono.
*   **Navegación Consistente en Pantallas Auxiliares:** Corregida la navegación desde pantallas como 'Configuración', 'Notificaciones' y 'Sobre Nosotros' para permitir un retorno adecuado a la pantalla anterior (dashboard) en lugar de llevar al inicio de sesión o salir de la aplicación. Todas estas pantallas ahora incluyen un botón de "volver" en su `AppBar`.
*   **Corrección de Perfil de Vendedor:** Eliminado el `AppBar` duplicado en la pantalla de perfil del vendedor y reestructurado el diseño para una presentación más limpia y sin conflictos.
*   **Mapeo Funcional de Botones en Dashboard de Vendedor:** Ajustada la lógica de los botones flotantes (`FloatingActionButton`) en el dashboard del vendedor para que las opciones de "Agregar Producto" y "Crear Publicación" aparezcan en sus respectivas pestañas ("Mis Productos" y "Mis Publicaciones").
*   **Gestión de Imágenes Verificada:** Confirmado que las pantallas de agregar/editar productos y publicaciones ya soportan imágenes opcionales, subidas desde galería/cámara y mediante URL, con navegación de retorno consistente.
*   **Corrección de Errores y Advertencias del Analizador:** Se han resuelto todos los errores y advertencias reportados por el analizador de código de Flutter, asegurando una base de código más limpia y robusta.

---

## 🛠️ Arquitectura y Tecnologías

### Stack Tecnológico
- **Framework:** [Flutter](https://flutter.dev/)
- **Backend:** [Firebase](https://firebase.google.com/) (Authentication, Realtime Database, Storage, Cloud Functions, Cloud Messaging)
- **Pasarela de Pagos:** Integración con [Mercado Pago](https://www.mercadopago.com.mx/) a través de Cloud Functions (aunque la implementación actual prioriza la transferencia bancaria y pago contra entrega).

### Arquitectura de Software
La aplicación utiliza una arquitectura moderna y escalable, diseñada para ser mantenible y robusta:

-   **Capa de Servicios (Service Layer):** Toda la lógica de negocio y la comunicación con Firebase está encapsulada en clases de servicio dedicadas (ej. `AuthService`, `ProductService`, `UserService`). Esto desacopla la interfaz de usuario de la lógica del backend, facilitando el mantenimiento y futuras migraciones.

-   **Gestión de Estado con Provider:** Se utiliza el paquete [Provider](https://pub.dev/packages/provider) para la gestión de estado. Los `ChangeNotifierProvider` exponen los datos de los servicios a la UI, permitiendo que los widgets reaccionen y se reconstruyan de forma eficiente cuando los datos cambian.

-   **Rendimiento y Escalabilidad:** Las listas principales (feed de publicaciones, lista de productos, historial de órdenes) implementan **paginación** (infinite scroll). Esto asegura que la aplicación cargue los datos en lotes, manteniendo un rendimiento alto y un bajo consumo de datos, sin importar la cantidad de información en la base de datos.

-   **Notificaciones Push (FCM):** Se ha implementado la base para notificaciones push a través de Firebase Cloud Messaging (FCM). Una Cloud Function se encarga de enviar notificaciones a los usuarios cuando reciben nuevos mensajes de chat y ahora también para **actualizaciones de estado de pedidos**, asegurando una comunicación en tiempo real y contextualizada.

-   **Diseño Adaptable (Responsive Design):** La navegación principal de la aplicación es totalmente adaptable. Utiliza un widget `ResponsiveScaffold` personalizado que muestra un `NavigationRail` (menú lateral fijo) en pantallas anchas como tabletas o computadoras, y un `Drawer` (menú de hamburguesa) en pantallas estrechas como las de los móviles. Esto asegura una experiencia de usuario óptima en cualquier dispositivo.

### Estructura del Proyecto
El proyecto sigue una estructura organizada para facilitar la navegación y el mantenimiento:
- **`lib/models`**: Contiene los modelos de datos de la aplicación (ej. `User`, `Product`, `Order`).
- **`lib/providers`**: Incluye los `ChangeNotifier` que gestionan el estado de la aplicación.
- **`lib/screens`**: Contiene las diferentes pantallas de la aplicación, organizadas por rol (admin, buyer, seller).
- **`lib/services`**: Encapsula la lógica de negocio y la comunicación con servicios externos como Firebase.
- **`lib/widgets`**: Contiene widgets reutilizables utilizados en toda la aplicación.

---

## 🏁 Empezando

Para ejecutar este proyecto localmente, asegúrate de tener el [SDK de Flutter](https://docs.flutter.dev/get-started/install) instalado y sigue estos pasos:

1. **Clona el repositorio:**
   ```sh
   git clone https://github.com/cobsari123-dotcom/marcket_app2.git
   ```
2. **Navega al directorio del proyecto:**
   ```sh
   cd marcket_app
   ```
3. **Instala las dependencias:**
   ```sh
   flutter pub get
   ```
4. **Ejecuta la aplicación:**
   ```sh
   flutter run
   ```

## 🤝 Cómo Contribuir

¡Agradecemos tu interés en contribuir a Manos del Mar! Para hacer tus contribuciones, por favor sigue los siguientes pasos:

1.  Haz un "fork" de este repositorio.
2.  Crea una nueva rama para tus cambios (`git checkout -b feature/tu-caracteristica`).
3.  Realiza tus cambios y asegúrate de que el código pase todas las pruebas.
4.  Haz "commit" de tus cambios (`git commit -m 'feat: Añade tu nueva característica'`).
5.  Sube tu rama (`git push origin feature/tu-caracteristica`).
6.  Abre un "Pull Request" describiendo detalladamente tus cambios.

Por favor, asegúrate de que tu código siga las convenciones de estilo existentes y documenta cualquier cambio importante.

## © Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.