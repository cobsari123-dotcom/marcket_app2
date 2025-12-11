import 'package:flutter/material.dart';
import 'package:marcket_app/models/faq_item.dart';
import 'package:marcket_app/services/faq_service.dart';
import 'package:provider/provider.dart';
import 'package:marcket_app/providers/user_profile_provider.dart';
import 'package:marcket_app/models/user.dart'; // Import UserModel

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FaqService _faqService = FaqService();
  List<FaqItem> _buyerFaqs = [];
  List<FaqItem> _sellerFaqs = [];
  List<FaqItem> _adminFaqs = [];
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // Initial length 1, will be updated
    _loadFaqs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = Provider.of<UserProfileProvider>(context, listen: false).currentUserModel;
    _updateTabController();
  }

  void _updateTabController() {
    int newLength = 0;
    if (_currentUser?.userType == 'Buyer') {
      newLength = 1;
    } else if (_currentUser?.userType == 'Seller') {
      newLength = 2; // Buyer + Seller tabs
    } else if (_currentUser?.userType == 'Admin') {
      newLength = 3; // Buyer + Seller + Admin tabs
    } else {
      newLength = 1; // Default to Buyer tab for unauthenticated users
    }

    if (_tabController.length != newLength) {
      _tabController.dispose();
      _tabController = TabController(length: newLength, vsync: this);
    }
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
    });

    _buyerFaqs = await _faqService.getFaqsByRole('Buyer');
    _sellerFaqs = await _faqService.getFaqsByRole('Seller');
    _adminFaqs = await _faqService.getFaqsByRole('Admin');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateTabController(); // Update tab controller length based on user role

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<Widget> tabs = [];
    List<Widget> tabViews = [];

    // Always include Buyer tab
    tabs.add(const Tab(text: 'Compradores'));
    tabViews.add(_FaqList(faqItems: _buyerFaqs));

    if (_currentUser?.userType == 'Seller' || _currentUser?.userType == 'Admin') {
      tabs.add(const Tab(text: 'Vendedores'));
      tabViews.add(_FaqList(faqItems: _sellerFaqs));
    }
    if (_currentUser?.userType == 'Admin') {
      tabs.add(const Tab(text: 'Administradores'));
      tabViews.add(_FaqList(faqItems: _adminFaqs));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: tabs,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: TabBarView(
            controller: _tabController,
            children: tabViews,
          ),
        ),
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  final List<FaqItem> faqItems;

  const _FaqList({required this.faqItems});

  @override
  Widget build(BuildContext context) {
    if (faqItems.isEmpty) {
      return const Center(
        child: Text('No hay preguntas frecuentes para este rol.'),
      );
    }
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