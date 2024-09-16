import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/card_provider.dart';

class StopwatchDisplay extends StatefulWidget {
  final int initialTotalSeconds;
  final DateTime? startedAt;
  final String cardId;

  const StopwatchDisplay({
    super.key,
    required this.initialTotalSeconds,
    this.startedAt,
    required this.cardId,
  });

  @override
  _StopwatchDisplayState createState() => _StopwatchDisplayState();
}

class _StopwatchDisplayState extends State<StopwatchDisplay> {
  late int _totalSeconds;
  Timer? _timer;
  bool _isPaused = true; // Track the stopwatch state
  DateTime? _startedAt;

  final TextEditingController hoursController = TextEditingController();
  final TextEditingController minutesController = TextEditingController();
  final TextEditingController secondsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize _totalSeconds and _startedAt based on the passed arguments
    _totalSeconds = widget.initialTotalSeconds;
    _startedAt = widget.startedAt;

    // Calculate initial time considering startedAt
    if (_startedAt != null) {
      final now = DateTime.now();
      _totalSeconds += now.difference(_startedAt!).inSeconds;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() async {
    setState(() {
      _isPaused = false;
      _startedAt = DateTime.now(); // Set the current time as the start time
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _totalSeconds += 1;
      });
    });
  }

  void _stopTimer() async {
    setState(() {
      _isPaused = true;
      _startedAt = null; // Clear startedAt to indicate the timer is stopped
    });

    _timer?.cancel();
  }

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Show the stopwatch control dialog
  void _showStopwatchDialog() {
    hoursController.text = (_totalSeconds ~/ 3600).toString().padLeft(2, '0');
    minutesController.text = ((_totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    secondsController.text = (_totalSeconds % 60).toString().padLeft(2, '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('stopwatch_controls.title'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: hoursController,
                          keyboardType: TextInputType.number,
                          enabled: _isPaused,
                          decoration: InputDecoration(labelText: 'stopwatch_controls.hours'.tr()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: minutesController,
                          keyboardType: TextInputType.number,
                          enabled: _isPaused,
                          decoration: InputDecoration(labelText: 'stopwatch_controls.minutes'.tr()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: secondsController,
                          keyboardType: TextInputType.number,
                          enabled: _isPaused,
                          decoration: InputDecoration(labelText: 'stopwatch_controls.seconds'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    setState(() {
                      _isPaused = true;
                      _startedAt = null;
                    });

                    _timer?.cancel();

                    ///Delete Timer on Server
                    await Provider.of<CardProvider>(context, listen: false).deleteStopwatch(
                      context: context,
                      cardId: widget.cardId,
                    );

                    Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: () async {
                    if (_isPaused) {
                      _startTimer();

                      // Update on server to reflect the started state
                      await Provider.of<CardProvider>(context, listen: false).updateStopwatch(
                        context: context,
                        cardId: widget.cardId,
                        stopwatchTotal: _totalSeconds,
                        stopwatchStartedAt: _startedAt.toString(),
                      );

                      Navigator.of(context).pop();
                    } else {
                      _stopTimer();

                      // Update on server to reflect the stopped state
                      await Provider.of<CardProvider>(context, listen: false).updateStopwatch(
                        context: context,
                        cardId: widget.cardId,
                        stopwatchTotal: _totalSeconds,
                        stopwatchStartedAt: null, // This will be null now
                      );

                      hoursController.text = (_totalSeconds ~/ 3600).toString().padLeft(2, '0');
                      minutesController.text = ((_totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
                      secondsController.text = (_totalSeconds % 60).toString().padLeft(2, '0');
                    }
                    setState(() {
                      debugPrint("RefreshUI");
                    }); // Refresh UI
                  },
                ),
                TextButton(
                  onPressed: _isPaused
                      ? () async {
                    setState(() {
                      final int hours = int.tryParse(hoursController.text) ?? 0;
                      final int minutes = int.tryParse(minutesController.text) ?? 0;
                      final int seconds = int.tryParse(secondsController.text) ?? 0;
                      _totalSeconds = hours * 3600 + minutes * 60 + seconds;
                    });

                    // Update on server to reflect the new time
                    await Provider.of<CardProvider>(context, listen: false).updateStopwatch(
                      context: context,
                      cardId: widget.cardId,
                      stopwatchTotal: _totalSeconds,
                      stopwatchStartedAt: null,
                    );

                    _startTimer();

                    // Update on server to reflect the started state
                    await Provider.of<CardProvider>(context, listen: false).updateStopwatch(
                      context: context,
                      cardId: widget.cardId,
                      stopwatchTotal: _totalSeconds,
                      stopwatchStartedAt: _startedAt.toString(),
                    );

                    Navigator.of(context).pop();
                  }
                      : null,
                  child: Text('stopwatch_controls.set_time'.tr()),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('cancel'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showStopwatchDialog,
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
            const SizedBox(width: 5),
            Text(
              _formatDuration(_totalSeconds),
            ),
          ],
        ),
      ),
    );
  }
}