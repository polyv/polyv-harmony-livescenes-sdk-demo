import { PLVCommonConstants, PLVLazyValue, PLVLiveSceneSDK, PLVNodeController } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus'
import { createPlayerViewNodeController, PlayerViewData } from '../../player/node/PLVLWPlayerView'
import { createPPTViewNodeController, PPTViewData } from './PLVLWPPTView'

@Component
export struct PLVLWPPTPlayerExchangeView {
  @State @Require isMainScreenUse: boolean = false
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State isPPTToMainScreen: boolean = false
  private pptViewNodeController: PLVLazyValue<PLVNodeController> = new PLVLazyValue(() => {
    return createPPTViewNodeController(!this.isMainScreenUse, new PPTViewData(this.sdk, this.layoutDataBus))
  })
  private playerViewNodeController: PLVLazyValue<PLVNodeController> = new PLVLazyValue(() => {
    return createPlayerViewNodeController(this.isMainScreenUse, new PlayerViewData(this.sdk, this.layoutDataBus))
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLayoutData()
  }

  aboutToDisappear(): void {
    this.pptViewNodeController.get().destroy()
    this.playerViewNodeController.get().destroy()
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    RelativeContainer() {
      // 由于Web组件交换位置后，H5页面不会自适应容器的大小，因此这里需要让其节点容器重新挂载
      if (this.isMainScreenUse && this.isPPTToMainScreen || (!this.isMainScreenUse && !this.isPPTToMainScreen)) {
        NodeContainer(this.pptViewNodeController.get())
          .hitTestBehavior(HitTestMode.Transparent)
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
      }
      NodeContainer(this.playerViewNodeController.get())
        .hitTestBehavior(HitTestMode.Transparent)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .focusable(false)
  }

  onLayoutData() {
    watchStates(() => {
      const isPPTToMainScreen = this.layoutDataBus.isPPTToMainScreen.value ?? false
      this.isPPTToMainScreen = isPPTToMainScreen
      const shouldShowPPT = this.isMainScreenUse ? isPPTToMainScreen : !isPPTToMainScreen
      this.pptViewNodeController.get().show(shouldShowPPT)
      this.playerViewNodeController.get().show(!shouldShowPPT)
    }).pushTo(this.observers)
  }
}