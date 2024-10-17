import {
  IPLVBackwardInterface,
  PLVCallback,
  PLVCommonConstants,
  PLVInteractCallback,
  PLVInteractManager,
  PLVInteractWeb,
  PLVLiveSceneSDK,
  PLVRedpackManager,
  PLVSimpleWeb,
  PLVSocketWebController,
  PLVToastUtils,
  PLVWebController
} from '@polyvharmony/live-scenes-sdk'
import { pushToCardPushDetailPage } from './cardpush/PLVLICardPushDetailPage';
import { pushToProductDetailPage } from '../product/PLVLIProductDetailPage';


const TAG = "[PLVInteractWeb]"

@Component
export struct PLVLIInteractWebView {
  // <editor-fold defaultstate="collapsed" desc="变量">
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @State interactManager?: PLVInteractManager = this.sdk?.interactManager
  @State interactCallback: PLVInteractCallback = new PLVInteractCallback()
  redpackManager?: PLVRedpackManager = this.sdk?.redpackManager
  @ObjectLink viewController: PLVInteractWebViewController
  @State controller?: PLVSocketWebController = this.sdk?.webControllerManager.create()
  @State innerController?:PLVWebController = new PLVWebController()
  @State isShowInnerWeb: boolean = false
  // 内部webview点击时拦截
  touchInnerWeb: boolean = false
  // 内部webview事件处理逻辑回调
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="View">
  aboutToAppear(): void {
    this.config()
  }

  build() {
    Column(){
      Stack({ alignContent: Alignment.Bottom}){
        PLVInteractWeb({
          interactManager: this.interactManager,
          interactCallback: this.interactCallback,
          controller: this.controller,
          redpackManager: this.redpackManager
        })
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
          .visibility(this.viewController.isShow ? Visibility.Visible : Visibility.Hidden)

        if (this.viewController.isShowInnerWeb) {
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
        if (this.viewController.isShowInnerWeb && !this.touchInnerWeb) {
          this.viewController.isShowInnerWeb = false
        }
      })
      .visibility(this.viewController.isShow || this.viewController.isShowInnerWeb ? Visibility.Visible : Visibility.Hidden)
    }
  }

  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="内部API">

  config() {
    this.interactCallback.processWebViewVisibility = (show) => {
      this.viewController.isShow = show
    }

    this.interactCallback.processOpenLinkEvent = (isInsideOpen, isOutsideOpen, url) => {
      if (isInsideOpen) {
        this.viewController.isShowInnerWeb = true

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
        PLVToastUtils.longShow($r('app.string.plvli_commodity_toast_empty_link'))
        return
      }
      pushToProductDetailPage(productLink)
    }
  }

  // </editor-fold>
}


// <editor-fold defaultstate="collapsed" desc="返回拦截处理">
@Observed
export class PLVInteractWebViewController implements IPLVBackwardInterface {
  isShow: boolean = false
  isShowInnerWeb: boolean = false
  accessBackward: PLVCallback<void, boolean> = () => {
    return this.isShow || this.isShowInnerWeb
  }
  backward: PLVCallback<void, void> = () => {
    if (this.isShowInnerWeb) {
      this.isShowInnerWeb = false
    }
    if (this.isShow) {
      this.isShow = false
    }
  }
}
// </editor-fold>
