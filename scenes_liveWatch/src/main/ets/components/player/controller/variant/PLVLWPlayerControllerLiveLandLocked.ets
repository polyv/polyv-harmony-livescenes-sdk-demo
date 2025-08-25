import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerControllerLockButton } from '../widget/PLVLWPlayerControllerLockButton';

@Component
export struct PLVLWPlayerControllerLiveLandLocked {
  build() {
    RelativeContainer() {
      PLVLWPlayerControllerLockButton()
        .width(36)
        .height(36)
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })
        .margin({
          left: 8
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}