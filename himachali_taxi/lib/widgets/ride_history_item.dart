import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride.dart';

class RideHistoryItem extends StatelessWidget {
  final Ride ride;
  final VoidCallback? onTap;

  const RideHistoryItem({
    Key? key,
    required this.ride,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(ride.timestamps.requested),
                    style: theme.textTheme.bodySmall,
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 16),
              _buildLocationInfo(
                icon: Icons.location_on,
                label: 'Pickup',
                address: ride.pickup.address,
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildLocationInfo(
                icon: Icons.location_on,
                label: 'Dropoff',
                address: ride.dropoff.address,
                theme: theme,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.duration.toStringAsFixed(0)} mins',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.straighten,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.distance.toStringAsFixed(1)} km',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    '₹${ride.fare.total.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (ride.status == 'COMPLETED' &&
                  (ride.passengerRating != null || ride.captainRating != null))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(ride.passengerRating?.rating ?? ride.captainRating?.rating ?? 0).toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String text = ride.status.toLowerCase();

    switch (ride.status) {
      case 'COMPLETED':
        backgroundColor = Colors.green;
        break;
      case 'CANCELLED':
        backgroundColor = Colors.red;
        break;
      case 'STARTED':
        backgroundColor = Colors.blue;
        break;
      case 'ACCEPTED':
        backgroundColor = Colors.orange;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocationInfo({
    required IconData icon,
    required String label,
    required String address,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                address,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
