#!/bin/bash
# Capacitor打包自动修复WebView SSL证书拦截，解决ERR_CONNECTION_CLOSED
MAIN_ACT="android/app/src/main/java/com/uzhan/app/MainActivity.java"
MANIFEST="android/app/src/main/AndroidManifest.xml"
SEC_XML="android/app/src/main/res/xml/network_security_config.xml"

# 1. 写入SSL需要的导入类
sed -i '1iimport android.net.http.SslError;\nimport android.webkit.SslErrorHandler;\nimport android.webkit.WebView;' $MAIN_ACT

# 2. 插入onResume重写方法，放行全部SSL错误
sed -i '/public class MainActivity extends BridgeActivity {/a\
  @Override\
  public void onResume() {\
    super.onResume();\
    WebView webView = getBridge().getWebView();\
    webView.setWebViewClient(new android.webkit.WebViewClient(){\
        @Override\
        public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {\
            handler.proceed();\
        }\
    });\
  }' $MAIN_ACT

# 3. Manifest添加明文流量权限
sed -i 's|<application|<application android:usesCleartextTraffic="true" android:networkSecurityConfig="@xml/network_security_config"|g' $MANIFEST

# 4. 创建信任全部证书的网络安全配置
mkdir -p android/app/src/main/res/xml
cat > $SEC_XML << EOF
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>
EOF
