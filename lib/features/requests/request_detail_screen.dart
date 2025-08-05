import 'package:addis_information_highway_mobile/models/data_request.dart';
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:addis_information_highway_mobile/features/dashboard/dashboard_content.dart'; // For StatusBadge
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic>? initialData;

  const RequestDetailScreen({
    required this.requestId,
    this.initialData,
    super.key,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late Future<DataRequest> _requestFuture;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _requestFuture = Future.value(DataRequest.fromJson(widget.initialData!));
    } else {
      _requestFuture = _fetchRequestDetails();
    }
  }

  Future<DataRequest> _fetchRequestDetails() async {
    try {
      final allRequests = await context.read<ApiService>().fetchDataRequests();
      return allRequests.firstWhere((req) => req.id == widget.requestId,
          orElse: () => throw Exception('Request with ID ${widget.requestId} not found.'));
    } catch (e) {
      throw Exception('Failed to load request details.');
    }
  }

  Future<void> _handleResponse(String action) async {
    setState(() => _isResponding = true);
    try {
      final message = await context
          .read<ApiService>()
          .respondToRequest(widget.requestId, action);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: draculaGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop(); // Go back to the previous screen (Dashboard/History)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: draculaRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        // --- NEW: Home button added to the AppBar ---
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.house),
            tooltip: 'Go to Dashboard',
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<DataRequest>(
        future: _requestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          final request = snapshot.data!;
          return _buildContent(context, request);
        },
      ),
    );
  }

  /// The main content widget, built only when data is successfully loaded.
  Widget _buildContent(BuildContext context, DataRequest request) {
    final isActionable = request.status == 'AWAITING_CONSENT';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Reduced vertical padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(LucideIcons.shieldCheck, size: 64, color: draculaPurple), // Smaller icon
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Consent Request',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: StatusBadge(status: request.status),
          ),
          const SizedBox(height: 24), // Reduced spacing
          const Text(
            'A data sharing request has been made:',
            style: TextStyle(color: draculaComment),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: LucideIcons.building2,
                    label: 'Requesting Institution',
                    value: request.requester['name'],
                    valueColor: draculaCyan,
                  ),
                  const Divider(color: draculaCurrentLine),
                  _buildDetailRow(
                    icon: LucideIcons.database,
                    label: 'Data Provider',
                    value: request.provider['name'],
                  ),
                  const Divider(color: draculaCurrentLine),
                  _buildDetailRow(
                    icon: LucideIcons.fileText,
                    label: 'Data Requested',
                    value: request.dataSchema['description'],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32), // Reduced spacing

          // Use an AnimatedSwitcher for a smooth transition between button states
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isActionable
                ? _buildActionButtons()
                : _buildNonActionableMessage(), // Show the info message for historical items
          ),
        ],
      ),
    );
  }

  /// A reusable widget for displaying a detail row.
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: draculaComment, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: draculaComment, fontSize: 12)),
                const SizedBox(height: 4),
                // AnimatedSwitcher provides a nice fade when data changes
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    value,
                    key: ValueKey<String>(value), // Important for the animation to trigger
                    style: TextStyle(
                      color: valueColor ?? draculaForeground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// A widget for the Approve/Deny action buttons.
  Widget _buildActionButtons() {
    return _isResponding
        ? const Center(child: CircularProgressIndicator(color: draculaPink))
        : Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleResponse('APPROVE'),
          icon: const Icon(LucideIcons.check),
          label: const Text('Approve'),
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(vertical: 16)),
            backgroundColor: WidgetStateProperty.all(draculaGreen),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon( // Use OutlinedButton for a secondary action
          onPressed: () => _handleResponse('DENY'),
          icon: const Icon(LucideIcons.x),
          label: const Text('Deny'),
          style: OutlinedButton.styleFrom(
            foregroundColor: draculaRed,
            side: const BorderSide(color: draculaRed),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  /// NEW WIDGET: A simple text message for historical requests.
  Widget _buildNonActionableMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'This request has been actioned and is no longer pending.',
          textAlign: TextAlign.center,
          style: TextStyle(color: draculaComment, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  /// A widget to display while data is loading.
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: draculaPink),
          SizedBox(height: 16),
          Text('Loading Request Details...', style: TextStyle(color: draculaComment)),
        ],
      ),
    );
  }

  /// A widget to display when an error occurs during fetching.
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.serverCrash, color: draculaRed, size: 60),
            const SizedBox(height: 16),
            const Text('Failed to Load Request', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: draculaComment), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _requestFuture = _fetchRequestDetails();
                });
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}