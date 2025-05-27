import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.sender.username[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSenderName && !isMe) ...[
                    Text(
                      message.sender.username,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (message.replyTo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${message.replyTo!.sender.username}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message.replyTo!.content,
                            style: TextStyle(
                              fontSize: 12,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeOnly,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        Text(
                          'edited',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white60 : Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getDeliveryIcon(),
                          size: 12,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Text(
                message.sender.username[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getDeliveryIcon() {
    switch (message.deliveryStatus) {
      case 'sent':
        return Icons.check;
      case 'delivered':
        return Icons.done_all;
      case 'read':
        return Icons.done_all;
      default:
        return Icons.schedule;
    }
  }
}
