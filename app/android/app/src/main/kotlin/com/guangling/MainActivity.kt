package com.guangling

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.guangling.plugin.MediaStorePlugin
import com.guangling.plugin.MediaSessionPlugin

class MainActivity : FlutterActivity() {
    private var mediaStorePlugin: MediaStorePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. 注册媒体库插件
        mediaStorePlugin = MediaStorePlugin(this).also {
            it.register(flutterEngine)
        }

        // 2. 注册音频服务控制插件
        MediaSessionPlugin(this).register(flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        // 将 activity 回调分发给具体的插件
        mediaStorePlugin?.handleActivityResult(requestCode, resultCode, data)
    }
}