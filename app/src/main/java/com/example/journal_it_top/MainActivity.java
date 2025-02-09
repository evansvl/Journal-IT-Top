package com.example.journal_it_top;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.webkit.ConsoleMessage;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

public class MainActivity extends AppCompatActivity {

    WebView mainWeb;
    private static final String TAG = "MainActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);

        // Устанавливаем отступы для системных панелей
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        // Инициализируем WebView
        mainWeb = findViewById(R.id.mainWeb);
        mainWeb.getSettings().setJavaScriptEnabled(true); // Включаем поддержку JavaScript
        mainWeb.getSettings().setAllowFileAccess(true); // Разрешаем доступ к файлам
        mainWeb.getSettings().setDomStorageEnabled(true); // Включаем поддержку DOM Storage

        // Устанавливаем пользовательский User-Agent для обхода защиты Cloudflare
        mainWeb.getSettings().setUserAgentString("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");

        mainWeb.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
                // Логирование или действия при старте загрузки
                Log.d(TAG, "Page started loading: " + url);
            }

            @Override
            public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse errorResponse) {
                super.onReceivedHttpError(view, request, errorResponse);
                // Логирование ошибок HTTP
                Log.e(TAG, "HTTP error: " + errorResponse.getStatusCode());
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                Log.d(TAG, "Page finished loading: " + url);

                mainWeb.clearCache(true);

                String removeAndApplyStylesScript = "window.addEventListener('load', function() {" +
                        "setTimeout(function() {" +
                        "  var links = document.getElementsByTagName('link');" +
                        "  for(var i = links.length - 1; i >= 0; i--) {" +
                        "    if (links[i].rel === 'stylesheet') {" +
                        "      links[i].parentNode.removeChild(links[i]);" +
                        "    }" +
                        "  }" +
                        "  var styles = document.getElementsByTagName('style');" +
                        "  for(var i = styles.length - 1; i >= 0; i--) {" +
                        "    styles[i].parentNode.removeChild(styles[i]);" +
                        "  }" +
                        "  var customCSS = 'body { margin: 0; overflow: hidden; background-color: #d3d3d3; display: flex; justify-content: center; align-items: center; height: 100vh; font-size: normal; }';" +
                        "  var style = document.createElement('style');" +
                        "  style.type = 'text/css';" +
                        "  style.appendChild(document.createTextNode(customCSS));" +
                        "  document.head.appendChild(style);" +
                        "}, 100);" +
                        "});";

                view.evaluateJavascript(removeAndApplyStylesScript, null);
            }
        });

        mainWeb.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
                Log.d(TAG, consoleMessage.message() + " -- From line "
                        + consoleMessage.lineNumber() + " of "
                        + consoleMessage.sourceId());
                return true;
            }
        });

        // Загружаем веб-страницу
        mainWeb.loadUrl("https://journal.top-academy.ru/");
    }
}
