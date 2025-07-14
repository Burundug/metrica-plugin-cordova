/*
 * Version for Cordova/PhoneGap
 * © 2017-2019 YANDEX
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

package com.yandex.metrica.plugin.cordova;

import android.app.Activity;

import android.content.Context;
import android.content.Intent;
import android.location.Location;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


import java.util.ArrayList;
import java.util.Iterator;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.appmetrica.analytics.AppMetrica;
import io.appmetrica.analytics.AppMetricaConfig;
import io.appmetrica.analytics.PreloadInfo;
import io.appmetrica.analytics.ecommerce.ECommerceAmount;
import io.appmetrica.analytics.ecommerce.ECommerceCartItem;
import io.appmetrica.analytics.ecommerce.ECommerceEvent;
import io.appmetrica.analytics.ecommerce.ECommerceOrder;
import io.appmetrica.analytics.ecommerce.ECommercePrice;
import io.appmetrica.analytics.ecommerce.ECommerceProduct;
import io.appmetrica.analytics.ecommerce.ECommerceReferrer;
import io.appmetrica.analytics.ecommerce.ECommerceScreen;


public class AppMetricaPlugin extends CordovaPlugin {

    private final Object mLock = new Object();
    private final ExecutorService mExecutor = Executors.newSingleThreadExecutor();
    private boolean mActivityPaused = true;
    private boolean mAppMetricaActivated = false;

    @Override
    public boolean execute(final String action, final JSONArray args,
                           final CallbackContext callbackContext) throws JSONException {
        getAppMetricaExecutor().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    if ("activate".equals(action)) {
                        activate(args, callbackContext);
                    } else if ("reportEvent".equals(action)) {
                        reportEvent(args, callbackContext);
                    } else if ("reportError".equals(action)) {
                        reportError(args, callbackContext);
                    } else if ("setLocation".equals(action)) {
                        setLocation(args, callbackContext);
                    } else if ("setLocationTracking".equals(action)) {
                        setLocationTracking(args, callbackContext);
                    } else if ("showScreen".equals(action)) {
                        showScreen(args, callbackContext);
                    } else if ("showProductCard".equals(action)) {
                        showProductCard(args, callbackContext);
                    } else if ("addToCart".equals(action)) {
                        addToCart(args, callbackContext);
                    } else if ("removeFromCart".equals(action)) {
                        removeFromCart(args, callbackContext);
                    } else if ("finishCheckout".equals(action)) {
                        finishCheckout(args, callbackContext);
                    } else {
                        callbackContext.error("Unknown action: " + action);
                    }
                } catch (JSONException ex) {
                    callbackContext.error(ex.getMessage());
                }
            }
        });
        return true;
    }


    @Override
    public void onPause(final boolean multitasking) {
        onPauseSession();
    }

    @Override
    public void onResume(final boolean multitasking) {
        onResumeSession();
    }

    @Override
    public void onNewIntent(final Intent intent) {
        getAppMetricaExecutor().execute(new Runnable() {
            @Override
            public void run() {
                if (mAppMetricaActivated) {
                    AppMetrica.reportAppOpen(getActivity());
                }
            }
        });
    }

    public ECommerceScreen createScreen(final JSONArray args) throws JSONException {
        final JSONObject object = args.getJSONObject(0);
        return new ECommerceScreen().setName(object.getString("screenName")).setSearchQuery(object.getString("searchQuery"));
    }

    public ECommerceProduct createProduct(final JSONArray params) throws JSONException {
        final JSONObject object = params.getJSONObject(0);
        ECommercePrice actualPrice = new ECommercePrice(new ECommerceAmount(Double.parseDouble(object.getString("price")), object.getString("currency")));
        return new ECommerceProduct(object.getString("sku")).setActualPrice(actualPrice).setName(object.getString("name"));
    }

    public ECommerceCartItem createCartItem(final JSONArray args) throws JSONException {
        try {
            final JSONObject object = args.getJSONObject(0);
            ECommerceScreen screen = this.createScreen(args);
            ECommerceProduct product = this.createProduct(args);
            ECommercePrice actualPrice = new ECommercePrice(new ECommerceAmount(Double.parseDouble(object.getString("price")), object.getString("currency")));
            ECommerceReferrer referrer = new ECommerceReferrer().setScreen(screen);
            return new ECommerceCartItem(product, actualPrice, Double.parseDouble(object.getString("quantity"))).setReferrer(referrer);
        } catch (Throwable t) {
            Log.e("ERROR", t.toString());
            return null;
        }
    }

    public void showScreen(final JSONArray params, final CallbackContext callbackContext) throws JSONException {
        ECommerceScreen screen = this.createScreen(params);
        ECommerceEvent showScreenEvent = ECommerceEvent.showScreenEvent(screen);
        AppMetrica.reportECommerce(showScreenEvent);
    }

    public void showProductCard(final JSONArray params, final CallbackContext callbackContext) throws JSONException {
        ECommerceScreen screen = this.createScreen(params);
        ECommerceProduct product = this.createProduct(params);
        ECommerceEvent showProductCardEvent = ECommerceEvent.showProductCardEvent(product, screen);
        AppMetrica.reportECommerce(showProductCardEvent);
    }

    public void addToCart(final JSONArray params, final CallbackContext callbackContext) throws JSONException {
        ECommerceCartItem cartItem = this.createCartItem(params);
        ECommerceEvent addCartItemEvent = ECommerceEvent.addCartItemEvent(cartItem);
        AppMetrica.reportECommerce(addCartItemEvent);
    }

    public void removeFromCart(final JSONArray params, final CallbackContext callbackContext) throws JSONException {
        ECommerceCartItem cartItem = this.createCartItem(params);
        ECommerceEvent removeCartItemEvent = ECommerceEvent.removeCartItemEvent(cartItem);
        AppMetrica.reportECommerce(removeCartItemEvent);
    }

    public void beginCheckout(final JSONArray products, final CallbackContext callbackContext) throws JSONException {
        String identifier = products.getJSONObject(0).getString("identifier");
        JSONArray jsonArray = products.getJSONObject(0).getJSONArray("products");
        ArrayList<ECommerceCartItem> cartItems = new ArrayList<>();
        try {
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONArray jsonArr = new JSONArray();
                cartItems.add(this.createCartItem(jsonArr.put(jsonArray.getJSONObject(i))));
            }
            ECommerceOrder order = new ECommerceOrder(identifier, cartItems);
            ECommerceEvent beginCheckoutEvent = ECommerceEvent.beginCheckoutEvent(order);
            AppMetrica.reportECommerce(beginCheckoutEvent);
            callbackContext.success("add products beginCheckout");
        } catch (JSONException ex) {
            callbackContext.error(ex.getMessage());
        }
    }

    public void finishCheckout(final JSONArray products, final CallbackContext callbackContext) throws JSONException {
        String identifier = products.getJSONObject(0).getString("identifier");
        JSONArray jsonArray = products.getJSONObject(0).getJSONArray("products");
        ArrayList<ECommerceCartItem> cartItems = new ArrayList<>();
        try {
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONArray jsonArr = new JSONArray();
                cartItems.add(this.createCartItem(jsonArr.put(jsonArray.getJSONObject(i))));
            }
            ECommerceOrder order = new ECommerceOrder(identifier, cartItems);
            ECommerceEvent purchaseEvent = ECommerceEvent.purchaseEvent(order);
            AppMetrica.reportECommerce(purchaseEvent);
            callbackContext.success("add products finishCheckout");
        } catch (JSONException ex) {
            callbackContext.error(ex.getMessage());
        }

    }

    private Activity getActivity() {
        return cordova.getActivity();
    }

    private ExecutorService getAppMetricaExecutor() {
        return mExecutor;
    }

    private void onPauseSession() {
        synchronized (mLock) {
            mActivityPaused = true;
            if (mAppMetricaActivated) {
                AppMetrica.pauseSession(getActivity());
            }
        }
    }

    private void onResumeSession() {
        synchronized (mLock) {
            mActivityPaused = false;
            if (mAppMetricaActivated) {
                AppMetrica.resumeSession(getActivity());
            }
        }
    }

    public static Location toLocation(final JSONObject locationObj) throws JSONException {
        final Location location = new Location("Custom");

        if (locationObj.has("latitude")) {
            location.setLatitude(locationObj.getDouble("latitude"));
        }
        if (locationObj.has("longitude")) {
            location.setLongitude(locationObj.getDouble("longitude"));
        }
        if (locationObj.has("altitude")) {
            location.setAltitude(locationObj.getDouble("altitude"));
        }
        if (locationObj.has("accuracy")) {
            location.setAccuracy((float) locationObj.getDouble("accuracy"));
        }
        if (locationObj.has("course")) {
            location.setBearing((float) locationObj.getDouble("course"));
        }
        if (locationObj.has("speed")) {
            location.setSpeed((float) locationObj.getDouble("speed"));
        }
        if (locationObj.has("timestamp")) {
            location.setTime(locationObj.getLong("timestamp"));
        }

        return location;
    }

    public static AppMetricaConfig toConfig(final JSONObject configObj) throws JSONException {
        final String apiKey = configObj.getString("apiKey");
        final AppMetricaConfig.Builder builder = AppMetricaConfig.newConfigBuilder(apiKey);

        if (configObj.has("handleFirstActivationAsUpdate")) {
            builder.handleFirstActivationAsUpdate(configObj.getBoolean("handleFirstActivationAsUpdate"));
        }
        if (configObj.has("locationTracking")) {
            builder.withLocationTracking(configObj.getBoolean("locationTracking"));
        }
        if (configObj.has("sessionTimeout")) {
            builder.withSessionTimeout(configObj.getInt("sessionTimeout"));
        }
        if (configObj.has("crashReporting")) {
            builder.withCrashReporting(configObj.getBoolean("crashReporting"));
        }
        if (configObj.has("appVersion")) {
            builder.withAppVersion(configObj.getString("appVersion"));
        }
        if (configObj.optBoolean("logs", false)) {
            builder.withLogs();
        }
        if (configObj.has("location")) {
            final Location location = toLocation(configObj.getJSONObject("location"));
            builder.withLocation(location);
        }
        if (configObj.has("preloadInfo")) {
            final JSONObject preloadInfoObj = configObj.getJSONObject("preloadInfo");
            final PreloadInfo.Builder infoBuilder = PreloadInfo.newBuilder(preloadInfoObj.getString("trackingId"));
            final JSONObject additionalInfoObj = preloadInfoObj.optJSONObject("additionalParams");
            if (additionalInfoObj != null) {
                for (Iterator<String> keyIterator = additionalInfoObj.keys(); keyIterator.hasNext(); ) {
                    final String key = keyIterator.next();
                    final String value = additionalInfoObj.getString(key);
                    infoBuilder.setAdditionalParams(key, value);
                }
            }
            builder.withPreloadInfo(infoBuilder.build());
        }

        return builder.build();
    }

    private void activate(final JSONArray args,
                          final CallbackContext callbackContext) throws JSONException {
        final JSONObject configObj = args.getJSONObject(0);
        final AppMetricaConfig config = toConfig(configObj);

        final Context context = getActivity().getApplicationContext();
        AppMetrica.activate(context, config);

        synchronized (mLock) {
            if (!mAppMetricaActivated) {
                AppMetrica.reportAppOpen(getActivity());
                if (!mActivityPaused) {
                    AppMetrica.resumeSession(getActivity());
                }
            }
            mAppMetricaActivated = true;
        }
    }

    private void reportEvent(final JSONArray args,
                             final CallbackContext callbackContext) throws JSONException {
        final String eventName = args.getString(0);
        String eventParametersJSONString = null;
        try {
            final JSONObject eventParametersObj = args.getJSONObject(1);
            eventParametersJSONString = eventParametersObj.toString();
        } catch (JSONException ignored) {
        }

        if (eventParametersJSONString != null) {
            AppMetrica.reportEvent(eventName, eventParametersJSONString);
        } else {
            AppMetrica.reportEvent(eventName);
        }
    }

    private void reportError(final JSONArray args,
                             final CallbackContext callbackContext) throws JSONException {
        final String errorName = args.getString(0);
        Throwable errorThrowable = null;
        try {
            final String errorReason = args.getString(1);
            errorThrowable = new Throwable(errorReason);
        } catch (JSONException ignored) {
        }

        AppMetrica.reportError(errorName, errorThrowable);
    }


    private void setLocation(final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        final JSONObject locationObj = args.getJSONObject(0);

        final Location location = toLocation(locationObj);
        AppMetrica.setLocation(location);
    }

    private void setLocationTracking(final JSONArray args,
                                     final CallbackContext callbackContext) throws JSONException {
        final boolean enabled = args.getBoolean(0);

        AppMetrica.setLocationTracking(enabled);
    }
}
