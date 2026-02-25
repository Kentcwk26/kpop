import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kpop/utils/information.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../utils/snackbar_helper.dart';
import 'utils/date_formatter.dart';

/// ---------------------------------------------------------------------------
/// WIDGET TYPE
/// ---------------------------------------------------------------------------

enum KWidgetType { clock, note }

/// ---------------------------------------------------------------------------
/// STATE
/// ---------------------------------------------------------------------------

class WidgetCreatorState {
  final bool exporting;
  final KWidgetType? selectedType;
  final File? imageFile;
  final String noteText;

  const WidgetCreatorState({
    this.exporting = false,
    this.selectedType,
    this.imageFile,
    this.noteText = '',
  });

  WidgetCreatorState copyWith({
    bool? exporting,
    KWidgetType? selectedType,
    File? imageFile,
    String? noteText,
  }) {
    return WidgetCreatorState(
      exporting: exporting ?? this.exporting,
      selectedType: selectedType ?? this.selectedType,
      imageFile: imageFile ?? this.imageFile,
      noteText: noteText ?? this.noteText,
    );
  }
}

/// ---------------------------------------------------------------------------
/// PROVIDER
/// ---------------------------------------------------------------------------

final widgetCreatorProvider =
    StateNotifierProvider<WidgetCreatorScreen, WidgetCreatorState>(
      (ref) => WidgetCreatorScreen(),
    );

/// ---------------------------------------------------------------------------
/// VIEWMODEL
/// ---------------------------------------------------------------------------

class WidgetCreatorScreen extends StateNotifier<WidgetCreatorState> {
  WidgetCreatorScreen() : super(const WidgetCreatorState());

  final ScreenshotController screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();

  void setWidgetType(KWidgetType type) {
    state = state.copyWith(selectedType: type);
  }

  void setNoteText(String text) {
    state = state.copyWith(noteText: text);
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    state = state.copyWith(imageFile: File(picked.path));
  }

