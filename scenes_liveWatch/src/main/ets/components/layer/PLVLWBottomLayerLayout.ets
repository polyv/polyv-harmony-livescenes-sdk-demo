import { PLVCommonConstants, PLVLinkMicState, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';
import { PLVLWLinkMicLayout } from '../linkmic/PLVLWLinkMicLayout';
import { PLVLWPlayerLayout } from '../player/PLVLWPlayerLayout';

@Preview
@Component
export struct PLVLWBottomLayerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isLinkmic: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isLinkmic = this.sdk?.linkmicManager.linkmicState.value === PLVLinkMicState.Joined
      this.layoutDataBus.isLinkmic.setValue(this.isLinkmic)
    }).pushTo(this.observers)
  }

  build() {
    RelativeContainer() {
      if (this.isLinkmic) {
        PLVLWLinkMicLayout()
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
      } else {
        PLVLWPlayerLayout()
          .width(PLVCommonConstants.FULL_PERCENT)
          .height(PLVCommonConstants.FULL_PERCENT)
      }
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

}