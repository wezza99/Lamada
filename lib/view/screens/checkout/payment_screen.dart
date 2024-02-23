// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_restaurant/data/model/body/place_order_body.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/provider/cart_provider.dart';
import 'package:flutter_restaurant/provider/order_provider.dart';
import 'package:flutter_restaurant/utill/app_constants.dart';
import 'package:flutter_restaurant/view/base/custom_app_bar.dart';
import 'package:flutter_restaurant/view/screens/checkout/widget/cancel_dialog.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  final String? url;
  final bool? formCheckout;
  const PaymentScreen({Key? key, this.url, this.formCheckout = true})
      : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String selectedUrl;
  double value = 0.0;
  final bool _isLoading = true;
  PullToRefreshController? pullToRefreshController;
  late MyInAppBrowser browser;
  PlaceOrderBody? placeOrderBody;

  @override
  void initState() {
    super.initState();
    selectedUrl = '${widget.url}';
    _initData();
  }

  void _initData() async {
    browser = MyInAppBrowser(context, widget.formCheckout ?? true);
    if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

      bool swAvailable = await AndroidWebViewFeature.isFeatureSupported(
          AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
      bool swInterceptAvailable =
          await AndroidWebViewFeature.isFeatureSupported(
              AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

      if (swAvailable && swInterceptAvailable) {
        AndroidServiceWorkerController serviceWorkerController =
            AndroidServiceWorkerController.instance();
        await serviceWorkerController
            .setServiceWorkerClient(AndroidServiceWorkerClient(
          shouldInterceptRequest: (request) async {
            return null;
          },
        ));
      }
    }

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.black,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          browser.webViewController.reload();
        } else if (Platform.isIOS) {
          browser.webViewController.loadUrl(
              urlRequest:
                  URLRequest(url: await browser.webViewController.getUrl()));
        }
      },
    );
    browser.pullToRefreshController = pullToRefreshController;

    await browser.openUrlRequest(
      urlRequest: URLRequest(url: Uri.parse(selectedUrl)),
      options: InAppBrowserClassOptions(
        inAppWebViewGroupOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
              useShouldOverrideUrlLoading: true, useOnLoadResource: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (() => _exitApp(context).then((value) => value!)),
      child: Scaffold(
        // backgroundColor: Theme.of(context).primaryColor,
        appBar: CustomAppBar(
            context: context,
            title: getTranslated('PAYMENT', context),
            onBackPressed: () => _exitApp(context)),
        body: Center(
          child: Stack(
            children: [
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor)),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _exitApp(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) => const CancelDialog(orderID: null));
  }
}

class MyInAppBrowser extends InAppBrowser {
  final BuildContext context;
  final bool fromCheckout;
  MyInAppBrowser(
    this.context,
    this.fromCheckout, {
    int? windowId,
    UnmodifiableListView<UserScript>? initialUserScripts,
  }) : super(windowId: windowId, initialUserScripts: initialUserScripts);

  bool _canRedirect = true;
  late PlaceOrderBody _placeOrderBody;

  @override
  Future onBrowserCreated() async {
    debugPrint("\n\nBrowser Created!\n\n");
  }

  @override
  Future onLoadStart(url) async {
    debugPrint("\n\nStarted: $url\n\n");
    _pageRedirect(url.toString());
  }

  @override
  Future onLoadStop(url) async {
    pullToRefreshController?.endRefreshing();
    debugPrint("\n\nStopped: $url\n\n");
    _pageRedirect(url.toString());
  }

  @override
  void onLoadError(url, code, message) {
    pullToRefreshController?.endRefreshing();
    debugPrint("Can't load [$url] Error: $message");
  }

  @override
  void onProgressChanged(progress) {
    if (progress == 100) {
      pullToRefreshController?.endRefreshing();
    }
    debugPrint("Progress: $progress");
  }

  @override
  void onExit() {
    if (_canRedirect) {
      if (fromCheckout) {
        RouterHelper.getOrderSuccessScreen('-1', 'payment-cancel');
      } else {
        RouterHelper.getWalletRoute(true,
            token: '', flag: 'fail', action: RouteAction.pushReplacement);
      }
    }

    debugPrint("\n\nBrowser closed!\n\n");
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
      navigationAction) async {
    debugPrint("\n\nOverride ${navigationAction.request.url}\n\n");
    return NavigationActionPolicy.ALLOW;
  }

  @override
  void onLoadResource(resource) {
    // print("Started at: " + response.startTime.toString() + "ms ---> duration: " + response.duration.toString() + "ms " + (response.url ?? '').toString());
  }

  @override
  void onConsoleMessage(consoleMessage) {
    debugPrint("""
    console output:
      message: ${consoleMessage.message}
      messageLevel: ${consoleMessage.messageLevel.toValue()}
   """);
  }

  void _pageRedirect(String url) {
    if (_canRedirect) {
      bool checkedUrl = (url.contains(
              '${AppConstants.baseUrl}${RouterHelper.orderSuccessScreen}') ||
          url.contains('${AppConstants.baseUrl}${RouterHelper.wallet}'));
      bool isSuccess = url.contains('success') && checkedUrl;
      bool isFailed = url.contains('fail') && checkedUrl;
      bool isCancel = url.contains('cancel') && checkedUrl;

      bool isWallet =
          url.contains('${AppConstants.baseUrl}${RouterHelper.wallet}');

      if (isSuccess || isFailed || isCancel) {
        _canRedirect = false;
        close();
      }
      if (isSuccess) {
        String token = url
            .replaceRange(0, url.indexOf('token='), '')
            .replaceAll('token=', '');

        if (isWallet) {
          RouterHelper.getWalletRoute(true,
              token: token,
              flag: 'success',
              action: RouteAction.pushReplacement);
        } else {
          if (token.isNotEmpty) {
            String decodeValue =
                utf8.decode(base64Url.decode(token.replaceAll(' ', '+')));
            String paymentMethod =
                decodeValue.substring(0, decodeValue.indexOf('&&'));
            String transactionReference = decodeValue.substring(
                decodeValue.indexOf('&&') + '&&'.length, decodeValue.length);
            String placeOrderString = utf8.decode(base64Url.decode(
                Provider.of<OrderProvider>(context, listen: false)
                    .getPlaceOrder()!
                    .replaceAll(' ', '+')));
            _placeOrderBody =
                PlaceOrderBody.fromJson(jsonDecode(placeOrderString)).copyWith(
              paymentMethod: paymentMethod.replaceAll('payment_method=', ''),
              transactionReference: transactionReference
                  .replaceRange(
                      0,
                      transactionReference.indexOf('transaction_reference='),
                      '')
                  .replaceAll('transaction_reference=', ''),
            );
            Provider.of<OrderProvider>(context, listen: false)
                .placeOrder(_placeOrderBody, _callback);
          } else {
            RouterHelper.getOrderSuccessScreen('-1', 'payment-fail');
          }
        }
      } else if (isWallet) {
        RouterHelper.getWalletRoute(true,
            token: 'failed',
            flag: 'failed',
            action: RouteAction.pushReplacement);
      } else if (isFailed) {
        RouterHelper.getOrderSuccessScreen(
          '-1',
          'payment-fail',
        );
      } else if (isCancel) {
        RouterHelper.getOrderSuccessScreen('-1', 'payment-cancel');
      }
    }
  }

  void _callback(
      bool isSuccess, String message, String orderID, int addressID) async {
    Provider.of<CartProvider>(context, listen: false).clearCartList();
    Provider.of<OrderProvider>(context, listen: false).stopLoader();
    if (isSuccess) {
      RouterHelper.getOrderSuccessScreen(orderID, 'success');
    } else {
      RouterHelper.getOrderSuccessScreen('-1', 'order-fail');
    }
  }
}
