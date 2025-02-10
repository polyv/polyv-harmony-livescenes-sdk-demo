import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { DerivedState, extendNumber, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVSAStatusUserInfoBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private actorNickName: string = ""
  @State private isAudioEnable: boolean = false
  @State private audioVolume: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.initActorNickName()
    const audioEnableState = new DerivedState(() => this.sdk.linkmicManager.localLinkMicViewer.value?.isAudioEnable.value ?? false)
    audioEnableState.observe(it => this.isAudioEnable = it).pushTo(this.observers)
    const audioVolumeState = new DerivedState(() => this.sdk.linkmicManager.localLinkMicViewer.value?.audioVolume.value ?? 0)
    audioVolumeState.observe(it => this.audioVolume = it).pushTo(this.observers)
  }

  private initActorNickName() {
    const actor = this.sdk.channelData.viewerActor
    const nickName = this.sdk.channelData.viewerName ?? ""
    let actorNickName: string
    if (actor !== undefined) {
      actorNickName = `${actor}-${nickName}`
    } else {
      actorNickName = nickName
    }
    if (actorNickName.length > 20) {
      this.actorNickName = actorNickName.substring(0, 20) + "..."
    } else {
      this.actorNickName = actorNickName
    }
  }

  build() {
    Row() {
      Text(this.actorNickName)
        .fontColor('#FFFFFF')
        .fontSize(12)
        .maxLines(1)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
        .ellipsisMode(EllipsisMode.END)

      Image(this.audioVolumeIcon())
        .width(14)
        .height(14)
        .margin({
          left: 6
        })
    }
    .backgroundColor('#33000000')
    .borderRadius(10)
    .padding({
      left: 8,
      right: 8,
      top: 2,
      bottom: 2
    })
  }

  private audioVolumeIcon(): Resource {
    if (!this.isAudioEnable) {
      return $r('app.media.plvsa_linkmic_audio_volume_closed')
    } else {
      const clampValue = extendNumber(this.audioVolume).coerceIn_ext(0, 100)
      const normalizeVolume = Math.round(clampValue / 10) * 10
      return $r(`app.media.plvsa_linkmic_audio_volume_value_${normalizeVolume}`)
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}