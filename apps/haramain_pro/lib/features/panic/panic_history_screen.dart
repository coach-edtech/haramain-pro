import 'package:flutter/material.dart';
import 'panic_service.dart';

/// Panic history screen showing list of recent panic alerts
/// Supports filtering by status and date
class PanicHistoryScreen extends StatefulWidget {
  final bool isJamaah;
  final String? jamaaahId;
  final String? grupId;
  final Function(PanicAlert alert)? onAlertTap;

  const PanicHistoryScreen({
    super.key,
    this.isJamaah = false,
    this.jamaaahId,
    this.grupId,
    this.onAlertTap,
  });

  @override
  State<PanicHistoryScreen> createState() => _PanicHistoryScreenState();
}

class _PanicHistoryScreenState extends State<PanicHistoryScreen> {
  List<PanicAlert> _alerts = [];
  bool _isLoading = true;
  
  // Filters
  PanicStatus? _statusFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<PanicAlert> history = await PanicService.instance.getPanicHistory(
        fromDate: _fromDate,
        toDate: _toDate,
      );

      // Filter by status if set
      if (_statusFilter != null) {
        history = history.where((a) => a.status == _statusFilter).toList();
      }

      // For Jamaah, filter to only their alerts
      if (widget.isJamaah && widget.jamaaahId != null) {
        history = history.where((a) => a.jamaaahId == widget.jamaaahId).toList();
      }

      // For group context, filter by grup
      if (widget.grupId != null) {
        history = history.where((a) => a.grupId == widget.grupId).toList();
      }

      setState(() {
        _alerts = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading panic history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        currentStatus: _statusFilter,
        currentFromDate: _fromDate,
        currentToDate: _toDate,
        onApply: (status, fromDate, toDate) {
          setState(() {
            _statusFilter = status;
            _fromDate = fromDate;
            _toDate = toDate;
          });
          _loadHistory();
        },
      ),
    );
  }

  String _getStatusLabel(PanicStatus status) {
    switch (status) {
      case PanicStatus.pending:
        return 'Pending';
      case PanicStatus.sent:
        return 'Sent';
      case PanicStatus.failed:
        return 'Failed';
      case PanicStatus.responded:
        return 'Responded';
      case PanicStatus.resolved:
        return 'Resolved';
    }
  }

  Color _getStatusColor(PanicStatus status) {
    switch (status) {
      case PanicStatus.pending:
        return Colors.orange;
      case PanicStatus.sent:
        return Colors.blue;
      case PanicStatus.failed:
        return Colors.red;
      case PanicStatus.responded:
        return Colors.green;
      case PanicStatus.resolved:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PanicStatus status) {
    switch (status) {
      case PanicStatus.pending:
        return Icons.hourglass_empty;
      case PanicStatus.sent:
        return Icons.send;
      case PanicStatus.failed:
        return Icons.error_outline;
      case PanicStatus.responded:
        return Icons.check_circle;
      case PanicStatus.resolved:
        return Icons.done_all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panic History'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No panic alerts found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      return _AlertCard(
                        alert: alert,
                        statusLabel: _getStatusLabel(alert.status),
                        statusColor: _getStatusColor(alert.status),
                        statusIcon: _getStatusIcon(alert.status),
                        onTap: () => widget.onAlertTap?.call(alert),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Alert card widget
class _AlertCard extends StatelessWidget {
  final PanicAlert alert;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.alert,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alert ${alert.id.substring(0, 8)}...',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Group: ${alert.grupId}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(alert.timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (alert.responderId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Responder: ${alert.responderId!.substring(0, 8)}...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (alert.responseType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alert.responseType!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Filter bottom sheet
class _FilterBottomSheet extends StatefulWidget {
  final PanicStatus? currentStatus;
  final DateTime? currentFromDate;
  final DateTime? currentToDate;
  final Function(PanicStatus?, DateTime?, DateTime?) onApply;

  const _FilterBottomSheet({
    this.currentStatus,
    this.currentFromDate,
    this.currentToDate,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  PanicStatus? _selectedStatus;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _fromDate = widget.currentFromDate;
    _toDate = widget.currentToDate;
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status filter
          const Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PanicStatus.values.map((status) {
              final isSelected = _selectedStatus == status;
              return FilterChip(
                label: Text(_getStatusLabel(status)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Date range
          const Text(
            'Date Range',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectDate(true),
                  child: Text(_fromDate != null
                      ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                      : 'From Date'),
                ),
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectDate(false),
                  child: Text(_toDate != null
                      ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                      : 'To Date'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedStatus, _fromDate, _toDate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(PanicStatus status) {
    switch (status) {
      case PanicStatus.pending:
        return 'Pending';
      case PanicStatus.sent:
        return 'Sent';
      case PanicStatus.failed:
        return 'Failed';
      case PanicStatus.responded:
        return 'Responded';
      case PanicStatus.resolved:
        return 'Resolved';
    }
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[PanicHistoryScreen] $message');
}
