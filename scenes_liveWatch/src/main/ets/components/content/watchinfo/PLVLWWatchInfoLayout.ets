import { PLVChannelData, PLVChatroomManager, PLVCommonConstants, PLVLiveSceneSDK, PLVUtils } from '@polyvharmony/live-scenes-sdk'
import { router } from '@kit.ArkUI'
import { MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus'

const TAG = '[PLVLWWatchInfoLayout]'

@Preview
@Component
export struct PLVLWWatchInfoLayout {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State chatroomManager: PLVChatroomManager | undefined = this.sdk?.chatroomManager
  @State isLayoutVisible: boolean = true
  // 为true时显示在线人数，为false时显示观看热度
  showOnlineUserNumber: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLayoutData()
    this.onChannelData()
    this.onChatData()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    Row() {
      Image($r("app.media.plvlw_common_back"))
        .padding(2)
        .width(28)
        .height(28)
        .draggable(false)
        .onClick(() => {
          if (PLVUtils.isLandscape()) {
            PLVUtils.changeOrientation(false)
          } else {
            router.back()
          }
        })
      RelativeContainer() {
        Image(this.channelData?.liveDetail?.coverImage)
          .width(28)
          .height(28)
          .borderRadius(28)
          .draggable(false)
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center }
          })
          .id('avatarImage')
        Text(this.channelData?.liveDetail?.getPublisher())
          .fontSize(12)
          .fontColor($r('app.color.plvlw_neutral_dark_white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .wordBreak(WordBreak.BREAK_ALL)
          .margin({ left: 4 })
          .alignRules({
            top: { anchor: 'avatarImage', align: VerticalAlign.Top },
            left: { anchor: 'avatarImage', align: HorizontalAlign.End },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .id('nickNameText')
        Text($r('app.string.plvlw_live_room_watch_count', this.showOnlineUserNumber ? this.chatroomManager?.onlineUserNumber + '' : this.channelData?.pageViewer + ''))
          .alignRules({
            left: { anchor: 'nickNameText', align: HorizontalAlign.Start },
            top: { anchor: 'nickNameText', align: VerticalAlign.Bottom },
            bottom: { anchor: 'avatarImage', align: VerticalAlign.Bottom },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .fontColor($r('app.color.plvlw_neutral_dark_white_60'))
          .fontSize(10)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .wordBreak(WordBreak.BREAK_ALL)
          .id('watchCountText')
      }
      .backgroundColor($r('app.color.plvlw_neutral_light_black_20'))
      .padding({ left: 4, right: 4 })
      .borderRadius(36)
      .width(136)
      .height(36)
    }
    .visibility(this.isLayoutVisible ? Visibility.Visible : Visibility.Hidden)
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(44)
    .padding({ left: 12 })
  }

  onLayoutData() {
    watchStates(() => {
      const isPortrait = this.layoutDataBus.isPortrait.value ?? true
      const isVisible = this.layoutDataBus.playerControllerStatus.value?.visible ?? false
      const isLocked = this.layoutDataBus.playerControllerStatus.value?.locked ?? false
      this.isLayoutVisible = isPortrait || (isVisible && !isLocked)
    }).pushTo(this.observers)
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