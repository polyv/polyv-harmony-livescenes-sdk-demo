import { IPLVIdEvent, PLVChannelData, PLVChatPlaybackDataVO, PLVCommonConstants, PLVLazyDataSource, PLVLiveSceneSDK, PLVLogger } from '@polyvharmony/live-scenes-sdk'
import { MutableObserver, PLVMediaPlayerState } from '@polyvharmony/media-player-sdk'
import { PLVLIChatListItem } from './PLVLIChatListItem'

const TAG = '[PLVLIChatPlaybackLayout]'

@Preview
@Component
export struct PLVLIChatPlaybackLayout {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @State isChatPlaybackEnabled: boolean = true
  @State chatPlaybackTipsVisible: boolean = true
  // 聊天
  chatListScroller: ListScroller = new ListScroller()
  // 当前显示的数据列表
  @State chatListData: PLVLazyDataSource<IPLVIdEvent> = new PLVLazyDataSource()
  @State isShowChatNewMessageTips: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.initData()
    this.onPlayerData()
    this.onChatPlaybackData()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }

  build() {
    Column() {
      Text($r('app.string.plvli_chat_playback_tips'))
        .fontSize(12)
        .backgroundColor('#E6FFFFFF')
        .borderRadius(4)
        .padding(8)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 12 })
        .fontColor('#FF333333')
        .constraintSize({ minWidth: 258 })
        .visibility(this.chatPlaybackTipsVisible ? Visibility.Visible : Visibility.Hidden)
        .onAppear(() => {
          setTimeout(() => {
            this.chatPlaybackTipsVisible = false
          }, 5000)
        })
      Stack({ alignContent: Alignment.BottomStart }) {
        List({ space: 4, scroller: this.chatListScroller }) {
          LazyForEach(this.chatListData, (item: IPLVIdEvent) => {
            ListItem() {
              PLVLIChatListItem({ itemData: item })
            }
          }, (item: IPLVIdEvent) => item.getUniqueId())
        }
        .onScrollIndex((start, end) => {
          if (end == this.chatListData.totalCount() - 1) {
            this.isShowChatNewMessageTips = false
          }
        })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Fade)
        .cachedCount(5)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

        if (this.isShowChatNewMessageTips) {
          this.newMessageTips(() => {
            this.isShowChatNewMessageTips = false
            this.chatListScroller.scrollEdge(Edge.Bottom)
          })
        }
      }
      .margin({ left: 16 })
      .width(244)
      .height(152)
    }
    .visibility(this.isChatPlaybackEnabled ? Visibility.Visible : Visibility.None)
  }

  @Builder
  newMessageTips(onClick?: () => void) {
    Text($r("app.string.plvli_chat_view_new_msg"))
      .backgroundColor('#ffffff')
      .borderRadius(10)
      .padding({
        left: 8,
        right: 8,
        top: 4,
        bottom: 4
      })
      .fontColor('#FFA611')
      .fontSize(14)
      .onClick(onClick)
  }

  initData() {
    this.isChatPlaybackEnabled = this.channelData?.liveDetail?.isChatPlaybackEnabled() ?? false
  }

  onPlayerData() {
    this.sdk?.playerManager.mainMediaPlayer.getStateListenerRegistry()
      .playerState
      .observe((value) => {
        if (value === PLVMediaPlayerState.STATE_PREPARED) {
          const playbackVideoData = this.sdk?.playerManager.mainMediaPlayer.getBusinessListenerRegistry().playbackVideoData.value
          const sessionId = playbackVideoData?.channelSessionId ?? ''
          const fileId = playbackVideoData?.fileId ?? ''
          this.sdk?.chatPlaybackManager.start(sessionId, fileId)
        }
        PLVLogger.info(TAG, `onPlayerData, playerState=${value}`)
      })
      .pushTo(this.observers)
  }

  onChatPlaybackData() {
    this.sdk?.chatPlaybackManager.setupPlayTimeCallback(() => {
      return this.sdk?.playerManager.mainMediaPlayer.getCurrentPosition() ?? 0
    })
    this.sdk?.chatPlaybackManager.eventNotify.on('insert_data', (...dataList: PLVChatPlaybackDataVO[]) => {
      this.pushDataToChatList(...dataList)
    }, this)
    this.sdk?.chatPlaybackManager.eventNotify.on('clear_data', () => {
      this.clearDataToChatList()
    }, this)
  }

  pushDataToChatList(...data: IPLVIdEvent[]) {
    this.chatListData.pushData(...data)
    if (this.chatListScroller.isAtEnd()) {
      this.chatListScroller.scrollEdge(Edge.Bottom)
    } else {
      this.isShowChatNewMessageTips = true
    }
  }

  clearDataToChatList() {
    this.chatListData.clearData()
  }
}