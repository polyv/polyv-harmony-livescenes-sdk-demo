import { PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import {
  lateInit,
  MutableObserver,
  PLVLiveStatusEnum,
  PLVMediaPlayerState,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../common/PLVLWLayoutDataBus';
import { PLVLWPlayerControllerVariantState } from '../vo/PLVLWPlayerControllerVariantState';

@Component
export struct PLVLWPlayerControllerLivePortFullScreen {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private showToPlayButton: boolean = false
  private observers: MutableObserver[] = []

  static match(variant: PLVLWPlayerControllerVariantState): boolean {
    return variant.isLive && variant.isPortrait && variant.isPlayerFullscreen && !variant.isCasting
  }

  aboutToAppear(): void {
    watchStates(() => {
      const isLinkmic = this.layoutDataBus.isLinkmic.value ?? false
      const isLive = this.sdk.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
        .liveStatus
        .value === PLVLiveStatusEnum.LIVE
      const isPaused = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .playerState
        .value === PLVMediaPlayerState.STATE_PAUSED
      this.showToPlayButton = isLive && isPaused && !isLinkmic
    }).pushTo(this.observers)
  }

  build() {
    Stack() {
      Image($r("app.media.plvlw_player_controller_to_play_icon_port_fullscreen"))
        .width(72)
        .height(72)
        .visibility(this.showToPlayButton ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.sdk.playerManager.mainMediaPlayer.restart()
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}