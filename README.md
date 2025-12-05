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
- **Chat Directo con Vendedores:** Comunícate directamente con los vendedores para resolver dudas.
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

## 🚀 Mejoras Recientes

A continuación, se detallan las *últimas* mejoras y correcciones implementadas para optimizar la experiencia de usuario y la estabilidad de la aplicación.
**Fecha de la Última Actualización:** viernes, 05 de diciembre de 2025

### Actualizaciones Recientes (Diciembre 2025)

-   **Panel de Administrador Mejorado:**
    *   La pantalla principal para administradores ahora es un feed de publicaciones completo.
    *   Implementado un modo de solo lectura para administradores en el feed, detalles de publicaciones y detalles de productos (sin opciones de compra, comentarios o calificaciones).
    *   Pantalla de perfil de administrador completamente rediseñada con estadísticas, información extendida, y funciones de seguridad (cambio de contraseña).
    *   Integrado el inicio de sesión con Google para administradores a través de una lista blanca de correos en Firebase (requiere configuración manual de emails en la base de datos).
    *   Se eliminó la opción de que los administradores cambien su foto de perfil, manteniendo un ícono predeterminado.
-   **Perfiles de Vendedor Detallados:**
    *   Implementada una vista de perfil público de vendedor con 3 pestañas (Productos, Publicaciones, Información del perfil).
    *   Esta vista es accesible tanto desde el feed principal como desde la gestión de usuarios, y opera en modo de solo lectura para administradores.
-   **Gestión de Usuarios Optimizada:**
    *   Al seleccionar un usuario en la pantalla de gestión, ahora se accede a su perfil público detallado (con las 3 pestañas).
-   **Mejoras en el Chat de Soporte (Administradores):**
    *   El listado de chats de soporte ahora muestra claramente el rol del usuario (Comprador/Vendedor) con etiquetas visuales (`Chips`).
    *   Se confirmó la funcionalidad existente de envío de imágenes y archivos en el chat.
-   **Correcciones de Estabilidad y Lints:**
    *   Se corrigieron errores de sintaxis y lints para mejorar la calidad y estabilidad del código.

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

---

## 🏁 Empezando

Para ejecutar este proyecto localmente, asegúrate de tener el [SDK de Flutter](https://docs.flutter.dev/get-started/install) instalado y sigue estos pasos:

1. **Clona el repositorio:**
   ```sh
   git clone https://github.com/cobsari123-dotcom/marcket_app.git
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

"Actualizaci�n para forzar la recarga de GitHub" 
