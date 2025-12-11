import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/providers/feed_provider.dart';
import 'package:marcket_app/providers/theme_provider.dart';
import 'package:marcket_app/providers/product_list_provider.dart';
import 'package:marcket_app/providers/order_list_provider.dart';
import 'package:marcket_app/providers/seller_order_list_provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/providers/admin_dashboard_provider.dart';
import 'package:marcket_app/providers/user_management_provider.dart';
import 'package:marcket_app/providers/admin_complaints_provider.dart';
import 'package:marcket_app/providers/wishlist_provider.dart';
import 'package:marcket_app/providers/notification_service.dart';
import 'package:marcket_app/services/auth_management_service.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart';
import 'package:marcket_app/screens/chat/chat_screen.dart';
import 'package:marcket_app/screens/public_seller_profile_screen.dart';
import 'package:marcket_app/screens/seller/publication_details_screen.dart';
import 'package:marcket_app/screens/welcome_screen.dart';
import 'package:marcket_app/screens/login_screen.dart';
import 'package:marcket_app/screens/register_screen.dart';
import 'package:marcket_app/screens/home_screen.dart';
import 'package:marcket_app/screens/recover_password_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_dashboard_screen.dart';
import 'package:marcket_app/screens/buyer/favorites_screen.dart';
import 'package:marcket_app/screens/buyer/reels_publications_screen.dart';
import 'package:marcket_app/screens/common/welcome_dashboard_screen.dart';
import 'package:marcket_app/screens/seller/seller_dashboard_screen.dart';
import 'package:marcket_app/screens/seller/add_edit_product_screen.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:marcket_app/screens/admin/admin_dashboard_screen.dart';
import 'package:marcket_app/screens/admin/admin_home_screen.dart';
import 'package:marcket_app/screens/seller/create_edit_publication_screen.dart';
import 'package:marcket_app/screens/app_initializer.dart';
import 'package:marcket_app/screens/complete_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Handler para mensajes en segundo plano o cuando la app está terminada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => ProductListProvider()),
        ChangeNotifierProvider(create: (_) => OrderListProvider()),
        ChangeNotifierProvider(create: (_) => SellerOrderListProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => UserManagementProvider()),
        ChangeNotifierProvider(create: (_) => AdminComplaintsProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        Provider<AuthManagementService>(create: (_) => AuthManagementService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Manos del Mar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/app_initializer', // Usar el AppInitializer
            routes: {
              '/app_initializer': (context) => const AppInitializer(),
              '/splash': (context) => const SplashScreen(),
              '/': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                final userType = args is String ? args : 'Buyer';
                return HomeScreen(userType: userType);
              },
              '/recover_password': (context) => const RecoverPasswordScreen(),
              '/buyer_dashboard': (context) => const BuyerDashboardScreen(),
              '/seller_dashboard': (context) => const SellerDashboardScreen(),
              '/admin_dashboard': (context) => const AdminDashboardScreen(),
              '/admin_home': (context) => const AdminHomeScreen(),
              '/complete_profile': (context) {
                final user = ModalRoute.of(context)!.settings.arguments as User;
                return CompleteProfileScreen(user: user);
              },
              '/add_edit_product': (context) {
                final product =
                    ModalRoute.of(context)!.settings.arguments as Product?;
                return AddEditProductScreen(product: product);
              },
              '/create_edit_publication': (context) {
                final publication =
                    ModalRoute.of(context)!.settings.arguments as Publication?;
                return CreateEditPublicationScreen(publication: publication);
              },
              '/publication_details': (context) {
                final args = ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
                final publication = args['publication'] as Publication;
                final bool isAdmin = args['isAdmin'] ?? false;
                return PublicationDetailsScreen(
                    publication: publication, isAdmin: isAdmin);
              },
              '/chat_list': (context) => const ChatListScreen(),
              '/chat': (context) {
                final arguments = ModalRoute.of(context)!.settings.arguments;
                Map<String, String> chatArgs; // Make it non-nullable by default

                if (arguments is Map<String, dynamic> &&
                    arguments.containsKey('chatRoomId') &&
                    arguments.containsKey('otherUserName') &&
                    arguments['chatRoomId'] is String &&
                    arguments['otherUserName'] is String) {
                  chatArgs = Map<String, String>.from(arguments);
                } else {
                  // Log the unexpected argument type for debugging
                  debugPrint(
                      'Error: /chat route received unexpected arguments type or format. Received: $arguments (Type: ${arguments.runtimeType})');
                  return const Scaffold(
                      body: Center(
                          child: Text("Error: Argumentos de chat inválidos.")));
                }

                return ChatScreen(
                  chatRoomId: chatArgs['chatRoomId']!,
                  otherUserName: chatArgs['otherUserName']!,
                );
              },
              '/favorites': (context) => const FavoritesScreen(),
              '/reels_publications': (context) => const ReelsPublicationsScreen(),
              '/welcome_dashboard': (context) => const WelcomeDashboardScreen(),
              '/public_seller_profile': (context) {
                final arguments = ModalRoute.of(context)!.settings.arguments;
                if (arguments is Map<String, dynamic>) {
                  final sellerId = arguments['sellerId'] as String?;
                  final isAdmin = arguments['isAdmin'] as bool? ?? false;
                  if (sellerId != null) {
                    return PublicSellerProfileScreen(
                        sellerId: sellerId, isAdmin: isAdmin);
                  }
                }
                return const Scaffold(
                    body: Center(child: Text("Error: Seller ID not provided.")));
              },
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'ES'),
            ],
          );
        },
      ),
    );
  }
}
