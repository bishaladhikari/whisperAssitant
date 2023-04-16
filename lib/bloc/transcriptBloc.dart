import 'package:rxdart/rxdart.dart';

class TranscriptBloc {
  final BehaviorSubject<String> _transcriptText =
  BehaviorSubject<String>();

  void drainStream() {
    transcriptText.value = '';
  }

  dispose() {
    transcriptText.close();
  }

  BehaviorSubject<String> get transcriptText => _transcriptText;
}

final transcriptBloc = TranscriptBloc();
