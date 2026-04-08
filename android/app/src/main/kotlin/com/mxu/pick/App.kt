package com.mxu.pick

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        
        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint("lib/main.dart", "prewarm")
        )
        FlutterEngineCache.getInstance().put("pick_engine", flutterEngine)
    }
}
