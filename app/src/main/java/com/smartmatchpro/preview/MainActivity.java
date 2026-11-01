package com.smartmatchpro.preview;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebResourceRequest;
import org.json.JSONObject;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

public final class MainActivity extends Activity {
    private static final int FILE_PICKER_REQUEST = 40;
    private static final String LOGIN_KEY_ALIAS = "smart_match_pro_saved_login_v1";
    private static final String LOGIN_PREFS = "remembered_login";
    private WebView webView;
    private ValueCallback<Uri[]> fileCallback;

    private SecretKey rememberedLoginKey() throws Exception {
        KeyStore store = KeyStore.getInstance("AndroidKeyStore");
        store.load(null);
        if (store.containsAlias(LOGIN_KEY_ALIAS)) {
            return (SecretKey) store.getKey(LOGIN_KEY_ALIAS, null);
        }
        KeyGenerator generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
        generator.init(new KeyGenParameterSpec.Builder(LOGIN_KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build());
        return generator.generateKey();
    }

    private void saveRememberedCredentials(String identifier, String password) {
        if (identifier == null || password == null) {
            clearRememberedCredentials();
            return;
        }
        try {
            JSONObject credentials = new JSONObject();
            credentials.put("identifier", identifier);
            credentials.put("password", password);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, rememberedLoginKey());
            byte[] encrypted = cipher.doFinal(credentials.toString().getBytes(StandardCharsets.UTF_8));
            getSharedPreferences(LOGIN_PREFS, MODE_PRIVATE).edit()
                    .putString("iv", Base64.encodeToString(cipher.getIV(), Base64.NO_WRAP))
                    .putString("data", Base64.encodeToString(encrypted, Base64.NO_WRAP))
                    .commit();
        } catch (Exception ignored) {
            clearRememberedCredentials();
        }
    }

    private String getRememberedCredentials() {
        SharedPreferences preferences = getSharedPreferences(LOGIN_PREFS, MODE_PRIVATE);
        String iv = preferences.getString("iv", null);
        String data = preferences.getString("data", null);
        if (iv == null || data == null) return "{}";
        try {
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, rememberedLoginKey(),
                    new GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)));
            String json = new String(cipher.doFinal(Base64.decode(data, Base64.NO_WRAP)), StandardCharsets.UTF_8);
            return new JSONObject(json).toString();
        } catch (Exception ignored) {
            clearRememberedCredentials();
            return "{}";
        }
    }

    private void clearRememberedCredentials() {
        getSharedPreferences(LOGIN_PREFS, MODE_PRIVATE).edit().clear().commit();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        settings.setSupportZoom(false);
        webView.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return handleNavigation(request.getUrl());
            }
            @Override public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return handleNavigation(Uri.parse(url));
            }
            private boolean handleNavigation(Uri uri) {
                if ("file".equalsIgnoreCase(uri.getScheme())
                        && "android_asset".equalsIgnoreCase(uri.getHost())) return false;
                if ("https".equalsIgnoreCase(uri.getScheme())) {
                    try { startActivity(new Intent(Intent.ACTION_VIEW, uri)); }
                    catch (Exception ignored) { }
                }
                return true;
            }
        });
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
            @JavascriptInterface public String getRememberedCredentials() {
                return MainActivity.this.getRememberedCredentials();
            }
            @JavascriptInterface public void saveRememberedCredentials(String identifier, String password) {
                MainActivity.this.saveRememberedCredentials(identifier, password);
            }
            @JavascriptInterface public void clearRememberedCredentials() {
                MainActivity.this.clearRememberedCredentials();
            }
            private void openGsmaCatalog(boolean search) {
                runOnUiThread(() -> {
                    Intent intent = new Intent(MainActivity.this, GsmArenaActivity.class);
                    intent.putExtra(GsmArenaActivity.EXTRA_SEARCH, search);
                    startActivity(intent);
                });
            }
            @JavascriptInterface public void hideKeyboard() {
                runOnUiThread(() -> {
                    InputMethodManager manager = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
                    View target = MainActivity.this.getCurrentFocus();
                    if (manager != null && target != null) {
                        manager.hideSoftInputFromWindow(target.getWindowToken(), 0);
                    }
                    if (target != null) target.clearFocus();
                    if (webView != null) webView.clearFocus();
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
