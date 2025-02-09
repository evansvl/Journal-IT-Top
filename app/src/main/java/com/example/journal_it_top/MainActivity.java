package com.example.journal_it_top;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.util.Log;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import java.io.InputStream;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {

    WebView mainWeb;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        mainWeb = findViewById(R.id.mainWeb);
        mainWeb.getSettings().setJavaScriptEnabled(true);
        mainWeb.getSettings().setAllowFileAccess(true);
        mainWeb.getSettings().setDomStorageEnabled(true);

        mainWeb.getSettings().setUserAgentString("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");

        mainWeb.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
            }

            @Override
            public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse errorResponse) {
                super.onReceivedHttpError(view, request, errorResponse);
                Log.d("WebView", "Ошибка HTTP: " + errorResponse.getStatusCode());
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);

                String removeStylesScript = "var links = document.getElementsByTagName('link');" +
                        "for(var i = links.length - 1; i >= 0; i--) {" +
                        "  links[i].parentNode.removeChild(links[i]);" +
                        "}" +
                        "var styles = document.getElementsByTagName('style');" +
                        "for(var i = styles.length - 1; i >= 0; i--) {" +
                        "  styles[i].parentNode.removeChild(styles[i]);" +
                        "}";

                view.evaluateJavascript(removeStylesScript, null);

                String cssFilePath = "file:///android_asset/styles.css";
                String applyCustomCSS = "var link = document.createElement('link');" +
                        "link.rel = 'stylesheet';" +
                        "link.type = 'text/css';" +
                        "link.href = '" + cssFilePath + "';" +
                        "document.head.appendChild(link);";

                view.evaluateJavascript(applyCustomCSS, null);
            }
        });

        mainWeb.loadUrl("https://journal.top-academy.ru/");
    }
}
