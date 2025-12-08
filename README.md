# Marcket App: Manos del Mar 🛍️

¡Bienvenido a Marcket App, también conocida como "Manos del Mar"! Una aplicación móvil de comercio electrónico desarrollada con Flutter que conecta a artesanos y pescadores locales de Campeche, México, con consumidores interesados en productos auténticos y sostenibles.

## 🌟 La Misión de Manos del Mar

Nuestra misión es empoderar a los productores locales, aumentar sus ingresos y promover el rico patrimonio cultural de Campeche, ofreciendo una plataforma digital que supera las barreras de los intermediarios y la falta de visibilidad en línea.

## ✨ Características Principales

### Para Compradores 🛒
- **Feed de Productos y Publicaciones:** Explora un flujo constante de productos auténticos y publicaciones de diferentes vendedores, con paginación para un rendimiento óptimo.
- **Filtros y Ordenamiento:** Filtra las publicaciones por categoría y ordénalas por fecha o título para encontrar exactamente lo que buscas.
- **Lista de Deseos (Favoritos):** Guarda tus productos preferidos en una lista de favoritos para acceder a ellos fácilmente.
- **Carrito de Compras y Pedidos:** Añade productos al carrito, realiza pedidos y lleva un seguimiento de su estado en tu historial.
- **Chat Directo con Vendedores:** Comunícate directamente con artesanos y pescadores locales.
- **Reseñas y Calificaciones:** Valora los productos y vendedores después de una compra.

### Para Vendedores 🧑‍💼
- **Dashboard de Vendedor:** Un panel de control intuitivo para gestionar tu tienda.
- **Gestión de Productos y Publicaciones:** Añade, edita y elimina productos y publicaciones promocionales de forma sencilla.
- **Gestión de Pedidos:** Revisa y gestiona los pedidos realizados por los clientes.
- **Perfil de Vendedor Personalizado:** Personaliza tu perfil público con tu historia y la información de tu negocio.

### Para Administradores 👮
- **Dashboard de Administrador:** Un panel central para supervisar y gestionar la plataforma.
- **Gestión de Usuarios:** Busca, visualiza y elimina cuentas de compradores o vendedores.
- **Soporte Centralizado:** Atiende consultas y gestiona quejas de los usuarios a través de un chat y un sistema de tickets.
- **Notificaciones a Usuarios:** Envía avisos y notificaciones directamente a los usuarios.

---

## 🚀 Mejoras Recientes

A continuación, se detallan las *últimas* mejoras y correcciones implementadas para optimizar la experiencia de usuario y la estabilidad de la aplicación.
**Fecha de la Última Actualización:** domingo, 07 de diciembre de 2025

### Actualizaciones Recientes (Diciembre 2025)

*   **Perfiles y Registro:**
    *   La selección de género y el calendario para la fecha de nacimiento funcionan correctamente.
    *   Añadidos mensajes de confirmación de 3 segundos al guardar cambios en las pantallas de perfil.
*   **Auditoría de UI/UX:**
    *   Se realizó una auditoría completa de la UI/UX, confirmando que no hay títulos duplicados ni errores de navegación que redirijan al login o cierren la app inesperadamente.
*   **Subida de Imágenes Mejorada:**
    *   Tanto para **Productos** como para **Publicaciones**, ahora puedes añadir imágenes desde:
        1.  **Galería**
        2.  **Cámara** del teléfono
        3.  Una **URL** de internet
*   **Gestión de Usuarios (Administrador):**
    *   Nueva pantalla "Gestión de Usuarios" en el panel de administrador.
    *   Permite buscar, ver detalles y **eliminar permanentemente** cuentas de usuarios, junto con sus productos y publicaciones.
*   **Sistema de Alertas Administrador-Usuario:**
    *   Los administradores pueden enviar **alertas** a usuarios desde la pantalla de detalle.
    *   Los usuarios (Compradores y Vendedores) tienen una nueva sección "Alertas de Administrador" para ver y **responder** a estos mensajes.
*   **Feed de Publicaciones Estilo TikTok:**
    *   Las pantallas de inicio de todos los roles (Comprador, Vendedor y Administrador) ahora son un **feed de publicaciones a pantalla completa** con desplazamiento vertical.
    *   Implementada funcionalidad de **"Me Gusta"**, con actualización de contador en base de datos y UI.
    *   Funcionalidad de **Comentarios** que permite ver, añadir nuevos comentarios, y **subir imágenes** en ellos.
    *   Botón para **Compartir** publicaciones en redes sociales o mediante URL.
    *   Restricciones de rol: Administradores pueden ver pero no interactuar (dar "me gusta", comentar, compartir).
*   **Perfil Público de Vendedor Detallado:**
    *   La pantalla de perfil público de vendedor ahora cuenta con 3 pestañas: **Perfil**, **Publicaciones** y **Productos**.
    *   **Enlaces a Redes Sociales:** Integración de campos para Facebook, Instagram, TikTok, WhatsApp y sitio web en el perfil de edición del vendedor. Estos enlaces se muestran en el perfil público con iconos y acceso directo.
*   **Compartir Productos y Perfiles de Vendedor:**
    *   Añadida la función de **Compartir** para productos individuales desde su pantalla de detalles.
    *   Añadida la función de **Compartir** para el perfil público de los vendedores.

---

## 🛠️ Arquitectura y Tecnologías

### Stack Tecnológico
- **Framework:** [Flutter](https://flutter.dev/)
- **Backend:** [Firebase](https://firebase.google.com/) (Authentication, Realtime Database, Storage, Cloud Functions, Cloud Messaging)
- **Pasarela de Pagos:** Integración con [Mercado Pago](https://www.mercadopago.com.mx/) a través de Cloud Functions.

### Arquitectura de Software
La aplicación utiliza una arquitectura moderna y escalable, diseñada para ser mantenible y robusta:

-   **Capa de Servicios (Service Layer):** Toda la lógica de negocio y la comunicación con Firebase está encapsulada en clases de servicio dedicadas (ej. `AuthService`, `ProductService`, `UserService`). Esto desacopla la interfaz de usuario de la lógica del backend, facilitando el mantenimiento y futuras migraciones.

-   **Gestión de Estado con Provider:** Se utiliza el paquete [Provider](https://pub.dev/packages/provider) para la gestión de estado. Los `ChangeNotifierProvider` exponen los datos de los servicios a la UI, permitiendo que los widgets reaccionen y se reconstruyan de forma eficiente cuando los datos cambian.

-   **Rendimiento y Escalabilidad:** Las listas principales (feed de publicaciones, lista de productos, historial de órdenes) implementan **paginación** (infinite scroll). Esto asegura que la aplicación cargue los datos en lotes, manteniendo un rendimiento alto y un bajo consumo de datos, sin importar la cantidad de información en la base de datos.

-   **Notificaciones Push (FCM):** Se ha implementado la base para notificaciones push a través de Firebase Cloud Messaging (FCM). Una Cloud Function se encarga de enviar notificaciones a los usuarios cuando reciben nuevos mensajes de chat, asegurando una comunicación en tiempo real.

-   **Diseño Adaptable (Responsive Design):** La navegación principal de la aplicación es totalmente adaptable. Utiliza un widget `ResponsiveScaffold` personalizado que muestra un `NavigationRail` (menú lateral fijo) en pantallas anchas como tabletas o computadoras, y un `Drawer` (menú de hamburguesa) en pantallas estrechas como las de los móviles. Esto asegura una experiencia de usuario óptima en cualquier dispositivo.

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