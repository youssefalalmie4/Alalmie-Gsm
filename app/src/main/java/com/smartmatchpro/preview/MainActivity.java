package com.smartmatchpro.preview;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public final class MainActivity extends Activity {
    private static final int FILE_PICKER_REQUEST = 40;
    private WebView webView;
    private ValueCallback<Uri[]> fileCallback;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setSupportZoom(false);
        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback,
                    FileChooserParams params) {
                if (fileCallback != null) fileCallback.onReceiveValue(null);
                fileCallback = callback;
                Intent intent = params.createIntent();
                try {
                    startActivityForResult(intent, FILE_PICKER_REQUEST);
                } catch (Exception exception) {
                    fileCallback = null;
                    callback.onReceiveValue(null);
                    return false;
                }
                return true;
            }
        });
        webView.addJavascriptInterface(new Object() {
            @JavascriptInterface public void openExternal(String url) {
                runOnUiThread(() -> {
                    try {
                        Uri uri = Uri.parse(url);
                        String scheme = uri.getScheme();
                        if ("https".equalsIgnoreCase(scheme) || "http".equalsIgnoreCase(scheme)) {
                            startActivity(new Intent(Intent.ACTION_VIEW, uri));
                        }
                    } catch (Exception ignored) {
                        // Ignore malformed URLs or missing browser apps.
                    }
                });
            }
            @JavascriptInterface public void openCompatibilityPortal() {
                runOnUiThread(() -> startActivity(
                        new Intent(MainActivity.this, CompatibilityActivity.class)));
            }
            @JavascriptInterface public void openGsmaDirectory() {
                openGsmaCatalog(false);
            }
            @JavascriptInterface public void openGsmaSearch(String query) {
                runOnUiThread(() -> {
                    Intent intent = new Intent(MainActivity.this, GsmArenaActivity.class);
                    intent.putExtra(GsmArenaActivity.EXTRA_QUERY, query == null ? "" : query);
                    startActivity(intent);
                });
            }
            private void openGsmaCatalog(boolean search) {
                runOnUiThread(() -> {
                    Intent intent = new Intent(MainActivity.this, GsmArenaActivity.class);
                    intent.putExtra(GsmArenaActivity.EXTRA_SEARCH, search);
                    startActivity(intent);
                });
            }
            @JavascriptInterface public void exitApp() { runOnUiThread(MainActivity.this::finish); }
            @JavascriptInterface public void setStatusBarColor(String color, boolean darkIcons) {
                MainActivity.this.runOnUiThread(() -> {
                    try {
                        MainActivity.this.getWindow().setStatusBarColor(Color.parseColor(color));
                        View decor = MainActivity.this.getWindow().getDecorView();
                        int flags = decor.getSystemUiVisibility();
                        flags = darkIcons ? flags | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
                                : flags & ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                        decor.setSystemUiVisibility(flags);
                    } catch (IllegalArgumentException ignored) {
                        // Keep the current system bar color if a theme color is invalid.
                    }
                });
            }
        }, "NativeApp");
        setContentView(webView);
        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != FILE_PICKER_REQUEST || fileCallback == null) return;
        Uri[] results = resultCode == RESULT_OK && data != null && data.getData() != null
                ? new Uri[]{data.getData()} : null;
        fileCallback.onReceiveValue(results);
        fileCallback = null;
    }

    @Override
    public void onBackPressed() {
        if (webView != null) webView.evaluateJavascript("handleSystemBack()", null);
        else super.onBackPressed();
    }

    @Override
    protected void onDestroy() {
        if (fileCallback != null) fileCallback.onReceiveValue(null);
        if (webView != null) {
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
