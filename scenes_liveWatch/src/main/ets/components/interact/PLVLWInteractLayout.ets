import {
  PLVCallback,
  PLVCommonConstants,
  PLVDeviceUtils,
  PLVInteractCallback,
  PLVInteractManager,
  PLVInteractWeb,
  PLVJSONObject,
  PLVLiveSceneSDK,
  PLVRedpackManager,
  PLVSimpleWeb,
  PLVSocketWebController,
  PLVToastUtils,
  PLVWebController
} from '@polyvharmony/live-scenes-sdk'
import { PLVLWCommonDef } from '../../common/PLVLWCommonDef'
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus'
import { pushToProductDetailPage } from '../content/toolbar/product/PLVLWProductDetailPage'
import { router } from '@kit.ArkUI'
import { lateInit } from '@polyvharmony/media-player-sdk'


const TAG = "[PLVLWInteractLayout]"

@Component
export struct PLVLWInteractLayout {
  // <editor-fold defaultstate="collapsed" desc="变量">
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State interactManager?: PLVInteractManager = this.sdk?.interactManager
  @State interactCallback: PLVInteractCallback = new PLVInteractCallback()
  private redpackManager?: PLVRedpackManager = this.sdk?.redpackManager
  private backHandler?: PLVCallback<void, boolean>
  @State controller?: PLVSocketWebController = this.sdk?.webControllerManager.create()
  @State innerController?: PLVWebController = new PLVWebController()
  @State isShowInnerWeb: boolean = false
  @State isShow: boolean = false
  // 内部webview点击时拦截
  touchInnerWeb: boolean = false

  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="View">
  aboutToAppear(): void {
    this.onInteractData()
    this.layoutDataBus?.registerBackPressedHandler(this.backHandler = () => {
      if (this.isShow || this.isShowInnerWeb) {
        if (this.isShowInnerWeb) {
          this.isShowInnerWeb = false
          return true
        }
        if (this.isShow) {
          this.isShow = false
          return true
        }
      }
      return false
    }, PLVLWCommonDef.BACK_PRIORITY_INTERACT_LAYOUT)
  }

  aboutToDisappear(): void {
    this.layoutDataBus?.unregisterBackPressedHandler(this.backHandler)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      PLVInteractWeb({
        interactManager: this.interactManager,
        interactCallback: this.interactCallback,
        controller: this.controller,
        redpackManager: this.redpackManager
      })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
        .visibility(this.isShow ? Visibility.Visible : Visibility.Hidden)

      if (this.isShowInnerWeb) {
        PLVSimpleWeb({
          controller: this.innerController,
          src: ""
        })
          .width(PLVCommonConstants.FULL_PERCENT)
          .height('70%')
          .align(Alignment.BottomEnd)
          .onClick((event) => {
            this.touchInnerWeb = true
          })
          .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .onClick((event) => {
      if (this.touchInnerWeb) {
        this.touchInnerWeb = false
        return
      }
      if (this.isShowInnerWeb && !this.touchInnerWeb) {
        this.isShowInnerWeb = false
      }
    })
    .visibility(this.isShow || this.isShowInnerWeb ? Visibility.Visible : Visibility.Hidden)
  }

  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="内部API">

  onInteractData() {
    this.interactCallback.processWebViewVisibility = (show) => {
      this.isShow = show
    }

    this.interactCallback.processOpenLinkEvent = (isInsideOpen, isOutsideOpen, url) => {
      if (isInsideOpen) {
        this.isShowInnerWeb = true

        this.innerController?.addOnControllerAttached(() => {
          this.innerController?.loadUrlCatch(url)
        })
      }
      if (isOutsideOpen) {
        pushToCardPushDetailPage(url)
      }
    }

    this.interactCallback.processClickProductEvent = (productLink) => {
      if (!productLink) {
        PLVToastUtils.longShow($r('app.string.plvlw_commodity_toast_empty_link'))
        return
      }
      pushToProductDetailPage(productLink)
    }
  }

  // </editor-fold>
}

// <editor-fold defaultstate="collapsed" desc="卡片推送详情跳转页">
const ROUTE_NAME = 'CardPushDetailPage'

function pushToCardPushDetailPage(url: string) {
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
struct CardPushDetailPage {
  cardpushDetailUrl?: string = (router.getParams() as PLVJSONObject)['url'] as string
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
        src: this.cardpushDetailUrl,
        showLoading: true
      })
    }
    .margin({ top: PLVDeviceUtils.getStatusBarHeight(), bottom: PLVDeviceUtils.getNavigationIndicatorHeight() })
  }
}

// </editor-fold>
