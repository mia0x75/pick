package com.mxu.pick

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity: FlutterActivity() {
    override fun getFlutterEngine(): FlutterEngine {
        return FlutterEngineCache.getInstance().get("pick_engine")!!
    }
}
