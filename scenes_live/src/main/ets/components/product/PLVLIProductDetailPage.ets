import { router } from '@kit.ArkUI'
import { PLVDeviceUtils, PLVJSONObject, PLVSimpleWeb, PLVWebController } from '@polyvharmony/live-scenes-sdk'

const ROUTE_NAME = 'PLVLIProductDetailPage'

export function pushToProductDetailPage(url: string) {
  router.pushNamedRoute({
    name: ROUTE_NAME,
    params: {
      url: url
    }
  })
}

@Preview
@Component
@Entry({
  routeName: ROUTE_NAME
})
struct PLVLIProductDetailPage {
  productDetailUrl?: string = (router.getParams() as PLVJSONObject)['url'] as string
  controller: PLVWebController = new PLVWebController()

  aboutToAppear(): void {
  }

  onBackPress(): boolean | void {
    if (this.controller.accessBackward()) {
      this.controller.backward()
      return true
    }
  }

  build() {
    Stack() {
      PLVSimpleWeb({
        controller: this.controller,
        src: this.productDetailUrl,
        showLoading: true
      })
    }
    .margin({ top: PLVDeviceUtils.getStatusBarHeight(), bottom: PLVDeviceUtils.getNavigationIndicatorHeight() })
  }
}