  Future<void> exportSelectedWidget(BuildContext context) async {
    final type = state.selectedType;
    if (type == null) return;

    state = state.copyWith(exporting: true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String widgetId;
      DocumentReference? widgetDoc;

      if (type == KWidgetType.clock) {
        // Create dynamic clock ID (like note)
        widgetDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('widgets')
            .doc();

        widgetId = widgetDoc.id;

        await widgetDoc.set({
          'id': widgetId,
          'userId': user.uid,
          'type': type.name,
          'name': 'Clock Widget',
          'style': _resolveStyle(type),
          'data': _resolveData(type),
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Note widgets: dynamic IDs
        widgetDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('widgets')
            .doc();
        widgetId = widgetDoc.id;

        await widgetDoc.set({
          'id': widgetId,
          'userId': user.uid,
          'type': type.name,
          'name': '${type.name} widget',
          'style': _resolveStyle(type),
          'data': _resolveData(type),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Capture screenshot
      final Uint8List? bytes = await screenshotController.capture(
        pixelRatio: 2.5,
      );
      if (bytes == null) {
        SnackBarHelper.showError(context, 'Failed to capture widget');
        return;
      }

      final dir = await getExternalStorageDirectory();
      if (dir == null) return;

      final file = File('${dir.path}/${widgetId}.png');
      await file.writeAsBytes(bytes);

      // Save HomeWidget data
      if (type == KWidgetType.clock) {
        await HomeWidget.saveWidgetData('clock_image_$widgetId', file.path);
        await HomeWidget.saveWidgetData('widget_mapping_$widgetId', widgetId);
        await HomeWidget.saveWidgetData('pending_k_widget_id', widgetId);
      } else if (type == KWidgetType.note) {
        await HomeWidget.saveWidgetData('note_image_$widgetId', file.path);
        await HomeWidget.saveWidgetData('note_text_$widgetId', state.noteText);
        await HomeWidget.saveWidgetData('widget_mapping_$widgetId', widgetId);
      }

      print(
        'Saving ${type.name} widget: widgetId=$widgetId, imagePath=${file.path}',
      );

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: _androidWidgetName(type),
        androidName: _androidWidgetName(type),
      );

      SnackBarHelper.showSuccess(context, 'Widget created successfully!');
    } finally {
      state = state.copyWith(exporting: false);
    }
  }

  String _androidWidgetName(KWidgetType type) {
    switch (type) {
      case KWidgetType.clock:
        return 'ClockHomeWidget';
      case KWidgetType.note:
        return 'NoteHomeWidget';
    }
  }

  Map<String, dynamic> _resolveStyle(KWidgetType type) {
    switch (type) {
      case KWidgetType.clock:
        return {
          'backgroundColor': '#000000',
          'textColor': '#FFFFFF',
          'fontSize': 40,
        };
      case KWidgetType.note:
        return {'backgroundColor': '#FFF3B0', 'textColor': '#000000'};
    }
  }

  Map<String, dynamic> _resolveData(KWidgetType type) {
    switch (type) {
      case KWidgetType.clock:
        return {'format': '24h'};
      case KWidgetType.note:
        return {'text': state.noteText};
    }
  }
}

/// ---------------------------------------------------------------------------
/// UI (COMBINED INSIDE SAME FILE)
/// ---------------------------------------------------------------------------

class WidgetCreator extends ConsumerWidget {
  const WidgetCreator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(widgetCreatorProvider);
    final creator = ref.read(widgetCreatorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Widget'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/creation-help'),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              /// Widget Type Selector
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: KWidgetType.values.map((type) {
                    return ChoiceChip(
                      label: Text(type.name.toUpperCase()),
                      selected: state.selectedType == type,
                      onSelected: (_) => creator.setWidgetType(type),
                    );
                  }).toList(),
                ),
              ),

              Column(
                children: [
                  GestureDetector(
                    onTap: () => creator.pickImage(),
                    child: Screenshot(
                      controller: creator.screenshotController,
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade400),
                          image: DecorationImage(
                            image: state.imageFile != null
                                ? FileImage(state.imageFile!)
                                : const AssetImage(
                                        'assets/images/empty_pic.jpg',
                                      )
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: IconText(
                      icon: Icons.info,
                      text: 'Tap to select an image from your gallery.',
                    ),
                  ),

                  /// Note input field (only for note widget)
                  if (state.selectedType == KWidgetType.note) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: TextField(
                        maxLines: 6,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your note here',
                        ),
                        onChanged: (value) => creator.setNoteText(value),
                      ),
                    ),
                  ],

                  /// Card showing uploaded image + live widget preview
                  if (state.imageFile != null && state.selectedType != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: uploaded image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                state.imageFile!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Right: live preview of widget content
                            Expanded(
                              child: state.selectedType == KWidgetType.clock
                                  ? ClockPreview(
                                      style: const {
                                        'backgroundColor': '#000000',
                                        'textColor': '#FFFFFF',
                                        'fontSize': 18,
                                      },
                                      data: {
                                        'format': '12h',
                                        'imagePath': state.imageFile?.path,
                                      },
                                    )
                                  : NotePreview(
                                      style: const {
                                        'backgroundColor': '#FFF3B0',
                                        'textColor': '#000000',
                                        'fontSize': 16,
                                      },
                                      data: {
                                        'text': state.noteText.isEmpty
                                            ? 'Your note displays here'
                                            : state.noteText,
                                        'imagePath': state.imageFile?.path,
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  /// Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: state.exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.widgets),
                      label: const Text('Create Widget'),
                      onPressed: state.exporting
                          ? null
                          : () => creator.exportSelectedWidget(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClockPreview extends StatelessWidget {
  final Map<String, dynamic> style;
  final Map<String, dynamic> data;

  const ClockPreview({super.key, required this.style, required this.data});

  @override
  Widget build(BuildContext context) {
    final DateTime now = _resolveTime();
    final String format = data['format'] ?? 'HH:mm';
    final bool showSeconds = data['showSeconds'] ?? false;

    final String timeText = _formatTime(now, format, showSeconds);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            timeText,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  DateTime _resolveTime() {
    final String timezone = data['timezone'] ?? 'local';
    if (timezone == 'utc') {
      return DateTime.now().toUtc();
    }
    return DateTime.now();
  }

  String _formatTime(DateTime time, String format, bool showSeconds) {
    if (format == '12h') {
      return showSeconds
          ? DateFormatter.fullFormat12HourMinuteSecondsUpper(time)
          : DateFormatter.fullFormat12HourUpper(time);
    }
    return showSeconds
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}'
        : DateFormatter.format24Hour(time);
  }
}

class NotePreview extends StatelessWidget {
  final Map<String, dynamic> style;
  final Map<String, dynamic> data;

  const NotePreview({super.key, required this.style, required this.data});

  @override
  Widget build(BuildContext context) {
    final String text = data['text'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [Text(text, maxLines: 6, overflow: TextOverflow.ellipsis)],
      ),
    );
  }
}
