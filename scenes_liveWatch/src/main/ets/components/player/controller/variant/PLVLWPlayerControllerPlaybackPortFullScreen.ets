import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerControllerPlayPauseButton } from '../widget/PLVLWPlayerControllerPlayPauseButton';
import { PLVLWPlayerControllerProgressLayout } from '../widget/PLVLWPlayerControllerProgressLayout';

@Component
export struct PLVLWPlayerControllerPlaybackPortFullScreen {
  build() {
    RelativeContainer() {
      PLVLWPlayerControllerPlayPauseButton()
        .id('plvlw_player_controller_play_pause_button')
        .width(36)
        .height(36)
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })
        .margin({
          left: 8
        })

      PLVLWPlayerControllerProgressLayout()
        .id('plvlw_player_controller_progress_layout')
        .alignRules({
          start: { anchor: 'plvlw_player_controller_play_pause_button', align: HorizontalAlign.End },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })
        .margin({
          left: 8,
          right: 8
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(56)
  }
}