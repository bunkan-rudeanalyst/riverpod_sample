import 'package:flutter_riverpod/flutter_riverpod.dart';

// カウンター管理用provider
final counterProvider = StateProvider<int>((_) => 0);
