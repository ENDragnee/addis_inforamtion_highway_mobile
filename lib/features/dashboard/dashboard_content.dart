import 'package:addis_information_highway_mobile/models/data_request.dart';
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    _requestsFuture = context.read<ApiService>().fetchDataRequests();
  }

  void _refreshRequests() {
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

        final allRequests = snapshot.data!;
        final pendingRequests = allRequests.where((r) => r.status == 'AWAITING_CONSENT').toList();

        if (pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 80, color: draculaGreen),
                const SizedBox(height: 16),
                Text('All Caught Up!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('You have no pending consent requests.', style: TextStyle(color: draculaComment)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshRequests(),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Pending Requests', style: Theme.of(context).textTheme.headlineSmall),
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
