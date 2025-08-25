import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerControllerDanmuOpenButton } from '../widget/PLVLWPlayerControllerDanmuOpenButton';
import { PLVLWPlayerControllerPlayPauseButton } from '../widget/PLVLWPlayerControllerPlayPauseButton';
import { PLVLWPlayerControllerPPTStatusLayout } from '../widget/PLVLWPlayerControllerPPTStatusLayout';
import { PLVLWPlayerControllerToggleOrientationButton } from '../widget/PLVLWPlayerControllerToggleOrientationButton';

@Component
export struct PLVLWPlayerControllerLivePortHalfScreen {
  build() {
    RelativeContainer() {
      PLVLWPlayerControllerPlayPauseButton()
        .id('plvlw_player_controller_play_pause_button')
        .width(36)
        .height(36)
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          left: 8,
          bottom: 8
        })

      PLVLWPlayerControllerPPTStatusLayout()
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          bottom: 12
        })

      PLVLWPlayerControllerDanmuOpenButton()
        .id('plvlw_player_controller_danmu_open_button')
        .width(36)
        .height(36)
        .padding(6)
        .alignRules({
          end: { anchor: 'plvlw_player_controller_toggle_orientation_button', align: HorizontalAlign.Start },
          center: { anchor: 'plvlw_player_controller_toggle_orientation_button', align: VerticalAlign.Center }
        })
        .margin({
          right: 8
        })

      PLVLWPlayerControllerToggleOrientationButton()
        .id('plvlw_player_controller_toggle_orientation_button')
        .width(36)
        .height(36)
        .alignRules({
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
        })
        .margin({
          right: 8,
          bottom: 8
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}