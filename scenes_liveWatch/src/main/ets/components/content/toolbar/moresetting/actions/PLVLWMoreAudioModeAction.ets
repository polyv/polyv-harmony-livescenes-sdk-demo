import { PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import {
  lateInit,
  MutableObserver,
  PLVMediaOutputMode,
  PLVMediaPlayerPlayingState,
  watchStates
} from '@polyvharmony/media-player-sdk';
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common';

@Component
export struct PLVLWMoreAudioModeAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  @State private isAudioMode: boolean = false
  @State private isVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      const supportOutputModes = mediaPlayer.getBusinessListenerRegistry().supportMediaOutputModes.value ?? []
      const currentOutputMode = mediaPlayer.getBusinessListenerRegistry()
        .currentMediaOutputMode
        .value ?? PLVMediaOutputMode.AUDIO_VIDEO
      const supportAudioMode = supportOutputModes.includes(PLVMediaOutputMode.AUDIO_ONLY)
      const isMediaPlaying = mediaPlayer.getStateListenerRegistry()
        .playingState
        .value === PLVMediaPlayerPlayingState.PLAYING
      const isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
      this.isAudioMode = currentOutputMode === PLVMediaOutputMode.AUDIO_ONLY
      this.isVisible = isMediaPlaying && isLive && supportAudioMode
    }).pushTo(this.observers)
  }

  build() {
    MoreSettingActionView({
      icon: $r('app.media.plvlw_more_audio_mode_icon'),
      iconColor: this.isAudioMode ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_tint') : undefined,
      title: $r('app.string.plvlw_player_audio_mode'),
      titleColor: this.isAudioMode
        ? $r('app.color.plvlw_more_setting_action_popup_layout_selected_item_text')
        : $r('app.color.plvlw_more_setting_action_title')
    })
      .onClick(() => {
        if (!this.isAudioMode) {
          this.sdk.playerManager.mainMediaPlayer.changeMediaOutputMode(PLVMediaOutputMode.AUDIO_ONLY)
        } else {
          this.sdk.playerManager.mainMediaPlayer.changeMediaOutputMode(PLVMediaOutputMode.AUDIO_VIDEO)
        }
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
      })
      .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}