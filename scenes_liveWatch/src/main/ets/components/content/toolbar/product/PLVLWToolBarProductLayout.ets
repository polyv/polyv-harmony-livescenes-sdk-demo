import {
  EVENT_TYPE_CLICK_PRODUCT_BUTTON,
  PLVAvoidAreaChangeListener,
  PLVCommonConstants,
  PLVInteractManager,
  PLVLiveSceneSDK,
  PLVProductContentBean,
  PLVProductWeb,
  PLVSocketWebController,
  PLVToastUtils,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus'
import { pushToProductDetailPage } from './PLVLWProductDetailPage'
import { window } from '@kit.ArkUI'

@Component
export struct PLVLWToolBarProductIcon {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private bottomMargin: number = 0
  @State private readonly defaultBottomMargin: number = 0
  private isPortrait: boolean = true
  private controller?: CustomDialogController = undefined
  private portraitController = new CustomDialogController({
    builder: PLVLWProductDialog({ bottomMargin: this.bottomMargin }),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  private landController = new CustomDialogController({
    builder: PLVLWProductDialog({ bottomMargin: this.defaultBottomMargin }),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true,
    keyboardAvoidMode: KeyboardAvoidMode.NONE
  })
  private avoidAreaChangeListener: PLVAvoidAreaChangeListener | undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isPortrait = this.layoutDataBus.isPortrait.value ?? true
      this.controller = this.isPortrait ? this.portraitController : this.landController
    }).pushTo(this.observers)
    this.avoidAreaChangeListener = PLVUtils.listenerAvoidAreaChange((data) => {
      if (data.type == window.AvoidAreaType.TYPE_KEYBOARD) {
        const isKeyboardShow = data.area.bottomRect.height > 0
        this.bottomMargin = isKeyboardShow ? -16 : 0
      }
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.avoidAreaChangeListener?.off()
  }

  build() {
    Image($r('app.media.plvlw_tool_bar_shopping_icon'))
      .onClick(() => {
        this.controller?.open()
      })
  }
}

@CustomDialog
struct PLVLWProductDialog {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @Link bottomMargin: number
  @State private readonly productController: PLVSocketWebController = this.sdk.webControllerManager.create()
  @State private readonly interactManager: PLVInteractManager = this.sdk.interactManager
  @State private isPortrait: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.productController.eventNotify.on(EVENT_TYPE_CLICK_PRODUCT_BUTTON, this.onClickProduct, this)
    this.layoutDataBus.isPortrait.observe(it => this.isPortrait = it).pushTo(this.observers)
  }

  build() {
    Stack() {
      PLVProductWeb({
        controller: this.productController,
        interactManager: this.interactManager
      })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
    }
    .borderRadius({
      topLeft: 12,
      topRight: this.isPortrait ? 12 : 0,
      bottomLeft: this.isPortrait ? 0 : 12
    })
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : 375)
    .height(this.isPortrait ? 420 : PLVCommonConstants.FULL_PERCENT)
    .clip(true)
    .margin({ bottom: this.bottomMargin })
    .backgroundColor('#FFFFFF')
  }

  private onClickProduct = (data: PLVProductContentBean) => {
    const productLink = data.getLinkByType()
    if (!productLink) {
      PLVToastUtils.longShow($r('app.string.plvlw_commodity_toast_empty_link'))
      return
    }
    pushToProductDetailPage(productLink)
    this.controller.close()
  }

  aboutToDisappear(): void {
    this.productController.eventNotify.off(EVENT_TYPE_CLICK_PRODUCT_BUTTON, this.onClickProduct, this)
    MutableObserver.disposeAll(this.observers)
  }
}