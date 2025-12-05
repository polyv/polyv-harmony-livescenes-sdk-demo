import { PLVCommonConstants, PLVLazyValue, PLVLiveSceneSDK, PLVNodeController } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus'
import { createPlayerViewNodeController, PlayerViewData } from '../../player/node/PLVLWPlayerView'
import { PLVLWPPTNodeContainer } from './PLVLWPPTNodeContainer'

@Component
export struct PLVLWPPTPlayerExchangeView {
  @State @Require isMainScreenUse: boolean = false
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State isPPTToMainScreen: boolean = false
  @State private isPPTVisible: boolean = false
  private playerViewNodeController: PLVLazyValue<PLVNodeController> = new PLVLazyValue(() => {
    return createPlayerViewNodeController(this.isMainScreenUse, new PlayerViewData(this.sdk, this.layoutDataBus))
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLayoutData()
  }

  aboutToDisappear(): void {
    this.playerViewNodeController.get().destroy()
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    RelativeContainer() {
      if (this.isPPTVisible) {
        PLVLWPPTNodeContainer()
      } else {
        NodeContainer(this.playerViewNodeController.get())
          .hitTestBehavior(HitTestMode.Transparent)
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
      }
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .focusable(false)
  }

  onLayoutData() {
    watchStates(async () => {
      const isPPTToMainScreen = this.layoutDataBus.isPPTToMainScreen.value ?? false
      this.isPPTToMainScreen = isPPTToMainScreen
      const shouldShowPPT = this.isMainScreenUse ? isPPTToMainScreen : !isPPTToMainScreen
      this.isPPTVisible = shouldShowPPT
      this.playerViewNodeController.get().show(!shouldShowPPT)
    }).pushTo(this.observers)
  }
}