import { PLVCommonConstants, PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { PLVLWPlayerControllerLiveLandLocked } from './variant/PLVLWPlayerControllerLiveLandLocked';
import { PLVLWPlayerControllerLiveLandscape } from './variant/PLVLWPlayerControllerLiveLandscape';
import { PLVLWPlayerControllerLivePortFullScreen } from './variant/PLVLWPlayerControllerLivePortFullScreen';
import { PLVLWPlayerControllerLivePortHalfScreen } from './variant/PLVLWPlayerControllerLivePortHalfScreen';
import { PLVLWPlayerControllerPlaybackLandLocked } from './variant/PLVLWPlayerControllerPlaybackLandLocked';
import { PLVLWPlayerControllerPlaybackLandscape } from './variant/PLVLWPlayerControllerPlaybackLandscape';
import { PLVLWPlayerControllerPlaybackPortFullScreen } from './variant/PLVLWPlayerControllerPlaybackPortFullScreen';
import { PLVLWPlayerControllerPlaybackPortHalfScreen } from './variant/PLVLWPlayerControllerPlaybackPortHalfScreen';
import { PLVLWPlayerControllerGestureHandler } from './widget/PLVLWPlayerControllerGestureHandler';

@Component
export struct PLVLWPlayerControllerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private isPlayerFullscreen: boolean = false
  @State private isLive: boolean = false
  @State private isVisible: boolean = false
  @State private isLocked: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isPortrait = this.layoutDataBus.isPortrait.value ?? true
      this.isPlayerFullscreen = this.layoutDataBus.playerFullscreen.value ?? false
      this.isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
      this.isVisible = this.layoutDataBus.playerControllerStatus.value?.visible ?? false
      this.isLocked = this.layoutDataBus.playerControllerStatus.value?.locked ?? false
    }).pushTo(this.observers)
  }

  build() {
    Stack() {
      PLVLWPlayerControllerGestureHandler()

      Stack() {
        if (this.isLive && this.isPortrait && !this.isPlayerFullscreen) {
          PLVLWPlayerControllerLivePortHalfScreen()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (this.isLive && this.isPortrait && this.isPlayerFullscreen) {
          PLVLWPlayerControllerLivePortFullScreen()
        }
        if (this.isLive && !this.isPortrait && this.isLocked) {
          PLVLWPlayerControllerLiveLandLocked()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (this.isLive && !this.isPortrait && !this.isLocked) {
          PLVLWPlayerControllerLiveLandscape()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (!this.isLive && this.isPortrait && !this.isPlayerFullscreen) {
          PLVLWPlayerControllerPlaybackPortHalfScreen()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (!this.isLive && !this.isPortrait && this.isLocked) {
          PLVLWPlayerControllerPlaybackLandLocked()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (!this.isLive && !this.isPortrait && !this.isLocked) {
          PLVLWPlayerControllerPlaybackLandscape()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
      }
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
export struct PLVLWContentLayoutEmbedPlayerController {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private isPortrait: boolean = true
  @State private isPlayerFullscreen: boolean = false
  @State private isLive: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isPortrait = this.layoutDataBus.isPortrait.value ?? true
      this.isPlayerFullscreen = this.layoutDataBus.playerFullscreen.value ?? false
      this.isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
    }).pushTo(this.observers)
  }

  build() {
    if (!this.isLive && this.isPortrait && this.isPlayerFullscreen) {
      PLVLWPlayerControllerPlaybackPortFullScreen()
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}