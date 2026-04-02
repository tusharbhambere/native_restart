package io.native_restart.example

import android.content.Context
import io.native_restart.RestartPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun provideFlutterEngine(context: Context) = RestartPlugin.provideFlutterEngine()
}
