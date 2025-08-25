import { PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk'
import {
  isLiteralTrue,
  lateInit,
  MutableObserver,
  PLVMediaPlayerPlayingState,
  watchStates
} from '@polyvharmony/media-player-sdk'
import { PLVLWMoreBitRateSelectDialog } from '../../../content/toolbar/moresetting/actions/PLVLWMoreBitRateAction'
import { PLVLWMoreSpeedSelectDialog } from '../../../content/toolbar/moresetting/actions/PLVLWMoreSpeedAction'
import { PLVLWMoreSettingIcon } from '../../../content/toolbar/moresetting/PLVLWMoreSettingLayout'

@Component
export struct PLVLWPlayerControllerTopToolBarLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private bitRateButtonVisible: boolean = false
  @State private bitRateButtonText: ResourceStr = $r('app.string.plvlw_player_definition')
  private readonly bitRateSelectDialog = new CustomDialogController({
    builder: PLVLWMoreBitRateSelectDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  @State private speedButtonVisible: boolean = false
  private readonly speedSelectDialog = new CustomDialogController({
    builder: PLVLWMoreSpeedSelectDialog(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const mediaPlayer = this.sdk.playerManager.mainMediaPlayer
      const supportBitRates = mediaPlayer.getBusinessListenerRegistry().supportMediaBitRates.value ?? []
      const currentBitRate = mediaPlayer.getBusinessListenerRegistry().currentMediaBitRate.value
      const isMediaPlaying = mediaPlayer.getStateListenerRegistry()
        .playingState
        .value === PLVMediaPlayerPlayingState.PLAYING
      this.bitRateButtonVisible = supportBitRates.length > 0 && isMediaPlaying
      this.bitRateButtonText = currentBitRate?.name ?? $r('app.string.plvlw_player_definition')
    }).pushTo(this.observers)

    const channelSupportSpeedControl = isLiteralTrue(this.sdk.channelData.liveDetail?.playbackMultiplierEnabled)
    const isPlayback = this.sdk.channelData.loginType === PLVLoginType.PLAYBACK
    this.speedButtonVisible = channelSupportSpeedControl && isPlayback
  }

  build() {
    Row({ space: 16 }) {
      Text($r('app.string.plvlw_player_speed_short'))
        .fontSize(16)
        .fontColor($r('app.color.plvlw_player_controller_top_toolbar_text'))
        .visibility(this.speedButtonVisible ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.speedSelectDialog.open()
        })

      Text(this.bitRateButtonText)
        .fontSize(16)
        .fontColor($r('app.color.plvlw_player_controller_top_toolbar_text'))
        .visibility(this.bitRateButtonVisible ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          this.bitRateSelectDialog.open()
        })

      PLVLWMoreSettingIcon()
        .width(36)
        .height(36)
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}