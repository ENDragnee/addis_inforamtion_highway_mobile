import 'package:addis_information_highway_mobile/models/data_request.dart';
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import  'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  late Future<List<DataRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the initial data when the widget is first created.
    _requestsFuture = _fetchData();
  }

  // Helper function to fetch data from the ApiService.
  Future<List<DataRequest>> _fetchData() {
    // We use `mounted` check to prevent errors if the widget is disposed
    // while the async operation is in flight.
    if (mounted) {
      return context.read<ApiService>().fetchDataRequests();
    }
    return Future.value([]); // Return an empty list if not mounted
  }

  // This method is called by the pull-to-refresh indicator and
  // after returning from the detail screen.
  Future<void> _refreshRequests() async {
    // This triggers the FutureBuilder to re-run with the new Future.
    setState(() {
      _requestsFuture = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DataRequest>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        // --- 1. Loading State ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: draculaPink));
        }

        // --- 2. Error State ---
        if (snapshot.hasError) {
          return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.serverCrash, color: draculaRed, size: 60),
                    const SizedBox(height: 16),
                    Text('Failed to load requests', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), style: const TextStyle(color: draculaComment), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshRequests,
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              )
          );
        }

        // --- 3. Empty & Success States ---
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available.'));
        }

        final allRequests = snapshot.data!;
        final pendingRequests = allRequests.where((r) => r.status == 'AWAITING_CONSENT').toList();

        // --- 3a. Success State (No Pending Requests) ---
        if (pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.checkCheck, size: 80, color: draculaGreen),
                const SizedBox(height: 16),
                Text('All Caught Up!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('You have no pending consent requests.', style: TextStyle(color: draculaComment)),
              ],
            ),
          );
        }

        // --- 3b. Success State (With Pending Requests) ---
        // The RefreshIndicator widget wraps the scrollable list.
        return RefreshIndicator(
          onRefresh: _refreshRequests, // This is the magic line
          color: draculaPink,
          backgroundColor: draculaCurrentLine,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Pending Requests (${pendingRequests.length})', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ...pendingRequests.map((req) => RequestCard(
                request: req,
                onTap: () async {
                  context.goNamed('request-detail',
                    pathParameters: {'id': req.id},
                    extra: req.toJson(),
                  );
                  _refreshRequests();
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

class RequestCard extends StatelessWidget {
  final DataRequest request;
  final VoidCallback onTap;

  const RequestCard({
    required this.request,
    required this.onTap,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // The InkWell provides the ripple effect on tap
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Match Card's border radius
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use Flexible to prevent long titles from causing overflow
                  Flexible(
                    child: Text(
                      request.dataSchema['description'],
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 12),

              // Details Section
              Text(
                'From: ${request.provider['name']}',
                style: const TextStyle(color: draculaComment, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'To: ${request.requester['name']}',
                style: const TextStyle(color: draculaComment, fontSize: 13),
              ),

              // Conditional "Awaiting Response" indicator
              if (request.status == 'AWAITING_CONSENT') ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                        'Awaiting your response... ',
                        style: TextStyle(color: draculaOrange, fontStyle: FontStyle.italic, fontSize: 13)
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: draculaOrange)
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Status Badge Widget
// ===========================================================================
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    // Determine color based on the status string
    final (Color color, IconData? icon) = switch (status) {
      'AWAITING_CONSENT' => (draculaOrange, Icons.hourglass_empty_rounded),
      'APPROVED' || 'COMPLETED' => (draculaGreen, Icons.check_circle_rounded),
      'DENIED' || 'EXPIRED' || 'FAILED' => (draculaRed, Icons.cancel_rounded),
      _ => (draculaComment, null),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            // Replace underscores with spaces for readability
            status.replaceAll('_', ' '),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
