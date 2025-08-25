import { PLVCommonConstants, PLVLiveSceneSDK, PLVQAWeb, PLVSocketWebController } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVLWQATabLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private webController: PLVSocketWebController = this.sdk.webControllerManager.create()

  build() {
    Stack() {
      PLVQAWeb({ controller: this.webController })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}