import {
  EVENT_TYPE_CLICK_PRODUCT_BUTTON,
  IPLVBackwardInterface,
  PLVCallback,
  PLVCommonConstants,
  PLVDeviceUtils,
  PLVEventNotify,
  PLVInteractManager,
  PLVLiveSceneSDK,
  PLVProductContentBean,
  PLVProductWeb,
  PLVSocketWebController,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk'
import { pushToProductDetailPage } from './PLVLIProductDetailPage'

const TAG = '[PLVLIProductWebView]'

@Preview
@Component
export struct PLVLIProductWebView {
  @Link viewController: PLVProductWebViewController
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @State productController?: PLVSocketWebController = this.sdk?.webControllerManager.create()
  @State interactManager?: PLVInteractManager = this.sdk?.interactManager
  @State offsetY: number = 6 + PLVDeviceUtils.getNavigationIndicatorHeight()

  aboutToAppear(): void {
    this.onProductData()
    this.onViewData()
  }

  build() {
    Column() {
      Stack() {
        Column() {
          PLVProductWeb({
            controller: this.productController,
            interactManager: this.interactManager
          })
        }
        .padding({
          left: 6,
          right: 6,
          top: 6,
          bottom: PLVDeviceUtils.getNavigationIndicatorHeight() - 6
        })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
      }
      .onTouch((event) => {
        event.stopPropagation()
      })
      .borderRadius({
        topLeft: 12,
        topRight: 12,
        bottomLeft: 0,
        bottomRight: 0
      })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(420)
      .backgroundColor('#CC000000')
      .backdropBlur(8)
    }
    .onTouch(() => {
      this.viewController.isShow = false
    })
    .offset({ y: this.offsetY })
    .justifyContent(FlexAlign.End)
    .visibility(this.viewController.isShow ? Visibility.Visible : Visibility.None)
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  onProductData() {
    this.productController?.eventNotify.on(EVENT_TYPE_CLICK_PRODUCT_BUTTON, (data: PLVProductContentBean) => {
      const productLink = data.getLinkByType()
      if (!productLink) {
        PLVToastUtils.longShow($r('app.string.plvli_commodity_toast_empty_link'))
        return
      }
      pushToProductDetailPage(productLink)
      this.viewController.isShow = false
    }, this)
  }

  onViewData() {
    this.viewController.eventNotify.on('isShow', (arg: boolean) => {
      this.viewController.isShow = arg
    }, this)
  }
}

export class PLVProductWebViewController implements IPLVBackwardInterface {
  isShow: boolean = false
  eventNotify: PLVEventNotify<'isShow'> = new PLVEventNotify(this)
  accessBackward: PLVCallback<void, boolean> = () => {
    return this.isShow
  }
  backward: PLVCallback<void, void> = () => {
    if (this.isShow) {
      this.eventNotify.emit('isShow', false)
      this.isShow = false
    }
  }
}