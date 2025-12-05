import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerControllerVariantState } from '../vo/PLVLWPlayerControllerVariantState';
import { PLVLWPlayerControllerLockButton } from '../widget/PLVLWPlayerControllerLockButton';

@Component
export struct PLVLWPlayerControllerLiveLandLocked {
  static match(variant: PLVLWPlayerControllerVariantState): boolean {
    return variant.isLive && !variant.isPortrait && variant.isLocked && !variant.isCasting
  }

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