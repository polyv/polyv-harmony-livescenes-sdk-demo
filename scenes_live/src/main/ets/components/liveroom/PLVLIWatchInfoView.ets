import { PLVChannelData, PLVChatroomManager, PLVCommonConstants, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'

const TAG = '[PLVLIWatchInfoView]'

@Preview
@Component
export struct PLVLIWatchInfoView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @State chatroomManager: PLVChatroomManager | undefined = this.sdk?.chatroomManager
  // 为true时显示在线人数，为false时显示观看热度
  showOnlineUserNumber: boolean = true

  aboutToAppear(): void {
    this.onChannelData()
    this.onChatData()
  }

  build() {
    RelativeContainer() {
      Image(this.channelData?.liveDetail?.coverImage)
        .width(28)
        .height(28)
        .borderRadius(28)
        .margin({ left: 4 })
        .draggable(false)
        .alignRules({
          left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
        })
        .id('avatarImage')
      Text(this.channelData?.liveDetail?.getPublisher())
        .fontSize(14)
        .fontColor('#ffffff')
        .margin({ left: 4, top: 2 })
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          left: { anchor: 'avatarImage', align: HorizontalAlign.End }
        })
        .id('nickNameText')
      Text() {
        ImageSpan($r('app.media.plvli_watch'))
          .width(12)
          .height(12)
          .margin({ right: 3 })
          .verticalAlign(ImageSpanAlignment.CENTER)
        Span(this.showOnlineUserNumber ? this.chatroomManager?.onlineUserNumber + '' : this.channelData?.pageViewer + '')
          .fontColor('#ffffff')
          .fontSize(12)
      }
      .alignRules({
        left: { anchor: 'nickNameText', align: HorizontalAlign.Start },
        top: { anchor: 'nickNameText', align: VerticalAlign.Bottom },
        right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
      })
      .margin({ right: 8 })
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(1)
      .id('watchCountText')
    }
    .backgroundColor('#73000000')
    .borderRadius(36)
    .width(118)
    .height(36)
  }

  onChannelData() {
    this.channelData?.eventNotify.on('page_viewer', (arg: number) => {
      this.channelData!.pageViewer = arg
    }, this)
  }

  onChatData() {
    this.chatroomManager?.eventNotify.on('online_user_number', (arg: number) => {
      this.chatroomManager!.onlineUserNumber = arg
    }, this)
  }
}