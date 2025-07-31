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
    _requestsFuture = context.read<ApiService>().fetchDataRequests();
  }

  void _refreshHistory() {
    setState(() {
      _requestsFuture = context.read<ApiService>().fetchDataRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DataRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data requests found.'));
        }

        // Filter for historical requests only
        final historicalRequests = snapshot.data!.where((r) => r.status != 'AWAITING_CONSENT').toList();

        if (historicalRequests.isEmpty) {
          return const Center(child: Text('Your request history is empty.', style: TextStyle(color: draculaComment)));
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: historicalRequests.length,
            itemBuilder: (context, index) {
              final req = historicalRequests[index];
              return RequestCard(
                request: req,
                onTap: () {
                  context.goNamed('request-detail',
                    pathParameters: {'id': req.id},
                    extra: req.toJson(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}