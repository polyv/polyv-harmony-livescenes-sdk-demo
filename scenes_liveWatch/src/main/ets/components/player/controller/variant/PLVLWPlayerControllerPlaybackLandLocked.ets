import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerControllerLockButton } from '../widget/PLVLWPlayerControllerLockButton';
import { PLVLWPlayerControllerProgressLayout } from '../widget/PLVLWPlayerControllerProgressLayout';

@Component
export struct PLVLWPlayerControllerPlaybackLandLocked {
  build() {
    RelativeContainer() {
      PLVLWPlayerControllerProgressLayout()
        .id('plvlw_player_controller_progress_layout')
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          left: 8,
          right: 8,
          bottom: 6
        })

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