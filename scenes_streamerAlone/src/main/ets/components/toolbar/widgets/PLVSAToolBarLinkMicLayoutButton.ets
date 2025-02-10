import { PLVLiveSceneSDK, PLVUserType } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus'
import { PLVSALinkMicLayoutType } from '../../linkmic/PLVSALinkMicLayout'

@Component
export struct PLVSAToolBarLinkMicLayoutButton {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private isVisible: boolean = false
  @State private layoutType: PLVSALinkMicLayoutType = PLVSALinkMicLayoutType.TILE
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.channelLinkMicViewers.observe(linkmicViewers => {
      const isTeacher = this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER
      this.isVisible = isTeacher && linkmicViewers.length > 1
    })
      .pushTo(this.observers)
    this.pageDataBus.linkmicLayoutType.observe(it => this.layoutType = it).pushTo(this.observers)
  }

  build() {
    if (this.isVisible) {
      Image(this.layoutTypeIcon())
        .width(36)
        .height(36)
        .onClick(() => {
          if (this.layoutType === PLVSALinkMicLayoutType.TILE) {
            this.pageDataBus.linkmicLayoutType.setValue(PLVSALinkMicLayoutType.SPEAKER)
          } else {
            this.pageDataBus.linkmicLayoutType.setValue(PLVSALinkMicLayoutType.TILE)
          }
        })
    }
  }

  private layoutTypeIcon(): Resource {
    switch (this.layoutType) {
      case PLVSALinkMicLayoutType.TILE:
      default:
        return $r('app.media.plvsa_linkmic_layout_speaker_icon');
      case PLVSALinkMicLayoutType.SPEAKER:
        return $r('app.media.plvsa_linkmic_layout_tile_icon');
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}