import 'package:addis_information_highway_mobile/models/data_request.dart';
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:addis_information_highway_mobile/theme/dracula_theme.dart';
import 'package:addis_information_highway_mobile/features/dashboard/dashboard_content.dart'; // For StatusBadge
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  // initialData is an optimization to avoid re-fetching when navigating from a list.
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
  // Use a Future to manage the state of the data fetching.
  late Future<DataRequest> _requestFuture;
  bool _isResponding = false; // Separate loading state for the action buttons

  @override
  void initState() {
    super.initState();
    // Decide whether to use the pre-loaded data or fetch it.
    if (widget.initialData != null) {
      // If data is already available, create a completed Future instantly.
      _requestFuture = Future.value(DataRequest.fromJson(widget.initialData!));
    } else {
      // If navigating directly to this screen, fetch the data from the API.
      _requestFuture = _fetchRequestDetails();
    }
  }

  /// Fetches the details for a single request. This is the fallback.
  Future<DataRequest> _fetchRequestDetails() async {
    try {
      // This assumes your ApiService has a method to fetch a single request.
      // If not, you would filter the list from `fetchDataRequests`.
      final allRequests = await context.read<ApiService>().fetchDataRequests();
      return allRequests.firstWhere((req) => req.id == widget.requestId);
    } catch (e) {
      // Propagate the error to be handled by the FutureBuilder.
      throw Exception('Failed to load request details.');
    }
  }

  /// Handles the user's response (Approve/Deny) to the request.
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
          ),
        );
        // Go back to the dashboard after a successful response.
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: draculaRed,
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
      appBar: AppBar(title: const Text('Request Details')),
      body: FutureBuilder<DataRequest>(
        future: _requestFuture,
        builder: (context, snapshot) {
          // --- State 1: Loading ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          // --- State 2: Error ---
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          // --- State 3: Success ---
          // The data is guaranteed to be available here.
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(Icons.security_rounded, size: 80, color: draculaPurple),
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
          const SizedBox(height: 32),
          const Text(
            'A data sharing request has been made:',
            style: TextStyle(color: draculaComment),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            icon: Icons.business_rounded,
            label: 'Requesting Institution',
            value: request.requester['name'],
            valueColor: draculaCyan,
          ),
          _buildDetailRow(
            icon: Icons.source_rounded,
            label: 'Data Provider',
            value: request.provider['name'],
          ),
          _buildDetailRow(
            icon: Icons.description_rounded,
            label: 'Data Requested',
            value: request.dataSchema['description'],
          ),
          const SizedBox(height: 48),

          if (isActionable)
            _buildActionButtons()
          else
            Center(
              child: Text(
                'This request has been actioned and is no longer pending.',
                textAlign: TextAlign.center,
                style: TextStyle(color: draculaComment, fontStyle: FontStyle.italic),
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: draculaComment, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: draculaComment, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? draculaForeground,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
        ? const Center(child: CircularProgressIndicator())
        : Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleResponse('APPROVE'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Approve'),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(draculaGreen),
            padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _handleResponse('DENY'),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Deny'),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(draculaRed),
            padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ],
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
            const Icon(Icons.error_outline, color: draculaRed, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Request',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: draculaComment),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _requestFuture = _fetchRequestDetails();
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}