import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class StopwatchDisplay extends StatefulWidget {
  final int initialTotalSeconds;
  final DateTime? startedAt;

  const StopwatchDisplay({
    super.key,
    required this.initialTotalSeconds,
    this.startedAt,
  });

  @override
  _StopwatchDisplayState createState() => _StopwatchDisplayState();
}

class _StopwatchDisplayState extends State<StopwatchDisplay> {
  late int _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialTotalSeconds;

    // Calculate elapsed time if startedAt is provided
    if (widget.startedAt != null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (widget.startedAt != null) {
          final now = DateTime.now();
          _totalSeconds = now.difference(widget.startedAt!).inSeconds + widget.initialTotalSeconds;
        } else {
          _totalSeconds += 1;
        }
      });
    });
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.info(
            message:
            'not_available_function'.tr(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 4.0, bottom: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: _timer != null && _timer!.isActive ? Colors.green[100] : Colors.red[100],
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.timer_outlined),
            const SizedBox(width: 5,),
            Text(
              _formatDuration(_totalSeconds),
            ),
          ],
        )
      ),
    );
  }
}
