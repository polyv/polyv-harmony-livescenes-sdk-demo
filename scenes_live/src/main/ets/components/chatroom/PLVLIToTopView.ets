import { PLVChannelData, PLVCommonConstants, PLVLiveSceneSDK, PLVLogger, PLVLoginType, PLVStateData, PLVTextUtils, PLVToTopEvent } from '@polyvharmony/live-scenes-sdk'
import { MutableObserver, PLVLiveStatusEnum } from '@polyvharmony/media-player-sdk'
import PLVLIFaceManager from '../../common/PLVLIFaceManager'

@Preview
@Component
export struct PLVLIToTopView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @State @Watch('onNoLiveChanged') isNoLive: boolean = true
  @State toTopData?: PLVStateData<PLVToTopEvent> = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    if (this.channelData?.loginType == PLVLoginType.LIVE) {
      this.onPlayerData()
      this.onChatData()
    } else {
      this.isNoLive = false
      this.onChatPlaybackData()
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }

  build() {
    if (this.toTopData?.data && !this.isNoLive) {
      Row() {
        Text() {
          Span(this.toTopData?.data.nick + ': ')
            .fontColor('#FFD16B')
          ForEach(PLVTextUtils.parseString(this.toTopData?.data.content), (data: string) => {
            if (typeof PLVLIFaceManager.getFace(data) === 'string') {
              Span(PLVLIFaceManager.getFace(data))
            } else {
              ImageSpan(PLVLIFaceManager.getFace(data))
                .width(21)
                .height(21)
                .verticalAlign(ImageSpanAlignment.CENTER)
            }
          })
        }
        .width(0)
        .layoutWeight(1)
        .padding({ right: 6 })
        .height(PLVCommonConstants.FULL_PERCENT)
        .fontColor('#FFFFFFFF')
        .fontSize(14)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($r('app.media.plvli_popup_close'))
          .draggable(false)
          .padding(10)
          .width(32)
          .height(32)
          .onClick(() => {
            this.toTopData = undefined
          })
      }
      .alignItems(VerticalAlign.Center)
      .padding({
        left: 12,
        right: 12
      })
      .width(320)
      .height(60)
      .borderRadius(8)
      .backgroundColor('#A8333333')
      .backdropBlur(8)
    }
  }

  onPlayerData() {
    this.sdk?.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
      .liveStatus
      .observe((liveStatus) => {
        this.isNoLive = liveStatus === PLVLiveStatusEnum.NO_LIVE
      })
      .pushTo(this.observers)
  }

  onChatData() {
    this.sdk?.chatroomManager.eventNotify.on('to_top', (data: PLVStateData<PLVToTopEvent>) => {
      this.toTopData = data
    }, this)
  }

  onChatPlaybackData() {
    this.sdk?.chatPlaybackManager.eventNotify.on('to_top', (data: PLVStateData<PLVToTopEvent>) => {
      this.toTopData = data
    }, this)
  }

  onNoLiveChanged() {
    if (this.isNoLive) {
      this.toTopData = undefined
    }
  }
}