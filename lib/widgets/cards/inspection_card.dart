import 'package:flutter/material.dart';
import 'package:medical_lab_flutter/models/inspection_model.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class InspectionCard extends StatelessWidget {
  final Inspection inspection;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showActions;

  const InspectionCard({
    super.key,
    required this.inspection,
    this.onTap,
    this.showStatus = true,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final timeFormat = DateFormat('hh:mm a', 'ar');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inspection.typeArabic,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Gap(4),
                        if (inspection.description != null)
                          Text(
                            inspection.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (showStatus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: inspection.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: inspection.statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            inspection.statusIcon,
                            size: 14,
                            color: inspection.statusColor,
                          ),
                          const Gap(4),
                          Text(
                            inspection.statusArabic,
                            style: TextStyle(
                              fontSize: 12,
                              color: inspection.statusColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Gap(16),

              // Inspection Details
              Row(
                children: [
                  _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'التاريخ',
                    value: inspection.scheduledDate != null
                        ? dateFormat.format(inspection.scheduledDate!)
                        : 'غير محدد',
                  ),
                  const Gap(16),
                  _buildDetailItem(
                    icon: Icons.location_on,
                    label: 'المكان',
                    value: inspection.location ?? 'غير محدد',
                  ),
                  const Gap(16),
                  _buildDetailItem(
                    icon: Icons.person,
                    label: 'الفاحص',
                    value: inspection.inspector?.name ?? 'لم يتم التعيين',
                  ),
                ],
              ),

              // Result
              if (inspection.result != null) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: inspection.passed == true
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        inspection.passed == true
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: inspection.passed == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inspection.result!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: inspection.passed == true
                                    ? Colors.green[800]
                                    : Colors.red[800],
                                fontFamily: 'Cairo',
                              ),
                            ),
                            if (inspection.score != null) ...[
                              const Gap(4),
                              LinearProgressIndicator(
                                value: inspection.score! / 100,
                                backgroundColor: Colors.grey[200],
                                color: inspection.score! >= 70
                                    ? Colors.green
                                    : inspection.score! >= 50
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                              const Gap(4),
                              Text(
                                '${inspection.score!.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Report
              if (inspection.reportUrl != null) ...[
                const Gap(12),
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.blue),
                    const Gap(8),
                    Text(
                      'تقرير الفحص متاح',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // TODO: View report
                      },
                      child: const Text(
                        'عرض التقرير',
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              if (showActions) ...[
                const Gap(16),
                Row(
                  children: [
                    if (inspection.status == 'SCHEDULED') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Start inspection
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text(
                            'بدء الفحص',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                      const Gap(8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: View details
                        },
                        child: const Text(
                          'تفاصيل',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class InspectionRequestCard extends StatelessWidget {
  final InspectionRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const InspectionRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.type,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const Gap(4),
                        Text(
                          request.priority == 'HIGH'
                              ? '🟥 عالي'
                              : request.priority == 'MEDIUM'
                              ? '🟨 متوسط'
                              : '🟩 منخفض',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'طلب جديد',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),

              // Details
              Text(
                request.reason,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontFamily: 'Cairo',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(12),

              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const Gap(8),
                  Text(
                    request.desiredDate != null
                        ? 'مطلوب في: ${dateFormat.format(request.desiredDate!)}'
                        : 'بدون تاريخ محدد',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              const Gap(8),

              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      request.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Gap(8),

              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const Gap(8),
                  Text(
                    request.contactPhone,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),

              // Actions
              if (onApprove != null || onReject != null) ...[
                const Gap(16),
                Row(
                  children: [
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text(
                            'رفض',
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                    if (onApprove != null) ...[
                      if (onReject != null) const Gap(8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'موافقة',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Cairo',
                            ),
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
}
