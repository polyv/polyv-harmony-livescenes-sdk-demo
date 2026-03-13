import { PLVCallback, PLVCommonConstants, PLVLiveSceneSDK, PLVStreamerInteractCallback, PLVStreamerInteractWeb, PLVStreamerInteractWebController } from "@polyvharmony/live-scenes-sdk";
import { Disposable, lateInit } from "@polyvharmony/media-player-sdk";
import { PLVSAPageDataBus } from "../../common/PLVSAPageDataBus";

@Component
export struct PLVSAInteractLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State interactCallback: PLVStreamerInteractCallback = new PLVStreamerInteractCallback()
  @State controller: PLVStreamerInteractWebController = this.sdk.webControllerManager.createStreamerInteractWebController()
  @State @Watch('onShow') isShow: boolean = false
  isShowCallback: PLVCallback<boolean> | undefined
  private onBackPressDisposable: Disposable | null = null

  aboutToAppear(): void {
    this.sdk.streamerInteractManager.setupController(this.controller)
    this.controller.interactCallback = this.interactCallback
    this.onBackPressDisposable = this.pageDataBus.onBackPressHandler.register(20, () => this.onBackPress())
    this.onInteractData()
  }

  onBackPress(): boolean {
    if (this.isShow) {
      this.isShow = false
      return true
    }
    return false
  }

  aboutToDisappear(): void {
    this.onBackPressDisposable?.dispose()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      PLVStreamerInteractWeb({
        controller: this.controller,
      })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
        .visibility(this.isShow ? Visibility.Visible : Visibility.Hidden)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .visibility(this.isShow ? Visibility.Visible : Visibility.Hidden)
  }

  private onShow() {
    this.isShowCallback?.(this.isShow)
  }

  private onInteractData() {
    this.interactCallback.processWebViewVisibility = (show) => {
      this.isShow = show
    }
  }
}