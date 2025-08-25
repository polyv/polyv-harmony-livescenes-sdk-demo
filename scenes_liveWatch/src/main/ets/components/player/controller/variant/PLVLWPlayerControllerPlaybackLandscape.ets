import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk';
import { PLVLWRewardMessageLayout } from '../../../chatroom/widget/PLVLWRewardMessageLayout';
import { PLVLWInteractSideBarLayout } from '../../../content/interactsidebar/PLVLWInteractSideBarLayout';
import { PLVLWProductPushCardLayout } from '../../../content/interactsidebar/product/PLVLWProductPushCardLayout';
import { PLVLWToolBarLayout } from '../../../content/toolbar/PLVLWToolBarLayout';
import { PLVLWPlayerControllerDanmuOpenButton } from '../widget/PLVLWPlayerControllerDanmuOpenButton';
import { PLVLWPlayerControllerLockButton } from '../widget/PLVLWPlayerControllerLockButton';
import { PLVLWPlayerControllerPlayPauseButton } from '../widget/PLVLWPlayerControllerPlayPauseButton';
import { PLVLWPlayerControllerProgressLayout } from '../widget/PLVLWPlayerControllerProgressLayout';
import { PLVLWPlayerControllerTopToolBarLayout } from '../widget/PLVLWPlayerControllerTopToolBarLayout';

@Component
export struct PLVLWPlayerControllerPlaybackLandscape {
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
          bottom: 20
        })

      PLVLWPlayerControllerDanmuOpenButton()
        .id('plvlw_player_controller_danmu_open_button')
        .width(36)
        .height(36)
        .padding(6)
        .alignRules({
          start: { anchor: 'plvlw_player_controller_play_pause_button', align: HorizontalAlign.End },
          center: { anchor: 'plvlw_player_controller_play_pause_button', align: VerticalAlign.Center }
        })
        .margin({
          left: 16
        })

      PLVLWToolBarLayout()
        .id('plvlw_player_controller_tool_bar_layout')
        .alignRules({
          start: { anchor: 'plvlw_player_controller_danmu_open_button', align: HorizontalAlign.End },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          center: { anchor: 'plvlw_player_controller_danmu_open_button', align: VerticalAlign.Center }
        })
        .margin({
          left: 8,
          right: 8
        })

      PLVLWPlayerControllerProgressLayout()
        .id('plvlw_player_controller_progress_layout')
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
          bottom: { anchor: 'plvlw_player_controller_play_pause_button', align: VerticalAlign.Top }
        })
        .margin({
          left: 8,
          right: 8,
          bottom: 6
        })

      PLVLWPlayerControllerTopToolBarLayout()
        .id('plvlw_player_controller_top_toolbar_layout')
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          top: 12,
          right: 20
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

      PLVLWRewardMessageLayout({
        maxShowRewards: 1
      })
        .alignRules({
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          bottom: { anchor: 'plvlw_player_controller_play_pause_button', align: VerticalAlign.Top }
        })
        .margin({
          bottom: 40
        })

      PLVLWInteractSideBarLayout({
        layoutStyle: 'landscape'
      })
        .alignRules({
          top: { anchor: 'plvlw_player_controller_top_toolbar_layout', align: VerticalAlign.Bottom },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          top: 6,
          right: 20
        })

      PLVLWProductPushCardLayout()
        .alignRules({
          bottom: { anchor: 'plvlw_player_controller_tool_bar_layout', align: VerticalAlign.Top },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          bottom: 28,
          right: 20
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }
}