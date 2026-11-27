import { PLVLWPlaybackStepSeekLayout } from '../widget/PLVLWPlaybackStepSeekLayout';
import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWPlayerControllerVariantState } from '../vo/PLVLWPlayerControllerVariantState';
import { PLVLWPlayerControllerPlayPauseButton } from '../widget/PLVLWPlayerControllerPlayPauseButton';
import { PLVLWPlayerControllerProgressLayout } from '../widget/PLVLWPlayerControllerProgressLayout';

@Component
export struct PLVLWPlayerControllerPlaybackPortFullScreen {
  static match(variant: PLVLWPlayerControllerVariantState): boolean {
    return !variant.isLive && variant.isPortrait && variant.isPlayerFullscreen && !variant.isCasting
  }

  build() {
    RelativeContainer() {
      PLVLWPlaybackStepSeekLayout()
        .alignRules({
          middle: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Center },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}

/** 竖屏全屏的底部进度条嵌入内容层，中央按钮由播放器内的回放子控制栏承载。 */
@Component
export struct PLVLWPlayerControllerPlaybackPortFullScreenBar {
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
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#00000000', 0], ['#4D000000', 1]]
    })
  }
}
