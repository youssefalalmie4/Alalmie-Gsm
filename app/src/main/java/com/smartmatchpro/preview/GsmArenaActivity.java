package com.smartmatchpro.preview;

import android.app.Activity;
import android.os.Bundle;
import android.net.Uri;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public final class GsmArenaActivity extends Activity {
    public static final String EXTRA_SEARCH = "search";
    public static final String EXTRA_QUERY = "query";
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setSupportZoom(true);
        settings.setBuiltInZoomControls(true);
        settings.setDisplayZoomControls(false);
        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient());
        setContentView(webView);
        if (savedInstanceState == null) {
            String query = getIntent().getStringExtra(EXTRA_QUERY);
            if (query != null && !query.trim().isEmpty()) {
                webView.loadUrl("https://www.gsmarena.com/res.php3?sSearch=" + Uri.encode(query.trim()));
            } else {
                boolean search = getIntent().getBooleanExtra(EXTRA_SEARCH, false);
                webView.loadUrl(search
                        ? "https://www.gsmarena.com/"
                        : "https://www.gsmarena.com/makers.php3");
            }
        } else {
            webView.restoreState(savedInstanceState);
        }
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        if (webView != null) webView.saveState(outState);
        super.onSaveInstanceState(outState);
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
