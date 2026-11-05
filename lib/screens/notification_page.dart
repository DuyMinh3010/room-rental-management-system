import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'invoice_detail_page.dart';
import 'room_detail_page.dart';

class NotificationPage extends StatelessWidget {
  final bool landlord;
  const NotificationPage({super.key, this.landlord = true});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: AppBar(
      backgroundColor: canvas,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 30, color: ink),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: const Text(
        'Thông báo',
        style: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    body: RecordsView(
      collection: 'notifications',
      field: landlord ? 'audience' : 'recipientUid',
      equals: landlord ? 'managers' : store.uid,
      builder: (_, all) => RecordsView(
        collection: 'users/${store.uid}/reads',
        builder: (_, reads) {
          all.sort(
            (a, b) => (b.time('createdAt') ?? DateTime(2000)).compareTo(
              a.time('createdAt') ?? DateTime(2000),
            ),
          );
          final readIds = reads.map((r) => r.id).toSet();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (all.isEmpty) empty('Chưa có thông báo'),
              for (final n in all)
                Builder(
                  builder: (context) {
                    final isRead = readIds.contains(n.id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRead
                              ? line
                              : blue.withValues(alpha: 0.35),
                          width: isRead ? 0.7 : 1.1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          try {
                            await store.markRead(n.id);
                          } catch (e) {
                            if (context.mounted) message(context, e.toString());
                          }
                          if (!context.mounted) return;
                          if (n.text('invoiceId').isNotEmpty) {
                            await openPage(
                              context,
                              InvoiceDetailPage(
                                invoiceId: n.text('invoiceId'),
                                landlord: landlord,
                              ),
                            );
                          } else if (landlord && n.text('roomId').isNotEmpty) {
                            await openPage(
                              context,
                              RoomDetailPage(roomId: n.text('roomId')),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? const Color(0xFFF1F5F9)
                                      : softBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isRead
                                      ? Icons.notifications_none_rounded
                                      : Icons.mark_email_unread_outlined,
                                  color: isRead ? muted : blue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.text('title'),
                                            style: TextStyle(
                                              color: ink,
                                              fontSize: 13.5,
                                              fontWeight: isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: blue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.text('body'),
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      n
                                              .time('createdAt')
                                              ?.toLocal()
                                              .toString()
                                              .substring(0, 16) ??
                                          '',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    ),
  );
}

class NotificationButton extends StatelessWidget {
  final bool landlord;
  const NotificationButton({super.key, this.landlord = true});
  @override
  Widget build(BuildContext context) => RecordsView(
    collection: 'notifications',
    field: landlord ? 'audience' : 'recipientUid',
    equals: landlord ? 'managers' : store.uid,
    builder: (_, notices) => RecordsView(
      collection: 'users/${store.uid}/reads',
      builder: (_, reads) {
        final seen = reads.map((r) => r.id).toSet();
        final count = notices.where((n) => !seen.contains(n.id)).length;
        return IconButton(
          onPressed: () =>
              openPage(context, NotificationPage(landlord: landlord)),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.notifications_outlined, color: ink),
          ),
        );
      },
    ),
  );
}
