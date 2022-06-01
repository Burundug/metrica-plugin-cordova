# AppMetrica Cordova Plugin (Fork)

## Documentation

Common documentation available on [AppMetrica official site][DOCUMENTATION]. Documentation for this plugin will be
published soon.

## Sample project

Sample project to use is available at [sample/][GitHubSAMPLE].

## Installation



```bash
cordova plugin add https://github.com/Burundug/metrica-plugin-cordova.git
```

## Ecommerce usage

**Link to ecommerce documentation**

[Android](https://appmetrica.yandex.ru/docs/data-collection/sending-ecommerce-android.html)

[Ios](https://appmetrica.yandex.ru/docs/data-collection/sending-ecommerce-ios.html)

### Add events

- Page opening
    ```javascript
    window.appMetrica.showScreen({
   "screenName": screenName,
   "searchQuery": searchQuery,
  })
    ```
- Add to cart
  ```javascript
  window.appMetrica.addToCart({
   "screenName": screenName,
   "searchQuery": searchQuery,
   "name": productName,
   "price": productPrice,
   "currency": currentCurrency,
   "sku": productSku,
   "quantity": productQuantity
  })
    ```
- Remove from cart
  ```javascript
  window.appMetrica.removeFromCart({
   "screenName": screenName,
   "searchQuery": searchQuery,
   "name": productName,
   "price": productPrice,
   "currency": currentCurrency,
   "sku": productSku,
   "quantity": productQuantity
  })
    ```
- View product card
  ```javascript
  window.appMetrica.showProductCard({
   "screenName": screenName,
   "searchQuery": searchQuery,
   "name": productName,
   "price": productPrice,
   "currency": currentCurrency,
   "sku": productSku,
   "quantity": productQuantity
  })
    ```
- Begin checkout
  ```javascript
  window.appMetrica.beginCheckout({
  "identifier": string,
  "products": [productsObject]
  })
    ```
- Finish checkout
    ```javascript
    window.appMetrica.finishCheckout({
  "identifier": string,
  "products": [productsObject]
  })
  ```

## AppStore submit notice

Starting from version 1.6.0 Yandex AppMetrica became also a tracking instrument and uses Apple idfa to attribute
installs. Because of that during submitting your application to the AppStore you will be prompted with three checkboxes
to state your intentions for idfa usage. As Yandex AppMetrica uses idfa for attributing app installations you need to
select **Attribute this app installation to a previously served advertisement**.

## Changelog

### Version 1.1.0

* Updated versions of the AppMetrica SDK (Android 4.2.0).
* Added android ecommerce support.

### Version 1.0.0

* Updated versions of the AppMetrica SDK (iOS 3.7.1 and Android 3.6.4).
* Changed API methods.

### Version 0.4.0

* Updated iOS version of the AppMetrica SDK (iOS 2.9.8).
* Changed the SDK to meet the requirements of the Apple App Store Review Team. Update the AppMetrica SDK to avoid any
  issues during the App Store moderation process.

### Version 0.3.0

* Support cordova-android@7.0.0

### Version 0.2.0

* Updated versions of the AppMetrica SDK (iOS 2.9.4 and Android 2.78)
* Added a method for getting the configuration of the AppMetrica Push Cordova plugin.
* Fixed installation of iOS part from NPM (#1).

### Version 0.1.0

* Implemented plugin for AppMetrica iOS (v2.8.0) and AppMetrica Android (v2.62).
* Provided sample.

## License

License agreement on use of Yandex AppMetrica is available at [EULA site][LICENSE]


[LICENSE]: https://yandex.com/legal/appmetrica_sdk_agreement/ "Yandex AppMetrica agreement"

[DOCUMENTATION]: https://appmetrica.yandex.com/docs/quick-start/concepts/quick-start.html "Yandex AppMetrica documentation"

[GitHubSAMPLE]: https://github.com/yandexmobile/metrica-plugin-cordova/tree/master/sample "Sample from reository"
