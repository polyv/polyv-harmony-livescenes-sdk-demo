import { PLVCommonConstants, PLVLiveSceneSDK, PLVSocketWebController, PLVTuwenWeb } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVLWTuwenTabLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private webController: PLVSocketWebController = this.sdk.webControllerManager.create()

  build() {
    Stack() {
      PLVTuwenWeb({ controller: this.webController })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}