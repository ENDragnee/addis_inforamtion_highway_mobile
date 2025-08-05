import 'package:addis_information_highway_mobile/models/data_request.dart';
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:addis_information_highway_mobile/features/dashboard/dashboard_content.dart'; // For RequestCard

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<DataRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchData();
  }

  Future<List<DataRequest>> _fetchData() {
    if (mounted) {
      return context.read<ApiService>().fetchDataRequests();
    }
    return Future.value([]);
  }

  // This method is now called by the RefreshIndicator
  Future<void> _refreshHistory() async {
    setState(() {
      _requestsFuture = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DataRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: draculaPink));
        }
        if (snapshot.hasError) {
          // You can create a more specific error widget if you like
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available.'));
        }

        // Filter for historical requests only
        final historicalRequests = snapshot.data!
            .where((r) => r.status != 'AWAITING_CONSENT')
            .toList();

        if (historicalRequests.isEmpty) {
          return const Center(
            child: Text(
              'Your request history is empty.',
              style: TextStyle(color: draculaComment),
            ),
          );
        }

        // ADDED: Wrap the ListView.builder with a RefreshIndicator
        return RefreshIndicator(
          onRefresh: _refreshHistory,
          color: draculaPink,
          backgroundColor: draculaCurrentLine,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: historicalRequests.length,
            itemBuilder: (context, index) {
              final req = historicalRequests[index];
              return RequestCard(
                request: req,
                onTap: () async {
                   context.goNamed('request-detail',
                    pathParameters: {'id': req.id},
                    extra: req.toJson(),
                  );
                  // Refreshing after viewing a historical item is optional, but good practice
                  _refreshHistory();
                },
              );
            },
          ),
        );
      },
    );
  }
}